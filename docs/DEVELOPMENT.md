# rsyncope Development

rsyncope is designed to be built with the [Retro68](https://github.com/autc04/Retro68) toolchain.

## Layout

| Path | What |
|---|---|
| `classic/macposix/` | POSIX on the File Manager and MacTCP: paths, descriptors, directories, `rename` that keeps resource forks, sockets/`poll`, the `--netatalk` storage backend, C99 `printf`, stubs |
| `classic/gui/` | The windowed application: `app.c` (event loop, menus, run queue, server), `bookmarks.c`, `editor.c`, `console.c`, `glue.c` |
| `classic/rsync/` | The command engine shared by both apps (`engine.c`), the console app (`front.c`), 68k `config.h`, `SIZE` resource |
| `openrsync/netatalk.c` | `--netatalk` mode (the virtual `._name` layer), shared with the Unix build |
| `openrsync/hfsname.c` | UTF-8 to HFS names: MacRoman, 31-byte limit with hash-suffixed mangling, `:` to `/`, case collisions |
| `classic/mptest/`, `classic/nettest/` | Self-tests that run inside Mac OS |
| `classic/tests/` | Host tests (`make -C classic/tests check`): `--netatalk` and `--mac-types`/`--mac-text`/`--dst-window` end to end against a stock rsync daemon, name rules, printf |
| `classic/emu/` | QEMU q800 scripts (`try-rsync.sh` for a client run, `try-daemon.sh` boots the Mac running the daemon and pushes to it through a forwarded port): boot unattended, run a test app or an rsync script, read the log back with `hfsutils` |
| `classic/make-dist.sh` | Packages both apps as disk images and MacBinary |

The About dialog is shared by both apps: `about.c` implements it and
`about.r` defines its resources; each app supplies its own name. The GUI's
other menus, dialog layouts, initial window and control definitions, and
static interface text are in `classic/gui/gui.r`. Editor DITL item order must match
the item enum in `classic/gui/editor.c`; window resizing, list contents, TextEdit,
and dynamic control state remain in code.

## Building

Using Retro68:

```bash
cmake -S classic -B build-classic \
  -DCMAKE_TOOLCHAIN_FILE=$PWD/Retro68-build/toolchain/m68k-apple-macos/cmake/retro68.toolchain.cmake
make -C build-classic        # build-classic/rsync/rsync.bin (MacBinary) and rsync.dsk
make -C classic/tests check-version  # verify version resources in both apps
```

For distribution, run `make -C build-classic dist`. This builds both apps and
places `rsyncope.img`, `rsyncope.dsk`, `rsyncope.bin`, and `rsync-console.bin`
in `build-classic/dist/`, ready to upload to a GitHub release. It requires
`hfsutils`. Run `make -C classic/tests check-dist` to verify packaging with a fresh build.

Retro68 can be built with either header set. The port is developed with the default, the Multiversal Interfaces. Apple's Universal Interfaces are used instead when they're installed in Retro68's `InterfacesAndLibraries` while building it; `classic/macposix/include/mactoolbox.h` picks the right headers for either. If a build with the Universal Interfaces trips on a missing name, rebuilding Retro68 with `--multiversal` is the known-good route.

The Unix build of openrsync, which the host tests use, is `cd openrsync && ./configure && make`. Run it in a copy, because `configure` rewrites the checked-in `config.h`.

## Testing in QEMU

See [`classic/emu/README.md`](../classic/emu/README.md) for the VM. The ROM and disk images are not in the repo. Then:

```bash
classic/emu/try-rsync.sh "rsync -av --delete rsync://10.0.2.2:8873/src/ :dest:"
```

This installs the built app in Startup Items, runs the command at boot, powers the Mac off, and prints `rsync log`. From QEMU's network, the host is 10.0.2.2.
