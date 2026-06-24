import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app/screens/profile_screen.dart';
import '../../app/ui/app_components.dart';
import '../../providers/auth_provider.dart';
import '../../services/odoo_service.dart';
import '../../theme/app_theme.dart';
import '../action_plans/action_plans_screen.dart';
import '../goals/goals_screen.dart';
import '../payroll/payroll_screen.dart';
import '../../app/core/module_navigation.dart';

class PortalScreen extends StatefulWidget {
  const PortalScreen({super.key});

  @override
  State<PortalScreen> createState() => _PortalScreenState();
}

class _PortalScreenState extends State<PortalScreen> {
  final OdooService _odoo = OdooService();

  bool _loading = true;
  String? _error;
  Map<String, dynamic> _partner = const {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final auth = context.read<AuthProvider>();
    if (auth.partnerId <= 0) {
      setState(() {
        _loading = false;
        _error = 'No se pudo localizar el perfil del usuario actual.';
      });
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      _partner = await _odoo.read(
        'res.partner',
        auth.partnerId,
        fields: const [
          'name',
          'email',
          'phone',
          'mobile',
          'function',
          'unidad_id',
          'acceso_intranet',
          'acceso_calidad',
          'portal_calidad_habilitado',
          'permiso_incidencias_ver',
          'permiso_incidencias_editar',
          'permiso_documentos_ver',
          'permiso_documentos_editar',
          'permiso_formacion_ver',
          'permiso_formacion_editar',
          'permiso_objetivos_ver',
          'permiso_objetivos_editar',
          'permiso_salud_ver',
          'permiso_salud_editar',
          'permiso_comunicaciones_ver',
          'permiso_comunicaciones_editar',
          'permiso_proveedores_ver',
          'permiso_proveedores_editar',
          'permiso_normativa_ver',
          'permiso_normativa_editar',
          'permiso_equipos_ver',
          'permiso_equipos_editar',
          'permiso_quimicos_ver',
          'permiso_quimicos_editar',
        ],
      );
    } catch (e) {
      _error = OdooService.prettyError(e);
    }

    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final actions = _buildActions(auth);
    final permissionRows = _buildPermissionRows(auth);

    return AppScaffold(
      title: 'Portal',
      actions: [
        IconButton(onPressed: _load, icon: const Icon(Icons.refresh_rounded)),
      ],
      child: _loading
          ? const AppLoadingView(label: 'Cargando portal...')
          : _error != null
              ? AppEmptyState(
                  title: 'No se pudo cargar el portal',
                  subtitle: _error!,
                  icon: Icons.error_outline_rounded,
                  action: AppButton.primary(
                    label: 'Reintentar',
                    onPressed: _load,
                  ),
                )
              : ListView(
                  children: [
                    _PortalHero(partner: _partner, auth: auth),
                    const SizedBox(height: 20),
                    AppSectionHeader(
                      title: 'Accesos rápidos',
                      subtitle:
                          'Atajos disponibles según los permisos reales del usuario en Odoo.',
                    ),
                    if (actions.isEmpty)
                      const AppEmptyState(
                        title: 'Sin accesos disponibles',
                        subtitle:
                            'Este usuario no tiene secciones de portal habilitadas en este momento.',
                        icon: Icons.lock_outline_rounded,
                      )
                    else
                      LayoutBuilder(
                        builder: (context, constraints) {
                          final width = constraints.maxWidth;
                          final columns = width >= 980
                              ? 3
                              : width >= 680
                                  ? 2
                                  : 1;
                          final spacing = 12.0;
                          final itemWidth =
                              (width - spacing * (columns - 1)) / columns;

                          return Wrap(
                            spacing: spacing,
                            runSpacing: spacing,
                            children: actions
                                .map(
                                  (action) => SizedBox(
                                    width: itemWidth,
                                    child: _PortalActionCard(action: action),
                                  ),
                                )
                                .toList(),
                          );
                        },
                      ),
                    const SizedBox(height: 20),
                    AppSectionHeader(
                      title: 'Permisos activos',
                      subtitle:
                          'Resumen del acceso efectivo del usuario portal en la aplicación.',
                    ),
                    ...permissionRows.map(
                      (row) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: _PortalPermissionCard(row: row),
                      ),
                    ),
                  ],
                ),
    );
  }

  List<_PortalAction> _buildActions(AuthProvider auth) {
    final actions = <_PortalAction>[
      _PortalAction(
        title: 'Mi perfil',
        subtitle: 'Consulta y actualiza tus datos personales.',
        icon: Icons.account_circle_outlined,
        color: AppTheme.primary,
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const ProfileScreen()),
          );
        },
      ),
      if (auth.canViewModule('payroll'))
        _PortalAction(
          title: 'Nóminas',
          subtitle: 'Documentos salariales publicados en el portal.',
          icon: Icons.receipt_long_rounded,
          color: AppTheme.success,
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const PayrollScreen()),
            );
          },
        ),
      if (auth.canViewModule('reservas'))
        _moduleAction(
          auth: auth,
          moduleKey: 'reservas',
          title: 'Reservas',
          subtitle: 'Consulta y gestiona tus reservas disponibles.',
          icon: Icons.calendar_month_rounded,
          color: AppTheme.accent,
        ),
      if (auth.canViewModule('training'))
        _moduleAction(
          auth: auth,
          moduleKey: 'training',
          title: 'Formación',
          subtitle: 'Historial y registro de formación del usuario.',
          icon: Icons.school_rounded,
          color: AppTheme.info,
        ),
      if (auth.canViewModule('suggestions'))
        _moduleAction(
          auth: auth,
          moduleKey: 'suggestions',
          title: 'Sugerencias',
          subtitle: 'Envía propuestas y sigue su estado.',
          icon: Icons.lightbulb_outline_rounded,
          color: AppTheme.warning,
        ),
      if (auth.canViewModule('incidents'))
        _moduleAction(
          auth: auth,
          moduleKey: 'incidents',
          title: 'Incidencias',
          subtitle: 'No conformidades y acciones correctivas.',
          icon: Icons.warning_amber_rounded,
          color: AppTheme.danger,
        ),
      if (auth.canViewModule('documents'))
        _moduleAction(
          auth: auth,
          moduleKey: 'documents',
          title: 'Documentos',
          subtitle: 'Documentación y registros disponibles.',
          icon: Icons.description_outlined,
          color: AppTheme.primary,
        ),
      if (auth.canViewModule('goals'))
        _PortalAction(
          title: 'Objetivos',
          subtitle: 'Seguimiento de objetivos personales o asignados.',
          icon: Icons.flag_outlined,
          color: AppTheme.success,
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const GoalsScreen()),
            );
          },
        ),
      if (auth.canViewModule('action_plans'))
        _PortalAction(
          title: 'Planes de acción',
          subtitle: 'Acciones ligadas a objetivos e incidencias.',
          icon: Icons.task_alt_rounded,
          color: AppTheme.warning,
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const ActionPlansScreen()),
            );
          },
        ),
      if (auth.canViewModule('communications'))
        _moduleAction(
          auth: auth,
          moduleKey: 'communications',
          title: 'Comunicaciones',
          subtitle: 'Comunicados y actividad compartida.',
          icon: Icons.campaign_outlined,
          color: AppTheme.info,
        ),
      if (auth.canViewModule('suppliers'))
        _moduleAction(
          auth: auth,
          moduleKey: 'suppliers',
          title: 'Proveedores',
          subtitle: 'Consulta de proveedores homologados.',
          icon: Icons.local_shipping_outlined,
          color: AppTheme.warning,
        ),
      if (auth.canViewModule('health'))
        _moduleAction(
          auth: auth,
          moduleKey: 'health',
          title: 'Salud',
          subtitle: 'Reconocimientos y vigilancia de la salud.',
          icon: Icons.monitor_heart_outlined,
          color: AppTheme.accent,
        ),
      if (auth.canViewModule('normative'))
        _moduleAction(
          auth: auth,
          moduleKey: 'normative',
          title: 'Normativa',
          subtitle: 'Normas, revisiones y requisitos aplicables.',
          icon: Icons.gavel_rounded,
          color: AppTheme.primary,
        ),
      if (auth.canViewModule('equipment'))
        _moduleAction(
          auth: auth,
          moduleKey: 'equipment',
          title: 'Equipos',
          subtitle: 'Inventario y estado de equipos relacionados.',
          icon: Icons.precision_manufacturing_rounded,
          color: AppTheme.warning,
        ),
      if (auth.canViewModule('chemicals'))
        _moduleAction(
          auth: auth,
          moduleKey: 'chemicals',
          title: 'Químicos',
          subtitle: 'Productos, fichas y caducidades visibles.',
          icon: Icons.science_outlined,
          color: AppTheme.success,
        ),
    ];

    return actions;
  }

  _PortalAction _moduleAction({
    required AuthProvider auth,
    required String moduleKey,
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
  }) {
    return _PortalAction(
      title: title,
      subtitle: subtitle,
      icon: icon,
      color: color,
      onTap: () => ModuleNavigation.openModule(
        context,
        auth: auth,
        moduleKey: moduleKey,
        title: title,
      ),
    );
  }

  List<_PortalPermissionRow> _buildPermissionRows(AuthProvider auth) {
    return [
      _PortalPermissionRow(
        title: 'Acceso general',
        subtitle: auth.isPortalUser
            ? 'Perfil portal autenticado en la aplicación.'
            : 'Perfil interno con acceso a los flujos de portal.',
        canView: auth.hasAppAccess,
        canEdit: auth.isInternalUser,
      ),
      _PortalPermissionRow(
        title: 'Sugerencias y formación personal',
        subtitle:
            'Autoservicio disponible para perfiles portal según la documentación de Odoo.',
        canView: auth.canViewModule('suggestions') || auth.canViewModule('training'),
        canEdit: auth.canEditModule('suggestions') || auth.canEditModule('training'),
      ),
      _PortalPermissionRow(
        title: 'Objetivos y planes',
        subtitle: 'Control del trabajo asignado y acciones derivadas.',
        canView: auth.canViewModule('goals') || auth.canViewModule('action_plans'),
        canEdit: auth.canEditModule('goals') || auth.canEditModule('action_plans'),
      ),
      _PortalPermissionRow(
        title: 'Incidencias y documentación',
        subtitle: 'Secciones gobernadas por permisos específicos del partner.',
        canView: auth.canViewModule('incidents') || auth.canViewModule('documents'),
        canEdit: auth.canEditModule('incidents') || auth.canEditModule('documents'),
      ),
      _PortalPermissionRow(
        title: 'Activos y cumplimiento',
        subtitle: 'Equipos, químicos, salud, normativa y proveedores.',
        canView: auth.canViewModule('equipment') ||
            auth.canViewModule('chemicals') ||
            auth.canViewModule('health') ||
            auth.canViewModule('normative') ||
            auth.canViewModule('suppliers'),
        canEdit: auth.canEditModule('equipment') ||
            auth.canEditModule('chemicals') ||
            auth.canEditModule('health') ||
            auth.canEditModule('normative') ||
            auth.canEditModule('suppliers'),
      ),
    ];
  }
}

