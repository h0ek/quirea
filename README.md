# Quirea

<img src="web/static/logo.svg" alt="Quirea logo" width="76" height="76">

**Follow what matters.**

Quirea is a small, open-source feed reader built for reading, not for selling your attention. It is a hobby project for people who want to follow their own sources without ads, AI features, algorithms or subscription tiers.

The goal is a fast, visual reader that you can host yourself. A public Quirea instance may be offered later; no address is available yet.

## Status

**0.1.0-dev — technical bootstrap, not a usable RSS reader yet.** It includes the Go web server, worker skeleton, PostgreSQL schema, installation checks and deployment examples. Accounts, feeds and the reader interface are not implemented in this version.

## Installation

Quirea runs as a separate Linux service behind an existing nginx server, with PostgreSQL. No Docker, PHP or Node.js required. Prepare the server yourself; the installer checks the environment and installs Quirea-owned files only.

See the [Wiki](wiki/Home.md) for server preparation, installation, configuration, updates and removal.

## Local build

```bash
make test
make build
QUIREA_STATIC_DIR="$PWD/web/static" ./dist/quirea serve
```

Open `http://127.0.0.1:8174`.

## Help improve Quirea

Use [Issues](https://github.com/h0ek/quirea/issues) to report a bug or suggest a focused improvement. Please report security vulnerabilities privately via GitHub Security Advisories, not public issues. You can also contribute an interface translation; see the [Wiki](wiki/Translations.md).

## License

[GNU AGPLv3](LICENSE) · Copyright (c) 2025 hoek
