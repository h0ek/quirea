# Using Quirea

**The 0.1.0-dev bootstrap is not a functioning RSS reader.** It serves a basic landing page and lightweight health/status endpoints. You cannot create accounts, subscribe to feeds or import OPML yet.

The intended reading experience is visual and simple: Today, Unread and All, followed sources, categories, Favorites and Read Later. There will be three layouts only: Magazine (default), Cards and Compact. The interface is designed for desktop and phone browsers; no native mobile application is required.

Subscriptions will support standard RSS/Atom feeds and OPML import/export, including Feedly exports with category preservation. Thumbnail selection should prefer feed-provided images, then a suitable article image, with a consistent placeholder if none is available. Public Explore and account registration will be optional instance features.

The bootstrap already includes a simple language selector. It chooses from available translation files using the browser's preferred language unless the visitor selects another language. Before accounts exist, the selection is saved only in that browser. See [Translations](Translations).
