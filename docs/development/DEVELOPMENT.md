# Desarrollo

## Preparación

```bash
cd cic_odoo_app
flutter pub get
flutter analyze
flutter test
```

Activa un dispositivo o emulador y utiliza `flutter run` con `--dart-define` para apuntar a un entorno autorizado. Nunca grabes secretos en `app_env.dart` ni `app_config.dart`.

## Convenciones observadas

- Pantallas en `lib/features/<dominio>/` o `lib/screens/`.
- Lógica de red centralizada en servicios; no crees clientes Odoo dispersos.
- Estado de sesión, panel y preferencias mediante `ChangeNotifier` y Provider.
- Portal: usa `PortalApiService`, no el ORM genérico como atajo.
- Llamadas de lectura pueden indicar `readOnly`; las que cambian datos no.
- Usa `OdooValues` al interpretar respuestas dinámicas y `OdooService.prettyError` para mensajes de usuario.
- Registra fallos con `AppLogger`, sin cargas sensibles.

## Añadir un módulo

1. Confirma primero en Odoo el modelo/controlador, ACL, record rules, campos y capacidades portal.
2. Crea la pantalla en la carpeta de dominio y el servicio/facade si aporta una responsabilidad nueva.
3. Registra el módulo en `ModuleRegistry` y enrútalo en `ModuleRouter`.
4. Añade la regla cliente de visibilidad/edición solo como mejora de UX; no sustituye Odoo.
5. Añade textos ARB si son visibles al usuario y genera localizaciones según la configuración del proyecto.
6. Añade pruebas unitarias/widget, ejecuta análisis y valida en un entorno Odoo de pruebas.

No modifiques el código generado bajo `lib/l10n/generated/` manualmente.
