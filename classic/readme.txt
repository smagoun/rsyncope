rsyncope

"rsyncope" opens two windows:

  rsync Bookmarks   your saved syncs.  New... makes one; double-click
                    (or Edit...) opens one for review; Sync runs it,
                    Preview shows what would change (dry run).
  rsync Console     the command line: type rsync commands, Up and Down
                    arrows recall earlier ones, "help" lists built-ins.

Each bookmark names a server (an rsync daemon), a module and path on
it, a folder on this Mac, and the options: resource forks (netatalk
"._" files), Apple -E (when the server is a Mac running OS X), delete
extras, type/creator by name, Mac line endings, daylight-saving
tolerance, compression.  Bookmarks are kept in the text file
"rsync Bookmarks" next to the app.

Copy the apps to a writable folder on an HFS disk.  A 68k Mac running
System 7.1 or Mac OS 8.1 is needed.  Host names need MacTCP DNR in the
System Folder.  Real hardware has not yet been tested.

Security: transfers are not encrypted.  There is no SSH support; use
only a trusted network or a separately secured tunnel or VPN.  A daemon
password does not protect data in transit.

Server: when "rsyncd.conf" is next to rsyncope, it starts the server at
launch and serves its configured folders to other computers:

    rsync -av -E dir/ rsync://<this Mac's address>/incoming/

(-E carries resource forks from a Mac running OS X.)  The status line
in the Bookmarks window shows the address.  Server > Start Server at
Launch turns the automatic start off.  To use the sample, copy it next
to the app, rename it "rsyncd.conf", and uncomment a module, its path
and "use chroot = no".  Restrict access to trusted hosts; use
"read only = yes" when writes are not needed.

Local paths in console commands are HFS paths: Disk:Folder: or
:Folder: (relative to the app).  $(NAME) in a command comes from an
"rsync prefs" file next to the app (lines like  SRV = 192.168.1.10).

"rsync console" is the same engine with only a console window, for
scripting.

Give the app at least 8 MB (Get Info > Memory) for large trees.
