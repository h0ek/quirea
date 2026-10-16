# Development

Quirea is a small, AGPLv3-licensed hobby project. Contributions that improve reading, performance, accessibility, security or installation are welcome; unnecessary dependencies and features unrelated to reading are not a goal.

## Work locally

Use a supported Go toolchain:

```bash
make test
make vet
make build
QUIREA_STATIC_DIR="$PWD/web/static" ./dist/quirea serve
```

The default local address is `http://127.0.0.1:8174`. CI runs Go tests and checks. Do not commit credentials, runtime data or generated `dist/` artifacts. Never change previously applied SQL migration files.

Bug reports and suggestions use the two GitHub Issue forms. For security issues, use the private vulnerability reporting workflow. Interface translations use JSON files; see [Translations](Translations).

## Release notes

Publish release notes on the **GitHub Release** for each tag. Keep them short, useful and human-readable. Use only the sections that actually apply:

```text
Added
- What users can do now

Fixed
- Which user-facing problems were resolved

Changed
- Important behavior changes

Upgrade notes
- Any required operator actions or migrations, or "No manual steps"
```

Link to GitHub's comparison between tags for anyone who wants the full code diff. Verify release archives and their checksums before publishing. Do not promise automatic updates until a tested and verified updater exists.

## GitHub Wiki

`wiki/` in the main repository is the documentation source. After creating the GitHub repository, enable Wiki and create the first `Home` page there. Then publish updates with:

```bash
./scripts/publish-wiki.sh git@github.com:h0ek/quirea.wiki.git
```

The script mirrors local `wiki/` to GitHub Wiki, including deleting pages that no longer exist locally. Edit local sources first; do not keep unique manual pages only on GitHub Wiki.
