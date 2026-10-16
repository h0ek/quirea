#!/usr/bin/env bash
set -euo pipefail

if (( $# != 1 )); then
    printf 'Usage: %s <wiki-git-url>\n' "$0" >&2
    exit 2
fi

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
REMOTE="$1"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

command -v git >/dev/null 2>&1 || { printf '%s\n' 'git is required.' >&2; exit 1; }
command -v rsync >/dev/null 2>&1 || { printf '%s\n' 'rsync is required.' >&2; exit 1; }

git clone "$REMOTE" "$TMP/wiki"
rsync -a --delete --exclude=.git "$ROOT/wiki/" "$TMP/wiki/"
git -C "$TMP/wiki" add -A

if git -C "$TMP/wiki" diff --cached --quiet; then
    printf '%s\n' 'Wiki is already up to date.'
    exit 0
fi

git -C "$TMP/wiki" commit -m "Sync Quirea wiki"
git -C "$TMP/wiki" push
