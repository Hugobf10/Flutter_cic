import 'package:flutter/foundation.dart';

import '../auth/core/auth_models.dart';
import '../auth/services/auth_service.dart';
import '../config/app_config.dart';
import '../services/odoo_service.dart';

enum AuthState { initial, loading, authenticated, unauthenticated, error }

/// Provider de autenticación de UI. Mantiene compatibilidad con la app existente
/// delegando en AuthService + proveedores desacoplados.
class AuthProvider extends ChangeNotifier {
  final OdooService _odoo = OdooService();
  final OdooAuthService _authService = OdooAuthService();

  AuthState _state = AuthState.initial;
  String? _errorMessage;
  String _serverUrl = '';
  String _database = '';
  Map<String, dynamic> _partnerProfile = const {};
  Map<String, dynamic> _userProfile = const {};

  AuthState get state => _state;
  String? get errorMessage => _errorMessage;
  String get userName => _odoo.userInfo?['name'] ?? '';
  String get userLogin => _odoo.userInfo?['username'] ?? '';
  int get userId => _odoo.userInfo?['uid'] ?? 0;
  int get partnerId => _odoo.userInfo?['partner_id'] is List
      ? (_odoo.userInfo!['partner_id'] as List).first as int
      : (_odoo.userInfo?['partner_id'] ?? 0) as int;
  String get serverUrl => _serverUrl;
  String get database => _database;
  bool get isAuthenticated => _state == AuthState.authenticated;
  bool get isPortalUser => _userProfile['share'] == true;
  bool get isInternalUser => isAuthenticated && !isPortalUser;
  bool get accesoIntranet => _partnerProfile['acceso_intranet'] == true;
  bool get accesoCalidad => _partnerProfile['acceso_calidad'] == true;
  bool get portalCalidadHabilitado =>
      _partnerProfile['portal_calidad_habilitado'] == true;
  String get profileImageBase64 =>
      (_partnerProfile['image_128'] ?? _partnerProfile['image_1920'] ?? '')
          .toString();
  String get unidadNombre {
    final unidad = _partnerProfile['unidad_id'];
    if (unidad is List && unidad.length >= 2) return unidad[1].toString();
    return '';
  }

  bool get isAdmin {
    final login = userLogin.toLowerCase();
    final name = userName.toLowerCase();
    return login == 'admin' || name.contains('admin');
  }

  bool get hasIntranetAccess =>
      isAdmin || (accesoIntranet && accesoCalidad && portalCalidadHabilitado);
  bool get hasPortalAppAccess => isPortalUser;
  bool get hasAppAccess => isAdmin || hasIntranetAccess || hasPortalAppAccess;

  Map<String, bool> get portalPermissions => {
    'Incidencias': _partnerProfile['permiso_incidencias_ver'] == true,
    'Formación': _partnerProfile['permiso_formacion_ver'] == true,
    'Documentos': _partnerProfile['permiso_documentos_ver'] == true,
    'Salud': _partnerProfile['permiso_salud_ver'] == true,
    'Comunicaciones': _partnerProfile['permiso_comunicaciones_ver'] == true,
    'Nóminas': true,
    'Reservas': true,
    'Sugerencias': true,
    'Proveedores': _partnerProfile['permiso_proveedores_ver'] == true,
    'Normativa': _partnerProfile['permiso_normativa_ver'] == true,
    'Equipos': _partnerProfile['permiso_equipos_ver'] == true,
    'Químicos': _partnerProfile['permiso_quimicos_ver'] == true,
  };
  int get enabledPortalPermissions =>
      portalPermissions.values.where((e) => e).length;

  bool canEditModule(String moduleKey) {
    if (isAdmin) return true;
    const editPermissionMap = {
      'incidents': 'permiso_incidencias_editar',
      'training': 'permiso_formacion_editar',
      'elearning': 'permiso_formacion_editar',
      'goals': 'permiso_objetivos_editar',
      'action_plans': 'permiso_objetivos_editar',
      'documents': 'permiso_documentos_editar',
      'health': 'permiso_salud_editar',
      'communications': 'permiso_comunicaciones_editar',
      'suppliers': 'permiso_proveedores_editar',
      'normative': 'permiso_normativa_editar',
      'equipment': 'permiso_equipos_editar',
      'chemicals': 'permiso_quimicos_editar',
    };
    final permissionField = editPermissionMap[moduleKey];
    if (permissionField != null) {
      return _partnerProfile[permissionField] == true;
    }
    if (isPortalUser) {
      switch (moduleKey) {
        case 'suggestions':
          return hasPortalAppAccess;
        default:
          return false;
      }
    }
    switch (moduleKey) {
      case 'reservas':
      case 'goals':
      case 'planning':
      case 'action_plans':
      case 'purchases':
      case 'suggestions':
      case 'recruitment':
        return true;
      default:
        return false;
    }
  }

