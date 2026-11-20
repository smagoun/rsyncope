#!/usr/bin/env python3
import binascii
from pathlib import Path
import re
import struct
import sys


def u16(data, offset):
    return struct.unpack_from(">H", data, offset)[0]


def u32(data, offset):
    return struct.unpack_from(">I", data, offset)[0]


def resources(path):
    binary = path.read_bytes()
    start = 128 + ((u32(binary, 83) + 127) & ~127)
    fork = binary[start:start + u32(binary, 87)]
    data = u32(fork, 0)
    resource_map = u32(fork, 4)
    types = resource_map + u16(fork, resource_map + 24)
    result = {}

    for i in range(u16(fork, types) + 1):
        entry = types + 2 + 8 * i
        resource_type = fork[entry:entry + 4]
        refs = types + u16(fork, entry + 6)
        for j in range(u16(fork, entry + 4) + 1):
            ref = refs + 12 * j
            resource_id = u16(fork, ref)
            pos = data + (u32(fork, ref + 4) & 0xffffff)
            result[(resource_type, resource_id)] = fork[pos + 4:pos + 4 + u32(fork, pos)]
    return result


def pstring(text):
    value = text.encode("ascii")
    return bytes([len(value)]) + value


def check_app(path, name, about, version, major, minor, bugfix):
    found = resources(path)
    prefix = bytes([major // 10 * 16 + major % 10, minor * 16 + bugfix, 0x80, 0, 0, 0])
    prefix += pstring(version)
    for resource_id in (1, 2):
        long_text = (
            f"{version}, Copyright (c) 2026 The rsyncope contributors"
            if resource_id == 1 else f"{name} {version}"
        )
        if found.get((b"vers", resource_id)) != prefix + pstring(long_text):
            raise ValueError(f"{path}: incorrect vers {resource_id}")
    if about and found.get((b"STR ", 128)) != pstring(f"rsyncope {version}"):
        raise ValueError(f"{path}: incorrect About title")
    print(f"ok - {name} version resources")


def check_bundle(path):
    with path.open("rb") as f:
        header = f.read(128)
    if len(header) != 128:
        raise ValueError(f"{path}: truncated header")
    if not header[73] & 0x20:
        raise ValueError(f"{path}: missing hasBundle")
    if binascii.crc_hqx(header[:124], 0) != u16(header, 124):
        raise ValueError(f"{path}: incorrect MacBinary CRC")
    print(f"ok - {path} hasBundle and header CRC")

    if path.suffix != ".bin":
        raise ValueError(f"{path}: unexpected filename")
    sidecar = path.with_name("%" + path.stem + ".ad")
    with sidecar.open("rb") as f:
        fixed = f.read(26)
        if len(fixed) != 26 or u32(fixed, 0) != 0x00051607:
            raise ValueError(f"{sidecar}: invalid AppleDouble header")
        found = False
        for _ in range(u16(fixed, 24)):
            entry = f.read(12)
            if len(entry) != 12:
                raise ValueError(f"{sidecar}: truncated entries")
            entry_id, offset, length = struct.unpack(">III", entry)
            if entry_id != 9 or length < 32:
                continue
            next_entry = f.tell()
            f.seek(offset + 8)
            flags = f.read(2)
            if len(flags) != 2:
                raise ValueError(f"{sidecar}: missing Finder flags")
            if not u16(flags, 0) & 0x2000:
                raise ValueError(f"{sidecar}: missing hasBundle")
            found = True
            f.seek(next_entry)
    if not found:
        raise ValueError(f"{sidecar}: missing Finder info")
    print(f"ok - {sidecar} hasBundle")


def main(gui, console, header):
    match = re.search(r'^#define RSYNCOPE_VERSION "(\d+)\.(\d)\.(\d)"$', header.read_text(), re.M)
    if not match:
        raise ValueError(f"invalid version in {header}")
    version = ".".join(match.groups())
    major, minor, bugfix = map(int, match.groups())
    if major > 99:
        raise ValueError("major version cannot be encoded in a vers resource")
    check_app(gui, "rsyncope", True, version, major, minor, bugfix)
    check_app(console, "rsync console", False, version, major, minor, bugfix)
    check_bundle(gui)


if __name__ == "__main__":
    if len(sys.argv) != 4:
        sys.exit("usage: python3 version_test.py GUI.bin CONSOLE.bin version.h")
    main(*(Path(arg) for arg in sys.argv[1:]))
