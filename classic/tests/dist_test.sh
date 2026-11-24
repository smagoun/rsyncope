#!/bin/sh
set -eu
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
SOURCE_BUILD=${1:-"$ROOT/build-classic"}
T=$(mktemp -d)
trap 'rm -rf "$T"' 0

if "$ROOT/classic/make-dist.sh" "$T/missing" "$T/no-app" 2>"$T/error"; then
    echo "expected packaging with a missing application to fail" >&2
    exit 1
fi
grep 'Cannot read application:' "$T/error" >/dev/null
[ ! -e "$T/missing" ]

TOOLCHAIN=$(sed -n 's/^CMAKE_TOOLCHAIN_FILE:[^=]*=//p' "$SOURCE_BUILD/CMakeCache.txt")
if [ ! -f "$TOOLCHAIN" ]; then
    echo "Cannot find Retro68 toolchain in $SOURCE_BUILD/CMakeCache.txt" >&2
    exit 1
fi
BUILD="$T/build with spaces"
cmake -S "$ROOT/classic" -B "$BUILD" "-DCMAKE_TOOLCHAIN_FILE=$TOOLCHAIN"
cmake --build "$BUILD" --target dist
cmp "$BUILD/gui/rsyncope.bin" "$BUILD/dist/rsyncope.bin"
cmp "$BUILD/rsync/rsync.bin" "$BUILD/dist/rsync-console.bin"
cmp "$BUILD/dist/rsyncope.img" "$BUILD/dist/rsyncope.dsk"
[ ! -e "$BUILD/dist/rsync-console.dsk" ]
[ "$(wc -c < "$BUILD/dist/rsyncope.img")" -eq 4194304 ]

cp "$BUILD/gui/rsyncope.bin" "$T/orphan.bin"
"$ROOT/classic/make-dist.sh" "$T/from-bin-only" "$T/orphan.bin" \
    "$BUILD/rsync/rsync.bin"
cmp "$T/orphan.bin" "$T/from-bin-only/rsyncope.bin"
cmp "$T/from-bin-only/rsyncope.img" "$T/from-bin-only/rsyncope.dsk"

mkdir "$T/old-dist"
printf 'old image\n' > "$T/old-dist/rsync-console.dsk"
"$ROOT/classic/make-dist.sh" "$T/old-dist" "$BUILD/gui/rsyncope.bin" \
    "$BUILD/rsync/rsync.bin"
[ ! -e "$T/old-dist/rsync-console.dsk" ]
cmp "$T/old-dist/rsyncope.img" "$T/old-dist/rsyncope.dsk"

mkdir "$T/home"
export HOME="$T/home"
hmount "$BUILD/dist/rsyncope.img" >/dev/null
hls -l > "$T/list"
grep 'APPL/rSnc .*rsyncope$' "$T/list" >/dev/null
grep 'APPL/rSnC .*rsync console$' "$T/list" >/dev/null
grep 'TEXT/ttxt .*Read Me$' "$T/list" >/dev/null
grep 'TEXT/ttxt .*rsyncd.conf (sample)$' "$T/list" >/dev/null
grep 'TEXT/ttxt .*rsync prefs (sample)$' "$T/list" >/dev/null
hcopy -m :rsyncope "$T/gui.bin"
hcopy -m ':rsync console' "$T/console.bin"
hcopy -r ':Read Me' "$T/readme"
hcopy -r ':rsyncd.conf (sample)' "$T/conf.cr"
hcopy -r ':rsync prefs (sample)' "$T/prefs.cr"
humount >/dev/null

tr '\n' '\r' < "$ROOT/classic/readme.txt" > "$T/readme.cr"
cmp "$T/readme.cr" "$T/readme"
tr '\r' '\n' < "$T/conf.cr" > "$T/conf"
tr '\r' '\n' < "$T/prefs.cr" > "$T/prefs"
cmp "$ROOT/classic/rsyncd.conf.sample" "$T/conf"
cmp "$ROOT/classic/rsync-prefs.sample" "$T/prefs"
if grep -n -v '^#\|^$' "$T/conf" "$T/prefs"; then
    echo "sample configuration must be entirely commented out" >&2
    exit 1
fi
awk '
    /^} rsync_daemon_params\[\] = \{/ { table = 1; next }
    table && /^};/ { exit }
    table && /^[[:space:]]*PARAM(_DFLT)?\("/ {
        split($0, parts, "\"")
        if (parts[2] != "pid file" && parts[2] != "lock file")
            print parts[2]
    }
' "$ROOT/openrsync/daemon_cfg.c" | LC_ALL=C sort > "$T/expected-params"
[ -s "$T/expected-params" ]
awk -F ' = ' '/^# [a-z][a-z -]* = / {
    sub(/^# /, "", $1); print $1
}' "$T/conf" | LC_ALL=C sort > "$T/sample-params"
if ! diff -u "$T/expected-params" "$T/sample-params"; then
    echo "sample daemon options do not match the supported examples" >&2
    exit 1
fi
grep 'There are no predefined options' "$T/prefs" >/dev/null
grep 'not environment variables' "$T/prefs" >/dev/null

for app in gui console; do
    case "$app" in
        gui) source="$BUILD/dist/rsyncope.bin" ;;
        console) source="$BUILD/dist/rsync-console.bin" ;;
    esac
    dd if="$source" of="$T/source-forks" bs=128 skip=1 2>/dev/null
    dd if="$T/$app.bin" of="$T/image-forks" bs=128 skip=1 2>/dev/null
    cmp "$T/source-forks" "$T/image-forks"
    flags=$(od -An -tu1 -j 73 -N 1 "$T/$app.bin")
    [ "$((flags & 32))" -ne 0 ]
done
grep 'transfers are not encrypted' "$T/readme" >/dev/null

echo "ok - distribution images and MacBinary files"
