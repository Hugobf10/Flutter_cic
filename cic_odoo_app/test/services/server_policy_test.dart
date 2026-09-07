import 'package:flutter_test/flutter_test.dart';
import 'package:cic_odoo_app/config/server_policy.dart';

void main() {
  test('accepts HTTPS origins only, without credentials or paths', () {
    for (final valid in [
      'https://odoo.example.com',
      'https://odoo.example.com/',
      'https://odoo.example.com:8443',
    ]) {
      expect(ServerPolicy.isSecureOrigin(valid), isTrue, reason: valid);
    }
    for (final invalid in [
      '',
      'http://odoo.example.com',
      'odoo.example.com',
      'https://user:secret@odoo.example.com',
      'https://odoo.example.com/web',
      'https://odoo.example.com?token=secret',
      'https://odoo.example.com/#secret',
    ]) {
      expect(ServerPolicy.isSecureOrigin(invalid), isFalse, reason: invalid);
    }
  });
}
