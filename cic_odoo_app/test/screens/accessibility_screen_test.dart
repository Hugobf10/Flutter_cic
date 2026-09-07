import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cic_odoo_app/app/providers/app_state_provider.dart';
import 'package:cic_odoo_app/app/screens/accessibility_screen.dart';
import 'package:cic_odoo_app/l10n/generated/app_localizations.dart';
import 'package:cic_odoo_app/theme/accessibility_media.dart';
import 'package:cic_odoo_app/theme/app_theme.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('system magnification is never capped by app settings', () {
    const scaler = PreferenceTextScaler(TextScaler.linear(3), 1.4);
    expect(scaler.scale(20), closeTo(84, 0.001));
  });

  test('preferences survive restart and reset preserves language', () async {
    final first = AppStateProvider();
    await first.setLocale(const Locale('en'));
    await first.setHighContrast(true);
    await first.setAlternativeColors(true);
    await first.setBoldText(true);
    await first.setReduceMotion(true);
    await first.setTextScaleFactor(1.4);
    first.dispose();
    final restored = AppStateProvider();
    addTearDown(restored.dispose);
    await restored.preferencesReady;
    expect(restored.locale, const Locale('en'));
    expect(restored.highContrast, isTrue);
    expect(restored.alternativeColors, isTrue);
    expect(restored.boldText, isTrue);
    expect(restored.reduceMotion, isTrue);
    expect(restored.textScaleFactor, 1.4);
    await restored.setTextScaleFactor(double.nan);
    expect(restored.textScaleFactor, 1.4);
    await restored.resetAccessibilityPreferences();
    expect(restored.locale, const Locale('en'));
    expect(restored.highContrast, isFalse);
    expect(restored.alternativeColors, isFalse);
    expect(restored.textScaleFactor, 1);
  });

  for (final language in ['es', 'en']) {
    testWidgets('settings scroll on a narrow phone at 200% text in $language', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final settings = AppStateProvider();
      await settings.preferencesReady;
      addTearDown(settings.dispose);
      await tester.pumpWidget(
        ChangeNotifierProvider.value(
          value: settings,
          child: MaterialApp(
            locale: Locale(language),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            theme: AppTheme.lightThemeFor(highContrast: true),
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(context).copyWith(
                textScaler: const TextScaler.linear(2),
                disableAnimations: true,
                highContrast: true,
              ),
              child: child!,
            ),
            home: const AccessibilityScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      final back = find.text(
        language == 'es' ? 'Volver arriba' : 'Back to top',
      );
      await tester.scrollUntilVisible(back, 250, maxScrolls: 60);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await tester.tap(back);
      await tester.pumpAndSettle();
      expect(
        find.text(language == 'es' ? 'Tamaño del texto' : 'Text size'),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    });
  }
}
