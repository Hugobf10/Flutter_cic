import 'package:flutter_test/flutter_test.dart';
import 'package:cic_odoo_app/main.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const CicSuperApp());
    // Verifica que el splash screen se muestra
    expect(find.text('CIC SuperApp'), findsOneWidget);
  });
}
