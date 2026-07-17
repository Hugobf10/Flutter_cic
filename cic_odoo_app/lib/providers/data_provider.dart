import 'package:flutter/material.dart';
import '../services/odoo_service.dart';
import '../services/portal_api_service.dart';

/// Provider genérico para cargar listas de registros Odoo.
class DataProvider extends ChangeNotifier {
  final OdooService _odoo = OdooService();
  final PortalApiService _portalApi = PortalApiService();

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
      final section = _portalSectionFor(model);
      final searchValue = _portalSearchValue(domain);
      final results = _odoo.isPortalSession && section != null
          ? await _portalApi.section(
              section,
              limit: limit ?? 200,
              params: searchValue == null ? const {} : {'q': searchValue},
            )
          : await _odoo.searchRead(
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
      _totalCount = _odoo.isPortalSession && section != null
          ? _records.length
          : await _odoo.searchCount(model, domain: domain);
    } catch (e) {
      _errorMessage = e.toString();
    }

    _isLoading = false;
    notifyListeners();
  }

  String? _portalSectionFor(String model) {
    const sections = {
      'calidad.documento': 'documents',
      'calidad.incidencia': 'incidents',
      'calidad.formacion.asistencia': 'training',
      'calidad.salud.reconocimiento': 'health',
      'calidad.normativa': 'normative',
      'calidad.objetivo': 'goals',
      'calidad.plan.accion': 'action_plans',
      'calidad.equipo': 'equipment',
      'calidad.quimico': 'chemicals',
      'calidad.proveedor.unidad': 'suppliers',
      'calidad.comunicacion': 'communications',
    };
    return sections[model];
  }

  String? _portalSearchValue(List<dynamic> domain) {
    for (final item in domain) {
      if (item is List && item.length >= 3 && item[1] == 'ilike') {
        final value = item[2]?.toString().trim();
        if (value != null && value.isNotEmpty) return value;
      }
    }
    return null;
  }

  void clearRecords() {
    _records = [];
    _totalCount = 0;
    notifyListeners();
  }
}
