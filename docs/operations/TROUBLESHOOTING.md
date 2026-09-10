# Resolución de problemas

## El módulo no aparece

Comprueba el tipo de usuario, las ACL del modelo y los campos de permiso del contacto, o las capacidades que devuelve el bootstrap de portal. La app no puede ampliar permisos del servidor.

## El controlador móvil no responde

La app identifica respuestas no JSON de rutas móviles como controlador no disponible. Confirma que los módulos Odoo de portal están instalados y actualizados en el entorno objetivo.

## Un adjunto no abre

Revisa permisos del adjunto/registro, disponibilidad de datos base64, espacio del dispositivo y compatibilidad del tipo. El nombre local se sanea, por lo que caracteres especiales se sustituyen por `_`.

## El build release falla

En Android, comprueba `key.properties`, el keystore autorizado y el JDK compatible con Gradle. En iOS, confirma firma, perfiles y capacidades necesarias. Los valores exactos no están en Git.

## La app se cierra

El bootstrap instala un widget de error global y registra el tipo de error. Reproduce con `flutter run`, consulta logs saneados y revisa Sentry solo si está habilitado; no compartas datos sensibles.
