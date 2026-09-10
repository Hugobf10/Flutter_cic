# Build y publicación

## Validación previa

```bash
cd cic_odoo_app
flutter pub get
flutter analyze
flutter test
flutter build apk --release
flutter build ios --release
flutter build web --release
```

## Android

`PRODUCTION.md` exige `android/key.properties` con `storeFile`, `storePassword`, `keyAlias` y `keyPassword` para un release. El archivo y el keystore deben estar fuera de Git. El flujo actual falla de forma deliberada si falta una firma de publicación; no reutiliza la clave debug.

La identidad real de la clave, Play Console, package id publicado y proceso de distribución **no están determinados a partir del repositorio**.

## Configuración por entorno

El build de producción debe pasar `ODOO_BASE_URL` y `ODOO_DATABASE` propios. No debe depender del staging por defecto. Sentry y FCM son opt-in y requieren los defines correspondientes.

## Puerta de salida funcional

Antes de publicar: probar login, perfil, documentos, reservas, comunicaciones, permisos internos/portal, dispositivos reales, lector de pantalla, iOS/web y el backend Odoo desplegado. `PRODUCTION.md` no declara la aplicación lista para producción.
