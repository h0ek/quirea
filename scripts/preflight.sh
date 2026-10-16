#!/usr/bin/env bash
set -euo pipefail

failures=0
warnings=0

ok() { printf '[OK] %s\n' "$1"; }
warn() { printf '[WARN] %s\n' "$1"; warnings=$((warnings + 1)); }
fail() { printf '[FAIL] %s\n' "$1"; failures=$((failures + 1)); }
info() { printf '[INFO] %s\n' "$1"; }

if [[ "$(uname -s 2>/dev/null || true)" == "Linux" ]]; then
    ok "Linux detected"
else
    fail "Linux is required"
fi

arch="$(uname -m 2>/dev/null || true)"
case "$arch" in
    x86_64|amd64) ok "Architecture: amd64" ;;
    aarch64|arm64) ok "Architecture: arm64" ;;
    *) fail "Unsupported architecture: ${arch:-unknown}" ;;
esac

if [[ -r /etc/os-release ]]; then
    os_name="$(. /etc/os-release; printf '%s' "${PRETTY_NAME:-${NAME:-Linux}}")"
    info "Operating system: $os_name"
fi

if command -v systemctl >/dev/null 2>&1 && [[ -d /run/systemd/system ]]; then
    ok "systemd detected"
else
    fail "systemd is required"
fi

if command -v nginx >/dev/null 2>&1; then
    nginx_version="$(nginx -v 2>&1 | sed -E 's#^nginx version: nginx/##')"
    ok "nginx detected: $nginx_version"
    if nginx -t >/dev/null 2>&1; then
        ok "nginx configuration test passed"
    else
        fail "nginx configuration test failed"
    fi
    nginx_dump="$(nginx -T 2>&1 || true)"
    nginx_user="$(printf '%s\n' "$nginx_dump" | sed -nE 's/^[[:space:]]*user[[:space:]]+([^ ;]+).*/\1/p' | head -n1)"
    if [[ -z "$nginx_user" ]]; then
        nginx_user="$(nginx -V 2>&1 | sed -nE 's/.*--user=([^ ]+).*/\1/p' | head -n1)"
    fi
    [[ -n "$nginx_user" ]] && info "nginx worker user: $nginx_user"
    if printf '%s\n' "$nginx_dump" | grep -Eq 'include[[:space:]]+[^;]*sites-enabled/\*'; then
        info "nginx vhost layout: sites-available/sites-enabled"
    elif printf '%s\n' "$nginx_dump" | grep -Eq 'include[[:space:]]+[^;]*conf\.d/\*\.conf'; then
        info "nginx vhost layout: conf.d"
    else
        info "nginx vhost layout: custom or not automatically classified"
    fi
else
    fail "nginx is required"
fi

if command -v psql >/dev/null 2>&1; then
    psql_version="$(psql --version | sed -E 's/^psql \(PostgreSQL\) ([0-9]+).*/\1/')"
    psql_full="$(psql --version | sed -E 's/^psql \(PostgreSQL\) //')"
    if [[ "$psql_version" =~ ^[0-9]+$ ]] && (( psql_version >= 16 )); then
        ok "PostgreSQL client detected: $psql_full"
    else
        fail "PostgreSQL 16 or newer is required; detected: $psql_full"
    fi
else
    fail "PostgreSQL client tools are required"
fi

if [[ -n "${QUIREA_DATABASE_URL:-}" ]] && command -v psql >/dev/null 2>&1; then
    if server_version="$(psql "$QUIREA_DATABASE_URL" -XAtq -v ON_ERROR_STOP=1 -c "SHOW server_version" 2>/dev/null)"; then
        ok "PostgreSQL connection succeeded: $server_version"
    else
        fail "PostgreSQL connection failed"
    fi
else
    warn "Database connection not tested; set QUIREA_DATABASE_URL to test it"
fi

command -v sha256sum >/dev/null 2>&1 && ok "sha256sum detected" || fail "sha256sum is required"
command -v openssl >/dev/null 2>&1 && ok "OpenSSL detected" || warn "OpenSSL not found"
command -v curl >/dev/null 2>&1 && ok "curl detected" || warn "curl not found"

if command -v getenforce >/dev/null 2>&1; then
    selinux="$(getenforce 2>/dev/null || true)"
    info "SELinux: ${selinux:-unknown}"
fi

if command -v php >/dev/null 2>&1; then
    php_version="$(php -r 'echo PHP_VERSION;' 2>/dev/null || true)"
    info "Existing PHP detected: ${php_version:-unknown}; Quirea does not use or modify PHP"
fi

if command -v mariadb >/dev/null 2>&1; then
    maria_version="$(mariadb --version 2>/dev/null | head -n1)"
    info "Existing MariaDB detected; Quirea does not use or modify MariaDB"
    [[ -n "$maria_version" ]] && info "$maria_version"
fi

if (( failures > 0 )); then
    printf '\nPreflight failed with %d error(s) and %d warning(s).\n' "$failures" "$warnings"
    exit 1
fi

printf '\nPreflight passed with %d warning(s).\n' "$warnings"
