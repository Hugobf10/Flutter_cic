import 'dart:async';
import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:odoo_rpc/odoo_rpc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/app_config.dart';
import 'app_logger.dart';
import 'odoo_values.dart';

/// Servicio singleton que encapsula toda la comunicación con Odoo 17 vía JSON-RPC.
class OdooService {
  OdooService._internal();
  static final OdooService _instance = OdooService._internal();
  factory OdooService() => _instance;

  late OdooClient _client;
  OdooSession? _session;
  Map<String, dynamic>? _userInfo;
  String? _lastAuthError;
  bool _initialized = false;
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  static const _kSessionJson = 'odoo_session_json';
  static const _kSessionUserInfoJson = 'odoo_user_info_json';
  static const _kSessionJsonPrefs = 'odoo_session_json_prefs';
  static const _kSessionUserInfoJsonPrefs = 'odoo_user_info_json_prefs';

  bool get isAuthenticated =>
      _session != null && _session!.id.isNotEmpty && _session!.userId > 0;
  OdooSession? get session => _session;
  Map<String, dynamic>? get userInfo => _userInfo;
  Map<String, dynamic> get sessionInfo => _userInfo ?? const {};
  String get baseUrl => _client.baseURL;
  String? get lastAuthError => _lastAuthError;

  static bool isAccessError(Object? error) {
    final raw = error?.toString().toLowerCase() ?? '';
    return raw.contains('accesserror') ||
        raw.contains('acceso denegado') ||
        raw.contains('permisos') ||
        raw.contains('forbidden');
  }

  static bool isMethodUnavailable(Object? error) {
    final raw = error?.toString().toLowerCase() ?? '';
    return raw.contains('attributeerror') ||
        raw.contains('has no attribute') ||
        raw.contains('method not found') ||
        raw.contains('not a valid action') ||
        raw.contains('unknown method') ||
        raw.contains('unknown model') ||
        raw.contains('model not found');
  }

  static String prettyError(Object? error) {
    final raw = error?.toString() ?? '';
    if (isAccessError(error)) {
      return 'Tu usuario no tiene permisos para esta acción en Odoo.';
    }
    final firstLine = raw.split('\n').first.trim();
    if (firstLine.isEmpty) return 'Se produjo un error inesperado.';
    if (firstLine.length > 180) return '${firstLine.substring(0, 180)}...';
    return firstLine;
  }

  static String prettyAuthError(Object? error) {
    final raw = error?.toString() ?? '';
    final normalized = raw.toLowerCase();

    if (normalized.contains('database not found')) {
      return 'Base de datos no encontrada. Revisa el servidor y el nombre exacto de la BBDD.';
    }
    if (normalized.contains('wrong login/password') ||
        normalized.contains('bad login or password') ||
        normalized.contains('credenciales') ||
        normalized.contains('invalid login') ||
        normalized.contains('authentication failed')) {
      return 'Usuario o contraseña incorrectos.';
    }
    if (normalized.contains('accesserror')) {
      return 'No se pudo iniciar sesión en Odoo con esos datos.';
    }

    return prettyError(error);
  }

  static bool isPublicSession(Map<String, dynamic> info) {
    return OdooValues.boolValue(info['is_public']);
  }

  /// Returns null only for non-standard/custom session payloads.
  static bool? sessionIsInternal(Map<String, dynamic> info) {
    final explicit = info['is_internal_user'];
    if (explicit is bool) return explicit;
    final companies = info['user_companies'];
    if (companies is Map && companies.isNotEmpty) return true;
    if (companies is List && companies.isNotEmpty) return true;
    if (info.containsKey('user_companies') && companies == false) return false;
    if (info['is_admin'] == true || info['is_system'] == true) return true;
    return null;
  }

  /// Inicializa el cliente con la URL de Odoo.
  void init({String? baseUrl, OdooSession? session}) {
    _client = OdooClient(
      (baseUrl ?? AppConfig.odooBaseUrl).trim(),
      sessionId: session,
    );
    _initialized = true;
    AppLogger.info(
      'Cliente Odoo inicializado',
      data: {'baseUrl': _client.baseURL},
      scope: 'odoo',
    );
  }

  // ─── Autenticación ─────────────────────────────────────────────────

