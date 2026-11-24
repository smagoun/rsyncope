# Using rsyncope

See the [project README](../README.md) for an overview, build instructions, and project status.

At the prompt in either application:

```
rsync -av --delete 192.168.1.10::src/MyApp/ "Macintosh HD:Projects:MyApp:"
rsync -av --delete $(SRV)::src/MyApp/ :MyApp:
```

* **Remote side:** an rsync daemon (`host::module/path` or `rsync://host/module/path`). The Mac has no ssh, so `host:path` doesn't work.
* **Local side:** an HFS path (`Disk:Folder:`, or `:Folder:` relative to the app). A trailing colon means "the folder's contents", like a trailing `/` in rsync.
* **`$(NAME)`:** taken from a text file `rsync prefs` next to the app, which holds lines like `SRV = 192.168.1.10`.
  Names are user-defined substitutions, not predefined settings or environment variables.
* **Resource forks:** on by default (`--netatalk`), described below. Turn off with `--no-netatalk`.
* **`--mac-types[=FILE]`:** files that arrive without a `._` sidecar get a type and creator chosen by name. The built-in table maps source/text files to `TEXT/ttxt` (SimpleText), `.rsrc` to `rsrc/RSED`, and so on. FILE adds or overrides entries, one per line: `.c TEXT KAHL` (THINK C), `Makefile TEXT MPS ` or `README TEXT R*ch`. A sidecar's own Finder info always wins.
* **`--mac-text[=EXTS]`:** files with these extensions are stored with Mac (CR) line endings. The default list is `.c .h .cp .cpp .cc .hpp .r .p .pas .a .s .asm .txt .make .mk`; give your own as `--mac-text=.c,.h,.r`. LF and CR are swapped as bytes, so rsync still sees the server's exact contents: unchanged files are skipped, `--checksum` agrees, and changes go as deltas. A file with CRLF ends up with LF-CR on the Mac and round-trips exactly. Off by default.
* **DST:** HFS dates are local time, so when daylight saving time starts or ends every local date shifts by an hour. A file whose size matches and whose date is off by exactly one hour (± `--modify-window`) is treated as unchanged. On by default in the Mac build; `--no-dst-window` turns it off. On Unix, `--dst-window` turns it on.
* **Host names** are looked up through the `MacTCP DNR` resolver in the System Folder (TCP/IP control panel's name server).
* **Built-in commands:**
  * `trace on` / `trace off` logs every file and network call.
  * `set NAME=VALUE` sets an environment variable. For example, `set RSYNC_GMT_OFFSET=-18000` pins the time zone (seconds east of UTC) for a Mac that never switches to daylight saving time.
  * `memory` prints the partition size, free memory, the largest free block and the lowest free memory since the last `memory` (the peak a command needed).
  * `quit` leaves the app.

## The Mac as a server (another computer pushes to it)

Type `rsync --daemon` at the prompt. It serves the modules in a text file `rsyncd.conf` next to the app, one connection at a time, until Cmd-. stops it. Folder paths in the config use the POSIX form, `/Disk/Folder`:

The distribution image includes commented samples of `rsync prefs` and
`rsyncd.conf`. The daemon sample provides option examples and notes Classic
Mac OS limitations. Rename and edit it before use.

```
[incoming]
    path = /Macintosh HD/Incoming
    read only = no
    use chroot = no
```

From the other computer:

```bash
rsync -av --delete dir/ rsync://192.168.1.20/incoming/dir/
```

* **Resource forks from a Mac running OS X** come across with its stock rsync's `-E` (`--extended-attributes`): `rsync -av -E dir/ rsync://classicmac/incoming/dir/`.
  * The Mac daemon reads Apple's format and turns the `._name` entries into resource forks and Finder info.
  * macOS's rsync reports those entries with the data fork's size, so forks are re-checked on every push. Delta transfer keeps that cheap.
* **From Linux**, a netatalk tree's `._name` files are enough; no option is needed.
* **Verified in QEMU:** pushes from rsync 3.2.7 and openrsync, `-E` pushes from the Linux build (which now also sends Apple's format), updates, `--delete` and a no-op run.

## Mac to Mac, and sending from the Mac

When the Mac sends (a push from the Mac, or anyone pulling from the Mac's server), each file with a resource fork or Finder info goes out as `name` plus a `._name` AppleDouble sidecar. So:

* **Another Mac** running this port unpacks the sidecars into real forks.
* **A Linux netatalk share** receives the sidecars, but a stock rsync daemon does not create Netatalk's separate metadata attribute. AFP may not expose the fork correctly even when the sidecar is intact. A push without `-E` that includes resource forks warns about this, including in previews and no-op runs; the app cannot determine whether a destination is a Netatalk share.
* **With `-E`,** the Mac also adds Apple's marker byte to each entry, so macOS's `rsync -E` unpacks them itself.

For an affected file on a Netatalk `ea = sys` volume, `nad set -l none filename` on the server creates metadata and made the fork readable in the observed case. This changes the file's color label and does **not** restore its original Finder info. It is not a general metadata-preservation solution. Verify the fork through AFP before relying on the copy, and keep the original.

Tested in QEMU between the Mac OS 8.1 and System 7.1 VMs, in both directions (`classic/emu/try-mac2mac.sh`):

* **What was copied:** pushes and pulls of a tree with resource forks, fork-only files, type/creator, MacRoman and 31-character names, and nested folders.
* **Repeat runs** sent nothing.
* **A changed fork** re-sent only that file.

**System 7.1 stamps resource forks.** Whenever any program writes a resource fork through the File Manager, System 7.1 stores a record of its own in bytes 48–125 of the fork: the file's name, a date and the fork lengths.

* That area is reserved for the system, so resource files work exactly as before.
* A copy written on 7.1 differs from its source only in those bytes.
* Mac OS 8.1 does the same, but rsync avoids it there by flushing each fork before closing it, so 8.1 copies are byte-for-byte identical.

## Server setup (Linux + netatalk 4)

Run a stock rsync daemon on the netatalk volume, with a module like this in `rsyncd.conf`:

```
[src]
    path = /srv/afp/Projects
    read only = yes
    uid = <share owner>
    gid = <share owner>
```

On the tested `ea = sys` volume, netatalk keeps resource forks in `._name` sidecars and Finder metadata in an extended attribute. Sidecars can also contain Finder info; a stock daemon transfers sidecars but not that attribute. The Mac side presents every local file's fork and Finder info as a virtual `._name`:

* The quick check (size and mtime) works on forks, so unchanged forks are not re-sent.
* Delta transfer works on forks.
* Received sidecars are unpacked into the real resource fork and Finder info.
* `--delete` and removed sidecars are handled.
* The sidecar's mtime is kept in the file's HFS backup date, so a fork-only change on the server re-sends only the fork.
