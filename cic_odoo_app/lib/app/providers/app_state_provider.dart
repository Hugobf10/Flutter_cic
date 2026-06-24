import 'package:flutter/material.dart';

import '../../services/odoo_service.dart';
import '../core/module_registry.dart';
import '../models/app_module.dart';
import '../models/app_notification.dart';

class AppStateProvider extends ChangeNotifier {
  final OdooService _odoo = OdooService();

  ThemeMode _themeMode = ThemeMode.light;
  bool _loadingAcl = false;
  bool _loadingNotifications = false;

  final Set<String> _grantedPermissions = <String>{};
  List<AppNotification> _notifications = const [];

  ThemeMode get themeMode => _themeMode;
  bool get loadingAcl => _loadingAcl;
  bool get loadingNotifications => _loadingNotifications;
  List<AppNotification> get notifications => _notifications;
  int get unreadNotifications => _notifications.where((n) => n.unread).length;

  List<AppModule> get availableModules {
    return ModuleRegistry.all.where((m) {
      if (m.requiredPermission == null) return true;
      return _grantedPermissions.contains(m.requiredPermission);
    }).toList();
  }

  void toggleThemeMode() {
    _themeMode = _themeMode == ThemeMode.dark
        ? ThemeMode.light
        : ThemeMode.dark;
    notifyListeners();
  }

  Future<void> initialize() async {
    await Future.wait([loadAccessControl(), loadNotifications()]);
  }

  Future<void> loadAccessControl() async {
    _loadingAcl = true;
    notifyListeners();

    try {
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
