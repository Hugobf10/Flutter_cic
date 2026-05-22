import 'auth_models.dart';

/// Capa desacoplada para proveedores de autenticación.
/// Nota: se mantiene este nombre por requisito funcional de la migración SSO.
abstract class AuthProvider {
  Future<AuthResult> login();
  Future<void> logout();
  Future<bool> restoreSession();
  Future<AuthUser?> currentUser();
}
