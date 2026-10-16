# Operations

## Checks

```bash
systemctl status quirea quirea-worker
journalctl -u quirea -u quirea-worker --since today
quirea doctor
curl -fsS http://127.0.0.1:8174/healthz
curl -fsS http://127.0.0.1:8174/status
sudo nginx -t
```

In `0.1.0-dev`, `doctor`, `/healthz` and `/status` are basic diagnostics, not proof that database access or feed downloads work end-to-end.

## Backup

Back up the PostgreSQL database and `/etc/quirea/`; the latter can contain credentials. Use `pg_dump` with your usual protected PostgreSQL authentication and restore-test periodically. Store backups outside the server if possible and keep access restricted. Installed binaries can be restored from verified releases.

## Updates

An automatic GitHub-release updater is **not included in 0.1.0-dev**. For now, build or download the new release, verify it, back up database and configuration, read release notes, stop the two Quirea services, deploy the new version, run forward migrations and restart. Test health and the reader before reopening public traffic.

Database rollback is not guaranteed: restoring an older binary after a schema change may require restoring the matching database backup. Never assume changing the executable alone reverses migrations.

Each GitHub Release should explain, in plain language, what was added, fixed or changed and whether administrators must do anything. No separate changelog file is maintained.

## Remove Quirea

1. Back up user data and instance configuration if you may need them later.
2. Stop and disable only Quirea services:

```bash
sudo systemctl disable --now quirea quirea-worker
```

3. Remove the Quirea-specific nginx vhost or include that **you added**, check `nginx -t`, then reload nginx.
4. Remove Quirea-owned systemd unit files, `/usr/local/bin/quirea`, `/usr/local/bin/quirea-worker`, `/usr/local/share/quirea/` and `/usr/local/lib/quirea/`; run `systemctl daemon-reload`.
5. Only after confirming backups, decide separately whether to remove `/etc/quirea/`, `/var/lib/quirea/`, the `quirea` system user and the dedicated PostgreSQL database/role.

Do not delete databases, accounts, nginx config directories or other applications automatically. There is no one-click uninstall in this bootstrap.

## Troubleshooting

If the page fails, verify the service binds to the same loopback address as nginx `proxy_pass`, and test the app directly with curl. On SELinux hosts, inspect AVC denials before changing policy. If migrations fail, check the PostgreSQL role, database and connection settings. If other sites fail after a manual nginx edit, restore **only your Quirea vhost change** and retest nginx.
