import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

import '../config/app_config.dart';
import 'app_logger.dart';
import 'portal_api_service.dart';

/// Firebase is deliberately inactive until all build-time values exist.
/// The server-side credential belongs only in Odoo's deployment environment.
class PushNotificationsService {
  PushNotificationsService._();

  static final instance = PushNotificationsService._();

  final PortalApiService _portalApi = PortalApiService();
  StreamSubscription<String>? _tokenRefreshSubscription;
  StreamSubscription<RemoteMessage>? _foregroundSubscription;
  StreamSubscription<RemoteMessage>? _openedSubscription;
  bool _configured = false;
  bool _configuring = false;

  static FirebaseOptions get _options => FirebaseOptions(
    apiKey: AppConfig.firebaseApiKey,
    appId: AppConfig.firebaseAppId,
    messagingSenderId: AppConfig.firebaseMessagingSenderId,
    projectId: AppConfig.firebaseProjectId,
  );

  /// Registers the entry point before the UI starts, so a device which has
  /// already registered can receive a message while the app is backgrounded.
  static Future<void> prepareBackgroundHandling() async {
    if (!AppConfig.hasPushConfiguration) return;
    try {
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp(options: _options);
      }
      FirebaseMessaging.onBackgroundMessage(
        cicFirebaseBackgroundMessageHandler,
      );
    } catch (error, stackTrace) {
      AppLogger.error(
        'No se pudo preparar el receptor push en segundo plano',
        error: error,
        stackTrace: stackTrace,
        scope: 'push',
      );
    }
  }

  Future<void> configure({VoidCallback? onForegroundMessage}) async {
    if (!AppConfig.hasPushConfiguration || _configured || _configuring) return;
    _configuring = true;
    try {
      await prepareBackgroundHandling();
      final messaging = FirebaseMessaging.instance;
      await messaging.setAutoInitEnabled(true);

      final settings = await messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );
      if (settings.authorizationStatus == AuthorizationStatus.denied) {
        AppLogger.info(
          'Notificaciones push no autorizadas por el usuario',
          scope: 'push',
        );
        return;
      }

      if (defaultTargetPlatform == TargetPlatform.iOS &&
          await messaging.getAPNSToken() == null) {
        AppLogger.info(
          'APNs aún no ha entregado un token; se reintentará al abrir la app',
          scope: 'push',
        );
        return;
      }

      final token = await messaging.getToken(
        vapidKey: AppConfig.firebaseVapidKey.isEmpty
            ? null
            : AppConfig.firebaseVapidKey,
      );
      if (token != null && token.isNotEmpty) await _registerToken(token);

      _tokenRefreshSubscription = messaging.onTokenRefresh.listen(
        _registerToken,
        onError: (Object error, StackTrace stackTrace) => AppLogger.error(
          'No se pudo renovar el token push',
          error: error,
          stackTrace: stackTrace,
          scope: 'push',
        ),
      );
      _foregroundSubscription = FirebaseMessaging.onMessage.listen((message) {
        AppLogger.info(
          'Push recibido con la app en primer plano',
          data: {'message_id': message.messageId},
          scope: 'push',
        );
        onForegroundMessage?.call();
      });
      _openedSubscription = FirebaseMessaging.onMessageOpenedApp.listen((_) {
        onForegroundMessage?.call();
      });
      _configured = true;
    } catch (error, stackTrace) {
      AppLogger.error(
        'No se pudo configurar la recepción de notificaciones push',
        error: error,
        stackTrace: stackTrace,
        scope: 'push',
      );
    } finally {
      _configuring = false;
    }
  }

  Future<void> _registerToken(String token) async {
    try {
      await _portalApi.action(
        'push_register',
        values: {'token': token, 'platform': _platformName},
      );
    } catch (error, stackTrace) {
      AppLogger.error(
        'No se pudo registrar el dispositivo para avisos push',
        error: error,
        stackTrace: stackTrace,
        scope: 'push',
      );
    }
  }

  String get _platformName {
    if (kIsWeb) return 'web';
    return switch (defaultTargetPlatform) {
      TargetPlatform.iOS => 'ios',
      TargetPlatform.android => 'android',
      _ => 'other',
    };
  }

  void stop() {
    _tokenRefreshSubscription?.cancel();
    _foregroundSubscription?.cancel();
    _openedSubscription?.cancel();
    _tokenRefreshSubscription = null;
    _foregroundSubscription = null;
    _openedSubscription = null;
    _configured = false;
  }
}

@pragma('vm:entry-point')
Future<void> cicFirebaseBackgroundMessageHandler(RemoteMessage message) async {
  if (!AppConfig.hasPushConfiguration) return;
  if (Firebase.apps.isEmpty) {
    await Firebase.initializeApp(options: PushNotificationsService._options);
  }
  AppLogger.info(
    'Push recibido en segundo plano',
    data: {'message_id': message.messageId},
    scope: 'push',
  );
}
