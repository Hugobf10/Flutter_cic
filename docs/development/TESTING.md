# Tests y calidad

## Comandos

```bash
flutter analyze
flutter test
flutter test test/services/odoo_service_test.dart
```

La revisión de esta rama ejecutó `flutter analyze` sin incidencias. `flutter test` cubre archivos en `test/config`, `test/services`, `test/screens`, `test/theme` y el widget base.

| Área cubierta | Archivos principales |
| --- | --- |
| Configuración | `app_env_test.dart`, `server_policy_test.dart` |
| Sesión/Odoo | `odoo_service_test.dart`, `odoo_session_test.dart`, `session_storage_test.dart`, `rpc_executor_test.dart` |
| Privacidad/logs | `app_logger_test.dart` |
| Autorización | `auth_permissions_test.dart` |
| Pantallas | login, home, accesibilidad y destino de reservas |
| Tema/movimiento | `app_theme_test.dart`, `app_motion_test.dart` |

## Límites

Los tests no conectan con un Odoo real ni certifican ACL, record rules, controladores, push, cámara, PDF, OCR o publicación firmada. Antes de release deben hacerse pruebas integradas con cuenta interna y portal en el entorno autorizado.
