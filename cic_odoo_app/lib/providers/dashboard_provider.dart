import 'package:flutter/material.dart';
import '../services/odoo_service.dart';

enum DashboardState { initial, loading, loaded, error }

/// Provider del dashboard ejecutivo. Consume calidad.dashboard.service.
class DashboardProvider extends ChangeNotifier {
  final OdooService _odoo = OdooService();

  DashboardState _state = DashboardState.initial;
  String? _errorMessage;

  Map<String, dynamic>? _dashboardData;
  Map<String, dynamic>? _filterOptions;
  Map<String, dynamic> _activeFilters = {};
  bool _permissionDenied = false;

  DashboardState get state => _state;
  String? get errorMessage => _errorMessage;
  Map<String, dynamic>? get dashboardData => _dashboardData;
  Map<String, dynamic>? get filterOptions => _filterOptions;
  Map<String, dynamic> get activeFilters => _activeFilters;
  bool get permissionDenied => _permissionDenied;

  // Getters de conveniencia
  List<dynamic> get kpis =>
      (_dashboardData?['kpis'] as List<dynamic>?) ?? [];
  List<dynamic> get alerts =>
      (_dashboardData?['alerts'] as List<dynamic>?) ?? [];
  Map<String, dynamic>? get charts =>
      _dashboardData?['charts'] as Map<String, dynamic>?;
  List<dynamic> get summaryByUnit =>
      (_dashboardData?['summary_by_unit'] as List<dynamic>?) ?? [];

  /// Carga los datos del dashboard.
  Future<void> loadDashboard({Map<String, dynamic>? filters}) async {
    _state = DashboardState.loading;
    _errorMessage = null;
    _permissionDenied = false;
    notifyListeners();

    try {
      if (filters != null) _activeFilters = filters;
      _dashboardData = await _odoo.getDashboardData(filters: _activeFilters);
      _state = DashboardState.loaded;
    } catch (e) {
      if (OdooService.isAccessError(e)) {
        _permissionDenied = true;
        _dashboardData = const {
          'kpis': [],
          'alerts': [],
          'summary_by_unit': [],
          'charts': {},
        };
        _state = DashboardState.loaded;
        _errorMessage = 'Dashboard avanzado no disponible para este perfil.';
      } else {
        _state = DashboardState.error;
        _errorMessage = OdooService.prettyError(e);
      }
    }
    notifyListeners();
  }

  /// Carga las opciones de filtros.
  Future<void> loadFilterOptions() async {
    try {
      _filterOptions = await _odoo.getDashboardFilterOptions();
      notifyListeners();
    } catch (_) {
      // Silently fail – filters are optional
    }
  }

  /// Actualiza filtros y recarga el dashboard.
  Future<void> applyFilter(String key, dynamic value) async {
    _activeFilters[key] = value;
    await loadDashboard(filters: _activeFilters);
  }

  void clearFilters() {
    _activeFilters = {};
    loadDashboard();
  }
}
