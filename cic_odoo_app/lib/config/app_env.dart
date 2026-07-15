class AppEnv {
  static const String odooBaseUrl = String.fromEnvironment(
    'ODOO_BASE_URL',
    defaultValue: 'https://staging-cicancer.octupus.app/',
  );
  static const String odooDatabase = String.fromEnvironment(
    'ODOO_DATABASE',
    defaultValue: 'staging-cicancer.octupus.app',
  );
}
