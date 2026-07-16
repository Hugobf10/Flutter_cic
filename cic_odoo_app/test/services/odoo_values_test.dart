import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';

import 'package:cic_odoo_app/services/odoo_values.dart';

void main() {
  group('OdooValues', () {
    test('interprets many2one values and false safely', () {
      expect(OdooValues.many2oneId([12, 'Proveedor']), 12);
      expect(OdooValues.many2oneLabel([12, 'Proveedor']), 'Proveedor');
      expect(OdooValues.many2oneId(false), isNull);
      expect(
        OdooValues.many2oneLabel(false, fallback: 'Sin proveedor'),
        'Sin proveedor',
      );
    });

    test('normalizes numeric and date values', () {
      expect(OdooValues.number('12,50'), 12.5);
      expect(OdooValues.intValue('42'), 42);
      expect(OdooValues.dateTime('2026-07-16 14:30:00'), isNotNull);
      expect(OdooValues.dateTime(false), isNull);
    });

    test('decodes binary fields and data URLs', () {
      final encoded = base64Encode([1, 2, 3]);
      expect(OdooValues.binary(encoded), [1, 2, 3]);
      expect(OdooValues.binary('data:image/png;base64,$encoded'), [1, 2, 3]);
      expect(OdooValues.binary(false), isNull);
      expect(OdooValues.binary('not-base64'), isNull);
    });
  });
}
