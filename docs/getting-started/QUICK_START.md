# Guía rápida

## Requisitos

- Flutter estable compatible con el SDK `^3.11.5` declarado. El entorno de revisión usó Flutter 3.44.9 y Dart 3.12.2.
- Un emulador o dispositivo Flutter, o Chrome para web.
- Acceso HTTPS a Odoo y una base de datos Odoo autorizada.

## Arranque local

```bash
git clone git@github.com:Hugobf10/Flutter_cic.git
cd Flutter_cic/cic_odoo_app
flutter pub get
flutter analyze
flutter test
flutter run \
  --dart-define=ODOO_BASE_URL=https://odoo.example \
  --dart-define=ODOO_DATABASE=mi_base
```

No copies contraseñas, tokens de Sentry ni claves Firebase a `pubspec.yaml`, código Dart o Git. Los datos de Odoo se introducen en el inicio de sesión o se suministran en la compilación mediante `--dart-define`.

## Comprobación funcional mínima

1. La aplicación muestra la pantalla de inicio de sesión.
2. La URL no HTTPS se rechaza.
3. Con una cuenta autorizada aparece el panel principal.
4. Solo se muestran los módulos concedidos por Odoo.
5. Al cerrar sesión no se restaura una cookie desde preferencias sin cifrar.

Las pruebas contra datos reales de Odoo no están incluidas en el repositorio.
