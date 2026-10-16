#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
MIGRATIONS_DIR="${QUIREA_MIGRATIONS_DIR:-$ROOT/migrations}"
DATABASE_URL="${QUIREA_DATABASE_URL:-}"

if [[ -z "$DATABASE_URL" ]]; then
    printf '%s\n' 'QUIREA_DATABASE_URL is required.' >&2
    exit 1
fi

command -v psql >/dev/null 2>&1 || { printf '%s\n' 'psql is required.' >&2; exit 1; }
command -v sha256sum >/dev/null 2>&1 || { printf '%s\n' 'sha256sum is required.' >&2; exit 1; }

psql "$DATABASE_URL" -X -v ON_ERROR_STOP=1 -q <<'SQL'
CREATE TABLE IF NOT EXISTS schema_migrations (
    version text PRIMARY KEY,
    checksum text NOT NULL,
    applied_at timestamptz NOT NULL DEFAULT now()
);
SQL

for file in "$MIGRATIONS_DIR"/*.sql; do
    [[ -f "$file" ]] || continue
    name="$(basename "$file")"
    version="${name%%_*}"
    checksum="$(sha256sum "$file" | awk '{print $1}')"
    existing="$(psql "$DATABASE_URL" -XAtq -v ON_ERROR_STOP=1 -c "SELECT checksum FROM schema_migrations WHERE version = '$version'")"
    if [[ -n "$existing" ]]; then
        if [[ "$existing" != "$checksum" ]]; then
            printf 'Migration %s checksum mismatch.\n' "$name" >&2
            exit 1
        fi
        printf '[OK] %s already applied\n' "$name"
        continue
    fi
    psql "$DATABASE_URL" -X -v ON_ERROR_STOP=1 --single-transaction -q -f "$file" -c "INSERT INTO schema_migrations(version, checksum) VALUES ('$version', '$checksum')"
    printf '[OK] %s applied\n' "$name"
done