  bool canViewModule(String moduleKey) {
    if (isAdmin) return true;
    const permissionMap = {
      'dashboard': null,
      'quality': null,
      'incidents': 'permiso_incidencias_ver',
      'training': 'permiso_formacion_ver',
      'elearning': 'permiso_formacion_ver',
      'goals': 'permiso_objetivos_ver',
      'action_plans': 'permiso_objetivos_ver',
      'documents': 'permiso_documentos_ver',
      'reservas': null,
      'planning': null,
      'payroll': null,
      'health': 'permiso_salud_ver',
      'communications': 'permiso_comunicaciones_ver',
      'suppliers': 'permiso_proveedores_ver',
      'normative': 'permiso_normativa_ver',
      'equipment': 'permiso_equipos_ver',
      'chemicals': 'permiso_quimicos_ver',
      'suggestions': null,
      'portal': null,
      'permissions': null,
      'users': null,
      'roles': null,
      'organization': null,
      'purchases': null,
      'maintenance': null,
      'recruitment': null,
    };
    if (!permissionMap.containsKey(moduleKey)) return false;

    if (isPortalUser) {
      switch (moduleKey) {
        case 'dashboard':
        case 'payroll':
          return hasPortalAppAccess;
        case 'portal':
          return false;
        case 'quality':
          return canViewModule('incidents') ||
              canViewModule('training') ||
              canViewModule('communications') ||
              canViewModule('suppliers') ||
              canViewModule('suggestions') ||
              canViewModule('goals');
        case 'reservas':
        case 'planning':
          return hasPortalAppAccess;
        case 'training':
        case 'elearning':
        case 'suggestions':
        case 'documents':
        case 'goals':
          return hasPortalAppAccess;
        case 'incidents':
        case 'action_plans':
        case 'health':
        case 'communications':
        case 'suppliers':
        case 'normative':
        case 'equipment':
        case 'chemicals':
          final permissionField = permissionMap[moduleKey];
          return permissionField != null &&
              _partnerProfile[permissionField] == true;
        default:
          return false;
      }
    }

    final permissionField = permissionMap[moduleKey];
    if (permissionField == null) return true;
    return _partnerProfile[permissionField] == true;
  }

  /// Intenta restaurar sesión previa.
  Future<void> tryAutoLogin() async {
    _state = AuthState.loading;
    notifyListeners();

    final success = await _authService.restoreSession();
    if (_serverUrl.isEmpty) _serverUrl = AppConfig.odooBaseUrl;
    if (_database.isEmpty) _database = AppConfig.odooDatabaseName;
    if (success) {
      await _loadUserProfile();
      await _loadPartnerProfile();
    } else {
      _userProfile = const {};
      _partnerProfile = const {};
    }
    _state = success ? AuthState.authenticated : AuthState.unauthenticated;
    notifyListeners();
  }

  /// Alias semántico para restaurar sesión al abrir app.
  Future<void> restoreSession() => tryAutoLogin();

  /// Login manual clásico (usuario + contraseña).
  Future<bool> login({
    required String login,
    required String password,
    required String serverUrl,
    required String database,
  }) async {
    _state = AuthState.loading;
    _errorMessage = null;
    notifyListeners();

    _serverUrl = serverUrl.trim();
    _database = database.trim();

    if (_serverUrl.isEmpty || _database.isEmpty) {
      _state = AuthState.error;
      _errorMessage = 'Servidor y base de datos son obligatorios.';
      notifyListeners();
      return false;
    }

    final request = AuthLoginRequest(
      login: login,
      password: password,
      serverUrl: _serverUrl,
      database: _database,
    );

    final result = await _authService.authenticate(request);

    if (result.success) {
      await _loadUserProfile();
      await _loadPartnerProfile();
      _state = AuthState.authenticated;
      _errorMessage = null;
    } else {
      _userProfile = const {};
      _partnerProfile = const {};
      _state = AuthState.error;
      final rawError = (result.errorMessage ?? '').toLowerCase();
      final isLikelyCors =
          kIsWeb &&
          (rawError.contains('xmlhttprequest') ||
              rawError.contains('failed to fetch') ||
              rawError.contains('networkerror'));
      _errorMessage = isLikelyCors
          ? 'Bloqueo CORS del navegador: el servidor Odoo no permite peticiones desde localhost.'
          : (result.errorMessage?.isNotEmpty == true
                ? result.errorMessage
                : 'Credenciales incorrectas o servidor no disponible.');
    }
    notifyListeners();
    return result.success;
  }

  /// Cierra sesión.
  Future<void> logout() async {
    try {
      await _authService.destroySession();
    } catch (_) {}
    _userProfile = const {};
    _partnerProfile = const {};
    _state = AuthState.unauthenticated;
    _errorMessage = null;
    notifyListeners();
  }

  /// Carga usuario actual desde la sesión activa.
  Future<AuthUser?> loadCurrentUser() => _authService.loadCurrentUser();

  Future<void> _loadUserProfile() async {
    if (userId <= 0) {
      _userProfile = const {};
      return;
    }
    try {
      _userProfile = await _odoo.read(
        'res.users',
        userId,
        fields: const ['share'],
      );
    } catch (_) {
      _userProfile = const {};
    }
  }

  Future<void> _loadPartnerProfile() async {
    if (partnerId <= 0) {
      _partnerProfile = const {};
      return;
    }
    try {
      _partnerProfile = await _odoo.read(
        'res.partner',
        partnerId,
        fields: const [
          'unidad_id',
          'image_128',
          'acceso_intranet',
          'acceso_calidad',
          'portal_calidad_habilitado',
          'permiso_incidencias_ver',
          'permiso_formacion_ver',
          'permiso_documentos_ver',
          'permiso_salud_ver',
          'permiso_comunicaciones_ver',
          'permiso_proveedores_ver',
          'permiso_normativa_ver',
          'permiso_equipos_ver',
          'permiso_quimicos_ver',
          'permiso_objetivos_ver',
          'permiso_incidencias_editar',
          'permiso_formacion_editar',
          'permiso_documentos_editar',
          'permiso_salud_editar',
          'permiso_comunicaciones_editar',
          'permiso_proveedores_editar',
          'permiso_normativa_editar',
          'permiso_equipos_editar',
          'permiso_quimicos_editar',
          'permiso_objetivos_editar',
        ],
      );
    } catch (_) {
      _partnerProfile = const {};
    }
  }
}
