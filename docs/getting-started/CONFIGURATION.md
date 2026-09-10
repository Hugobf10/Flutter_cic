# Configuración

## Variables de compilación confirmadas

| Variable | Finalidad | Valor por defecto en código |
| --- | --- | --- |
| `ODOO_BASE_URL` | URL HTTPS de Odoo | staging de CICancer |
| `ODOO_DATABASE` | Base de datos Odoo | base staging de CICancer |
| `APP_NAME` | Nombre de la app | `CICAPP` |
| `APP_VERSION` | Versión mostrada | `1.0.0` |
| `ALLOW_ADVANCED_LOGIN_CONFIG` | Muestra servidor y base de datos en el inicio de sesión | `false` |
| `WORDPRESS_API_URL` | Fuente HTTP de noticias de la pantalla de inicio | API pública de CICancer |
| `HTTP_TIMEOUT_SECONDS` | Timeout RPC | `30` |
| `RPC_RETRIES` | Reintentos de lectura | `2` |
| `SENTRY_DSN` / `SENTRY_ENV` | Observabilidad opcional | desactivada / `development` |
| `SENTRY_TRACES_SAMPLE_RATE` | Muestreo Sentry | `0.1` |
| `PUSH_NOTIFICATIONS_ENABLED` | Activa FCM | `false` |
| `FIREBASE_*` | Configuración pública FCM | vacía |

Ejemplo de desarrollo:

```bash
flutter run \
  --dart-define=ODOO_BASE_URL=https://odoo.example \
  --dart-define=ODOO_DATABASE=mi_base \
  --dart-define=APP_NAME=CICAPP
```

Por defecto, el formulario de inicio de sesión solo muestra usuario y contraseña
y utiliza `ODOO_BASE_URL` y `ODOO_DATABASE` de la compilación. Activa
`ALLOW_ADVANCED_LOGIN_CONFIG=true` exclusivamente en compilaciones de soporte
cuando sea necesario que la persona usuaria introduzca otro servidor o base de
datos. La política de URL sigue exigiendo un origen HTTPS válido.

## Sentry

Si `SENTRY_DSN` está vacío, no se inicializa Sentry. Si se configura, el código desactiva explícitamente PII, capturas de pantalla y jerarquía visual. Aun así, la política de retención, el proyecto Sentry y sus permisos no constan en el repositorio.

## Push

FCM no se inicia a menos que la bandera y los cuatro identificadores exigidos
por `hasPushConfiguration` (`FIREBASE_API_KEY`, `FIREBASE_APP_ID`,
`FIREBASE_MESSAGING_SENDER_ID` y `FIREBASE_PROJECT_ID`) estén presentes.
`FIREBASE_VAPID_KEY` se pasa al obtener el token cuando se ha definido, pero no
forma parte de esa comprobación previa. La cuenta de servicio Firebase pertenece
al entorno Odoo, nunca al binario ni a este repositorio. Consulta
`PUSH_NOTIFICATIONS_SETUP.md` y la documentación técnica antes de activarlo.

## Preferencias locales

La cookie/sesión Odoo se guarda en `flutter_secure_storage`. Preferencias de interfaz, idioma, URL/base de datos y claves de lectura de notificaciones usan `shared_preferences`. La app elimina las antiguas instantáneas de sesión que pudieran existir en preferencias sin cifrar.
