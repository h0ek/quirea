# Installation

Quirea is designed to live alongside your existing sites, not take over the server. **The administrator prepares Linux, nginx, PostgreSQL, DNS and HTTPS.** The Quirea installer verifies requirements and adds only Quirea files and services. No Docker is required.

## Requirements

- Linux `amd64` or `arm64` with systemd
- Working nginx (distribution packages or nginx.org packages)
- PostgreSQL 16 or newer and `psql`
- A DNS hostname and HTTPS configured by the administrator
- `sha256sum`; `curl` and OpenSSL recommended
- Go toolchain only when building from source rather than installing release binaries

Quirea does not require PHP, MariaDB, Redis or Node.js and does not change existing installations of them.

## 1. Prepare the server

Use your distribution's package manager to install and start nginx and PostgreSQL. Package names and PostgreSQL versions depend on the distribution and configured repositories; check their official installation guides. Do not install duplicate nginx packages over an existing working nginx installation.

Check the components:

```bash
nginx -v
sudo nginx -t
psql --version
systemctl --version
```

Configure your chosen hostname and HTTPS independently. Do not alter unrelated virtual hosts, firewall rules or SELinux policy. Keep SELinux enforcing if your distribution uses it.

Create a dedicated database and role from a PostgreSQL administrative session:

```sql
CREATE ROLE quirea LOGIN PASSWORD 'choose-a-strong-unique-password';
CREATE DATABASE quirea OWNER quirea;
```

Use a local connection or correctly configured TLS for remote PostgreSQL. Never reuse another application's database role.

## 2. Get Quirea

When signed releases exist, download and verify the matching `linux-amd64` or `linux-arm64` archive. For the current source bootstrap, run from the repository root:

```bash
make test
make build
```

## 3. Preflight without changes

```bash
sudo ./scripts/install.sh --check
```

The check reports Linux architecture, systemd, nginx config health and layout, nginx worker user, PostgreSQL client, optional database connectivity and SELinux. To check PostgreSQL credentials, set `QUIREA_DATABASE_URL` in your environment without exposing the password in shell history. Preflight does not create files or install packages.

## 4. Install Quirea

```bash
sudo ./scripts/install.sh
```

The installer creates the `quirea` service account and installs owned files:

```text
/usr/local/bin/quirea
/usr/local/bin/quirea-worker
/usr/local/share/quirea/
/usr/local/lib/quirea/
/etc/quirea/
/var/lib/quirea/
/etc/systemd/system/quirea.service
/etc/systemd/system/quirea-worker.service
```

It does **not** install nginx/PostgreSQL, write to `nginx.conf`, create a vhost or modify other websites. See [Configuration](Configuration) for the next steps.

## 5. Configure and start

Edit `/etc/quirea/quirea.env`, run the SQL migrations using the installed migration script, and add a separate nginx vhost in your existing include layout. Test nginx before reloading it. Finally:

```bash
sudo systemctl enable --now quirea quirea-worker
quirea doctor
curl -fsS http://127.0.0.1:8174/healthz
```

The initial `doctor` and health endpoints are lightweight checks; they do not yet verify the full database and RSS pipeline. Check your other sites after introducing the new vhost.
