import '../../services/odoo_service.dart';
import '../core/auth_models.dart';
import '../providers/odoo_password_auth.dart';

class AuthService {
  AuthService({OdooService? odoo}) : _odoo = odoo ?? OdooService();

  final OdooService _odoo;

  Future<AuthResult> loginPassword(AuthLoginRequest request) async {
    final provider = OdooPasswordAuth(odoo: _odoo, request: request);
    final result = await provider.login();
    if (result.success) {
      await _odoo.persistSessionSnapshot();
    }
    return result;
  }

  Future<void> logout() async {
    final provider = OdooPasswordAuth(
      odoo: _odoo,
      request: const AuthLoginRequest(),
    );
    await provider.logout();
  }

  Future<bool> restoreSession() async {
    final provider = OdooPasswordAuth(
      odoo: _odoo,
      request: const AuthLoginRequest(),
    );
    return provider.restoreSession();
  }

  Future<AuthUser?> currentUser() async {
    final provider = OdooPasswordAuth(
      odoo: _odoo,
      request: const AuthLoginRequest(),
    );
    return provider.currentUser();
  }
}

/// Adaptador explícito para autenticación Odoo nativa (JSON-RPC /web/session/authenticate).
class OdooAuthService {
  OdooAuthService({AuthService? authService})
    : _authService = authService ?? AuthService();

  final AuthService _authService;

  Future<AuthResult> authenticate(AuthLoginRequest request) {
    return _authService.loginPassword(request);
  }

  Future<void> destroySession() {
    return _authService.logout();
  }

  Future<bool> restoreSession() {
    return _authService.restoreSession();
  }

  Future<AuthUser?> loadCurrentUser() {
    return _authService.currentUser();
  }
}
