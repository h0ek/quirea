#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

if [[ -d .git ]]; then
    printf '%s\n' 'Git repository already initialized.'
    exit 0
fi

git init -b main
git add .
printf '%s\n' 'Repository initialized and files staged. Review them and create the first commit with your own Git identity.'
