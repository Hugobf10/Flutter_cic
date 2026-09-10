import 'package:flutter_test/flutter_test.dart';

import 'package:cic_odoo_app/screens/reservas/reservation_entry_target.dart';

void main() {
  test('parses the reservation QR deep link payload', () {
    final target = ReservationEntryTarget.parse(
      'com.cic.flutter://reservas?tab=agenda&variantId=42&serviceTemplateId=8&label=Sala%20A',
    );

    expect(target, isNotNull);
    expect(target!.variantId, 42);
    expect(target.serviceTemplateId, 8);
    expect(target.resourceLabel, 'Sala A');
    expect(target.initialTabIndex, 2);
  });

  test('rejects empty or unrelated QR payloads', () {
    expect(ReservationEntryTarget.parse(''), isNull);
    expect(ReservationEntryTarget.parse('https://example.org/other'), isNull);
  });

  test(
    'rejects lookalike web links and paths outside the reservation entrypoint',
    () {
      expect(
        ReservationEntryTarget.parse(
          'https://example.org/reservas?variantId=42',
        ),
        isNull,
      );
      expect(
        ReservationEntryTarget.parse(
          'https://reservas/reservas/admin?variantId=42',
        ),
        isNull,
      );
    },
  );

  test('accepts the allowlisted reservation web entrypoint', () {
    final target = ReservationEntryTarget.parse(
      'https://reservas/reservas?variantId=42',
    );
    expect(target?.variantId, 42);
  });
}
