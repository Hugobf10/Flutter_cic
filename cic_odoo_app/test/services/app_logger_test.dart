import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cic_odoo_app/services/app_logger.dart';

void main() {
  test('redacts nested credentials and request payloads', () {
    final lines = <String>[];
    final original = debugPrint;
    debugPrint = (message, {wrapWidth}) => lines.add(message ?? '');
    addTearDown(() => debugPrint = original);
    AppLogger.info(
      'request',
      data: {
        'path': '/safe/path',
        'nested': [
          {'authorization': 'secret-a', 'session_id': 'secret-b'},
        ],
        'params': {'name': 'private name'},
        'email': 'private@example.com',
      },
    );
    final output = lines.join();
    expect(output, contains('/safe/path'));
    for (final secret in [
      'secret-a',
      'secret-b',
      'private name',
      'private@example.com',
    ]) {
      expect(output, isNot(contains(secret)));
    }
    expect(output, contains('[REDACTED]'));
  });
}
