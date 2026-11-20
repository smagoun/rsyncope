# rsyncope

rsyncope is a port of `openrsync/` (Apple's current rsync, protocol 29) to Classic Mac OS, built with [Retro68](https://github.com/autc04/Retro68). It pulls a tree from an rsync daemon and keeps resource forks and Finder info. The design and the reasons behind it are in [`docs/CLASSIC_MACOS_PORT.md`](../docs/CLASSIC_MACOS_PORT.md).

## Overview

There are two applications:

* **rsyncope**, the windowed app (`classic/gui`):
  * **rsync Bookmarks:** one window listing your saved syncs, like an FTP client's bookmarks. New… creates one. Double-clicking (or Edit…) opens it for review. Sync runs it, and Preview does a dry run.
  * **The editor window:** has every option, a Choose… folder button, the equivalent command line, and To Console, which copies that command to the console.
  * **rsync Console:** the command line, with history on the Up and Down arrows. `help` lists the built-ins: `bookmarks`, `sync NAME`, `preview NAME`, `server on|off`, `set`, `trace`, `memory`, `clear`, `quit`.
  * **The server:** starts at launch when an `rsyncd.conf` is next to the app (Server > Start Server at Launch turns that off). A sync started from the GUI pauses the server between connections, and it resumes afterwards.
  * **Storage:** bookmarks are kept in the text file `rsync Bookmarks` next to the app.
* **rsync console**, the same engine with only a console window (`classic/rsync`). It's used for scripting and the emulator tests.

See [`USAGE.md`](USAGE.md) for command-line examples, daemon setup, resource-fork behavior, and netatalk setup.


## Requirements

* A 68k Classic Mac running Mac OS 7.1 or 8.1
* HFS storage and MacTCP DNR in the System Folder for host names
* An rsync daemon for remote transfers; ssh and rsync-over-ssh are not supported

Real hardware and performance have not yet been tested.

## Security

**Transfers are not secure.** The Classic Mac build supports only rsync-daemon connections, not ssh. The rsync daemon protocol sends file data and transfer metadata over the network without transport encryption. A daemon password may restrict access, but it does not protect the data while it is in transit.

Use rsync only over a trusted network or a separately secured tunnel/VPN. Prefer `read only = yes` for modules that do not need writes, restrict daemon access with a firewall or host allowlist, and do not transfer secrets over an untrusted network.

## Layout

| Path | What |
|---|---|
| `macposix/` | POSIX on the File Manager and MacTCP: paths, descriptors, directories, `rename` that keeps resource forks, sockets/`poll`, the `--netatalk` storage backend, C99 `printf`, stubs |
| `gui/` | The windowed application: `app.c` (event loop, menus, run queue, server), `bookmarks.c`, `editor.c`, `console.c`, `glue.c` |
| `rsync/` | The command engine shared by both apps (`engine.c`), the console app (`front.c`), 68k `config.h`, `SIZE` resource |
| `openrsync/netatalk.c` | `--netatalk` mode (the virtual `._name` layer), shared with the Unix build |
| `openrsync/hfsname.c` | UTF-8 to HFS names: MacRoman, 31-byte limit with hash-suffixed mangling, `:` to `/`, case collisions |
| `mptest/`, `nettest/` | Self-tests that run inside Mac OS |
| `tests/` | Host tests (`make -C classic/tests check`): `--netatalk` and `--mac-types`/`--mac-text`/`--dst-window` end to end against a stock rsync daemon, name rules, printf |
| `emu/` | QEMU q800 scripts (`try-rsync.sh` for a client run, `try-daemon.sh` boots the Mac running the daemon and pushes to it through a forwarded port): boot unattended, run a test app or an rsync script, read the log back with `hfsutils`; `make-dist.sh` packages the app as a 1.44 MB disk image and MacBinary |

The About dialog is shared by both apps: `about.c` implements it and
`about.r` defines its resources; each app supplies its own name. The GUI's
other menus, dialog layouts, initial window and control definitions, and
static interface text are in `gui/gui.r`. Editor DITL item order must match
the item enum in `gui/editor.c`; window resizing, list contents, TextEdit,
and dynamic control state remain in code.

## Building

```bash
# Retro68 (68k only), once:
git clone --recursive https://github.com/autc04/Retro68.git
mkdir Retro68-build && cd Retro68-build && ../Retro68/build-toolchain.bash --no-ppc --no-carbon
```

```bash
cmake -S classic -B build-classic \
  -DCMAKE_TOOLCHAIN_FILE=$PWD/Retro68-build/toolchain/m68k-apple-macos/cmake/retro68.toolchain.cmake
make -C build-classic        # build-classic/rsync/rsync.bin (MacBinary) and rsync.dsk
make -C classic/tests check-version  # verify version resources in both apps
```

Retro68 can be built with either header set. The port is developed with the default, the Multiversal Interfaces. Apple's Universal Interfaces are used instead when they're installed in Retro68's `InterfacesAndLibraries` while building it; `macposix/include/mactoolbox.h` picks the right headers for either. If a build with the Universal Interfaces trips on a missing name, rebuilding Retro68 with `--multiversal` is the known-good route.

The Unix build of openrsync, which the host tests use, is `cd openrsync && ./configure && make`. Run it in a copy, because `configure` rewrites the checked-in `config.h`.

## Testing in QEMU

See [`emu/README.md`](emu/README.md) for the VM. The ROM and disk images are not in the repo. Then:

```bash
classic/emu/try-rsync.sh "rsync -av --delete rsync://10.0.2.2:8873/src/ :dest:"
```

This installs the built app in Startup Items, runs the command at boot, powers the Mac off, and prints `rsync log`. From QEMU's network, the host is 10.0.2.2.

## Status

Working in QEMU q800 with Mac OS 8.1, against rsync 3.2.7:
* pull with resource forks and Finder info
* a second run transfers nothing
* fork-only and data-only changes are re-sent separately
* `--delete`
* MacRoman and long file names

Also working, in QEMU and in the host tests: host names via MacTCP DNR, `--mac-types`, `--mac-text`, and DST tolerance (checked on the Mac by shifting the clock an hour with `set RSYNC_GMT_OFFSET`).

Known issues:
* **Pushing resource forks:** Pushing a file that contains a resource fork to a non-macOS host may fail to set the correct file attributes on that file, resulting in netatalk or other clients being unable to read the resource fork.

Not done yet:

* **Local copies** (two Mac paths, e.g. from a mounted AFP volume) need a thread-based server (plan §3.6).
* **ssh support** rsync-over-ssh is not supported for either the client or server.
* **Real hardware.** Not yet run on a classic Mac, and speed has not been measured.
* **Repeated commands.** Several commands in one session reset getopt, verbosity and filter rules. Other global state in openrsync may still carry over, so if a second command misbehaves, quit and relaunch.
