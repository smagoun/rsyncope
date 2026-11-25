#!/bin/sh
set -eu
S="$(cd "$(dirname "$0")" && pwd)"
ROOT="$(cd "$S/.." && pwd)"

if [ "$#" -ne 1 ]; then
    echo "usage: $0 <dist-dir>" >&2
    exit 1
fi
DIST=$1
cd "$ROOT"

if ! git diff --quiet || ! git diff --cached --quiet; then
    echo "Commit tracked changes before creating a release." >&2
    exit 1
fi
if [ -n "$(git ls-files --others --exclude-standard -- classic openrsync docs)" ]; then
    echo "Commit or remove untracked source and documentation files before creating a release." >&2
    exit 1
fi
VERSION=$(sed -n 's/^#define RSYNCOPE_VERSION "\([0-9][0-9]*\.[0-9][0-9]*\.[0-9][0-9]*\)"$/\1/p' "$S/version.h")
if [ -z "$VERSION" ] || [ "$(printf '%s\n' "$VERSION" | wc -l | tr -d ' ')" -ne 1 ]; then
    echo "Cannot determine a single release version from $S/version.h" >&2
    exit 1
fi
TAG="v$VERSION"
COMMIT=$(git rev-parse HEAD)

gh api "repos/{owner}/{repo}/commits/$COMMIT" --jq .sha >/dev/null
REMOTE_TAG=$(gh api "repos/{owner}/{repo}/git/matching-refs/tags/$TAG" \
    --paginate --jq ".[] | select(.ref == \"refs/tags/$TAG\") | .object.sha")
if [ -n "$REMOTE_TAG" ]; then
    if ! LOCAL_TAG=$(git rev-parse --verify "refs/tags/$TAG" 2>/dev/null) ||
       [ "$LOCAL_TAG" != "$REMOTE_TAG" ] ||
       [ "$(git rev-parse "refs/tags/$TAG^{commit}")" != "$COMMIT" ]; then
        echo "Remote tag $TAG does not match a local tag on HEAD; fetch and check the tag." >&2
        exit 1
    fi
fi

if [ ! -f "$S/LICENSE" ] || [ ! -r "$S/LICENSE" ]; then
    echo "Cannot read release license: $S/LICENSE" >&2
    exit 1
fi
set -- "$S/LICENSE"
for file in "$DIST"/* "$DIST"/.[!.]* "$DIST"/..?*; do
    [ -e "$file" ] || [ -L "$file" ] || continue
    if [ ! -f "$file" ] || [ ! -r "$file" ]; then
        echo "Release asset is not a readable file: $file" >&2
        exit 1
    fi
    name=${file##*/}
    for existing do
        if [ "${existing##*/}" = "$name" ]; then
            echo "Duplicate release asset name: $name" >&2
            exit 1
        fi
    done
    set -- "$@" "$file"
done
if [ "$#" -eq 1 ]; then
    echo "No distribution assets found in $DIST" >&2
    exit 1
fi
gh release create "$TAG" "$@" --draft --target "$COMMIT" \
    --title "rsyncope v$VERSION" --notes "Draft release for rsyncope v$VERSION."
