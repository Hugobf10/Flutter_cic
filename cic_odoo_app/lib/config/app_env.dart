class AppEnv {
  static const String odooBaseUrl = String.fromEnvironment(
    'ODOO_BASE_URL',
    // Staging remains the default until the deployment pipeline supplies its
    // own production values through --dart-define.
    defaultValue: 'https://staging-cicancer.octupus.app/',
  );
  static const String odooDatabase = String.fromEnvironment(
    'ODOO_DATABASE',
    defaultValue: 'staging-cicancer.octupus.app',
  );
}
