import 'dart:async';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../screens/reservas/reservation_entry_target.dart';
import '../../services/odoo_service.dart';
import '../../services/portal_api_service.dart';
import '../../services/odoo_values.dart';
import '../../services/app_logger.dart';
import '../core/module_registry.dart';
import '../models/app_module.dart';
import '../models/app_notification.dart';

class AppStateProvider extends ChangeNotifier {
  AppStateProvider() {
    _uiPreferencesFuture = _saveOrLoadPreference(_loadUiPreferences);
  }

  static const _readNotificationKeysPreference =
      'cic.read_notification_keys.v1';
  static const _themeModePreference = 'cic.ui.theme_mode.v1';
  static const _textScalePreference = 'cic.a11y.text_scale.v1';
  static const _highContrastPreference = 'cic.a11y.high_contrast.v1';
  static const _boldTextPreference = 'cic.a11y.bold_text.v1';
  static const _reduceMotionPreference = 'cic.a11y.reduce_motion.v1';
  static const _alternativeColorsPreference = 'cic.a11y.alternative_colors.v1';
  static const _localePreference = 'cic.ui.locale.v1';
  static const _maxStoredReadNotifications = 200;
  final OdooService _odoo = OdooService();
  final PortalApiService _portalApi = PortalApiService();

  ThemeMode _themeMode = ThemeMode.light;
  double _textScaleFactor = 1;
  bool _highContrast = false;
  bool _boldText = false;
  bool _reduceMotion = false;
  bool _alternativeColors = false;
  Locale? _locale;
  bool _disposed = false;
  late final Future<void> _uiPreferencesFuture;
  bool _loadingAcl = false;
  bool _loadingNotifications = false;

  final Set<String> _grantedPermissions = <String>{};
  final Set<String> _readNotificationKeys = <String>{};
  List<AppNotification> _notifications = const [];
  ReservationEntryTarget? _pendingReservationTarget;

  ThemeMode get themeMode => _themeMode;
  double get textScaleFactor => _textScaleFactor;
  bool get highContrast => _highContrast;
  bool get boldText => _boldText;
  bool get reduceMotion => _reduceMotion;
  bool get alternativeColors => _alternativeColors;
  Locale? get locale => _locale;
  Future<void> get preferencesReady => _uiPreferencesFuture;

