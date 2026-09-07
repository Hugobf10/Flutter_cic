import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:cic_odoo_app/services/rpc_executor.dart';

void main() {
  const executor = RpcExecutor(timeout: Duration(milliseconds: 20), retries: 3);
  test('a timed-out write is never retried', () async {
    var calls = 0;
    final pending = Completer<int>();
    await expectLater(
      executor.run(() {
        calls++;
        return pending.future;
      }),
      throwsA(isA<TimeoutException>()),
    );
    pending.complete(1); // The server may finish after the client timeout.
    expect(calls, 1);
  });
  test('a write is not repeated on connection failure', () async {
    var calls = 0;
    await expectLater(
      executor.run(() async {
        calls++;
        throw http.ClientException('connection lost');
      }),
      throwsA(isA<http.ClientException>()),
    );
    expect(calls, 1);
  });
  test('an explicitly read-only request retries a transient failure', () async {
    var calls = 0;
    final result = await executor.run(() async {
      if (++calls == 1) throw http.ClientException('offline');
      return 42;
    }, readOnly: true);
    expect(result, 42);
    expect(calls, 2);
  });
  test('permission and business errors are never retried', () async {
    var calls = 0;
    await expectLater(
      executor.run(() async {
        calls++;
        throw StateError('access denied');
      }, readOnly: true),
      throwsStateError,
    );
    expect(calls, 1);
  });
}
