# Introducción para usuarios

Flutter CIC es la aplicación móvil y multiplataforma que presenta capacidades de CICancer/Odoo según el usuario autenticado. No otorga permisos por sí misma: consulta el perfil, las ACL y las capacidades restringidas que calcula Odoo.

## Tipos de acceso

| Tipo | Cómo se determina | Consecuencia en la app |
| --- | --- | --- |
| Administrador | `session_info.is_admin` y sesión interna | Acceso funcional amplio; Odoo sigue validando cada operación |
| Usuario interno | `session_info` / perfil de Odoo | La app comprueba ACL de lectura, escritura y creación por modelo |
| Usuario portal | Capacidades de `/my/calidad/mobile/bootstrap` | La app usa controladores móviles restringidos, no el ORM genérico |
| Sin acceso | No cumple acceso de intranet/portal | Se muestra la pantalla de acceso no concedido |

## Acceso

En una compilación normal, inicia sesión con usuario y contraseña válidos: el
servidor HTTPS y la base de datos ya proceden de la configuración de esa
compilación. Las compilaciones de soporte pueden habilitar la configuración
avanzada para introducir servidor y base de datos; ambos deben ser válidos. Una
sesión guardada solo se restaura cuando coincide con el servidor y la base de
datos previstos por la compilación, salvo que esta permita explícitamente esa
configuración avanzada.

## Conceptos importantes

- **Módulo**: área funcional que aparece solo si existe permiso de vista.
- **Portal**: experiencia restringida para usuarios externos; los datos los entrega el controlador Odoo, ya filtrados.
- **Notificación**: actividad reciente que la app puede marcar como leída localmente.
- **Adjunto**: documento descargado desde Odoo; los adjuntos de portal se guardan de forma temporal.
- **Modo sin datos**: no es una función offline. La disponibilidad sin red no está determinada por el código como capacidad de negocio.

La interfaz está parcialmente localizada en español e inglés. El propio proyecto advierte que la traducción de todos los módulos continúa pendiente.
