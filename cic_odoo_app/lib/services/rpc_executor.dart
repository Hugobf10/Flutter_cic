import 'dart:async';

import 'package:http/http.dart' as http;

/// A timed-out write may already have committed on the server. Only callers
/// that explicitly identify a read-only operation may retry it.
class RpcExecutor {
  const RpcExecutor({required this.timeout, required this.retries});

  final Duration timeout;
  final int retries;

  Future<T> run<T>(
    Future<T> Function() operation, {
    bool readOnly = false,
  }) async {
    final attempts = readOnly ? retries.clamp(0, 3) : 0;
    for (var attempt = 0; ; attempt++) {
      try {
        return await operation().timeout(timeout);
      } catch (error) {
        final transient =
            error is TimeoutException || error is http.ClientException;
        if (!transient || attempt >= attempts) rethrow;
        await Future<void>.delayed(Duration(milliseconds: 250 * (attempt + 1)));
      }
    }
  }
}