  /// Inicia sesión. Devuelve true si fue exitoso.
  Future<bool> authenticate(
    String login,
    String password, {
    String? database,
  }) async {
    _ensureInit();
    _lastAuthError = null;
    try {
      _session = await _withRetry(
        () => _client.authenticate(
          database ?? AppConfig.odooDatabaseName,
          login,
          password,
        ),
      );
      if (!await _fetchUserInfo()) {
        throw Exception('Odoo no devolvió información de sesión válida.');
      }
      try {
        await persistSessionSnapshot(database: database);
      } catch (e) {
        AppLogger.warning(
          'No se pudo persistir sesión segura; login seguirá activo en memoria',
          data: {'error': e.toString()},
          scope: 'odoo.auth',
        );
      }
      AppLogger.info('Autenticación Odoo OK', scope: 'odoo.auth');
      return true;
    } on OdooException catch (e) {
      _lastAuthError = e.message;
      AppLogger.warning(
        'Autenticación Odoo fallida',
        data: {'error': e.message},
        scope: 'odoo.auth',
      );
      _session = null;
      _userInfo = null;
      return false;
    } catch (e) {
      _lastAuthError = e.toString();
      AppLogger.error(
        'Error autenticando en Odoo',
        error: e,
        scope: 'odoo.auth',
      );
      _session = null;
      _userInfo = null;
      return false;
    }
  }

  /// Compat para llamadas existentes.
  Future<bool> tryAutoLogin() => tryRestoreStoredSession();

  /// Cierra la sesión y borra tokens/sesión persistida.
  Future<void> logout() async {
    _session = null;
    _userInfo = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('odoo_login');
    await prefs.remove('odoo_database');
    await prefs.remove('odoo_url');
    await prefs.remove(_kSessionJsonPrefs);
    await prefs.remove(_kSessionUserInfoJsonPrefs);
    try {
      await _secureStorage.delete(key: _kSessionJson);
      await _secureStorage.delete(key: _kSessionUserInfoJson);
    } catch (e) {
      AppLogger.warning(
        'No se pudo borrar sesión de secure storage en logout',
        data: {'error': e.toString()},
        scope: 'odoo.auth',
      );
    }
  }

  Future<void> persistSessionSnapshot({String? database}) async {
    if (_session == null) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('odoo_login', _session!.userLogin);
    await prefs.setString('odoo_database', database ?? _session!.dbName);
    await prefs.setString('odoo_url', _client.baseURL);

    final sessionJson = jsonEncode(_session!.toJson());
    final userInfoJson = _userInfo == null ? '' : jsonEncode(_userInfo);
    // Fallback siempre disponible (incluido macOS sin entitlement de keychain).
    await prefs.setString(_kSessionJsonPrefs, sessionJson);
    await prefs.setString(_kSessionUserInfoJsonPrefs, userInfoJson);

    // Intento de persistencia segura: si falla, seguimos con fallback sin romper login.
    try {
      await _secureStorage.write(key: _kSessionJson, value: sessionJson);
      await _secureStorage.write(
        key: _kSessionUserInfoJson,
        value: userInfoJson,
      );
    } catch (e) {
      AppLogger.warning(
        'Secure storage no disponible; usando fallback en SharedPreferences',
        data: {'error': e.toString()},
        scope: 'odoo.auth',
      );
    }
  }

  Future<bool> tryRestoreStoredSession() async {
    final prefs = await SharedPreferences.getInstance();
    final url = prefs.getString('odoo_url');
    if ((url ?? '').trim().isEmpty) return false;

    String? sessionJson;
    String? userInfoJson;
    try {
      sessionJson = await _secureStorage.read(key: _kSessionJson);
      userInfoJson = await _secureStorage.read(key: _kSessionUserInfoJson);
    } catch (e) {
      AppLogger.warning(
        'No se pudo leer sesión de secure storage; usando fallback',
        data: {'error': e.toString()},
        scope: 'odoo.auth',
      );
    }
    sessionJson ??= prefs.getString(_kSessionJsonPrefs);
    userInfoJson ??= prefs.getString(_kSessionUserInfoJsonPrefs);
    if ((sessionJson ?? '').isEmpty) return false;

    try {
      final raw = jsonDecode(sessionJson!);
      if (raw is! Map<String, dynamic>) return false;
      final restoredSession = OdooSession.fromJson(raw);
      init(baseUrl: url, session: restoredSession);
      _session = restoredSession;

      if ((userInfoJson ?? '').isNotEmpty) {
        final userRaw = jsonDecode(userInfoJson!);
        if (userRaw is Map) {
          _userInfo = Map<String, dynamic>.from(userRaw);
        }
      }

      if (restoredSession.id.isEmpty || restoredSession.userId <= 0) {
        _clearSessionInMemory();
        return false;
      }
      if (!await _fetchUserInfo()) {
        _clearSessionInMemory();
        return false;
      }

      try {
        await persistSessionSnapshot(
          database: prefs.getString('odoo_database'),
        );
      } catch (e) {
        AppLogger.warning(
          'No se pudo refrescar persistencia de sesión restaurada',
          data: {'error': e.toString()},
          scope: 'odoo.auth',
        );
      }
      return true;
    } catch (e) {
      _clearSessionInMemory();
      AppLogger.warning(
        'No se pudo restaurar sesión persistida',
        data: {'error': e.toString()},
        scope: 'odoo.auth',
      );
      return false;
    }
  }

