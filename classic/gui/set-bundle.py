#!/usr/bin/env python3
import binascii
import os
from pathlib import Path
import struct
import subprocess
import sys
import tempfile


def update_flags(path, offset):
    with path.open("r+b") as f:
        f.seek(offset)
        flags = f.read(2)
        if len(flags) != 2:
            raise ValueError(f"{path}: missing Finder flags")
        f.seek(offset)
        f.write(struct.pack(">H", struct.unpack(">H", flags)[0] | 0x2000))


def set_bundle(base, tools, host):
    bin_path = base.with_name(base.name + ".bin")
    with bin_path.open("r+b") as f:
        header = bytearray(f.read(128))
        if len(header) != 128:
            raise ValueError(f"{bin_path}: truncated header")
        header[73] |= 0x20
        struct.pack_into(">H", header, 124, binascii.crc_hqx(header[:124], 0))
        f.seek(0)
        f.write(header)

    sidecar = base.with_name("%" + base.name + ".ad")
    with sidecar.open("rb") as f:
        fixed = f.read(26)
        if len(fixed) != 26:
            raise ValueError(f"{sidecar}: truncated header")
        if struct.unpack_from(">I", fixed)[0] != 0x00051607:
            raise ValueError(f"{sidecar}: not AppleDouble")
        finder_offset = None
        for _ in range(struct.unpack_from(">H", fixed, 24)[0]):
            entry = f.read(12)
            if len(entry) != 12:
                raise ValueError(f"{sidecar}: truncated entries")
            entry_id, offset, length = struct.unpack(">III", entry)
            if entry_id == 9 and length >= 32:
                finder_offset = offset
    if finder_offset is None:
        raise ValueError(f"{sidecar}: missing Finder info")
    update_flags(sidecar, finder_offset + 8)

    if host == "Darwin":
        app = base.with_name(base.name + ".APPL")
        hex_info = subprocess.check_output(
            ["/usr/bin/xattr", "-px", "com.apple.FinderInfo", str(app)],
            text=True,
        )
        try:
            info = bytearray.fromhex(hex_info)
        except ValueError as exc:
            raise ValueError(f"{app}: invalid Finder info") from exc
        if len(info) != 32:
            raise ValueError(f"{app}: invalid Finder info")
        struct.pack_into(">H", info, 8, struct.unpack_from(">H", info, 8)[0] | 0x2000)
        subprocess.run(
            ["/usr/bin/xattr", "-wx", "com.apple.FinderInfo", info.hex(), str(app)],
            check=True,
        )
    else:
        update_flags(base.parent / ".finf" / (base.name + ".APPL"), 8)

    # hfsutils stores its current volume in HOME; isolate it from other builds.
    with tempfile.TemporaryDirectory() as home:
        env = dict(os.environ, HOME=home)
        subprocess.run([str(tools / "hmount"), str(base) + ".dsk"], env=env, check=True)
        try:
            subprocess.run([str(tools / "hdel"), ":rsyncope"], env=env, check=True)
            subprocess.run(
                [str(tools / "hcopy"), "-m", str(bin_path), ":rsyncope"],
                env=env,
                check=True,
            )
        finally:
            subprocess.run([str(tools / "humount")], env=env, check=True)


if __name__ == "__main__":
    if len(sys.argv) != 4:
        sys.exit("usage: python3 set-bundle.py OUTPUT_BASE HFS_TOOLS HOST_SYSTEM")
    set_bundle(Path(sys.argv[1]), Path(sys.argv[2]), sys.argv[3])
