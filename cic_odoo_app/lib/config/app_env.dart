class AppEnv {
  static const String stagingBaseUrl = 'https://staging-cicancer.octupus.app/';
  static const String stagingDatabase = 'staging-cicancer.octupus.app';

  static const String odooBaseUrl = String.fromEnvironment(
    'ODOO_BASE_URL',
    // Staging remains the default until the deployment pipeline supplies its
    // own production values through --dart-define.
    defaultValue: stagingBaseUrl,
  );
  static const String odooDatabase = String.fromEnvironment(
    'ODOO_DATABASE',
    defaultValue: stagingDatabase,
  );

  /// A release build may only use the checked-in staging fallback when the
  /// build explicitly identifies itself as a staging distribution.
  static const bool allowStagingInRelease = bool.fromEnvironment(
    'ALLOW_STAGING_IN_RELEASE',
    defaultValue: false,
  );

  static bool get usesStagingTarget =>
      odooBaseUrl.trim() == stagingBaseUrl && odooDatabase == stagingDatabase;
}
