import 'package:flutter_test/flutter_test.dart';
import 'package:cic_odoo_app/config/app_config.dart';

void main() {
  test('the development build has a usable CIC staging configuration', () {
    expect(AppConfig.odooBaseUrl, 'https://staging-cicancer.octupus.app/');
    expect(AppConfig.odooDatabaseName, 'staging-cicancer.octupus.app');
    expect(AppConfig.hasValidBaseUrl, isTrue);
  });
}
