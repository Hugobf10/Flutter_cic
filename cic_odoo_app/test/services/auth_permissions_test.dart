import 'package:flutter_test/flutter_test.dart';
import 'package:cic_odoo_app/providers/auth_provider.dart';

class _NamedAdmin extends AuthProvider {
  @override
  String get userLogin => 'admin';
  @override
  bool get isAuthenticated => true;
  @override
  bool get isInternalUser => true;
}

void main() {
  test('the admin username does not grant administrator privileges', () {
    final auth = _NamedAdmin();
    addTearDown(auth.dispose);
    expect(auth.isAdmin, isFalse);
  });
}
