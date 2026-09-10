# Integración con Odoo

## Autenticación y sesión

`OdooPasswordAuth` valida URL HTTPS y ejecuta autenticación nativa Odoo. Tras autenticarse, `OdooService` consulta `/web/session/get_session_info` y conserva el identificador activo al refrescar metadatos. La sesión se serializa en almacenamiento seguro; preferencias antiguas sin cifrar se eliminan, nunca se restauran.

## Dos vías de datos

| Tipo de usuario | Vía | Motivo |
| --- | --- | --- |
| Interno | JSON-RPC ORM: `search_read`, `read`, `create`, `write`, métodos | Odoo aplica ACL y record rules de los modelos |
| Portal | `/my/calidad/mobile/*` | El servidor devuelve capacidades y datos ya restringidos |

## Controladores confirmados

| Ruta | Uso |
| --- | --- |
| `/my/calidad/mobile/bootstrap` | Perfil y capacidades del portal |
| `/my/calidad/mobile/section` | Listados y detalle por sección |
| `/my/calidad/mobile/action` | Acciones de portal, incluyendo altas/ediciones permitidas |
| `/my/calidad/mobile/attachment` | Adjuntos restringidos |
| `/my/calidad/mobile/purchases/*` | Bootstrap, pedido, alta, confirmación, recepción y factura de compras |

## Secciones y acciones de portal

Secciones observadas: incidencias, formación, documentos, salud e historial, reservas y sus servicios/variantes/agenda, objetivos, planes, químicos e informe químico, normativa, equipos, comunicaciones, sugerencias, proveedores, nóminas, perfil y reclutamiento.

Acciones observadas: crear/actualizar incidencias, objetivos, planes, químicos, comunicaciones, sugerencias, proveedores y reservas; adjuntar a incidencias o comunicaciones; completar/crear formación; confirmar/cancelar reservas; registrar push y editar perfil. La autorización, las claves aceptadas y las transiciones pertenecen al código Odoo, no a Flutter.

## Modelos relevantes consultados directamente

`calidad.incidencia`, `calidad.formacion`, `calidad.formacion.asistencia`,
`calidad.documento`, `calidad.documento.version`, `calidad.objetivo`,
`calidad.plan.accion`, `calidad.quimico`, `calidad.normativa`,
`calidad.equipo`, `calidad.salud.reconocimiento`, `calidad.comunicacion`,
`calidad.perfil`, `calidad.proveedor.unidad`, `reserva.reserva`,
`reserva.session.type`, `purchase.order`, `purchase.order.line`,
`product.template`, `product.product`, `stock.picking`, `stock.move`,
`maintenance.request`, `payroll.document`, `hr.payslip`, `res.partner`,
`res.users` e `ir.attachment`.

Esta lista describe referencias de cliente, no garantiza que todos esos modelos estén disponibles en cada despliegue o perfil Odoo.
