# Production Checklist

## Estado de la revisión — 5 septiembre 2026

Esta revisión no certifica todavía la aplicación como lista para producción.
Las notificaciones push reales siguen fuera del alcance de este cierre.

Verificación local: `flutter analyze` sin incidencias y `flutter test` con 43
pruebas correctas, incluidas migración de sesión sin fallback inseguro, política
HTTPS, redacción de logs, ausencia de reintentos de escritura y ajustes en español/
inglés a 320 × 640 con texto al 200 %. `flutter build apk --debug` compila; es una
APK de prueba, no una versión firmada/configurada para publicación.
Comprobado también el bloqueo de `assembleRelease --dry-run`: falta la firma
de publicación y el proceso se detiene con un mensaje explícito, sin usar la
clave debug. Para Gradle directo usar JDK 21 (el incluido en Android Studio);
el Java 25 de la terminal no es compatible con esta configuración.

Implementado en esta revisión:

- HTTPS obligatorio; sin credenciales de sesión en preferencias sin cifrar.
- Reintentos automáticos únicamente para lecturas identificadas. Las escrituras
  no se repiten tras un timeout: el servidor podría haberlas procesado ya.
- Sesión de administrador determinada por Odoo, nunca por el nombre de usuario.
- Registros de diagnóstico con redacción de credenciales y cargas de peticiones;
  las excepciones enviadas mediante MonitoringService conservan tipo y pila,
  no el mensaje original. Sin capturas de pantalla ni jerarquía visual en Sentry.
- Perfil → Accesibilidad: ampliación adicional sin limitar la ampliación del
  sistema, texto reforzado, alto contraste, reducción de movimiento, paleta
  alternativa para los chips de estado compartidos, explicación VoiceOver/TalkBack
  y botón de volver arriba. Preferencias persistentes.
- Español/inglés en ajustes de accesibilidad, navegación y parte del perfil.
  La interfaz avisa de que la traducción del resto de módulos está pendiente.
- Superficies compartidas sin sombras, tipografía Plus Jakarta Sans de la
  identidad previa, temas reutilizados y pestañas cargadas al visitarlas por
  primera vez.
- Android: permiso de red en release, tráfico HTTP deshabilitado, backup de la
  aplicación deshabilitado y firma release separada de la clave debug.

Pendiente antes de autorizar una publicación:

- Pruebas integradas contra staging con usuario portal e interno: foto de perfil,
  crear/confirmar/cancelar reservas, documentos y destinatarios de comunicaciones
  (incluidas unidades hijas). Los tests de widgets no verifican el despliegue Odoo.
- Auditoría de ACL/reglas de registro del servidor, operaciones sobre IDs ajenos,
  cambio de cuenta, cachés de documentos, estado y notificaciones entre sesiones.
  Ocultar módulos en Flutter no sustituye la autorización en Odoo.
- Completar y revisar traducciones de login, home y todos los módulos.
- Revisión completa de contraste, etiquetas, foco, objetivos táctiles y textos
  grandes en todas las pantallas. Prueba real con VoiceOver y TalkBack, incluidos
  documentos PDF y controles de plugins. No se declara conformidad WCAG todavía.
- Validación visual en móvil/tablet, navegación, scroll y rendimiento medido en
  dispositivos reales; build iOS y web, firma y distribución de producción.
- Revisar la telemetría automática de Sentry y sus integraciones antes de activarla;
  la redacción de AppLogger no cubre automáticamente otras fuentes de eventos.

Referencias usadas: [accesibilidad Flutter](https://docs.flutter.dev/ui/accessibility/ui-design-and-styling),
[pruebas de accesibilidad](https://docs.flutter.dev/ui/accessibility/accessibility-testing),
[firma Android](https://docs.flutter.dev/deployment/android#sign-the-app).

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
- `PUSH_NOTIFICATIONS_ENABLED` (optional; only after the Firebase acceptance test)
- `FIREBASE_API_KEY`, `FIREBASE_APP_ID`, `FIREBASE_MESSAGING_SENDER_ID`,
  `FIREBASE_PROJECT_ID` (required together when push is enabled)
- `FIREBASE_VAPID_KEY` (required for web push)
- `ALLOW_STAGING_IN_RELEASE=true` (only for a deliberate signed staging build)

Example:

```bash
flutter build apk --release \
  --dart-define=ODOO_BASE_URL=https://odoo.tuempresa.com \
  --dart-define=ODOO_DATABASE=tu_db \
  --dart-define=APP_NAME="CICApp" \
  --dart-define=SENTRY_DSN=https://<key>@sentry.io/<project> \
  --dart-define=SENTRY_ENV=production
```

Important:
- The development build keeps the CIC staging server/database as its default so
  testers can sign in without exposing technical fields.
- A production build must provide its own `ODOO_BASE_URL` and `ODOO_DATABASE`
  through `--dart-define`; this replaces the staging defaults. A release using
  either repository default is rejected unless it explicitly declares
  `ALLOW_STAGING_IN_RELEASE=true`.

## Security
- Password persistence has been removed.
- Odoo session snapshot is stored in secure storage (`flutter_secure_storage`).
- Login/database/url metadata are stored in preferences for convenience.
- FCM remains disabled until its public client configuration and the Odoo server
  secret are available. See `../docs/operations/FIREBASE_PUSH_NOTIFICATIONS.md`.

## Runtime resilience
- RPC calls include bounded timeouts; only explicit read-only operations retry.
- Invalid base URL is blocked at init with explicit error.
- Global fallback error widget added for unexpected UI crashes.

## Pre-release gate

Android release requiere `android/key.properties` con `storeFile`, `storePassword`,
`keyAlias` y `keyPassword`, apuntando a la clave de publicación autorizada. El archivo
y el keystore están excluidos de Git. No crear una clave nueva si ya existe una app
publicada: usar la clave/proceso de firma establecido. Sin configuración válida,
la compilación release falla deliberadamente; debug sigue disponible para pruebas.

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
