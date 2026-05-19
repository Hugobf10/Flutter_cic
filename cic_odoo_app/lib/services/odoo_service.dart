import 'dart:async';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:odoo_rpc/odoo_rpc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/app_config.dart';
import 'app_logger.dart';

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

  bool get isAuthenticated => _session != null;
  OdooSession? get session => _session;
  Map<String, dynamic>? get userInfo => _userInfo;
  String get baseUrl => _client.baseURL;
  String? get lastAuthError => _lastAuthError;

  static bool isAccessError(Object? error) {
    final raw = error?.toString().toLowerCase() ?? '';
    return raw.contains('accesserror') ||
        raw.contains('acceso denegado') ||
        raw.contains('permisos') ||
        raw.contains('forbidden');
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

  /// Inicializa el cliente con la URL de Odoo.
  void init({String? baseUrl}) {
    _client = OdooClient((baseUrl ?? AppConfig.odooBaseUrl).trim());
    _initialized = true;
    AppLogger.info('Cliente Odoo inicializado', data: {'baseUrl': _client.baseURL}, scope: 'odoo');
  }

  // ─── Autenticación ─────────────────────────────────────────────────

  /// Inicia sesión. Devuelve true si fue exitoso.
  Future<bool> authenticate(String login, String password,
      {String? database}) async {
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
      await _fetchUserInfo();
      try {
        await _persistCredentials(login, password, database);
      } catch (e, st) {
        AppLogger.warning(
          'Autenticado, pero no se pudieron persistir credenciales',
          data: {'error': e.toString()},
          scope: 'odoo.auth',
        );
        AppLogger.error(
          'Error persistiendo credenciales',
          error: e,
          stackTrace: st,
          scope: 'odoo.auth',
        );
      }
      AppLogger.info('Autenticación Odoo OK', data: {'login': login}, scope: 'odoo.auth');
      return true;
    } on OdooException catch (e) {
      _lastAuthError = e.message;
      AppLogger.warning('Autenticación Odoo fallida', data: {'login': login, 'error': e.message}, scope: 'odoo.auth');
      _session = null;
      _userInfo = null;
      return false;
    } catch (e) {
      _lastAuthError = e.toString();
      AppLogger.error('Error autenticando en Odoo', error: e, scope: 'odoo.auth');
      _session = null;
      _userInfo = null;
      return false;
    }
  }

  /// Intenta restaurar la sesión guardada.
  Future<bool> tryAutoLogin() async {
    final prefs = await SharedPreferences.getInstance();
    final login = prefs.getString('odoo_login');
    String? password;
    try {
      password = await _secureStorage.read(key: 'odoo_password');
    } catch (e) {
      AppLogger.warning(
        'No se pudo leer password del secure storage',
        data: {'error': e.toString()},
        scope: 'odoo.auth',
      );
    }
    final database = prefs.getString('odoo_database');
    final url = prefs.getString('odoo_url');
    password ??= prefs.getString('odoo_password_fallback');

    if (login == null || password == null) return false;

    init(baseUrl: url);
    return authenticate(login, password, database: database);
  }

  /// Cierra la sesión y borra credenciales.
  Future<void> logout() async {
    _session = null;
    _userInfo = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('odoo_login');
    await prefs.remove('odoo_database');
    await prefs.remove('odoo_url');
    await prefs.remove('odoo_password_fallback');
    try {
      await _secureStorage.delete(key: 'odoo_password');
    } catch (e) {
      AppLogger.warning(
        'No se pudo borrar password de secure storage en logout',
        data: {'error': e.toString()},
        scope: 'odoo.auth',
      );
    }
  }

  Future<void> _persistCredentials(
      String login, String password, String? database) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('odoo_login', login);
    await prefs.setString(
        'odoo_database', database ?? AppConfig.odooDatabaseName);
    await prefs.setString('odoo_url', _client.baseURL);
    await prefs.setString('odoo_password_fallback', password);
    await _secureStorage.write(key: 'odoo_password', value: password);
  }

  Future<void> _fetchUserInfo() async {
    if (_session == null) return;
    try {
      final result =
          await _withRetry(() => _client.callRPC('/web/session/get_session_info', 'call', {}));
      _userInfo = Map<String, dynamic>.from(result as Map);
    } catch (_) {
      _userInfo = null;
    }
  }

  // ─── Helpers internos para construir params de callKw ──────────────

  Map<String, dynamic> _buildKwParams(
    String model,
    String method, {
    List<dynamic> args = const [],
    Map<String, dynamic> kwargs = const {},
  }) {
    return {
      'model': model,
      'method': method,
      'args': args,
      'kwargs': kwargs,
    };
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
    return List<dynamic>.from(result as List);
  }

  /// Cuenta registros que cumplen un dominio.
  Future<int> searchCount(String model,
      {List<dynamic> domain = const []}) async {
    _ensureInit();
    final result = await _withRetry(
      () => _client.callKw(
        _buildKwParams(model, 'search_count', args: [domain]),
      ),
    );
    return result as int;
  }

  /// Lee campos de un registro por ID.
  Future<Map<String, dynamic>> read(
    String model,
    int id, {
    List<String> fields = const [],
  }) async {
    final kwargs =
        fields.isNotEmpty ? <String, dynamic>{'fields': fields} : <String, dynamic>{};
    _ensureInit();
    final result = await _withRetry(
      () => _client.callKw(
        _buildKwParams(model, 'read', args: [
          [id]
        ], kwargs: kwargs),
      ),
    );
    final list = List<dynamic>.from(result as List);
    return Map<String, dynamic>.from(list.first as Map);
  }

  /// Crea un registro. Devuelve el ID creado.
  Future<int> create(String model, Map<String, dynamic> values) async {
    _ensureInit();
    final result = await _withRetry(
      () => _client.callKw(
        _buildKwParams(model, 'create', args: [values]),
      ),
    );
    return result as int;
  }

  /// Actualiza un registro.
  Future<bool> write(
      String model, int id, Map<String, dynamic> values) async {
    _ensureInit();
    final result = await _withRetry(
      () => _client.callKw(
        _buildKwParams(model, 'write', args: [
          [id],
          values
        ]),
      ),
    );
    return result as bool;
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
  Future<Map<String, dynamic>> getDashboardData(
      {Map<String, dynamic>? filters}) async {
    final result = await callMethod(
      'calidad.dashboard.service',
      'get_dashboard_data',
      args: [filters ?? {}],
    );
    return Map<String, dynamic>.from(result as Map);
  }

  /// Opciones de filtro del dashboard.
  Future<Map<String, dynamic>> getDashboardFilterOptions() async {
    final result = await callMethod(
      'calidad.dashboard.service',
      'get_filter_options',
    );
    return Map<String, dynamic>.from(result as Map);
  }

  void _ensureInit() {
    if (_initialized) return;
    if (!AppConfig.hasValidBaseUrl) {
      throw Exception('Config Odoo inválida: ODOO_BASE_URL no es una URL válida.');
    }
    init();
  }

  Future<T> _withRetry<T>(Future<T> Function() fn) async {
    int attempt = 0;
    Object? lastError;
    while (attempt <= AppConfig.rpcRetries) {
      try {
        return await fn().timeout(Duration(seconds: AppConfig.httpTimeoutSeconds));
      } on TimeoutException {
        lastError = Exception('Timeout de red con Odoo (${AppConfig.httpTimeoutSeconds}s).');
        AppLogger.warning(
          'Timeout Odoo',
          data: {'attempt': attempt + 1, 'max': AppConfig.rpcRetries + 1},
          scope: 'odoo.rpc',
        );
        if (attempt == AppConfig.rpcRetries) rethrow;
      } catch (e) {
        lastError = e;
        AppLogger.warning(
          'Error RPC Odoo, reintento',
          data: {'attempt': attempt + 1, 'max': AppConfig.rpcRetries + 1, 'error': e.toString()},
          scope: 'odoo.rpc',
        );
        if (attempt == AppConfig.rpcRetries) rethrow;
      }
      attempt++;
      await Future<void>.delayed(Duration(milliseconds: 250 * attempt));
    }
    AppLogger.error('Fallo RPC Odoo tras reintentos', error: lastError, scope: 'odoo.rpc');
    throw lastError ?? Exception('Error de conexión con Odoo.');
  }
}
