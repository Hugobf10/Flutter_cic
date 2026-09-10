# Instalación

## Obtener el código

```bash
git clone git@github.com:Hugobf10/Flutter_cic.git
cd Flutter_cic/cic_odoo_app
git checkout main
flutter pub get
```

La aplicación reside dentro de `cic_odoo_app/`; los comandos Flutter deben ejecutarse desde esa carpeta.

## Herramientas

`pubspec.yaml` declara Dart `^3.11.5`, Flutter y los paquetes requeridos. La versión concreta de Android Studio, Xcode, CocoaPods, SDK Android, JDK y los dispositivos de CI **no está determinada a partir del repositorio**.

Para Android se requiere un SDK Android configurado en Flutter. Para iOS y macOS se requiere macOS con Xcode y CocoaPods. Windows y Linux utilizan los proyectos generados por Flutter; sus dependencias de sistema deben seguir la guía oficial de Flutter de la plataforma correspondiente.

## Ejecutar en desarrollo

```bash
flutter run \
  --dart-define=ODOO_BASE_URL=https://odoo.example \
  --dart-define=ODOO_DATABASE=mi_base
```

La política del cliente solo acepta orígenes HTTPS, sin usuario embebido, query, fragmento ni ruta distinta de la raíz.

## Verificación de código

```bash
flutter analyze
flutter test
```

## Builds

```bash
flutter build apk --debug
flutter build apk --release
flutter build ios --release
flutter build web --release
```

El build Android de publicación exige la configuración de firma descrita en [Build y publicación](../operations/BUILD_AND_RELEASE.md). No se debe generar una clave nueva si ya existe una aplicación publicada sin confirmar primero el proceso de firma vigente.
