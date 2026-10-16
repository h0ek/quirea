# Configuration

Quirea stores service settings in `/etc/quirea/quirea.env`. Restrict this file to `root:quirea` with mode `0640` or stricter; it may contain secrets.

```text
QUIREA_LISTEN_ADDR=127.0.0.1:8174
QUIREA_INSTANCE_NAME=Quirea
QUIREA_BASE_URL=https://reader.example.org
QUIREA_DATABASE_URL=postgresql://quirea:password@127.0.0.1:5432/quirea?sslmode=disable
QUIREA_STATIC_DIR=/usr/local/share/quirea
QUIREA_WORKER_INTERVAL=1m
```

The database URL above is illustrative. Use your actual role, password, address and connection security settings. Do not commit credentials to Git.

## PostgreSQL migrations

Database migrations are numbered and checksum-checked. Never edit an already applied migration; add the next migration in a future release.

Run the installed script with credentials available to the `quirea` user, for example through a protected administrator-provided environment:

```bash
sudo -u quirea env QUIREA_DATABASE_URL='postgresql://...' /usr/local/lib/quirea/migrate.sh
```

Avoid leaving real passwords in shell history. The installed `quirea.env` is read by systemd; the standalone migration script does not automatically read that file.

## nginx reverse proxy

Quirea listens on `127.0.0.1:8174`; nginx terminates HTTPS. Example configurations are installed in `/etc/quirea/examples/` and provided in `deploy/nginx/` in the source tree.

The preflight inspects nginx with `nginx -V`, `nginx -T` and `nginx -t` instead of assuming the Debian `sites-enabled` directory. Official nginx.org packages may use `conf.d`, and custom layouts also work. The nginx worker may be `www-data`, `nginx` or another account; Quirea uses loopback TCP rather than a shared PHP socket.

Place the Quirea server block in an **already included** vhost directory, selecting a unique hostname. Never overwrite an existing file or change the global `nginx.conf` just to add Quirea. Confirm with:

```bash
sudo nginx -t
sudo systemctl reload nginx
```

On SELinux systems, arrange the narrowly scoped permission nginx needs to connect to Quirea's local port; do not disable SELinux.

## Application settings

Accounts, themes, registration modes, Explore, analytics and instance branding are not implemented in `0.1.0-dev`. Their settings will appear in the admin UI as those features are added. The public site should never display database credentials or detailed internal diagnostics.