  @override
  void notifyListeners() {
    if (!_disposed) super.notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  Future<void> setLocale(Locale? value) async {
    if (value != null && !const {'es', 'en'}.contains(value.languageCode)) {
      return;
    }
    await _uiPreferencesFuture;
    _locale = value;
    notifyListeners();
    await _saveOrLoadPreference(() async {
      final prefs = await SharedPreferences.getInstance();
      if (value == null) {
        await prefs.remove(_localePreference);
      } else {
        await prefs.setString(_localePreference, value.languageCode);
      }
    });
  }

  Future<void> setAlternativeColors(bool value) async {
    await _uiPreferencesFuture;
    _alternativeColors = value;
    notifyListeners();
    await _saveOrLoadPreference(_persistAccessibilityPreferences);
  }

  bool get loadingAcl => _loadingAcl;
  bool get loadingNotifications => _loadingNotifications;
  List<AppNotification> get notifications => _notifications;
  int get unreadNotifications => _notifications.where((n) => n.unread).length;
  ReservationEntryTarget? get pendingReservationTarget =>
      _pendingReservationTarget;

  List<AppModule> get availableModules {
    return ModuleRegistry.all.where((m) {
      // Purchases is a backend workflow and is never part of the portal intranet.
      if (_odoo.isPortalSession && m.key == 'purchases') return false;
      if (m.requiredPermission == null) return true;
      if (m.key == 'communications') {
        return _grantedPermissions.contains('communications.view') ||
            _grantedPermissions.contains('suggestions.view');
      }
      if (m.key == 'planning') {
        return _grantedPermissions.contains('goals.view') ||
            _grantedPermissions.contains('action_plans.view') ||
            _grantedPermissions.contains('chemicals.view');
      }
      return _grantedPermissions.contains(m.requiredPermission);
    }).toList();
  }

  Future<void> toggleThemeMode() async {
    await _uiPreferencesFuture;
    _themeMode = _themeMode == ThemeMode.dark
        ? ThemeMode.light
        : ThemeMode.dark;
    notifyListeners();
    await _saveOrLoadPreference(_persistThemeMode);
  }

  Future<void> setTextScaleFactor(double value) async {
    await _uiPreferencesFuture;
    if (!value.isFinite) return;
    final normalized = value.clamp(1.0, 1.4).toDouble();
    if (_textScaleFactor == normalized) return;
    _textScaleFactor = normalized;
    notifyListeners();
    await _saveOrLoadPreference(_persistAccessibilityPreferences);
  }

  Future<void> setHighContrast(bool value) async {
    await _uiPreferencesFuture;
    if (_highContrast == value) return;
    _highContrast = value;
    notifyListeners();
    await _saveOrLoadPreference(_persistAccessibilityPreferences);
  }

  Future<void> setBoldText(bool value) async {
    await _uiPreferencesFuture;
    if (_boldText == value) return;
    _boldText = value;
    notifyListeners();
    await _saveOrLoadPreference(_persistAccessibilityPreferences);
  }

  Future<void> setReduceMotion(bool value) async {
    await _uiPreferencesFuture;
    if (_reduceMotion == value) return;
    _reduceMotion = value;
    notifyListeners();
    await _saveOrLoadPreference(_persistAccessibilityPreferences);
  }

  Future<void> resetAccessibilityPreferences() async {
    await _uiPreferencesFuture;
    _textScaleFactor = 1;
    _highContrast = false;
    _boldText = false;
    _reduceMotion = false;
    _alternativeColors = false;
    notifyListeners();
    await _saveOrLoadPreference(_persistAccessibilityPreferences);
  }

  Future<void> _saveOrLoadPreference(Future<void> Function() operation) async {
    try {
      await operation();
    } catch (error) {
      // An unavailable preferences plugin must not prevent startup or reading.
      AppLogger.warning(
        'Preferencias no disponibles',
        data: {'type': error.runtimeType.toString()},
        scope: 'preferences',
      );
    }
  }

  void setPendingReservationTarget(ReservationEntryTarget target) {
    _pendingReservationTarget = target;
    notifyListeners();
  }

  ReservationEntryTarget? consumePendingReservationTarget() {
    final target = _pendingReservationTarget;
    _pendingReservationTarget = null;
    notifyListeners();
    return target;
  }

  Future<void> initialize() async {
    await _uiPreferencesFuture;
    await _loadReadNotificationKeys();
    await Future.wait([loadAccessControl(), loadNotifications()]);
  }

  Future<void> _loadUiPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    _themeMode = prefs.getString(_themeModePreference) == 'dark'
        ? ThemeMode.dark
        : ThemeMode.light;
    _textScaleFactor = (prefs.getDouble(_textScalePreference) ?? 1)
        .clamp(1.0, 1.4)
        .toDouble();
    _highContrast = prefs.getBool(_highContrastPreference) ?? false;
    _boldText = prefs.getBool(_boldTextPreference) ?? false;
    _reduceMotion = prefs.getBool(_reduceMotionPreference) ?? false;
    _alternativeColors = prefs.getBool(_alternativeColorsPreference) ?? false;
    final language = prefs.getString(_localePreference);
    _locale = const {'es', 'en'}.contains(language) ? Locale(language!) : null;
    notifyListeners();
  }

