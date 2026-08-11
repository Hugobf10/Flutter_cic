import 'package:cic_odoo_app/app/ui/app_components.dart';
import 'package:cic_odoo_app/theme/app_motion.dart';
import 'package:cic_odoo_app/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('las superficies neumórficas se adaptan al modo claro y oscuro', (
    tester,
  ) async {
    Future<BoxDecoration> renderWith(ThemeData theme) async {
      await tester.pumpWidget(
        MaterialApp(
          key: ValueKey(theme.brightness),
          theme: theme,
          home: const Scaffold(body: NeumorphicSurface(child: Text('CIC'))),
        ),
      );

      final surface = tester.widget<AnimatedContainer>(
        find.descendant(
          of: find.byType(NeumorphicSurface),
          matching: find.byType(AnimatedContainer),
        ),
      );
      return surface.decoration! as BoxDecoration;
    }

    final light = await renderWith(AppTheme.lightTheme);
    final dark = await renderWith(AppTheme.darkTheme);

    expect(AppTheme.lightTheme.brightness, Brightness.light);
    expect(AppTheme.darkTheme.brightness, Brightness.dark);
    expect(light.color, isNot(dark.color));
    expect(light.boxShadow, hasLength(2));
    expect(dark.boxShadow, hasLength(2));
    expect(
      AppTheme.lightTheme.pageTransitionsTheme.builders[TargetPlatform.windows],
      isA<AppPageTransitionsBuilder>(),
    );
  });

  testWidgets(
    'AppAvatar muestra la foto de Odoo y conserva iniciales de respaldo',
    (tester) async {
      const pixelPng =
          'data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNk+A8AAQUBAScY42YAAAAASUVORK5CYII=';

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: const Scaffold(
            body: Row(
              children: [
                AppAvatar(name: 'Hugo Benítez', imageBase64: pixelPng),
                AppAvatar(name: 'Hugo Benítez', imageBase64: 'false'),
              ],
            ),
          ),
        ),
      );

      expect(find.byKey(const ValueKey('app-avatar-image')), findsOneWidget);
      expect(find.text('HB'), findsOneWidget);
    },
  );

  testWidgets('AppIconSurface aplica relieve a los iconos compartidos', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        home: const Scaffold(
          body: AppIconSurface(
            icon: Icons.school_rounded,
            color: AppTheme.success,
          ),
        ),
      ),
    );

    expect(find.byType(NeumorphicSurface), findsOneWidget);
    expect(find.byIcon(Icons.school_rounded), findsOneWidget);
  });
}
