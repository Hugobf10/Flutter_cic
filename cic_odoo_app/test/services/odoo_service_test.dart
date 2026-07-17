import 'package:flutter_test/flutter_test.dart';
import 'package:odoo_rpc/odoo_rpc.dart';

import 'package:cic_odoo_app/services/odoo_service.dart';

void main() {
  test('shows the functional Odoo message instead of the traceback', () {
    final error = OdooException({
      'code': 200,
      'message': 'Odoo Server Error',
      'data': {
        'name': 'odoo.exceptions.UserError',
        'message': 'La cantidad recibida supera la pendiente (3).',
        'debug': 'Traceback (most recent call last): ...',
      },
    });

    expect(
      OdooService.prettyError(error),
      'La cantidad recibida supera la pendiente (3).',
    );
  });
}