  Future<void> _persistThemeMode() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _themeModePreference,
      _themeMode == ThemeMode.dark ? 'dark' : 'light',
    );
  }

  Future<void> _persistAccessibilityPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    await Future.wait([
      prefs.setDouble(_textScalePreference, _textScaleFactor),
      prefs.setBool(_highContrastPreference, _highContrast),
      prefs.setBool(_boldTextPreference, _boldText),
      prefs.setBool(_reduceMotionPreference, _reduceMotion),
      prefs.setBool(_alternativeColorsPreference, _alternativeColors),
    ]);
  }

  Future<void> _loadReadNotificationKeys() async {
    final prefs = await SharedPreferences.getInstance();
    _readNotificationKeys
      ..clear()
      ..addAll(
        prefs.getStringList(_readNotificationKeysPreference) ?? const [],
      );
  }

  Future<void> markNotificationRead(AppNotification notification) async {
    if (!notification.unread || notification.id <= 0) return;
    _readNotificationKeys.add(notification.storageKey);
    _notifications = _notifications
        .map(
          (item) => item.storageKey == notification.storageKey
              ? item.copyWith(unread: false)
              : item,
        )
        .toList(growable: false);
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    final stored = _readNotificationKeys.toList();
    if (stored.length > _maxStoredReadNotifications) {
      stored.removeRange(0, stored.length - _maxStoredReadNotifications);
      _readNotificationKeys
        ..clear()
        ..addAll(stored);
    }
    await prefs.setStringList(_readNotificationKeysPreference, stored);
  }

  AppNotification _notification({
    required int id,
    required String moduleKey,
    required String title,
    required String subtitle,
    required String level,
    required String createdAtLabel,
  }) {
    final key = '$moduleKey:$id';
    return AppNotification(
      id: id,
      title: title,
      subtitle: subtitle,
      level: level,
      createdAtLabel: createdAtLabel,
      moduleKey: moduleKey,
      unread: id > 0 && !_readNotificationKeys.contains(key),
    );
  }

  Future<void> loadAccessControl() async {
    _loadingAcl = true;
    notifyListeners();

    try {
      if (_odoo.isPortalSession) {
        final bootstrap = await _portalApi.bootstrap();
        final capabilities = bootstrap['capabilities'];
        final granted = <String>{'portal.view'};
        if (capabilities is Map) {
          for (final entry in capabilities.entries) {
            if (entry.value is Map && entry.value['view'] == true) {
              granted.add('${entry.key}.view');
            }
          }
        }
        _grantedPermissions
          ..clear()
          ..addAll(granted);
        _loadingAcl = false;
        notifyListeners();
        return;
      }
      final dynamic acl = await _odoo.callMethod(
        'calidad.security.service',
        'get_mobile_acl',
      );

      final granted = <String>{};
      if (acl is Map && acl['permissions'] is List) {
        for (final p in (acl['permissions'] as List)) {
          granted.add(p.toString());
        }
      }

      if (granted.isNotEmpty) {
        _grantedPermissions
          ..clear()
          ..addAll(granted);
      } else {
        _grantedPermissions.clear();
      }
    } catch (_) {
      _grantedPermissions.clear();
    }

    _loadingAcl = false;
    notifyListeners();
  }

  Future<void> loadNotifications() async {
    _loadingNotifications = true;
    notifyListeners();

    final items = <AppNotification>[];

    if (_odoo.isPortalSession) {
      for (final entry in const [
        ('incidents', 'Incidencia', 'incidents'),
        ('communications', 'Comunicación', 'communications'),
      ]) {
        try {
          final rows = await _portalApi.section(entry.$1, limit: 5);
          for (final row in rows) {
            items.add(
              _notification(
                id: OdooValues.intValue(row['id']) ?? 0,
                title: OdooValues.string(row['name'], fallback: entry.$2),
                subtitle: OdooValues.string(row['tipo'], fallback: entry.$2),
                level: entry.$3 == 'incidents' ? 'high' : 'medium',
                createdAtLabel: OdooValues.string(
                  row['fecha'],
                  fallback: 'Ahora',
                ),
                moduleKey: entry.$3,
              ),
            );
          }
        } catch (_) {
          // A section disabled by the portal capability simply has no feed.
        }
      }
      _notifications = items;
      _loadingNotifications = false;
      notifyListeners();
      return;
    }

    try {
      final incidentRows = await _odoo.searchRead(
        'calidad.incidencia',
        fields: ['name', 'tipo', 'fecha', 'estado'],
        order: 'id desc',
        limit: 5,
      );
      for (final row in incidentRows) {
        final m = Map<String, dynamic>.from(row as Map);
        items.add(
          _notification(
            id: OdooValues.intValue(m['id']) ?? 0,
            title: OdooValues.string(m['name'], fallback: 'Incidencia'),
            subtitle: OdooValues.string(
              m['tipo'],
              fallback: 'Nueva incidencia',
            ),
            level: 'high',
            createdAtLabel: OdooValues.string(m['fecha'], fallback: 'Ahora'),
            moduleKey: 'incidents',
          ),
        );
      }
    } catch (_) {}

    try {
      final commRows = await _odoo.searchRead(
        'calidad.comunicacion',
        fields: ['name', 'tipo', 'fecha', 'estado'],
        order: 'id desc',
        limit: 5,
      );
      for (final row in commRows) {
        final m = Map<String, dynamic>.from(row as Map);
        items.add(
          _notification(
            id: OdooValues.intValue(m['id']) ?? 0,
            title: OdooValues.string(m['name'], fallback: 'Comunicación'),
            subtitle: OdooValues.string(
              m['tipo'],
              fallback: 'Nueva comunicación',
            ),
            level: 'medium',
            createdAtLabel: OdooValues.string(m['fecha'], fallback: 'Ahora'),
            moduleKey: 'communications',
          ),
        );
      }
    } catch (_) {}

    _notifications = items;

    _loadingNotifications = false;
    notifyListeners();
  }
}
