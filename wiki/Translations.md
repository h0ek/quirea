# Translations

English is the base interface language. Quirea loads small JSON dictionaries from `web/static/locales/`. The bootstrap ships with English (`en.json`) and Polish (`pl.json`).

To add a translation, copy `en.json` to a lower-case language code such as `de.json` or `pt-br.json`, keep the same message keys, and translate the string values. Set `name` to the language name displayed in the selector.

```json
{
  "name": "English",
  "messages": {
    "tagline": "Follow what matters.",
    "bootstrap": "Bootstrap build is running.",
    "language": "Language",
    "automatic": "Automatic"
  }
}
```

The server detects valid locale files automatically. The browser chooses a supported language based on its language preferences, with English as the fallback. Visitors can override the choice. Until account settings exist, the choice stays in the browser's local storage.

Translation content is added using DOM `textContent`, not HTML. Translations must not contain HTML or tracking scripts. Keep the files small and submit them via a pull request. New release archives and the installer include the locale files.

The current dictionary covers only the bootstrap page. More message keys will be added alongside future reader features. Avoid translating variable names, HTTP paths or configuration keys.
