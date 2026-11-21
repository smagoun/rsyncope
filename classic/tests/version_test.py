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


def check_app(path, name, about_name, version, major, minor, bugfix):
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
    if about_name and found.get((b"STR ", 128)) != pstring(f"{about_name} {version}"):
        raise ValueError(f"{path}: incorrect About title")
    print(f"ok - {name} version resources")


def check_shared_about(gui, console):
    gui_resources = resources(gui)
    console_resources = resources(console)
    for key in ((b"STR ", 129), (b"STR ", 130), (b"STR ", 131),
                (b"DITL", 128), (b"TEXT", 128)):
        if gui_resources.get(key) != console_resources.get(key):
            raise ValueError(f"{gui} and {console}: About resources differ at {key}")

    gui_dialog = gui_resources[(b"DLOG", 128)]
    console_dialog = console_resources[(b"DLOG", 128)]
    gui_title = pstring("About rsyncope")
    console_title = pstring("About rsync console")
    title_offset = gui_dialog.find(gui_title[1:])
    if (title_offset < 1 or gui_dialog[title_offset - 1] != len(gui_title) - 1 or
            console_dialog[title_offset - 1:title_offset + len(console_title) - 1] !=
            console_title):
        raise ValueError(f"{console}: incorrect About dialog name")
    gui_end = title_offset - 1 + len(gui_title)
    console_end = title_offset - 1 + len(console_title)
    gui_end += gui_end % 2
    console_end += console_end % 2
    if (gui_dialog[:title_offset - 1] != console_dialog[:title_offset - 1] or
            gui_dialog[gui_end:] != console_dialog[console_end:]):
        raise ValueError(f"{gui} and {console}: About dialog layouts differ")
    print("ok - shared About dialog resources")


def bundle_mappings(found, path):
    bundle = found.get((b"BNDL", 128))
    if bundle is None:
        raise ValueError(f"{path}: missing BNDL 128")
    mappings = {}
    offset = 8
    while offset < len(bundle):
        resource_type = bundle[offset:offset + 4]
        count = u16(bundle, offset + 4) + 1
        offset += 6
        for _ in range(count):
            local_id = u16(bundle, offset)
            resource_id = u16(bundle, offset + 2)
            mappings[(resource_type, local_id)] = resource_id
            offset += 4
    return mappings


def check_finder_icons(gui, console):
    gui_resources = resources(gui)
    console_resources = resources(console)
    gui_creator = gui.read_bytes()[69:73]
    console_creator = console.read_bytes()[69:73]
    if gui_creator == console_creator:
        raise ValueError(f"{gui} and {console}: application creator codes must differ")
    for path, found, creator in (
            (gui, gui_resources, gui_creator),
            (console, console_resources, console_creator)):
        bundle = found.get((b"BNDL", 128))
        if bundle is None or bundle[:4] != creator:
            raise ValueError(f"{path}: BNDL signature does not match application creator")

    icon_types = (b"ICN#", b"ics#", b"icl8", b"ics8", b"icl4", b"ics4")
    for icon_type in icon_types:
        if gui_resources.get((icon_type, 128)) is None:
            raise ValueError(f"{gui}: missing existing {icon_type.decode()} 128")
        if gui_resources.get((icon_type, 129)) is not None:
            raise ValueError(f"{gui}: unexpected console {icon_type.decode()} 129")
        if console_resources.get((icon_type, 129)) is None:
            raise ValueError(f"{console}: missing {icon_type.decode()} 129")

    gui_map = bundle_mappings(gui_resources, gui)
    console_map = bundle_mappings(console_resources, console)
    if gui_map.get((b"ICN#", 0)) != 128:
        raise ValueError(f"{gui}: BNDL does not select icon 128")
    if console_map.get((b"ICN#", 0)) != 129:
        raise ValueError(f"{console}: BNDL does not select icon 129")
    print("ok - Finder icons are assigned to the correct app")


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
    check_app(gui, "rsyncope", "rsyncope", version, major, minor, bugfix)
    check_app(console, "rsync console", "rsync console", version,
        major, minor, bugfix)
    check_shared_about(gui, console)
    check_finder_icons(gui, console)
    check_bundle(gui)
    check_bundle(console)


if __name__ == "__main__":
    if len(sys.argv) != 4:
        sys.exit("usage: python3 version_test.py GUI.bin CONSOLE.bin version.h")
    main(*(Path(arg) for arg in sys.argv[1:]))
