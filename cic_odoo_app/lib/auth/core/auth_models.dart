class AuthUser {
  const AuthUser({
    required this.userId,
    required this.partnerId,
    required this.name,
    required this.login,
  });

  final int userId;
  final int partnerId;
  final String name;
  final String login;
}

class AuthResult {
  const AuthResult({
    required this.success,
    this.user,
    this.errorMessage,
  });

  final bool success;
  final AuthUser? user;
  final String? errorMessage;
}

class AuthLoginRequest {
  const AuthLoginRequest({
    this.login,
    this.password,
    this.serverUrl,
    this.database,
  });

  final String? login;
  final String? password;
  final String? serverUrl;
  final String? database;
}
