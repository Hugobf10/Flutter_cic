import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cic_odoo_app/app/ui/app_components.dart';
import 'package:cic_odoo_app/main.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const CicSalamancaApp());
    // El splash usa únicamente el flequillito animado, sin el nombre ni spinner.
    expect(find.byType(AppLoadingIndicator), findsOneWidget);
    expect(find.text('CIC Salamanca'), findsNothing);
    expect(find.byType(CircularProgressIndicator), findsNothing);
  });
}
