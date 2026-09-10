import 'package:flutter/material.dart';

import '../../l10n/strings.dart';
import '../../providers/auth_provider.dart';
import 'module_router.dart';

class ModuleNavigation {
  ModuleNavigation._();

  static void openModule(
    BuildContext context, {
    required AuthProvider auth,
    required String moduleKey,
    String? title,
  }) {
    if (!auth.canViewModule(moduleKey)) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ModuleRouter.build(
          moduleKey,
          title ?? _defaultTitle(context, moduleKey),
        ),
      ),
    );
  }

  static String? inferModuleKeyFromKpi(Map<String, dynamic> kpi) {
    final explicit = kpi['module_key']?.toString().trim();
    if (explicit != null && explicit.isNotEmpty) {
      return explicit;
    }

    final haystack = [
      kpi['title']?.toString(),
      kpi['helper']?.toString(),
      kpi['subtitle']?.toString(),
      kpi['label']?.toString(),
    ].whereType<String>().join(' ').toLowerCase();

    if (haystack.contains('inciden')) return 'incidents';
    if (haystack.contains('document')) return 'documents';
    if (haystack.contains('comunica')) return 'communications';
    if (haystack.contains('proveedor')) return 'suppliers';
    if (haystack.contains('formaci')) return 'training';
    if (haystack.contains('objetiv')) return 'planning';
    if (haystack.contains('plan de acci') || haystack.contains('action plan')) {
      return 'planning';
    }
    if (haystack.contains('plan')) return 'planning';
    if (haystack.contains('reserva')) return 'reservas';
    if (haystack.contains('nómina') || haystack.contains('nomina')) {
      return 'payroll';
    }
    if (haystack.contains('salud')) return 'health';
    if (haystack.contains('equipo')) return 'equipment';
    if (haystack.contains('químic') || haystack.contains('quimic')) {
      return 'planning';
    }
    return null;
  }

  static String _defaultTitle(BuildContext context, String moduleKey) {
    switch (moduleKey) {
      case 'dashboard':
        return context.l10n.home;
      case 'incidents':
        return context.l10n.incidents;
      case 'documents':
        return context.uiText('Documentos', 'Documents');
      case 'communications':
        return context.l10n.communications;
      case 'suppliers':
        return context.uiText('Proveedores', 'Suppliers');
      case 'training':
      case 'elearning':
        return context.l10n.training;
      case 'goals':
        return context.uiText('Objetivos', 'Goals');
      case 'planning':
        return context.uiText('Planificación', 'Planning');
      case 'reservas':
        return context.l10n.reservations;
      case 'payroll':
        return context.l10n.payroll;
      case 'health':
        return context.uiText('Vigilancia de la salud', 'Health surveillance');
      case 'portal':
        return context.l10n.home;
      case 'maintenance':
        return context.uiText('Mantenimiento', 'Maintenance');
      default:
        return moduleKey;
    }
  }
}
