import 'dart:convert';
import 'dart:typed_data';

/// Small, defensive readers for values returned by Odoo's JSON-RPC ORM.
class OdooValues {
  OdooValues._();

  static Map<String, dynamic> map(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return Map<String, dynamic>.from(value);
    return <String, dynamic>{};
  }

  static int? intValue(dynamic value) {
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString().trim() ?? '');
  }

  static double number(dynamic value, {double fallback = 0}) {
    if (value is num) return value.toDouble();
    final parsed = double.tryParse(
      value?.toString().trim().replaceAll(',', '.') ?? '',
    );
    return parsed ?? fallback;
  }

  static bool boolValue(dynamic value, {bool fallback = false}) {
    if (value is bool) return value;
    if (value is num) return value != 0;
    final normalized = value?.toString().trim().toLowerCase();
    if (normalized == 'true' || normalized == '1') return true;
    if (normalized == 'false' || normalized == '0') return false;
    return fallback;
  }

  static String string(dynamic value, {String fallback = ''}) {
    if (value == null || value == false) return fallback;
    final result = value.toString().trim();
    return result.isEmpty ? fallback : result;
  }

  static int? many2oneId(dynamic value) {
    if (value is List && value.isNotEmpty) {
      return intValue(value.first);
    }
    if (value is Map) {
      return intValue(value['id']);
    }
    return intValue(value);
  }

  static String many2oneLabel(dynamic value, {String fallback = ''}) {
    if (value is List && value.length > 1) {
      return string(value[1], fallback: fallback);
    }
    if (value is Map) {
      return string(value['display_name'] ?? value['name'], fallback: fallback);
    }
    return fallback;
  }

  static List<int> ids(dynamic value) {
    if (value is! List) return const [];
    return value.map(many2oneId).whereType<int>().toList(growable: false);
  }

  static DateTime? dateTime(dynamic value) {
    final raw = string(value);
    if (raw.isEmpty) return null;
    return DateTime.tryParse(raw.replaceFirst(' ', 'T'));
  }

  static Uint8List? binary(dynamic value) {
    final raw = string(value);
    if (raw.isEmpty) return null;
    final encoded = raw.startsWith('data:')
        ? raw.substring(raw.indexOf(',') + 1)
        : raw;
    try {
      final bytes = base64Decode(encoded);
      return bytes.isEmpty ? null : Uint8List.fromList(bytes);
    } on FormatException {
      return null;
    }
  }
}
