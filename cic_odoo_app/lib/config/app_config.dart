import 'app_env.dart';

/// Configuración centralizada de la app CIC Odoo.
class AppConfig {
  AppConfig._();

  static String get odooBaseUrl => AppEnv.odooBaseUrl;
  static String get odooDatabaseName => AppEnv.odooDatabase;

  static const String appName = String.fromEnvironment(
    'APP_NAME',
    defaultValue: 'CIC Salamanca',
  );

  static const String appVersion = String.fromEnvironment(
    'APP_VERSION',
    defaultValue: '1.0.0',
  );

  /// La configuración técnica del servidor permanece oculta en producción.
  /// Solo las compilaciones de soporte que la necesiten deben habilitarla.
  static const bool allowAdvancedLoginConfig = bool.fromEnvironment(
    'ALLOW_ADVANCED_LOGIN_CONFIG',
    defaultValue: false,
  );

  static const String wordpressApiUrl = String.fromEnvironment(
    'WORDPRESS_API_URL',
    defaultValue:
        'https://www.cicancer.org/wp-json/wp/v2/posts?per_page=5&_embed=1',
  );

  static const int httpTimeoutSeconds = int.fromEnvironment(
    'HTTP_TIMEOUT_SECONDS',
    defaultValue: 30,
  );

  static const int rpcRetries = int.fromEnvironment(
    'RPC_RETRIES',
    defaultValue: 2,
  );

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
    return uri != null &&
        uri.hasScheme &&
        (uri.scheme == 'http' || uri.scheme == 'https') &&
        uri.host.isNotEmpty;
  }
}
