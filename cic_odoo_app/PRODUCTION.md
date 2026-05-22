# Production Checklist

## Build config (required)
Use dart defines per environment:

- `ODOO_BASE_URL`
- `ODOO_DATABASE`
- `APP_NAME` (optional)
- `APP_VERSION` (optional)
- `HTTP_TIMEOUT_SECONDS` (optional)
- `RPC_RETRIES` (optional)
- `SENTRY_DSN` (optional, recomendado prod)
- `SENTRY_ENV` (optional, e.g. production/staging)
- `SENTRY_TRACES_SAMPLE_RATE` (optional, e.g. 0.1)
- `USE_OAUTH` (`true|false`)
- `OAUTH_CLIENT_ID` (required if `USE_OAUTH=true`)
- `OAUTH_DISCOVERY_URL` (required if `USE_OAUTH=true`)
- `OAUTH_REDIRECT_URL` (default `app://auth/callback`)
- `OAUTH_SCOPES` (default `openid profile email offline_access`)

Example:

```bash
flutter build apk --release \
  --dart-define=ODOO_BASE_URL=https://odoo.tuempresa.com \
  --dart-define=ODOO_DATABASE=tu_db \
  --dart-define=APP_NAME="CIC SuperApp" \
  --dart-define=SENTRY_DSN=https://<key>@sentry.io/<project> \
  --dart-define=SENTRY_ENV=production
```

Important:
- The app does not include a default Odoo URL/database in source code.
- Always provide `ODOO_BASE_URL` and `ODOO_DATABASE` via `--dart-define`.

## Security
- Password persistence has been removed.
- Odoo session snapshot is stored in secure storage (`flutter_secure_storage`).
- Login/database/url metadata are stored in preferences for convenience.
- OAuth tokens are stored in secure storage only.

## Runtime resilience
- RPC calls include timeout + retry strategy.
- Invalid base URL is blocked at init with explicit error.
- Global fallback error widget added for unexpected UI crashes.

## Pre-release gate
Run before every release:

```bash
flutter pub get
flutter analyze
flutter test
flutter build apk --release
flutter build ios --release
flutter build web --release
```

## Pre-push secret scan
Run before pushing to GitHub:

```bash
rg -n --hidden -S "(password|passwd|token|secret|apikey|api_key|bearer|authorization|BEGIN PRIVATE|client_secret)" . \
  -g'!.git' -g'!build' -g'!.dart_tool' -g'!ios/Pods' -g'!macos/Pods'
```
