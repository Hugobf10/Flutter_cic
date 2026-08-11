import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:cic_odoo_app/app/providers/app_state_provider.dart';
import 'package:cic_odoo_app/config/app_config.dart';
import 'package:cic_odoo_app/providers/auth_provider.dart';
import 'package:cic_odoo_app/screens/login/login_screen.dart';
import 'package:cic_odoo_app/theme/app_theme.dart';

void main() {
  testWidgets(
    'login offers useful privacy information without technical data',
    (tester) async {
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (_) => AuthProvider()),
            ChangeNotifierProvider(create: (_) => AppStateProvider()),
          ],
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            home: const LoginScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Accede a tu espacio'), findsOneWidget);
      expect(find.text('Privacidad desde el primer paso'), findsOneWidget);
      expect(
        find.textContaining('Antes de identificarte no cargamos avisos'),
        findsOneWidget,
      );
      expect(find.text(AppConfig.odooBaseUrl), findsNothing);
      expect(find.text(AppConfig.odooDatabaseName), findsNothing);
      expect(find.text('Configuración de soporte'), findsNothing);
      expect(find.byType(CircularProgressIndicator), findsNothing);
    },
  );

  testWidgets('login keeps the complete design on a compact phone', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => AuthProvider()),
          ChangeNotifierProvider(create: (_) => AppStateProvider()),
        ],
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          home: const LoginScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Tu espacio CIC'), findsOneWidget);
    expect(find.text('Accede a tu espacio'), findsOneWidget);
    expect(find.textContaining('¿Problemas para entrar?'), findsOneWidget);
  });
}
