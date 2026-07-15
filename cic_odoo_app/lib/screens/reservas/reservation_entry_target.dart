import 'dart:convert';

class ReservationEntryTarget {
  const ReservationEntryTarget({
    this.serviceTemplateId,
    this.variantId,
    this.day,
    this.resourceLabel,
    this.initialTabIndex = 2,
    this.rawValue,
  });

  final int? serviceTemplateId;
  final int? variantId;
  final DateTime? day;
  final String? resourceLabel;
  final int initialTabIndex;
  final String? rawValue;

  bool get hasContext =>
      serviceTemplateId != null || variantId != null || day != null;

  ReservationEntryTarget copyWith({
    int? serviceTemplateId,
    int? variantId,
    DateTime? day,
    String? resourceLabel,
    int? initialTabIndex,
    String? rawValue,
  }) {
    return ReservationEntryTarget(
      serviceTemplateId: serviceTemplateId ?? this.serviceTemplateId,
      variantId: variantId ?? this.variantId,
      day: day ?? this.day,
      resourceLabel: resourceLabel ?? this.resourceLabel,
      initialTabIndex: initialTabIndex ?? this.initialTabIndex,
      rawValue: rawValue ?? this.rawValue,
    );
  }

  static ReservationEntryTarget? parse(String? raw) {
    final value = raw?.trim();
    if (value == null || value.isEmpty) return null;

    final directUri = Uri.tryParse(value);
    if (directUri != null &&
        directUri.hasScheme &&
        (directUri.host.isNotEmpty || directUri.path.isNotEmpty)) {
      final parsed = fromUri(directUri, rawValue: value);
      if (parsed != null) return parsed;
    }

    final jsonParsed = _fromJson(value);
    if (jsonParsed != null) return jsonParsed;

    final compact = RegExp(r'^(?:reservas|reserva|cic-reserva):(\d+)$');
    final match = compact.firstMatch(value.toLowerCase());
    if (match != null) {
      return ReservationEntryTarget(
        variantId: int.tryParse(match.group(1)!),
        initialTabIndex: 2,
        rawValue: value,
      );
    }

    return null;
  }

  static ReservationEntryTarget? fromUri(Uri uri, {String? rawValue}) {
    final scheme = uri.scheme.toLowerCase();
    final host = uri.host.toLowerCase();
    final path = uri.path.toLowerCase();

    final isReservationsLink =
        host == 'reservas' ||
        host == 'reserva' ||
        path.contains('/reservas') ||
        path == '/reserva' ||
        uri.queryParameters['module']?.toLowerCase() == 'reservas';

    if (!isReservationsLink &&
        scheme != 'com.cic.flutter' &&
        scheme != 'reservas' &&
        scheme != 'reserva' &&
        scheme != 'cic-reserva') {
      return null;
    }

    final params = uri.queryParameters.map(
      (key, value) => MapEntry(key.toLowerCase(), value),
    );

    final tab = params['tab']?.toLowerCase().trim();
    final day = _parseDate(
      params['day'] ?? params['date'] ?? params['fecha'] ?? '',
    );
    final target = ReservationEntryTarget(
      serviceTemplateId: _firstInt(params, const [
        'servicetemplateid',
        'templateid',
        'producttemplateid',
      ]),
      variantId: _firstInt(params, const [
        'variantid',
        'resourceid',
        'servicioid',
        'productid',
      ]),
      day: day,
      resourceLabel: params['label'] ?? params['name'] ?? params['resource'],
      initialTabIndex: switch (tab) {
        'new' || 'nueva' || 'crear' => 0,
        'mine' || 'mis' => 1,
        _ => 2,
      },
      rawValue: rawValue ?? uri.toString(),
    );
    return target.hasContext ? target : null;
  }

  static ReservationEntryTarget? _fromJson(String raw) {
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return null;
      final json = decoded.map(
        (key, value) => MapEntry(key.toString().toLowerCase(), value),
      );
      final module = json['module']?.toString().toLowerCase();
      if (module != null && module != 'reservas' && module != 'reserva') {
        return null;
      }
      final target = ReservationEntryTarget(
        serviceTemplateId: _coerceInt(
          json['servicetemplateid'] ?? json['templateid'],
        ),
        variantId: _coerceInt(
          json['variantid'] ?? json['resourceid'] ?? json['servicioid'],
        ),
        day: _parseDate(
          (json['day'] ?? json['date'] ?? json['fecha'] ?? '').toString(),
        ),
        resourceLabel: (json['label'] ?? json['name'] ?? json['resource'])
            ?.toString(),
        initialTabIndex: _coerceTabIndex(
          (json['tab'] ?? json['screen'])?.toString(),
        ),
        rawValue: raw,
      );
      return target.hasContext ? target : null;
    } catch (_) {
      return null;
    }
  }

  static int _coerceTabIndex(String? value) {
    switch (value?.trim().toLowerCase()) {
      case '0':
      case 'new':
      case 'nueva':
      case 'crear':
        return 0;
      case '1':
      case 'mine':
      case 'mis':
        return 1;
      default:
        return 2;
    }
  }

  static int? _firstInt(Map<String, String> params, List<String> keys) {
    for (final key in keys) {
      final parsed = _coerceInt(params[key]);
      if (parsed != null) return parsed;
    }
    return null;
  }

  static int? _coerceInt(Object? value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString().trim() ?? '');
  }

  static DateTime? _parseDate(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return null;
    final parsed = DateTime.tryParse(trimmed);
    if (parsed == null) return null;
    return DateTime(parsed.year, parsed.month, parsed.day);
  }
}