  void _clearSessionInMemory() {
    _session = null;
    _userInfo = null;
  }

  Future<bool> _fetchUserInfo() async {
    if (_session == null) return false;
    try {
      final result = await _withRetry(
        () => _client.callRPC('/web/session/get_session_info', 'call', {}),
      );
      if (result is! Map) return false;
      final info = Map<String, dynamic>.from(result);
      final uid = info['uid'];
      if (uid is! num || uid.toInt() <= 0) return false;
      _userInfo = info;
      // Keep the restored session if a custom Odoo controller omits an
      // optional session_info field. The session cookie is still valid.
      try {
        _session = OdooSession.fromSessionInfo(info);
      } catch (e) {
        AppLogger.warning(
          'session_info válido, pero incompleto para reconstruir OdooSession',
          data: {'error': e.toString()},
          scope: 'odoo.auth',
        );
      }
      return true;
    } catch (e) {
      AppLogger.warning(
        'No se pudo validar la sesión Odoo',
        data: {'error': e.toString()},
        scope: 'odoo.auth',
      );
      return false;
    }
  }

  /// Checks model ACLs without bypassing record rules.
  Future<bool> checkAccessRights(String model, String operation) async {
    final result = await callMethod(
      model,
      'check_access_rights',
      args: [operation],
      kwargs: const {'raise_exception': false},
    );
    return result == true;
  }

  // ─── Helpers internos para construir params de callKw ──────────────

  Map<String, dynamic> _buildKwParams(
    String model,
    String method, {
    List<dynamic> args = const [],
    Map<String, dynamic> kwargs = const {},
  }) {
    return {'model': model, 'method': method, 'args': args, 'kwargs': kwargs};
  }

  // ─── ORM genérico ─────────────────────────────────────────────────

  /// Busca y lee registros de un modelo.
  Future<List<dynamic>> searchRead(
    String model, {
    List<dynamic> domain = const [],
    List<String> fields = const [],
    int? limit,
    int? offset,
    String? order,
  }) async {
    final kwargs = <String, dynamic>{};
    if (fields.isNotEmpty) kwargs['fields'] = fields;
    if (limit != null) kwargs['limit'] = limit;
    if (offset != null) kwargs['offset'] = offset;
    if (order != null) kwargs['order'] = order;

    _ensureInit();
    final result = await _withRetry(
      () => _client.callKw(
        _buildKwParams(model, 'search_read', args: [domain], kwargs: kwargs),
      ),
    );
    if (result == false || result == null) return const [];
    if (result is! List) {
      throw FormatException('Respuesta search_read inválida para $model.');
    }
    return List<dynamic>.from(result);
  }

  /// Cuenta registros que cumplen un dominio.
  Future<int> searchCount(
    String model, {
    List<dynamic> domain = const [],
  }) async {
    _ensureInit();
    final result = await _withRetry(
      () =>
          _client.callKw(_buildKwParams(model, 'search_count', args: [domain])),
    );
    final count = result is num ? result.toInt() : int.tryParse('$result');
    if (count == null) {
      throw FormatException('Respuesta search_count inválida para $model.');
    }
    return count;
  }

  /// Lee campos de un registro por ID.
  Future<Map<String, dynamic>> read(
    String model,
    int id, {
    List<String> fields = const [],
  }) async {
    final kwargs = fields.isNotEmpty
        ? <String, dynamic>{'fields': fields}
        : <String, dynamic>{};
    _ensureInit();
    final result = await _withRetry(
      () => _client.callKw(
        _buildKwParams(
          model,
          'read',
          args: [
            [id],
          ],
          kwargs: kwargs,
        ),
      ),
    );
    if (result is! List || result.isEmpty || result.first is! Map) {
      throw StateError('El registro $model/$id no está disponible.');
    }
    return Map<String, dynamic>.from(result.first as Map);
  }

