import 'package:flutter/foundation.dart';

import '../auth/core/auth_models.dart';
import '../auth/services/auth_service.dart';
import '../config/app_config.dart';
import '../services/odoo_service.dart';
import '../services/odoo_values.dart';

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
  final Map<String, bool> _modelAccess = <String, bool>{};

  AuthState get state => _state;
  String? get errorMessage => _errorMessage;
  String get userName => OdooValues.string(_odoo.userInfo?['name']);
  String get userLogin => OdooValues.string(_odoo.userInfo?['username']);
  int get userId => OdooValues.intValue(_odoo.userInfo?['uid']) ?? 0;
  int get partnerId =>
      OdooValues.many2oneId(_odoo.userInfo?['partner_id']) ?? 0;
  String get serverUrl => _serverUrl;
  String get database => _database;
  bool get isAuthenticated => _state == AuthState.authenticated;
  bool get isPortalUser =>
      _userProfile['share'] == true && _userProfile['public'] != true;
  bool get isPortalLikeUser => isPortalUser || portalCalidadHabilitado;
  bool get isInternalUser =>
      isAuthenticated && _userProfile['internal'] == true;
  Map<String, dynamic> get partnerProfile =>
      Map<String, dynamic>.unmodifiable(_partnerProfile);
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
    return login == 'admin' || _odoo.sessionInfo['is_admin'] == true;
  }

  bool get hasIntranetAccess =>
      isAdmin || (accesoIntranet && accesoCalidad && portalCalidadHabilitado);
  bool get hasPortalAppAccess => isAuthenticated && isPortalLikeUser;
  bool get hasAppAccess => isAdmin || hasIntranetAccess || hasPortalAppAccess;

  Map<String, bool> get portalPermissions => {
    'Incidencias': canViewModule('incidents'),
    'Formación': canViewModule('training'),
    'Documentos': canViewModule('documents'),
    'Salud': canViewModule('health'),
    'Comunicaciones': canViewModule('communications'),
    'Nóminas': canViewModule('payroll'),
    'Reservas': canViewModule('reservas'),
    'Sugerencias': canViewModule('suggestions'),
    'Proveedores': canViewModule('suppliers'),
    'Normativa': canViewModule('normative'),
    'Equipos': canViewModule('equipment'),
    'Químicos': canViewModule('chemicals'),
  };
  int get enabledPortalPermissions =>
      portalPermissions.values.where((e) => e).length;

  bool canEditModule(String moduleKey) {
    if (isAdmin) return true;
    final modelWriteAccess = _modelAccess['$moduleKey.write'];
    if (modelWriteAccess == false) return false;
    final modelCreateAccess = _modelAccess['$moduleKey.create'];
    if (modelCreateAccess == false) return false;
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
    if (hasPortalAppAccess && !hasIntranetAccess) {
      return modelWriteAccess == true && modelCreateAccess == true;
    }
    switch (moduleKey) {
      case 'reservas':
      case 'goals':
      case 'planning':
      case 'action_plans':
      case 'purchases':
      case 'suggestions':
      case 'recruitment':
      case 'profile':
        return true;
      default:
        return false;
    }
  }

  bool canViewModule(String moduleKey) {
    if (isAdmin) return true;
    final modelReadAccess = _modelAccess[moduleKey];
    if (modelReadAccess == false) return false;
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
      'profile': null,
    };
    if (!permissionMap.containsKey(moduleKey)) return false;

    if (hasPortalAppAccess && !hasIntranetAccess) {
      switch (moduleKey) {
        case 'dashboard':
        case 'payroll':
          return modelReadAccess == true;
        case 'portal':
          return hasPortalAppAccess;
        case 'quality':
          return canViewModule('incidents') ||
              canViewModule('training') ||
              canViewModule('communications') ||
              canViewModule('suppliers') ||
              canViewModule('suggestions') ||
              canViewModule('goals');
        case 'reservas':
        case 'planning':
          return modelReadAccess == true;
        case 'training':
        case 'elearning':
        case 'suggestions':
        case 'documents':
        case 'goals':
          return modelReadAccess == true;
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
              _partnerProfile[permissionField] == true &&
              modelReadAccess == true;
        default:
          return modelReadAccess == true;
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
      await _loadModelAccess();
    } else {
      _userProfile = const {};
      _partnerProfile = const {};
      _modelAccess.clear();
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
      await _loadModelAccess();
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
    _modelAccess.clear();
    _state = AuthState.unauthenticated;
    _errorMessage = null;
    notifyListeners();
  }

  /// Carga usuario actual desde la sesión activa.
  Future<AuthUser?> loadCurrentUser() => _authService.loadCurrentUser();

  Future<void> _loadUserProfile() async {
    final info = _odoo.sessionInfo;
    final isPublic = OdooService.isPublicSession(info);
    var isInternal = OdooService.sessionIsInternal(info);

    // Odoo's session_info is authoritative for a normal Odoo 17 session.
    // Only use res.users as a compatibility fallback for custom controllers.
    if (isInternal == null && userId > 0) {
      try {
        final profile = await _odoo.read(
          'res.users',
          userId,
          fields: const ['share'],
        );
        isInternal = !OdooValues.boolValue(profile['share']);
      } catch (e) {
        // A denied res.users read must never turn an internal user into a
        // portal user. An Odoo portal session has user_companies=false, so it
        // is classified above without this fallback.
        isInternal = false;
      }
    }

    _userProfile = {
      'share': !(isInternal ?? false) && !isPublic,
      'internal': isInternal ?? false,
      'public': isPublic,
    };
  }

  Future<void> _loadPartnerProfile() async {
    if (partnerId <= 0) {
      _partnerProfile = const {};
      return;
    }
    const standardFields = <String>[
      'name',
      'email',
      'phone',
      'mobile',
      'function',
      'comment',
      'unidad_id',
      'image_128',
      'image_1920',
    ];
    const customFields = <String>[
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
    ];
    try {
      _partnerProfile = await _odoo.read(
        'res.partner',
        partnerId,
        fields: [...standardFields, ...customFields],
      );
    } catch (_) {
      final profile = <String, dynamic>{};
      try {
        profile.addAll(
          await _odoo.read('res.partner', partnerId, fields: standardFields),
        );
      } catch (_) {}
      for (final field in customFields) {
        try {
          profile.addAll(
            await _odoo.read('res.partner', partnerId, fields: [field]),
          );
        } catch (_) {}
      }
      _partnerProfile = profile;
    }
  }

  Future<void> _loadModelAccess() async {
    const models = <String, String>{
      'dashboard': 'calidad.dashboard.service',
      'quality': 'calidad.incidencia',
      'incidents': 'calidad.incidencia',
      'training': 'calidad.formacion',
      'elearning': 'calidad.formacion',
      'documents': 'calidad.documento',
      'payroll': 'payroll.document',
      'goals': 'calidad.objetivo',
      'action_plans': 'calidad.plan.accion',
      'reservas': 'reserva.reserva',
      'planning': 'reserva.reserva',
      'health': 'calidad.salud.reconocimiento',
      'normative': 'calidad.normativa',
      'equipment': 'calidad.equipo',
      'chemicals': 'calidad.quimico',
      'suggestions': 'calidad.comunicacion',
      'communications': 'calidad.comunicacion',
      'suppliers': 'calidad.proveedor.unidad',
      'purchases': 'purchase.order',
      'maintenance': 'maintenance.request',
      'recruitment': 'hr.applicant',
      'profile': 'res.partner',
    };
    final results = await Future.wait(
      models.entries.map((entry) async {
        try {
          final candidates = entry.key == 'payroll'
              ? const ['payroll.document', 'hr.payslip']
              : [entry.value];
          Future<bool> anyAllowed(String operation) async {
            final values = await Future.wait(
              candidates.map((model) async {
                try {
                  return await _odoo.checkAccessRights(model, operation);
                } catch (_) {
                  return false;
                }
              }),
            );
            return values.any((allowed) => allowed);
          }

          final canRead = await anyAllowed('read');
          final canWrite = await anyAllowed('write');
          final canCreate = await anyAllowed('create');
          return MapEntry(entry.key, <String, bool>{
            'read': canRead,
            'write': canWrite,
            'create': canCreate,
          });
        } catch (_) {
          return MapEntry(entry.key, <String, bool>{
            'read': false,
            'write': false,
            'create': false,
          });
        }
      }),
    );
    _modelAccess
      ..clear()
      ..addEntries(
        results.expand(
          (entry) => [
            MapEntry(entry.key, entry.value['read'] == true),
            MapEntry('${entry.key}.write', entry.value['write'] == true),
            MapEntry('${entry.key}.create', entry.value['create'] == true),
          ],
        ),
      );
  }
}
