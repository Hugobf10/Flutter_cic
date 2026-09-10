# Mantenimiento

- Actualiza dependencias de forma planificada con `flutter pub outdated`; la revisión detectó paquetes con versiones posteriores, pero no actualizó ninguno.
- Ejecuta análisis y tests después de cada actualización.
- Revisa `pubspec.lock` junto con `pubspec.yaml`; no cambies paquetes por intuición.
- Revalida contratos de controladores, modelos, campos y permisos cada vez que se actualicen módulos Odoo.
- Mantén revisadas las traducciones ARB y regenera el código de localización con el flujo Flutter configurado.
- Rota claves de Sentry/Firebase/Odoo fuera de Git conforme a la política de infraestructura.

No hay procedimientos de backup de negocio en Flutter: los datos de negocio, adjuntos y sesiones están en Odoo/dispositivo. Los backups de Odoo se documentan en el repositorio de servidor.
