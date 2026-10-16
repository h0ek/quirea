#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
START=0
CHECK_ONLY=0

for arg in "$@"; do
    case "$arg" in
        --check) CHECK_ONLY=1 ;;
        --start) START=1 ;;
        *) printf 'Unknown option: %s\n' "$arg" >&2; exit 2 ;;
    esac
done

"$ROOT/scripts/preflight.sh"

if (( CHECK_ONLY == 1 )); then
    exit 0
fi

if (( EUID != 0 )); then
    printf '%s\n' 'Run the installer as root.' >&2
    exit 1
fi

BINARY_DIR=""
if [[ -x "$ROOT/bin/quirea" && -x "$ROOT/bin/quirea-worker" ]]; then
    BINARY_DIR="$ROOT/bin"
elif [[ -x "$ROOT/dist/quirea" && -x "$ROOT/dist/quirea-worker" ]]; then
    BINARY_DIR="$ROOT/dist"
elif command -v go >/dev/null 2>&1 && [[ -d "$ROOT/cmd" ]]; then
    mkdir -p "$ROOT/dist"
    (cd "$ROOT" && CGO_ENABLED=0 go build -trimpath -o dist/quirea ./cmd/quirea && CGO_ENABLED=0 go build -trimpath -o dist/quirea-worker ./cmd/quirea-worker)
    BINARY_DIR="$ROOT/dist"
else
    printf '%s\n' 'Release binaries were not found and this package does not contain buildable source.' >&2
    exit 1
fi

if [[ -d "$ROOT/web/static" ]]; then
    STATIC_DIR="$ROOT/web/static"
elif [[ -d "$ROOT/web" ]]; then
    STATIC_DIR="$ROOT/web"
else
    printf '%s\n' 'Quirea web assets were not found.' >&2
    exit 1
fi

if [[ -f "$ROOT/config/quirea.env.example" ]]; then
    CONFIG_EXAMPLE="$ROOT/config/quirea.env.example"
elif [[ -f "$ROOT/quirea.env.example" ]]; then
    CONFIG_EXAMPLE="$ROOT/quirea.env.example"
else
    printf '%s\n' 'Quirea configuration example was not found.' >&2
    exit 1
fi

command -v useradd >/dev/null 2>&1 || { printf '%s\n' 'useradd is required to create the Quirea service account.' >&2; exit 1; }

if ! id quirea >/dev/null 2>&1; then
    NOLOGIN="$(command -v nologin 2>/dev/null || true)"
    if [[ -z "$NOLOGIN" ]]; then
        if [[ -x /usr/sbin/nologin ]]; then
            NOLOGIN=/usr/sbin/nologin
        elif [[ -x /sbin/nologin ]]; then
            NOLOGIN=/sbin/nologin
        else
            NOLOGIN=/bin/false
        fi
    fi
    useradd --system --home-dir /var/lib/quirea --shell "$NOLOGIN" --user-group quirea
fi

install -d -o root -g quirea -m 0750 /etc/quirea
install -d -o quirea -g quirea -m 0750 /var/lib/quirea
install -d -o root -g root -m 0755 /usr/local/share/quirea
install -d -o root -g root -m 0755 /usr/local/share/quirea/locales
install -d -o root -g root -m 0755 /usr/local/lib/quirea/migrations
install -d -o root -g root -m 0755 /etc/quirea/examples

install -o root -g root -m 0755 "$BINARY_DIR/quirea" /usr/local/bin/quirea
install -o root -g root -m 0755 "$BINARY_DIR/quirea-worker" /usr/local/bin/quirea-worker
install -o root -g root -m 0644 "$STATIC_DIR/index.html" /usr/local/share/quirea/index.html
install -o root -g root -m 0644 "$STATIC_DIR/app.css" /usr/local/share/quirea/app.css
install -o root -g root -m 0644 "$STATIC_DIR/app.js" /usr/local/share/quirea/app.js
for asset in logo.svg favicon.ico apple-touch-icon.png icon-192.png icon-512.png; do
    install -o root -g root -m 0644 "$STATIC_DIR/$asset" "/usr/local/share/quirea/$asset"
done
install -o root -g root -m 0644 "$STATIC_DIR"/locales/*.json /usr/local/share/quirea/locales/
install -o root -g root -m 0644 "$ROOT"/migrations/*.sql /usr/local/lib/quirea/migrations/
install -o root -g root -m 0755 "$ROOT/scripts/migrate.sh" /usr/local/lib/quirea/migrate.sh
install -o root -g root -m 0644 "$ROOT/deploy/nginx/quirea-server.conf.example" /etc/quirea/examples/nginx-server.conf
install -o root -g root -m 0644 "$ROOT/deploy/nginx/quirea-location.conf" /etc/quirea/examples/nginx-location.conf

if [[ ! -f /etc/quirea/quirea.env ]]; then
    install -o root -g quirea -m 0640 "$CONFIG_EXAMPLE" /etc/quirea/quirea.env
fi

install -o root -g root -m 0644 "$ROOT/deploy/systemd/quirea.service" /etc/systemd/system/quirea.service
install -o root -g root -m 0644 "$ROOT/deploy/systemd/quirea-worker.service" /etc/systemd/system/quirea-worker.service

systemctl daemon-reload

if [[ -n "${QUIREA_DATABASE_URL:-}" ]]; then
    QUIREA_MIGRATIONS_DIR=/usr/local/lib/quirea/migrations QUIREA_DATABASE_URL="$QUIREA_DATABASE_URL" /usr/local/lib/quirea/migrate.sh
fi

if (( START == 1 )); then
    systemctl enable --now quirea.service quirea-worker.service
fi

printf '%s\n' 'Quirea files installed.'
printf '%s\n' 'Configure /etc/quirea/quirea.env.'
printf '%s\n' 'Use /etc/quirea/examples/nginx-server.conf or nginx-location.conf for the existing nginx layout.'
printf '%s\n' 'Run nginx -t before reloading nginx.'
printf '%s\n' 'Run systemctl enable --now quirea quirea-worker when configuration is ready.'
