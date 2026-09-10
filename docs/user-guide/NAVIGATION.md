# Navegación

Tras autenticarse, `SuperAppShell` organiza el acceso a inicio, módulos, actividad/notificaciones y perfil. Las pantallas se cargan por primera vez al visitarlas.

```text
Inicio
├── Métricas y actividad
├── Acciones rápidas
├── Noticias
├── Bandeja de aprobaciones
└── Notificaciones

Módulos
├── Incidencias                 ├── Formación
├── Documentos                  ├── Seguridad
├── Información entregada       ├── Nóminas
├── Reclutamiento               ├── Reservas
├── Planificación               ├── Vigilancia Salud
├── Normativa                   ├── Equipos
├── Publicaciones               ├── Permisos y roles
├── Comunicaciones              ├── Proveedores
├── Compras                     └── Mantenimiento

Perfil
├── Editar perfil
├── Accesibilidad
└── Cerrar sesión
```

`Organización` figura en el registro de módulos, pero está marcada como no implementada y lleva a una pantalla de placeholder. Algunas claves antiguas (`elearning`, `roles`, `users`, `suggestions`) se conservan para enlaces o compatibilidad y se redirigen a su pantalla actual.

## Enlaces profundos

Android e iOS declaran el esquema `com.cic.flutter`. Android registra los hosts
`reservas` y `oauth`; iOS declara el esquema sin restringir hosts en su plist.
La app interpreta objetivos de reserva. El flujo OAuth efectivo **no está
determinado por el código Dart actual**: no se debe asumir que esté operativo
solo por existir el host o referencias históricas.
