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

  test('authentication errors never expose internal server details', () {
    const internalError =
        'Exception: https://internal.example.test database=cic_private Traceback secret';

    final message = OdooService.prettyAuthError(internalError);

    expect(
      message,
      'No se pudo iniciar sesión. Revisa tus datos o inténtalo de nuevo más tarde.',
    );
    expect(message, isNot(contains('internal.example.test')));
    expect(message, isNot(contains('cic_private')));
  });

  test('authentication network errors use a safe actionable message', () {
    expect(
      OdooService.prettyAuthError('SocketException: connection refused'),
      'No se pudo conectar de forma segura. Comprueba tu conexión y vuelve a intentarlo.',
    );
  });
}
