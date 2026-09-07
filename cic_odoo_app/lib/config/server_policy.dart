class ServerPolicy {
  ServerPolicy._();

  static bool isSecureOrigin(String raw) {
    final uri = Uri.tryParse(raw.trim());
    return uri != null &&
        uri.scheme == 'https' &&
        uri.host.isNotEmpty &&
        uri.userInfo.isEmpty &&
        !uri.hasQuery &&
        !uri.hasFragment &&
        (uri.path.isEmpty || uri.path == '/');
  }
}
