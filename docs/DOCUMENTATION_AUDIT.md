# Auditoría de documentación

## Alcance y fuente de verdad

Fuente principal: `origin/main` del repositorio `Hugobf10/Flutter_cic`, revisado en el commit `16a6eb1` (`traduccion`). No existe una rama remota `staging`; por ello no se ha usado como referencia.

La auditoría de código contabiliza 89 archivos Dart bajo `cic_odoo_app/lib`, 16 archivos de test y tres documentos previos principales: `PRODUCTION.md`, `PUSH_NOTIFICATIONS_SETUP.md` y `AUDITORIA_PORTAL_MOVIL.md`.

## Comparativa

| Elemento previo | Código `main` | Estado |
| --- | --- | --- |
| README raíz | Solo contiene el nombre del repositorio | Obsoleto; sustituido por puerta de entrada |
| README de `cic_odoo_app` | Plantilla genérica Flutter | Obsoleto como manual de proyecto |
| `PRODUCTION.md`: HTTPS, secure storage, no reintentos de escritura, logging saneado | Confirmado en `ServerPolicy`, `OdooService`, `RpcExecutor` y `AppLogger` | Vigente |
| `PRODUCTION.md`: Sentry opcional y privacidad | Confirmado en `MonitoringService` y `AppConfig` | Vigente |
| `PRODUCTION.md`: OAuth y variables `USE_OAUTH` / `OAUTH_*` | No se encontró implementación OAuth activa en Dart ni esas variables en `AppConfig` | Parcialmente vigente / no tratar como activo |
| `PRODUCTION.md`: estado de release y pruebas contra staging | No comprobable sin infraestructura ni cuentas | No verificable |
| `PUSH_NOTIFICATIONS_SETUP.md` | FCM se configura por defines y registra token vía `push_register` | Parcialmente vigente; el servidor Firebase no consta aquí |
| `AUDITORIA_PORTAL_MOVIL.md` | Contexto histórico | Útil como antecedente; el código actual prevalece |

## Verificación realizada

- `flutter analyze`: sin incidencias en el checkout revisado.
- `flutter test`: 43 pruebas correctas sobre los 16 archivos existentes; la validez de la suite frente a Odoo real no puede certificarse sin entorno autorizado.
- No se ejecutaron builds de release, despliegues, publicación en stores ni pruebas con datos/usuarios reales.

## Riesgos técnicos encontrados

1. La documentación histórica de OAuth no coincide con la configuración Flutter actual y puede inducir a una compilación inválida.
2. El repositorio no contiene CI/CD, secretos de firma, configuración Firebase productiva ni contrato versionado de los controladores Odoo.
3. La autorización funcional depende de Odoo; cualquier cambio en modelos, controladores, ACL o record rules debe probarse de forma integrada.
4. La app declara traducción parcial y accesibilidad no certificada en todos los módulos.
5. `flutter pub get` informa de dependencias con versiones posteriores; una actualización requiere prueba controlada, no un upgrade masivo.