class _PortalHero extends StatelessWidget {
  const _PortalHero({
    required this.partner,
    required this.auth,
  });

  final Map<String, dynamic> partner;
  final AuthProvider auth;

  @override
  Widget build(BuildContext context) {
    final name = (partner['name'] ?? auth.userName).toString();
    final email = (partner['email'] ?? auth.userLogin).toString();
    final unidad = partner['unidad_id'] is List
        ? partner['unidad_id'][1].toString()
        : auth.unidadNombre;

    return AppCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppAvatar(name: name, size: 54),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name.isEmpty ? 'Usuario' : name,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      email,
                      style: const TextStyle(color: AppTheme.textSecondary),
                    ),
                    if (unidad.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        'Unidad: $unidad',
                        style: const TextStyle(color: AppTheme.textMuted),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              AppStatusChip(
                label: auth.isPortalUser ? 'Usuario portal' : 'Usuario interno',
                color: auth.isPortalUser ? AppTheme.accent : AppTheme.primary,
              ),
              AppStatusChip(
                label: auth.hasAppAccess ? 'Acceso app activo' : 'Sin acceso',
                color: auth.hasAppAccess ? AppTheme.success : AppTheme.danger,
              ),
              AppStatusChip(
                label: auth.portalCalidadHabilitado
                    ? 'Portal habilitado'
                    : 'Portal deshabilitado',
                color: auth.portalCalidadHabilitado
                    ? AppTheme.success
                    : AppTheme.warning,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PortalActionCard extends StatelessWidget {
  const _PortalActionCard({required this.action});

  final _PortalAction action;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: action.onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: action.color.withValues(alpha: 0.12),
              borderRadius: AppTheme.radiusSm,
            ),
            child: Icon(action.icon, color: action.color),
          ),
          const SizedBox(height: 12),
          Text(
            action.title,
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            action.subtitle,
            style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _PortalPermissionCard extends StatelessWidget {
  const _PortalPermissionCard({required this.row});

  final _PortalPermissionRow row;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  row.title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  row.subtitle,
                  style: const TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              AppStatusChip(
                label: row.canView ? 'Ver' : 'Sin vista',
                color: row.canView ? AppTheme.success : AppTheme.textMuted,
              ),
              const SizedBox(height: 8),
              AppStatusChip(
                label: row.canEdit ? 'Editar' : 'Solo lectura',
                color: row.canEdit ? AppTheme.info : AppTheme.textMuted,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PortalAction {
  const _PortalAction({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
}

class _PortalPermissionRow {
  const _PortalPermissionRow({
    required this.title,
    required this.subtitle,
    required this.canView,
    required this.canEdit,
  });

  final String title;
  final String subtitle;
  final bool canView;
  final bool canEdit;
}
