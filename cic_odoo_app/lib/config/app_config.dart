import 'package:flutter/foundation.dart' show kReleaseMode;

import 'app_env.dart';
import 'server_policy.dart';

/// Configuración centralizada de la app CIC Odoo.
class AppConfig {
  AppConfig._();

  static String get odooBaseUrl => AppEnv.odooBaseUrl;
  static String get odooDatabaseName => AppEnv.odooDatabase;

  static const String appName = String.fromEnvironment(
    'APP_NAME',
    defaultValue: 'CICAPP',
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

  /// Push stays opt-in until CIC supplies a Firebase project configuration.
  /// These client values identify the app; the server credential never ships
  /// in the mobile binary.
  static const bool pushNotificationsEnabled = bool.fromEnvironment(
    'PUSH_NOTIFICATIONS_ENABLED',
    defaultValue: false,
  );
  static const String firebaseApiKey = String.fromEnvironment(
    'FIREBASE_API_KEY',
    defaultValue: '',
  );
  static const String firebaseAppId = String.fromEnvironment(
    'FIREBASE_APP_ID',
    defaultValue: '',
  );
  static const String firebaseMessagingSenderId = String.fromEnvironment(
    'FIREBASE_MESSAGING_SENDER_ID',
    defaultValue: '',
  );
  static const String firebaseProjectId = String.fromEnvironment(
    'FIREBASE_PROJECT_ID',
    defaultValue: '',
  );
  static const String firebaseVapidKey = String.fromEnvironment(
    'FIREBASE_VAPID_KEY',
    defaultValue: '',
  );

  static bool get hasPushConfiguration =>
      pushNotificationsEnabled &&
      firebaseApiKey.isNotEmpty &&
      firebaseAppId.isNotEmpty &&
      firebaseMessagingSenderId.isNotEmpty &&
      firebaseProjectId.isNotEmpty;

  static bool get hasValidBaseUrl {
    return isOdooTargetAllowed(odooBaseUrl, odooDatabaseName);
  }

  /// Prevents an accidental store build from silently using the repository's
  /// staging defaults. Support and beta builds can opt in explicitly.
  static bool isOdooTargetAllowed(String baseUrl, String database) {
    if (!ServerPolicy.isSecureOrigin(baseUrl) || database.trim().isEmpty) {
      return false;
    }
    return !kReleaseMode ||
        AppEnv.allowStagingInRelease ||
        (baseUrl.trim() != AppEnv.stagingBaseUrl &&
            database.trim() != AppEnv.stagingDatabase);
  }
}
