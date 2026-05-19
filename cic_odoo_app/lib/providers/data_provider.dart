import 'package:flutter/material.dart';
import '../services/odoo_service.dart';

/// Provider genérico para cargar listas de registros Odoo.
class DataProvider extends ChangeNotifier {
  final OdooService _odoo = OdooService();

  bool _isLoading = false;
  String? _errorMessage;
  List<dynamic> _records = [];
  int _totalCount = 0;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  List<dynamic> get records => _records;
  int get totalCount => _totalCount;

  /// Carga registros de un modelo con dominio y campos opcionales.
  Future<void> loadRecords(
    String model, {
    List<dynamic> domain = const [],
    List<String> fields = const [],
    int? limit,
    int? offset,
    String? order,
    bool append = false,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final results = await _odoo.searchRead(
        model,
        domain: domain,
        fields: fields,
        limit: limit,
        offset: offset,
        order: order,
      );
      if (append) {
        _records.addAll(results);
      } else {
        _records = results;
      }
      _totalCount = await _odoo.searchCount(model, domain: domain);
    } catch (e) {
      _errorMessage = e.toString();
    }

    _isLoading = false;
    notifyListeners();
  }

  void clearRecords() {
    _records = [];
    _totalCount = 0;
    notifyListeners();
  }
}
