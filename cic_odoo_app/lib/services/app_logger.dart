import 'dart:convert';
import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';
import 'monitoring_service.dart';

class AppLogger {
  AppLogger._();

  static const _sensitiveKeyFragments = <String>{
    'password',
    'passwd',
    'secret',
    'token',
    'authorization',
    'cookie',
    'session',
    'image_data',
    'cv_data',
    'datas',
    'params',
    'values',
    'email',
    'phone',
    'mobile',
    'error',
    'description',
    'descripcion',
    'body',
    'message',
  };

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
      error: error?.runtimeType.toString(),
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
    final safeData = data == null ? null : _sanitize(data);
    final payload = <String, dynamic>{
      'level': level,
      'scope': scope,
      'message': message,
      ...?(safeData == null ? null : {'data': safeData}),
    };
    developer.log(
      jsonEncode(payload),
      name: 'cic_superapp',
      error: error,
      stackTrace: stackTrace,
    );
    if (!kReleaseMode) {
      debugPrint(
        '[${payload['level']}] [$scope] $message ${safeData == null ? '' : jsonEncode(safeData)}',
      );
    }
  }

  static dynamic _sanitize(dynamic value, {String parentKey = ''}) {
    final normalizedKey = parentKey.toLowerCase();
    if (_sensitiveKeyFragments.any(normalizedKey.contains)) {
      return '[REDACTED]';
    }
    if (value is Map) {
      return value.map(
        (key, nested) => MapEntry(
          key.toString(),
          _sanitize(nested, parentKey: key.toString()),
        ),
      );
    }
    if (value is Iterable) {
      return value
          .map((item) => _sanitize(item, parentKey: parentKey))
          .toList();
    }
    final text = value?.toString() ?? '';
    if (text.length > 1000) return '[REDACTED:${text.length} chars]';
    return value is String || value is num || value is bool || value == null
        ? value
        : '[${value.runtimeType}]';
  }
}
