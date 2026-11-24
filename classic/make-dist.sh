#!/bin/sh
# Package the built app for download:
#   <out>/rsyncope.img        4 MiB raw HFS volume image
#   <out>/rsyncope.dsk        identical image with a .dsk extension
#   <out>/rsyncope.bin        the application as MacBinary (StuffIt Expander)
#   <out>/rsync-console.bin   the console-only version, as MacBinary
# usage: classic/make-dist.sh <out-dir> [gui.bin] [console.bin]
set -e
S="$(cd "$(dirname "$0")" && pwd)"
if [ "$#" -lt 1 ] || [ "$#" -gt 3 ]; then
    echo "usage: $0 <out-dir> [gui.bin] [console.bin]" >&2
    exit 1
fi
OUT=$1
APP=${2:-$S/../build-classic/gui/rsyncope.bin}
CLI=${3:-$S/../build-classic/rsync/rsync.bin}
for f in "$APP" "$CLI"; do
    if [ ! -r "$f" ]; then
        echo "Cannot read application: $f" >&2
        exit 1
    fi
done
mkdir -p "$OUT"
T=$(mktemp -d)
trap 'rm -rf "$T"' 0
export HOME=$T
dd if=/dev/zero of="$OUT/rsyncope.img" bs=1024 count=4096 2>/dev/null
hformat -l "rsyncope" "$OUT/rsyncope.img" >/dev/null
hmount "$OUT/rsyncope.img" >/dev/null
hcopy -m "$APP" ":rsyncope"
hcopy -m "$CLI" ":rsync console"
tr '\n' '\r' < "$S/rsyncd.conf.sample" > "$T/conf.cr"; hcopy -r "$T/conf.cr" ":rsyncd.conf (sample)"
hattrib -t TEXT -c ttxt ":rsyncd.conf (sample)"
tr '\n' '\r' < "$S/readme.txt" > "$T/readme.cr"; hcopy -r "$T/readme.cr" ":Read Me"
hattrib -t TEXT -c ttxt ":Read Me"
tr '\n' '\r' < "$S/rsync-prefs.sample" > "$T/prefs.cr"; hcopy -r "$T/prefs.cr" ":rsync prefs (sample)"
hattrib -t TEXT -c ttxt ":rsync prefs (sample)"
hls -l
humount >/dev/null
cp "$APP" "$OUT/rsyncope.bin"
cp "$CLI" "$OUT/rsync-console.bin"
cp "$OUT/rsyncope.img" "$OUT/rsyncope.dsk"
rm -f -- "$OUT/rsync-console.dsk"
