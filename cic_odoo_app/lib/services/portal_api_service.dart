import 'package:flutter/foundation.dart';

import 'app_logger.dart';
import 'odoo_service.dart';
import 'odoo_values.dart';

/// Typed facade for the server-side equivalent of ``/my/calidad``.
class PortalApiService {
  PortalApiService({OdooService? odoo}) : _odoo = odoo ?? OdooService();

  final OdooService _odoo;

  Future<Map<String, dynamic>> bootstrap() async {
    final response = await _call('/my/calidad/mobile/bootstrap');
    if (response['ok'] != true) {
      throw StateError(
        'Odoo no ha podido calcular las capacidades de la intranet.',
      );
    }
    return response;
  }

  Future<List<Map<String, dynamic>>> section(
    String section, {
    int? recordId,
    int limit = 200,
    Map<String, dynamic> params = const {},
  }) async {
    final response = await _call(
      '/my/calidad/mobile/section',
      params: {
        'section': section,
        ...?(recordId == null ? null : {'record_id': recordId}),
        'limit': limit,
        ...params,
      },
    );
    final items = response['items'];
    if (items is! List) return [];
    return [...items.whereType<Map>().map(OdooValues.map)];
  }

  Future<Map<String, dynamic>> sectionPayload(
    String section, {
    int? recordId,
    Map<String, dynamic> params = const {},
  }) {
    return _call(
      '/my/calidad/mobile/section',
      params: {
        'section': section,
        ...?(recordId == null ? null : {'record_id': recordId}),
        ...params,
      },
    );
  }

  Future<Map<String, dynamic>> action(
    String name, {
    Map<String, dynamic> values = const {},
    int? recordId,
  }) async {
    return _call(
      '/my/calidad/mobile/action',
      params: {
        'action': name,
        ...?(values.isEmpty ? null : {'values': values}),
        ...?(recordId == null ? null : {'record_id': recordId}),
      },
    );
  }

  Future<Map<String, dynamic>> attachment({
    required String section,
    required int recordId,
    int? attachmentId,
  }) {
    return _call(
      '/my/calidad/mobile/attachment',
      params: {
        'section': section,
        'record_id': recordId,
        ...?(attachmentId == null ? null : {'attachment_id': attachmentId}),
      },
    );
  }

  Future<Map<String, dynamic>> _call(
    String path, {
    Map<String, dynamic> params = const {},
  }) async {
    try {
      final raw = await _odoo.callController(path, params: params);
      final response = OdooValues.map(raw);
      if (response.isEmpty) {
        throw FormatException('Respuesta vacía del controlador $path.');
      }
      return response;
    } catch (error, stackTrace) {
      AppLogger.error(
        'Error en controlador móvil de intranet',
        error: error,
        stackTrace: stackTrace,
        data: {'path': path, 'params': params},
        scope: 'portal.api',
      );
      if (kDebugMode) debugPrint(stackTrace.toString());
      rethrow;
    }
  }
}
