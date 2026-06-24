import 'package:flutter/material.dart';

import '../../features/module_placeholders/module_placeholder_screen.dart';
import '../../features/maintenance/maintenance_screen.dart';
import '../../features/planning/planning_screen.dart';
import '../../features/chemicals/chemicals_screen.dart';
import '../../features/communications/communications_screen.dart';
import '../../features/equipment/equipment_screen.dart';
import '../../features/health/health_screen.dart';
import '../../features/normativa/normativa_screen.dart';
import '../../features/payroll/payroll_screen.dart';
import '../../features/permissions/permissions_center_screen.dart';
import '../../features/portal/portal_screen.dart';
import '../../features/purchases/purchases_screen.dart';
import '../../features/suggestions/suggestions_screen.dart';
import '../../features/suppliers/suppliers_screen.dart';
import '../../features/training/training_screen.dart';
import '../../features/quality/quality_center_screen.dart';
import '../../features/recruitment/recruitment_screen.dart';
import '../../features/goals/goals_screen.dart';
import '../../screens/documentos/documentos_screen.dart';
import '../../screens/home/home_screen.dart';
import '../../screens/incidencias/incidencias_screen.dart';
import '../../screens/reservas/reservas_screen.dart';

class ModuleRouter {
  static Widget build(String moduleKey, String title) {
    switch (moduleKey) {
      case 'dashboard':
        return const HomeScreen();
      case 'incidents':
        return const IncidenciasScreen();
      case 'documents':
        return const DocumentosScreen();
      case 'quality':
        return const QualityCenterScreen();
      case 'training':
      case 'elearning':
        return const TrainingScreen();
      case 'planning':
        return const PlanningScreen();
      case 'reservas':
        return const ReservasScreen();
      case 'goals':
        return const GoalsScreen();
      case 'payroll':
        return const PayrollScreen();
      case 'health':
        return const HealthScreen();
      case 'normative':
        return const NormativaScreen();
      case 'equipment':
        return const EquipmentScreen();
      case 'chemicals':
        return const ChemicalsScreen();
      case 'suggestions':
        return const SuggestionsScreen();
      case 'permissions':
      case 'roles':
      case 'users':
        return const PermissionsCenterScreen();
      case 'communications':
        return const CommunicationsScreen();
      case 'suppliers':
        return const SuppliersScreen();
      case 'maintenance':
        return const MaintenanceScreen();
      case 'portal':
        return const PortalScreen();
      case 'organization':
        return ModulePlaceholderScreen(title: title);
      case 'purchases':
        return const PurchasesScreen();
      case 'recruitment':
        return const RecruitmentScreen();
      default:
        return ModulePlaceholderScreen(title: title);
    }
  }
}
