import 'dart:async';

import 'package:app_links/app_links.dart';

class DeepLinkService {
  AppLinks? _appLinks;
  StreamSubscription<Uri>? _subscription;
  bool _started = false;

  Future<void> start(void Function(Uri uri) onUri) async {
    if (_started) return;
    _started = true;
    _appLinks = AppLinks();

    final initialUri = await _appLinks!.getInitialLink();
    if (initialUri != null) {
      onUri(initialUri);
    }

    _subscription = _appLinks!.uriLinkStream.listen(onUri);
  }

  Future<void> dispose() async {
    await _subscription?.cancel();
    _subscription = null;
    _started = false;
  }
}
