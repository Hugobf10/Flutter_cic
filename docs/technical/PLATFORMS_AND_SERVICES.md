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

FCM se inicializa solo con `PUSH_NOTIFICATIONS_ENABLED=true` y
`FIREBASE_API_KEY`, `FIREBASE_APP_ID`, `FIREBASE_MESSAGING_SENDER_ID` y
`FIREBASE_PROJECT_ID`. `FIREBASE_VAPID_KEY` es opcional en la comprobación de
arranque y se usa al obtener el token cuando está definido. La app registra el
token mediante la acción portal `push_register`, solicita permiso y escucha
renovación, primer plano, apertura e inicio desde una notificación. Antes de
cerrar sesión intenta desactivar el token en Odoo mediante `push_unregister`
y borra el token FCM local. No hay configuración Firebase de producción en el
repositorio. El procedimiento de configuración, aceptación y reversión está en
[Firebase y notificaciones push](../operations/FIREBASE_PUSH_NOTIFICATIONS.md).
