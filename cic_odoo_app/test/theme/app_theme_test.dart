import 'package:cic_odoo_app/app/ui/app_components.dart';
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
  });
}
