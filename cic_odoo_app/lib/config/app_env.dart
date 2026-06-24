class AppEnv {
  static const String odooBaseUrl = String.fromEnvironment(
    'ODOO_BASE_URL',
    defaultValue: '',
  );
  static const String odooDatabase = String.fromEnvironment(
    'ODOO_DATABASE',
    defaultValue: '',
  );
}
