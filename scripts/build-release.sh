#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
VERSION="$(cat "$ROOT/VERSION")"
ARCH="$(go env GOARCH)"
OS="$(go env GOOS)"
OUT="$ROOT/dist/quirea-$VERSION-$OS-$ARCH"

rm -rf "$OUT"
mkdir -p "$OUT/bin" "$OUT/web" "$OUT/migrations" "$OUT/deploy/systemd" "$OUT/deploy/nginx" "$OUT/scripts"

(cd "$ROOT" && CGO_ENABLED=0 go build -trimpath -ldflags "-s -w -X github.com/h0ek/quirea/internal/runtimeinfo.Version=$VERSION" -o "$OUT/bin/quirea" ./cmd/quirea)
(cd "$ROOT" && CGO_ENABLED=0 go build -trimpath -ldflags "-s -w -X github.com/h0ek/quirea/internal/runtimeinfo.Version=$VERSION" -o "$OUT/bin/quirea-worker" ./cmd/quirea-worker)

cp -a "$ROOT/web/static/." "$OUT/web/"
cp "$ROOT"/migrations/*.sql "$OUT/migrations/"
cp "$ROOT"/deploy/systemd/*.service "$OUT/deploy/systemd/"
cp "$ROOT"/deploy/nginx/* "$OUT/deploy/nginx/"
cp "$ROOT"/scripts/install.sh "$ROOT"/scripts/preflight.sh "$ROOT"/scripts/migrate.sh "$OUT/scripts/"
cp "$ROOT"/config/quirea.env.example "$OUT/"
cp "$ROOT"/README.md "$ROOT"/LICENSE "$ROOT"/VERSION "$OUT/"

tar -C "$ROOT/dist" -czf "$OUT.tar.gz" "$(basename "$OUT")"
sha256sum "$OUT.tar.gz" > "$OUT.tar.gz.sha256"
printf '%s\n' "$OUT.tar.gz"
