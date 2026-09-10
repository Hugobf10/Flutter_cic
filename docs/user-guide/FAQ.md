# Preguntas frecuentes

## No veo un módulo

La pantalla se oculta cuando la app no recibe permiso de vista. En usuarios internos combina ACL del modelo con campos de permiso del contacto; en portal utiliza las capacidades del controlador móvil. Solicita revisión del usuario en Odoo.

## No puedo crear o editar

La app requiere capacidad de edición/creación y Odoo vuelve a validar la operación. Un módulo visible puede seguir ser solo de consulta.

## La aplicación rechaza mi servidor

Esto solo puede ocurrir en una compilación que tenga habilitada la configuración
avanzada de inicio de sesión. La app acepta únicamente un origen HTTPS con host,
sin credenciales en URL, query, fragmento ni ruta adicional. Confirma la URL
raíz con administración.

## No se restauró mi sesión

La sesión se guarda en almacenamiento seguro. Si no coincide con el servidor/base permitidos por la compilación, si caducó o si el almacenamiento seguro no está disponible, se pedirá iniciar sesión.

## No recibo notificaciones push

Push está desactivado por defecto. Requiere una compilación con configuración Firebase, permiso del dispositivo, registro correcto en Odoo y configuración del servidor. No se puede activar desde la interfaz.