  /// Crea un registro. Devuelve el ID creado.
  Future<int> create(String model, Map<String, dynamic> values) async {
    _ensureInit();
    final result = await _withRetry(
      () => _client.callKw(_buildKwParams(model, 'create', args: [values])),
    );
    final createdId = result is num ? result.toInt() : int.tryParse('$result');
    if (createdId == null || createdId <= 0) {
      throw FormatException('Odoo no devolvió el ID creado para $model.');
    }
    return createdId;
  }

  /// Actualiza un registro.
  Future<bool> write(String model, int id, Map<String, dynamic> values) async {
    _ensureInit();
    final result = await _withRetry(
      () => _client.callKw(
        _buildKwParams(
          model,
          'write',
          args: [
            [id],
            values,
          ],
        ),
      ),
    );
    if (result is bool) return result;
    throw FormatException('Respuesta write inválida para $model/$id.');
  }

  /// Ejecuta un método custom de un modelo.
  Future<dynamic> callMethod(
    String model,
    String method, {
    List<dynamic> args = const [],
    Map<String, dynamic> kwargs = const {},
  }) async {
    _ensureInit();
    return _withRetry(
      () => _client.callKw(
        _buildKwParams(model, method, args: args, kwargs: kwargs),
      ),
    );
  }

  /// Ejecuta un método sobre un recordset concreto (ids).
  Future<dynamic> callRecordMethod(
    String model,
    List<int> ids,
    String method, {
    List<dynamic> args = const [],
    Map<String, dynamic> kwargs = const {},
  }) async {
    _ensureInit();
    return _withRetry(
      () => _client.callKw(
        _buildKwParams(model, method, args: [ids, ...args], kwargs: kwargs),
      ),
    );
  }

  /// Llama al dashboard de calidad.
  Future<Map<String, dynamic>> getDashboardData({
    Map<String, dynamic>? filters,
  }) async {
    final result = await callMethod(
      'calidad.dashboard.service',
      'get_dashboard_data',
      args: [filters ?? {}],
    );
    return OdooValues.map(result);
  }

  /// Opciones de filtro del dashboard.
  Future<Map<String, dynamic>> getDashboardFilterOptions() async {
    final result = await callMethod(
      'calidad.dashboard.service',
      'get_filter_options',
    );
    return OdooValues.map(result);
  }

  void _ensureInit() {
    if (_initialized) return;
    if (!AppConfig.hasValidBaseUrl) {
      throw Exception(
        'Config Odoo inválida: ODOO_BASE_URL no es una URL válida.',
      );
    }
    init();
  }

  Future<T> _withRetry<T>(Future<T> Function() fn) async {
    int attempt = 0;
    Object? lastError;
    while (attempt <= AppConfig.rpcRetries) {
      try {
        return await fn().timeout(
          Duration(seconds: AppConfig.httpTimeoutSeconds),
        );
      } on TimeoutException {
        lastError = Exception(
          'Timeout de red con Odoo (${AppConfig.httpTimeoutSeconds}s).',
        );
        AppLogger.warning(
          'Timeout Odoo',
          data: {'attempt': attempt + 1, 'max': AppConfig.rpcRetries + 1},
          scope: 'odoo.rpc',
        );
        if (attempt == AppConfig.rpcRetries) rethrow;
      } on OdooException catch (e) {
        // Server-side ACL, validation and business errors are deterministic;
        // retrying them creates duplicate work and noisy logs.
        lastError = e;
        AppLogger.error('Error funcional de Odoo', error: e, scope: 'odoo.rpc');
        rethrow;
      } catch (e) {
        lastError = e;
        AppLogger.warning(
          'Error RPC Odoo, reintento',
          data: {
            'attempt': attempt + 1,
            'max': AppConfig.rpcRetries + 1,
            'error': e.toString(),
          },
          scope: 'odoo.rpc',
        );
        if (attempt == AppConfig.rpcRetries) rethrow;
      }
      attempt++;
      await Future<void>.delayed(Duration(milliseconds: 250 * attempt));
    }
    AppLogger.error(
      'Fallo RPC Odoo tras reintentos',
      error: lastError,
      scope: 'odoo.rpc',
    );
    throw lastError ?? Exception('Error de conexión con Odoo.');
  }
}
