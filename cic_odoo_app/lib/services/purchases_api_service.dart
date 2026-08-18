import 'app_logger.dart';
import 'odoo_service.dart';
import 'odoo_values.dart';

class PurchasesApiService {
  PurchasesApiService({OdooService? odoo}) : _odoo = odoo ?? OdooService();

  final OdooService _odoo;

  Future<Map<String, dynamic>> bootstrap({String? query}) =>
      _call('/my/calidad/mobile/purchases/bootstrap', {'query': query ?? ''});

  Future<Map<String, dynamic>> detail({int? orderId, String? query}) =>
      _call('/my/calidad/mobile/purchases/order', {
        ...?(orderId == null ? null : {'order_id': orderId}),
        ...?(query == null ? null : {'query': query}),
      });

  Future<Map<String, dynamic>> createOrder({
    required int supplierId,
    required List<Map<String, dynamic>> lines,
  }) => _call('/my/calidad/mobile/purchases/create', {
    'supplier_id': supplierId,
    'lines': lines,
  });

  Future<Map<String, dynamic>> confirm(int orderId) =>
      _call('/my/calidad/mobile/purchases/confirm', {'order_id': orderId});

  Future<Map<String, dynamic>> receive(
    int orderId,
    List<Map<String, dynamic>> lineQuantities,
  ) => _call('/my/calidad/mobile/purchases/receive', {
    'order_id': orderId,
    'line_quantities': lineQuantities,
  });

  Future<Map<String, dynamic>> invoiceDocument({
    required int orderId,
    required int invoiceId,
  }) => _call('/my/calidad/mobile/purchases/invoice', {
    'order_id': orderId,
    'invoice_id': invoiceId,
  });

  Future<Map<String, dynamic>> _call(
    String path,
    Map<String, dynamic> params,
  ) async {
    try {
      final result = OdooValues.map(
        await _odoo.callController(path, params: params),
      );
      if (result['ok'] != true) {
        throw StateError('Respuesta de Compras no válida.');
      }
      return result;
    } catch (error, stackTrace) {
      AppLogger.error(
        'Error en API móvil de Compras',
        error: error,
        stackTrace: stackTrace,
        data: {'path': path},
        scope: 'purchases.api',
      );
      rethrow;
    }
  }
}
