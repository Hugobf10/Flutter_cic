import 'package:sentry_flutter/sentry_flutter.dart';

import '../config/app_config.dart';

class MonitoringService {
  MonitoringService._();

  static Future<void> init() async {
    if (!AppConfig.hasSentry) return;
    await SentryFlutter.init(
      (options) {
        options.dsn = AppConfig.sentryDsn;
        options.environment = AppConfig.sentryEnvironment;
        options.tracesSampleRate = AppConfig.sentryTracesSampleRate;
      },
    );
  }

  static Future<void> captureException(
    Object error, {
    StackTrace? stackTrace,
    String? hint,
  }) async {
    if (!AppConfig.hasSentry) return;
    await Sentry.captureException(
      error,
      stackTrace: stackTrace,
      hint: Hint.withMap(<String, dynamic>{...?(hint == null ? null : {'hint': hint})}),
    );
  }
}
