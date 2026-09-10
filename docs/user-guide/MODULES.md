# Módulos funcionales

La siguiente tabla refleja `ModuleRegistry` y `ModuleRouter`. La columna de acceso resume la regla cliente; Odoo decide la autorización definitiva y el contenido visible.

| Módulo | Acciones visibles en app | Acceso cliente |
| --- | --- | --- |
| Incidencias | Listar, detalle, crear/editar, adjuntar y acciones de ciclo | `incidents.view` / capacidad portal |
| Formación | Consultar asistencia y completar/registrar formación según capacidad | `training.view` |
| Documentos | Consultar, descargar y abrir adjuntos | `documents.view` |
| Seguridad, Información, Publicaciones | Consulta de secciones de portal | Sin permiso específico en registro |
| Nóminas | Consulta de documentos salariales | ACL/capacidad de Odoo |
| Reclutamiento | Consulta de convocatorias/candidaturas asignadas | `recruitment.view`; interno y capacidad del backend |
| Reservas | Servicios, disponibilidad, agenda, crear, confirmar, cancelar o actualizar | ACL/capacidad de Odoo |
| Planificación | Entrada a objetivos, planes y químicos | Suma de permisos de sus subáreas |
| Vigilancia Salud | Reconocimientos e historial disponible | `health.view` |
| Normativa | Listado y consulta de normativa | `normative.view` |
| Equipos | Inventario y seguimiento | `equipment.view` |
| Permisos y roles | Roles y aprobaciones internas | `permissions.view`; no portal |
| Comunicaciones | Comunicaciones, sugerencias y destinatarios | `communications.view` |
| Proveedores | Consulta, alta/edición y detalle según capacidad | `suppliers.view` |
| Compras | Productos, pedidos, recepción y factura | Solo usuario interno con ACL |
| Mantenimiento | Solicitudes y equipos vinculados | Solo usuario interno con ACL |
| Organización | Placeholder | No implementado |

## Flujos principales

### Incidencia

```text
Abrir Incidencias → Crear o abrir registro → Completar campos/adjuntos
→ Enviar acción permitida → Odoo valida permisos, estado y reglas → Recargar listado
```

### Reserva

```text
Elegir servicio/variante → Consultar huecos → Seleccionar fecha y datos
→ Crear borrador o reserva → Confirmar o cancelar cuando el servidor lo permita
```

### Compras

```text
Buscar producto o escanear código → Crear pedido con proveedor y líneas
→ Confirmar → Registrar recepción → Consultar factura
```

La nomenclatura exacta de estados, los campos obligatorios y las transiciones son reglas del módulo Odoo desplegado y deben verificarse en ese entorno.
