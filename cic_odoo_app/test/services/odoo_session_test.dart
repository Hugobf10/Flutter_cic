import 'package:flutter_test/flutter_test.dart';

import 'package:cic_odoo_app/services/odoo_service.dart';

void main() {
  test('classifies standard Odoo portal session without res.users access', () {
    expect(
      OdooService.sessionIsInternal({
        'uid': 21,
        'is_public': false,
        'user_companies': false,
      }),
      false,
    );
  });

  test('classifies internal session from allowed companies', () {
    expect(
      OdooService.sessionIsInternal({
        'uid': 7,
        'user_companies': {
          'current_company': 1,
          'allowed_companies': {
            '1': {'id': 1, 'name': 'CIC'},
          },
        },
      }),
      true,
    );
  });

  test('does not treat public sessions as portal users', () {
    expect(OdooService.isPublicSession({'is_public': true}), true);
  });
}
