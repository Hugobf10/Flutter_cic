import 'package:flutter/foundation.dart';
import '../config/app_config.dart';
import '../services/odoo_service.dart';

enum AuthState { initial, loading, authenticated, unauthenticated, error }

/// Provider de autenticación. Gestiona login, logout y auto-login.
class AuthProvider extends ChangeNotifier {
  final OdooService _odoo = OdooService();

  AuthState _state = AuthState.initial;
  String? _errorMessage;
  String _serverUrl = '';
  String _database = '';
  Map<String, dynamic> _partnerProfile = const {};

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
  bool get accesoIntranet => _partnerProfile['acceso_intranet'] == true;
  bool get accesoCalidad => _partnerProfile['acceso_calidad'] == true;
  bool get portalCalidadHabilitado => _partnerProfile['portal_calidad_habilitado'] == true;
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
  Map<String, bool> get portalPermissions => {
        'Incidencias': _partnerProfile['permiso_incidencias_ver'] == true,
        'Formación': _partnerProfile['permiso_formacion_ver'] == true,
        'Documentos': _partnerProfile['permiso_documentos_ver'] == true,
        'Salud': _partnerProfile['permiso_salud_ver'] == true,
      'Comunicaciones': _partnerProfile['permiso_comunicaciones_ver'] == true,
      'Proveedores': _partnerProfile['permiso_proveedores_ver'] == true,
      'Normativa': _partnerProfile['permiso_normativa_ver'] == true,
      'Equipos': _partnerProfile['permiso_equipos_ver'] == true,
      'Químicos': _partnerProfile['permiso_quimicos_ver'] == true,
    };
  int get enabledPortalPermissions => portalPermissions.values.where((e) => e).length;

  bool canViewModule(String moduleKey) {
    if (isAdmin) return true;
    const map = {
      'dashboard': null,
      'quality': null,
      'incidents': 'permiso_incidencias_ver',
      'training': 'permiso_formacion_ver',
      'elearning': 'permiso_formacion_ver',
      'documents': 'permiso_documentos_ver',
      'planning': null,
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
    if (!map.containsKey(moduleKey)) return false;
    final permissionField = map[moduleKey];
    if (permissionField == null) return true;
    return _partnerProfile[permissionField] == true;
  }

  /// Intenta restaurar sesión previa.
  Future<void> tryAutoLogin() async {
    _state = AuthState.loading;
    notifyListeners();

    final success = await _odoo.tryAutoLogin();
    if (_serverUrl.isEmpty) _serverUrl = AppConfig.odooBaseUrl;
    if (_database.isEmpty) _database = AppConfig.odooDatabaseName;
    if (success) {
      await _loadPartnerProfile();
    } else {
      _partnerProfile = const {};
    }
    _state = success ? AuthState.authenticated : AuthState.unauthenticated;
    notifyListeners();
  }

  /// Login manual.
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
    _odoo.init(baseUrl: _serverUrl);

    final success =
        await _odoo.authenticate(login, password, database: _database);

    if (success) {
      await _loadPartnerProfile();
      _state = AuthState.authenticated;
    } else {
      _partnerProfile = const {};
      _state = AuthState.error;
      final rawError = (_odoo.lastAuthError ?? '').toLowerCase();
      final isLikelyCors = kIsWeb &&
          (rawError.contains('xmlhttprequest') ||
              rawError.contains('failed to fetch') ||
              rawError.contains('networkerror'));
      _errorMessage = isLikelyCors
          ? 'Bloqueo CORS del navegador: el servidor Odoo no permite peticiones desde localhost.'
          : (_odoo.lastAuthError?.isNotEmpty == true
              ? 'Error autenticando: ${_odoo.lastAuthError}'
              : 'Credenciales incorrectas o servidor no disponible.');
    }
    notifyListeners();
    return success;
  }

  /// Cierra sesión.
  Future<void> logout() async {
    try {
      await _odoo.logout();
    } catch (_) {}
    _partnerProfile = const {};
    _state = AuthState.unauthenticated;
    _errorMessage = null;
    notifyListeners();
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
          'permiso_incidencias_editar',
          'permiso_formacion_editar',
          'permiso_documentos_editar',
          'permiso_salud_editar',
          'permiso_comunicaciones_editar',
          'permiso_proveedores_editar',
          'permiso_normativa_editar',
          'permiso_equipos_editar',
          'permiso_quimicos_editar',
        ],
      );
    } catch (_) {
      _partnerProfile = const {};
    }
  }
}
