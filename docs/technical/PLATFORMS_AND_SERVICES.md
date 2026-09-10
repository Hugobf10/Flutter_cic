# Plataformas y servicios del dispositivo

## Android

El manifest declara internet, cámara, lectura de imágenes/almacenamiento y notificaciones. La actividad acepta los enlaces `com.cic.flutter://oauth` y `com.cic.flutter://reservas`. `usesCleartextTraffic` es `false` y `allowBackup` es `false`.

## iOS y macOS

iOS declara motivos de uso para cámara y biblioteca de fotos, además del
esquema de URL. En iOS, `NativeOcrChannel.swift` implementa OCR local mediante
Vision con español e inglés; la app Dart lo invoca en el canal
`com.cicancer.cic_odoo_app/native_ocr`.

El proyecto también contiene la plataforma macOS generada por Flutter, pero no
registra una implementación macOS de ese canal nativo. Por tanto, el OCR local
en macOS no está implementado por el código disponible.

## Adjuntos y PDF

`AttachmentService` selecciona archivos/PDF, codifica la carga en base64 y crea `ir.attachment` para flujos internos. Descarga adjuntos con `ir.attachment` o controlador portal, sanea el nombre local y los guarda temporalmente cuando corresponde. `syncfusion_flutter_pdfviewer` muestra PDF; `open_filex` abre tipos compatibles del sistema.

## Cámara y compras

`mobile_scanner` permite leer códigos de barras en Compras. La pantalla se integra con el servicio de compras de portal o modelos internos según el usuario.

## Push

FCM se inicializa solo con todos los `FIREBASE_*` requeridos y `PUSH_NOTIFICATIONS_ENABLED=true`. Registra el token mediante la acción portal `push_register`; solicita permiso, escucha renovación, primer plano y apertura. No hay configuración Firebase de producción en el repositorio.
