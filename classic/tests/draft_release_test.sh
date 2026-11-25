#!/bin/sh
set -eu
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
T=$(mktemp -d)
trap 'rm -rf "$T"' 0
REPO="$T/repo with spaces"
mkdir -p "$REPO/classic" "$T/bin" "$T/dist with spaces"
cp "$ROOT/classic/draft-release.sh" "$ROOT/classic/version.h" \
    "$ROOT/classic/readme.txt" "$ROOT/classic/USAGE.md" "$ROOT/classic/LICENSE" "$REPO/classic/"
cp "$ROOT/README.md" "$REPO/README.md"
git -C "$REPO" init -q
git -C "$REPO" add .
git -C "$REPO" -c user.name=Test -c user.email=test@example.invalid commit -qm initial

cat > "$T/bin/gh" <<'EOF'
#!/bin/sh
case "$1 $2" in
    "api repos/{owner}/{repo}/commits/"*) exit "${API_STATUS:-0}" ;;
    "api repos/{owner}/{repo}/git/matching-refs/tags/"*)
        printf '%s' "${REMOTE_TAG:-}"
        exit "${API_STATUS:-0}" ;;
    "release create")
        printf '%s\n' "$@" > "$GH_ARGS"
        ;;
    *) echo "unexpected gh arguments: $*" >&2; exit 1 ;;
esac
EOF
chmod +x "$T/bin/gh"
PATH="$T/bin:$PATH"
GH_ARGS="$T/gh-args"
export PATH GH_ARGS
DIST="$T/dist with spaces"
VERSION=$(sed -n 's/^#define RSYNCOPE_VERSION "\(.*\)"$/\1/p' "$REPO/classic/version.h")
TAG="v$VERSION"
printf 'image\n' > "$DIST/rsyncope.img"
printf 'binary\n' > "$DIST/file with spaces.bin"
printf 'hidden\n' > "$DIST/.hidden"
run_release() { sh "$REPO/classic/draft-release.sh" "$DIST"; }

run_release
grep -Fx -- "--draft" "$GH_ARGS" >/dev/null
grep -Fx -- "$(git -C "$REPO" rev-parse HEAD)" "$GH_ARGS" >/dev/null
grep -Fx -- "$TAG" "$GH_ARGS" >/dev/null
for asset in "$REPO/README.md" "$REPO/classic/readme.txt" \
    "$REPO/classic/USAGE.md" "$REPO/classic/LICENSE" \
    "$DIST/rsyncope.img" "$DIST/file with spaces.bin" "$DIST/.hidden"; do
    grep -Fx -- "$asset" "$GH_ARGS" >/dev/null
done

git -C "$REPO" tag -a "$TAG" -m test
REMOTE_TAG=$(git -C "$REPO" rev-parse "$TAG")
export REMOTE_TAG
run_release
REMOTE_TAG=0000000000000000000000000000000000000000
export REMOTE_TAG
rm "$GH_ARGS"
if run_release >"$T/out" 2>&1; then
    echo "expected mismatched remote tag to fail" >&2
    exit 1
fi
grep 'Remote tag .* does not match' "$T/out" >/dev/null
[ ! -e "$GH_ARGS" ]

unset REMOTE_TAG
printf 'change\n' >> "$REPO/README.md"
if run_release >"$T/out" 2>&1; then
    echo "expected dirty worktree to fail" >&2
    exit 1
fi
grep 'Commit tracked changes' "$T/out" >/dev/null
[ ! -e "$GH_ARGS" ]

git -C "$REPO" restore README.md
printf 'new source\n' > "$REPO/classic/untracked.c"
if run_release >"$T/out" 2>&1; then
    echo "expected untracked source to fail" >&2
    exit 1
fi
grep 'untracked source' "$T/out" >/dev/null
[ ! -e "$GH_ARGS" ]
rm "$REPO/classic/untracked.c"

API_STATUS=1
export API_STATUS
if run_release >"$T/out" 2>&1; then
    echo "expected GitHub API failure to fail" >&2
    exit 1
fi
[ ! -e "$GH_ARGS" ]
unset API_STATUS

printf 'extra\n' > "$DIST/README.md"
if run_release >"$T/out" 2>&1; then
    echo "expected duplicate asset name to fail" >&2
    exit 1
fi
grep 'Duplicate release asset name' "$T/out" >/dev/null
[ ! -e "$GH_ARGS" ]
echo "ok - draft release assets and revision checks"
