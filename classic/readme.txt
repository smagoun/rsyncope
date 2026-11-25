rsyncope 0.1.0

rsyncope is a port of Apple's rsync Classic Mac OS. It transfers files
to or from an rsync daemon and keeps resource forks and Finder info.
Only changed files are sent, which is much faster and less-error prone
than syncing files by hand. For technical details, see the documentation
in the rsyncope project at http://github.com/smagoun/rsyncope .


OVERVIEW

rsyncope includes two applications:

  rsyncope: the windowed app with:
    - rsync Bookmarks window: your saved syncs, like an FTP client's
      bookmarks.  New... makes one; double-click (or Edit...) opens
      one for review; Sync runs it, Preview shows what would change
      (dry run).
    - Editor window: every option, a Choose... folder button, the
      equivalent command line, and To Console.
    - rsync Console window: the command line; type rsync commands, Up
      and Down arrows recall earlier ones, "help" lists built-ins.
    - The server: starts at launch when "rsyncd.conf" is next to the
      app.  Server > Start Server at Launch turns that off.

  rsync console: the same engine with only a console window, for
      scripting and testing.

Each bookmark names a server (an rsync daemon), a module and path on
it, a folder on this Mac, and the options: resource forks (netatalk
"._" files), resource forks only or data only, type/creator by name,
Mac line endings, daylight-saving tolerance, compression, and others.
Bookmarks are kept in the text file "rsync Bookmarks" next to the app.

REQUIREMENTS

- A 68k Classic Mac running Mac OS 7.1 or greater with MacTCP
- An rsync daemon for remote transfers (ssh is not supported)

Real hardware has not yet been tested.

SECURITY

Transfers are not encrypted. There is no SSH support; use only a
trusted network or a separately secured tunnel or VPN. A daemon
password does not protect data in transit.

SERVER

When "rsyncd.conf" is next to rsyncope, it starts the server at
launch and serves its configured folders to other computers:

    rsync -av -E dir/ rsync://<this Mac's address>/incoming/

(-E carries resource forks from a Mac running OS X.)  The status line
in the Bookmarks window shows the address.  Server > Start Server at
Launch turns the automatic start off.  To use the sample, copy it next
to the app, rename it "rsyncd.conf", and uncomment a module, its path
and "use chroot = no".  Restrict access to trusted hosts; use
"read only = yes" when writes are not needed.

USAGE

Local paths in console commands are HFS paths: Disk:Folder: or
:Folder: (relative to the app).  $(NAME) in a command comes from an
"rsync prefs" file next to the app (lines like  SRV = 192.168.1.10).

For detailed command-line examples, daemon setup, resource-fork
behavior, and netatalk setup, see USAGE.md.

TIPS

- Give the app at least 8 MB (Get Info > Memory) for large trees.
- For more information, see the README and documentation in the
  rsyncope distribution.
