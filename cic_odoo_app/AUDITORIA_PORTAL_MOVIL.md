# Auditoria portal movil

La fuente de verdad es `calidad_portal` y los modulos que extienden sus rutas. La app nativa no usa WebView: consulta endpoints JSON autenticados que reutilizan los mismos dominios de partner, unidad, empresa y permisos que `/my/calidad`.

## Correspondencia web/Flutter

| Funcion web | Ruta/controlador/modelo | Flutter | Estado y accion |
| --- | --- | --- | --- |
| Inicio | `/my/calidad`, `CalidadPortalController._get_dashboard_values` | `PortalScreen`, `AuthProvider` bootstrap | Integrado con capacidades del servidor |
| Mi perfil | `/my/calidad/perfil`, `res.partner` | `ProfileScreen`, `EditProfileScreen` | Lectura y edicion limitada a campos permitidos por la web |
| Seguridad | `/my/calidad/seguridad`, `get_effective_permission_values` | `PortalSectionScreen(security)` | Integrado |
| Documentos | `/my/calidad/documentos`, `calidad.documento`, versiones y adjuntos | `DocumentosScreen` | Dominio web y descarga por endpoint seguro |
| Informacion entregada | `/my/calidad/informacion`, `calidad.informacion.partner_ids` | `PortalSectionScreen(information)` | Integrado |
| Formacion | `/my/calidad/formacion`, `calidad.formacion.asistencia` | `TrainingScreen`, registro externo | Listado y alta usan contrato movil |
| Salud | `/my/calidad/salud`, `calidad.salud.reconocimiento.partner_id` | `HealthScreen` | Lectura propia y dominio servidor |
| Normativa | `/my/calidad/normativa`, `calidad.normativa` por unidad | `NormativaScreen` | Integrado |
| Incidencias | `/my/calidad/incidencias`, `calidad.incidencia` por unidad | `IncidenciasScreen` | Listado/alta con dominio servidor |
| Objetivos | `/my/calidad/objetivos`, `calidad.objetivo` por unidad | `GoalsScreen` | Listado/alta con validacion servidor |
| Planes de accion | `/my/calidad/planes-accion`, `calidad.plan.accion` por unidad | `ActionPlansScreen` | Listado/alta/cambio de estado controlado |
| Equipos | `/my/calidad/equipos`, `calidad.equipo` por unidad | `EquipmentScreen` | Integrado |
| Quimicos | `/my/calidad/quimicos`, `calidad.quimico` por unidad | `ChemicalsScreen` | Listado y alta con validacion servidor |
| Proveedores | `/my/calidad/proveedores`, `calidad.proveedor.unidad` por unidad | `SuppliersScreen` | Consulta, alta y acciones permitidas |
| Comunicaciones | `/my/calidad/comunicaciones`, `calidad.comunicacion.partner_id` | `CommunicationsScreen` | Lectura propia |
| Sugerencias | `/my/calidad/sugerencias`, `calidad.comunicacion` | `SuggestionsScreen` y accion movil | Alta solo si el servidor la permite |
| Publicaciones | `/my/calidad/publicaciones`, `pubmed.publication` | `PortalSectionScreen(publications)` | Solo propias salvo grupo gestor |
| Reservas | `/my/reservas`, `reserva.reserva`, `product.template` reservable | `ReservasScreen` | Servicios, variantes, agenda, alta, confirmacion y QR |
| Reclutamiento | `/my/calidad/reclutamiento`, `hr.job` por entrevistador | `RecruitmentScreen` | Solo si el servidor devuelve puestos del usuario |
| Nominas | `/my/calidad/nominas`, `payroll.document.partner_id` | `PayrollScreen` | Solo documentos propios y adjuntos autorizados |
| QR | Datos reales de servicio/reserva, generado localmente | `ReservasScreen` | PNG temporal real para compartir iOS/Android |
| Compras | `purchase.order`, `product.product`, `purchase.order.line`, stock | `PurchasesScreen` | Exclusivo interno mediante API de `cic_modulo_compras` |

## Endpoints moviles

`calidad_portal`:

- `/my/calidad/mobile/bootstrap`
- `/my/calidad/mobile/section`
- `/my/calidad/mobile/action`
- `/my/calidad/mobile/attachment`

`cic_modulo_compras`:

- `/my/calidad/mobile/purchases/bootstrap`
- `/my/calidad/mobile/purchases/order`
- `/my/calidad/mobile/purchases/create`
- `/my/calidad/mobile/purchases/confirm`
- `/my/calidad/mobile/purchases/receive`

Todos son `auth="user"`, no aceptan un modelo o dominio arbitrario desde Flutter y validan el usuario y el registro antes de usar `sudo()`.
