import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:odoo_rpc/odoo_rpc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cic_odoo_app/services/odoo_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test(
    'secure-storage failure never falls back to plaintext session cookies',
    () async {
      SharedPreferences.setMockInitialValues({
        'odoo_session_json_prefs': 'legacy-cookie',
        'odoo_user_info_json_prefs': 'legacy-profile',
      });
      const channel = MethodChannel(
        'plugins.it_nomads.com/flutter_secure_storage',
      );
      final messenger =
          TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
      messenger.setMockMethodCallHandler(channel, (_) async {
        throw PlatformException(code: 'storage_unavailable');
      });
      addTearDown(() => messenger.setMockMethodCallHandler(channel, null));
      final odoo = OdooService();
      odoo.init(
        baseUrl: 'https://example.invalid',
        session: const OdooSession(
          id: 'synthetic-cookie',
          userId: 7,
          partnerId: 12,
          companyId: 1,
          allowedCompanies: [],
          userLogin: 'test-user',
          userName: 'Test',
          userLang: 'es_ES',
          userTz: 'Europe/Madrid',
          isSystem: false,
          dbName: 'test-db',
          serverVersion: '17.0',
        ),
      );
      addTearDown(() => odoo.init(baseUrl: 'https://example.invalid'));
      await expectLater(odoo.persistSessionSnapshot(), throwsStateError);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.containsKey('odoo_session_json_prefs'), isFalse);
      expect(prefs.containsKey('odoo_user_info_json_prefs'), isFalse);
      for (final key in prefs.getKeys()) {
        expect(prefs.get(key).toString(), isNot(contains('synthetic-cookie')));
      }
    },
  );
}
