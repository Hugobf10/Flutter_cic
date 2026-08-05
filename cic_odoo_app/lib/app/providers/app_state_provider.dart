import 'package:flutter/material.dart';

import '../../screens/reservas/reservation_entry_target.dart';
import '../../services/odoo_service.dart';
import '../../services/portal_api_service.dart';
import '../core/module_registry.dart';
import '../models/app_module.dart';
import '../models/app_notification.dart';

class AppStateProvider extends ChangeNotifier {
  final OdooService _odoo = OdooService();
  final PortalApiService _portalApi = PortalApiService();

  ThemeMode _themeMode = ThemeMode.light;
  bool _loadingAcl = false;
  bool _loadingNotifications = false;

  final Set<String> _grantedPermissions = <String>{};
  List<AppNotification> _notifications = const [];
  ReservationEntryTarget? _pendingReservationTarget;

  ThemeMode get themeMode => _themeMode;
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

  void toggleThemeMode() {
    _themeMode = _themeMode == ThemeMode.dark
        ? ThemeMode.light
        : ThemeMode.dark;
    notifyListeners();
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
    await Future.wait([loadAccessControl(), loadNotifications()]);
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
              AppNotification(
                id: (row['id'] as num?)?.toInt() ?? 0,
                title: row['name']?.toString() ?? entry.$2,
                subtitle: row['tipo']?.toString() ?? entry.$2,
                level: entry.$3 == 'incidents' ? 'high' : 'medium',
                createdAtLabel: row['fecha']?.toString() ?? 'Ahora',
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
          AppNotification(
            id: (m['id'] as num).toInt(),
            title: m['name']?.toString() ?? 'Incidencia',
            subtitle: m['tipo']?.toString() ?? 'Nueva incidencia',
            level: 'high',
            createdAtLabel: m['fecha']?.toString() ?? 'Ahora',
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
          AppNotification(
            id: (m['id'] as num).toInt(),
            title: m['name']?.toString() ?? 'Comunicación',
            subtitle: m['tipo']?.toString() ?? 'Nueva comunicación',
            level: 'medium',
            createdAtLabel: m['fecha']?.toString() ?? 'Ahora',
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
