import 'package:flutter/widgets.dart';

import '../../l10n/strings.dart';
import '../models/app_module.dart';

extension LocalizedAppModule on AppModule {
  String localizedTitle(BuildContext context) {
    final t = context.l10n;
    return switch (key) {
      'incidents' => t.incidents,
      'training' => t.training,
      'documents' => context.uiText('Documentos', 'Documents'),
      'security' => t.security,
      'information' => t.informationDelivered,
      'payroll' => t.payroll,
      'recruitment' => t.recruitment,
      'reservas' => t.reservations,
      'planning' => t.planning,
      'health' => t.healthSurveillance,
      'normative' => t.normative,
      'equipment' => t.equipment,
      'publications' => t.publications,
      'permissions' => t.permissionsRoles,
      'communications' => t.communications,
      'suppliers' => t.suppliers,
      'organization' => t.organisation,
      'purchases' => t.purchases,
      'maintenance' => t.maintenance,
      _ => title,
    };
  }

  String? localizedDescription(BuildContext context) {
    final t = context.l10n;
    return switch (key) {
      'incidents' => t.moduleIncidentsDescription,
      'training' => t.moduleTrainingDescription,
      'documents' => t.moduleDocumentsDescription,
      'security' => t.moduleSecurityDescription,
      'information' => t.moduleInformationDescription,
      'payroll' => t.modulePayrollDescription,
      'recruitment' => t.moduleRecruitmentDescription,
      'reservas' => t.moduleReservationsDescription,
      'planning' => t.modulePlanningDescription,
      'health' => t.moduleHealthDescription,
      'normative' => t.moduleNormativeDescription,
      'equipment' => t.moduleEquipmentDescription,
      'publications' => t.modulePublicationsDescription,
      'permissions' => t.modulePermissionsDescription,
      'communications' => t.moduleCommunicationsDescription,
      'suppliers' => t.moduleSuppliersDescription,
      'organization' => t.moduleOrganisationDescription,
      'purchases' => t.modulePurchasesDescription,
      'maintenance' => t.moduleMaintenanceDescription,
      _ => description,
    };
  }
}
