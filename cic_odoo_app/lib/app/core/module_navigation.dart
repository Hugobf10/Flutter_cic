import 'package:flutter/material.dart';

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
        builder: (_) =>
            ModuleRouter.build(moduleKey, title ?? _defaultTitle(moduleKey)),
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

  static String _defaultTitle(String moduleKey) {
    switch (moduleKey) {
      case 'dashboard':
        return 'Inicio';
      case 'incidents':
        return 'Incidencias';
      case 'documents':
        return 'Documentos';
      case 'communications':
        return 'Comunicaciones';
      case 'suppliers':
        return 'Proveedores';
      case 'training':
      case 'elearning':
        return 'Formación';
      case 'goals':
        return 'Objetivos';
      case 'planning':
        return 'Planificación';
      case 'reservas':
        return 'Reservas';
      case 'payroll':
        return 'Nóminas';
      case 'health':
        return 'Vigilancia de la salud';
      case 'portal':
        return 'Portal';
      case 'maintenance':
        return 'Mantenimiento';
      default:
        return moduleKey;
    }
  }
}
