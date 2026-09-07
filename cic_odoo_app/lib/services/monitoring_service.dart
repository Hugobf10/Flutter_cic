import 'package:sentry_flutter/sentry_flutter.dart';

import '../config/app_config.dart';

class MonitoringService {
  MonitoringService._();

  static Future<void> init() async {
    if (!AppConfig.hasSentry) return;
    await SentryFlutter.init((options) {
      options.dsn = AppConfig.sentryDsn;
      options.environment = AppConfig.sentryEnvironment;
      options.tracesSampleRate = AppConfig.sentryTracesSampleRate;
      options.sendDefaultPii = false;
      options.attachScreenshot = false;
      // Explicit privacy safeguard; Sentry currently marks this option experimental.
      // ignore: experimental_member_use
      options.attachViewHierarchy = false;
    });
  }

  static Future<void> captureException(
    Object error, {
    StackTrace? stackTrace,
    String? hint,
  }) async {
    if (!AppConfig.hasSentry) return;
    await Sentry.captureException(
      // Server errors may embed SQL, user input or private record contents.
      // Keep the failure category and local stack, never the raw exception.
      StateError('Application failure: ${error.runtimeType}'),
      stackTrace: stackTrace,
      hint: Hint.withMap(<String, dynamic>{
        ...?(hint == null ? null : {'hint': hint}),
      }),
    );
  }
}
