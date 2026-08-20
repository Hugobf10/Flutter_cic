import 'package:flutter_test/flutter_test.dart';
import 'package:odoo_rpc/odoo_rpc.dart';

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

  test('keeps the active session id when refreshing Odoo session info', () {
    const refreshedSession = OdooSession(
      id: '',
      userId: 7,
      partnerId: 12,
      companyId: 1,
      allowedCompanies: [],
      userLogin: 'usuario',
      userName: 'Usuario',
      userLang: 'es_ES',
      userTz: 'Europe/Madrid',
      isSystem: false,
      dbName: 'cic',
      serverVersion: '17.0',
    );

    final session = OdooService.withActiveSessionId(
      refreshedSession,
      'session-id-persistente',
    );

    expect(session.id, 'session-id-persistente');
    expect(session.userId, 7);
    expect(session.userLogin, 'usuario');
  });
}
