/// Configuración centralizada de la app CIC Odoo.
class AppConfig {
  AppConfig._();

  /// URL base de Odoo 17 (sin trailing slash).
  /// Recomendado inyectar con:
  /// --dart-define=ODOO_BASE_URL=https://tu-odoo.com
  static const String odooBaseUrl = String.fromEnvironment(
    'ODOO_BASE_URL',
    defaultValue: '',
  );

  /// Nombre de la base de datos de Odoo.
  /// --dart-define=ODOO_DATABASE=tu_db
  static const String odooDatabaseName = String.fromEnvironment(
    'ODOO_DATABASE',
    defaultValue: '',
  );

  /// Nombre visible de la aplicación.
  static const String appName = String.fromEnvironment(
    'APP_NAME',
    defaultValue: 'CIC Odoo',
  );

  /// Versión de la app.
  static const String appVersion = String.fromEnvironment(
    'APP_VERSION',
    defaultValue: '1.0.0',
  );

  /// Timeout general para peticiones HTTP (en segundos).
  static const int httpTimeoutSeconds = int.fromEnvironment(
    'HTTP_TIMEOUT_SECONDS',
    defaultValue: 30,
  );

  /// Reintentos para llamadas de red no autenticadas/intermitentes.
  static const int rpcRetries = int.fromEnvironment(
    'RPC_RETRIES',
    defaultValue: 2,
  );

  /// Observabilidad (Sentry)
  static const String sentryDsn = String.fromEnvironment(
    'SENTRY_DSN',
    defaultValue: '',
  );

  static const String sentryEnvironment = String.fromEnvironment(
    'SENTRY_ENV',
    defaultValue: 'development',
  );

  static const String _sentryTracesSampleRateRaw = String.fromEnvironment(
    'SENTRY_TRACES_SAMPLE_RATE',
    defaultValue: '0.1',
  );

  static double get sentryTracesSampleRate =>
      double.tryParse(_sentryTracesSampleRateRaw) ?? 0.1;

  static bool get hasSentry => sentryDsn.trim().isNotEmpty;

  static bool get hasValidBaseUrl {
    final uri = Uri.tryParse(odooBaseUrl);
    return uri != null && uri.hasScheme && (uri.scheme == 'http' || uri.scheme == 'https') && uri.host.isNotEmpty;
  }
}
