# Depuración

## Flutter

```bash
flutter run
flutter analyze
flutter test --name "texto del test"
```

Usa DevTools para árbol de widgets, rendimiento y logs. `AppLogger` emite JSON estructurado en el canal `cic_superapp`; en debug también imprime mensajes saneados.

## Odoo

Comprueba, por este orden: URL HTTPS, base de datos, sesión, perfil/capacidades, ACL, record rules, controlador y datos. Un `AccessError` se muestra como falta de permisos. Un controlador móvil no disponible se traduce a una solicitud de actualizar la intranet móvil de Odoo.

## Errores frecuentes

| Síntoma | Diagnóstico |
| --- | --- |
| Login falla | Confirma HTTPS, base, credenciales y accesibilidad de Odoo |
| Módulo oculto | Revisa capacidades portal o ACL/campos `permiso_*` |
| Datos vacíos | No asumas bug: las record rules pueden filtrar todo |
| Acción duplicada | No reintentes manualmente sin comprobar el estado en Odoo |
| Push inactivo | Verifica banderas de compilación, permiso, Firebase y registro servidor |

Nunca pegues en tickets el contenido de sesión, adjuntos, contraseñas o tokens.
