# Security

Quirea treats feed URLs, XML, HTML and images as untrusted content. The application runs in its own unprivileged systemd services and does not need access to other sites on the host.

The `0.1.0-dev` bootstrap includes baseline HTTP security headers and isolated service units. **It does not yet implement accounts, TOTP, a hardened RSS fetcher or the full security controls of the finished reader.** Do not treat it as a production-ready public service.

The planned fetcher must prevent SSRF through DNS, redirects and resolved IPs; reject unsafe XML, sanitize HTML and safely proxy/cache images. Authentication must use Argon2id, server-side sessions, proper authorization, CSRF protection, login throttling and optional TOTP with recovery codes. Instance analytics should avoid storing unnecessary reading history.

## Reporting a vulnerability

Please **do not post security vulnerabilities in public GitHub Issues**. After creating the repository, enable GitHub **Settings → Advanced Security → Private vulnerability reporting** and use the repository's **Security → Report a vulnerability** feature for private reports.

Include the affected release, steps to reproduce, impact and minimal proof of concept. Remove passwords, tokens and unrelated private data. Normal bugs and suggestions belong in the GitHub Issue templates.
