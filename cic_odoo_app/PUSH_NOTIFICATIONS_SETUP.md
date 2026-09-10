# Activación futura de notificaciones push

> La guía operativa vigente está en
> [`../docs/operations/FIREBASE_PUSH_NOTIFICATIONS.md`](../docs/operations/FIREBASE_PUSH_NOTIFICATIONS.md).
> Este archivo conserva el resumen técnico junto a la aplicación.

La base ya está incluida, pero permanece desactivada hasta que exista un
proyecto de Firebase. No hay secretos en este repositorio.

## Lo que envía Odoo

- Una incidencia nueva llega únicamente a personas con un dispositivo
  registrado, permiso para ver incidencias y visibilidad sobre su unidad.
- Un cron revisa cada hora las reservas confirmadas y avisa al contacto unas
  24 horas antes. Cada reserva se marca después de una entrega correcta para
  evitar duplicados.

## Preparar el servidor Odoo

1. Actualizar `calidad_portal`, `calidad_incidencias` y
   `reservas_servicios_avanzado_cic`.
2. Instalar `google-auth` en el entorno Python que ejecuta Odoo.
3. Crear un proyecto Firebase y habilitar la API HTTP v1 de Cloud Messaging.
4. Crear una cuenta de servicio con permiso para enviar mensajes FCM y guardar
   el JSON como secreto de despliegue, nunca en Git ni en parámetros visibles
   de Odoo.
5. Configurar estas variables de entorno del proceso Odoo:

   ```text
   CIC_FCM_PROJECT_ID=tu-proyecto-firebase
   CIC_FCM_SERVICE_ACCOUNT_JSON={...json-completo-de-la-cuenta-de-servicio...}
   ```

Odoo usa ese secreto para obtener credenciales OAuth temporales y mandar cada
mensaje a Firebase. Los tokens de los móviles se registran automáticamente en
Odoo al iniciar sesión con una compilación push habilitada. Al cerrar sesión,
la aplicación solicita la baja del token en Odoo y elimina el token local para
evitar que un dispositivo compartido conserve avisos del usuario anterior.

## Crear la compilación móvil habilitada

Al compilar, aportar los valores públicos del proyecto Firebase:

```text
--dart-define=PUSH_NOTIFICATIONS_ENABLED=true
--dart-define=FIREBASE_API_KEY=...
--dart-define=FIREBASE_APP_ID=...
--dart-define=FIREBASE_MESSAGING_SENDER_ID=...
--dart-define=FIREBASE_PROJECT_ID=...
```

Para web se añade también `FIREBASE_VAPID_KEY`. La aplicación solicita el
permiso de notificaciones al entrar con sesión válida. Si falta cualquiera de
estos valores, no inicializa Firebase ni registra tokens.

## iPhone

Antes de generar la versión iOS hay que activar en Xcode las capacidades
**Push Notifications** y **Background Modes / Remote notifications**, y subir
la clave APNs del Apple Developer Account al proyecto Firebase. Esto es el
paso que depende de la cuenta de Apple; no se necesita para Android.

## Prueba de aceptación

1. Instalar la compilación habilitada en un móvil físico y aceptar permisos.
2. Confirmar que aparece un registro de dispositivo activo en Odoo.
3. Enviar una incidencia de prueba en una unidad visible para ese usuario.
4. Crear una reserva de prueba dentro de la ventana de 23–25 horas y ejecutar
   el cron de recordatorios de forma manual.
