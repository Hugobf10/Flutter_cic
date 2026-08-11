import '../../services/odoo_service.dart';
import '../core/auth_models.dart';
import '../core/auth_provider.dart';

class OdooPasswordAuth implements AuthProvider {
  OdooPasswordAuth({required OdooService odoo, required this.request})
    : _odoo = odoo;

  final OdooService _odoo;
  final AuthLoginRequest request;

  @override
  Future<AuthResult> login() async {
    final serverUrl = (request.serverUrl ?? '').trim();
    final database = (request.database ?? '').trim();
    final login = (request.login ?? '').trim();
    final password = request.password ?? '';

    if (serverUrl.isEmpty ||
        database.isEmpty ||
        login.isEmpty ||
        password.isEmpty) {
      return const AuthResult(
        success: false,
        errorMessage: 'Completa servidor, base de datos, usuario y contraseña.',
      );
    }

    _odoo.init(baseUrl: serverUrl);
    final ok = await _odoo.authenticate(login, password, database: database);
    if (!ok) {
      final sanitized = OdooService.prettyAuthError(_odoo.lastAuthError);
      return AuthResult(
        success: false,
        errorMessage: sanitized.isNotEmpty
            ? sanitized
            : 'Credenciales incorrectas o servidor no disponible.',
      );
    }

    final user = await currentUser();
    return AuthResult(success: true, user: user);
  }

  @override
  Future<AuthUser?> currentUser() async {
    final info = _odoo.userInfo;
    if (info == null) return null;
    final partner = info['partner_id'];
    final partnerId = partner is List && partner.isNotEmpty
        ? (partner.first as num).toInt()
        : 0;
    return AuthUser(
      userId: (info['uid'] as num?)?.toInt() ?? 0,
      partnerId: partnerId,
      name: info['name']?.toString() ?? '',
      login: info['username']?.toString() ?? '',
    );
  }

  @override
  Future<void> logout() => _odoo.logout();

  @override
  Future<bool> restoreSession() => _odoo.tryRestoreStoredSession();
}
