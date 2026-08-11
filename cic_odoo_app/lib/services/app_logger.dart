import 'dart:convert';
import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';
import 'monitoring_service.dart';

class AppLogger {
  AppLogger._();

  static void info(
    String message, {
    Map<String, dynamic>? data,
    String scope = 'app',
  }) {
    _log('INFO', message, data: data, scope: scope);
  }

  static void warning(
    String message, {
    Map<String, dynamic>? data,
    String scope = 'app',
  }) {
    _log('WARN', message, data: data, scope: scope);
  }

  static void error(
    String message, {
    Object? error,
    StackTrace? stackTrace,
    Map<String, dynamic>? data,
    String scope = 'app',
  }) {
    _log(
      'ERROR',
      message,
      data: data,
      scope: scope,
      error: error,
      stackTrace: stackTrace,
    );
    if (error != null) {
      MonitoringService.captureException(
        error,
        stackTrace: stackTrace,
        hint: '$scope:$message',
      );
    }
  }

  static void _log(
    String level,
    String message, {
    Map<String, dynamic>? data,
    String scope = 'app',
    Object? error,
    StackTrace? stackTrace,
  }) {
    final payload = <String, dynamic>{
      'level': level,
      'scope': scope,
      'message': message,
      ...?(data == null ? null : {'data': data}),
    };
    developer.log(
      jsonEncode(payload),
      name: 'cic_superapp',
      error: error,
      stackTrace: stackTrace,
    );
    if (!kReleaseMode) {
      debugPrint(
        '[${payload['level']}] [$scope] $message ${data == null ? '' : jsonEncode(data)}',
      );
    }
  }
}
