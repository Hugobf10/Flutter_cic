import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app/screens/profile_screen.dart';
import '../../app/ui/app_components.dart';
import '../../providers/auth_provider.dart';
import '../../services/odoo_values.dart';
import '../../services/odoo_service.dart';
import '../../services/portal_api_service.dart';
import '../../theme/app_motion.dart';
import '../../theme/app_theme.dart';
import '../payroll/payroll_screen.dart';
import '../../app/core/module_navigation.dart';

class PortalScreen extends StatefulWidget {
  const PortalScreen({super.key});

  @override
  State<PortalScreen> createState() => _PortalScreenState();
}

class _PortalScreenState extends State<PortalScreen> {
  final PortalApiService _portalApi = PortalApiService();

  bool _loading = true;
  String? _error;
  Map<String, dynamic> _partner = const {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final bootstrap = await _portalApi.bootstrap();
      _partner = OdooValues.map(bootstrap['partner']);
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
      title: 'Mi espacio',
      actions: [
        IconButton(onPressed: _load, icon: Icon(Icons.refresh_rounded)),
      ],
      child: _loading
          ? const AppLoadingView(label: 'Cargando portal...')
          : _error != null
          ? AppEmptyState(
              title: 'No se pudo cargar el portal',
              subtitle: _error!,
              icon: Icons.error_outline_rounded,
              action: AppButton.primary(label: 'Reintentar', onPressed: _load),
            )
          : ListView(
              children: [
                AppReveal(
                  child: _PortalHero(partner: _partner, auth: auth),
                ),
                const SizedBox(height: 20),
                AppSectionHeader(
                  title: 'Servicios disponibles',
                  subtitle:
                      'Tu espacio de autoservicio, adaptado a tus permisos.',
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
                          ? 4
                          : width >= 660
                          ? 3
                          : 2;

                      return GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: actions.length,
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: columns,
                          mainAxisSpacing: 10,
                          crossAxisSpacing: 10,
                          childAspectRatio: width < 660 ? 1.65 : 1.5,
                        ),
                        itemBuilder: (_, index) => AppReveal(
                          delay: Duration(
                            milliseconds:
                                AppMotion.stagger.inMilliseconds * index,
                          ),
                          child: _PortalActionCard(action: actions[index]),
                        ),
                      );
                    },
                  ),
                const SizedBox(height: 20),
                AppSectionHeader(
                  title: 'Permisos activos',
                  subtitle:
                      'Resumen del acceso efectivo del usuario portal en la aplicación.',
                ),
                ...permissionRows.indexed.map(
                  (entry) => AppReveal(
                    delay: Duration(
                      milliseconds: AppMotion.stagger.inMilliseconds * entry.$1,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _PortalPermissionCard(row: entry.$2),
                    ),
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
          Navigator.of(
            context,
          ).push(MaterialPageRoute(builder: (_) => const ProfileScreen()));
        },
      ),
      if (auth.canViewModule('payroll'))
        _PortalAction(
          title: 'Nóminas',
          subtitle: 'Documentos salariales publicados en el portal.',
          icon: Icons.receipt_long_rounded,
          color: AppTheme.success,
          onTap: () {
            Navigator.of(
              context,
            ).push(MaterialPageRoute(builder: (_) => const PayrollScreen()));
          },
        ),
      if (auth.canViewModule('security'))
        _moduleAction(
          auth: auth,
          moduleKey: 'security',
          title: 'Seguridad',
          subtitle: 'Consulta tus permisos efectivos en la intranet.',
          icon: Icons.shield_outlined,
          color: AppTheme.success,
        ),
      if (auth.canViewModule('information'))
        _moduleAction(
          auth: auth,
          moduleKey: 'information',
          title: 'Información entregada',
          subtitle: 'Documentos y registros entregados a tu cuenta.',
          icon: Icons.inventory_2_outlined,
          color: AppTheme.info,
        ),
      if (auth.canViewModule('publications'))
        _moduleAction(
          auth: auth,
          moduleKey: 'publications',
          title: 'Publicaciones',
          subtitle: 'Tus publicaciones y las funciones habilitadas.',
          icon: Icons.article_outlined,
          color: AppTheme.primary,
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
      if (auth.canViewModule('communications'))
        _moduleAction(
          auth: auth,
          moduleKey: 'communications',
          title: 'Comunicaciones',
          subtitle: 'Comunicados, sugerencias y actividad compartida.',
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
      if (auth.canViewModule('planning'))
        _moduleAction(
          auth: auth,
          moduleKey: 'planning',
          title: 'Planificación',
          subtitle: 'Objetivos, planes de acción, químicos e informe.',
          icon: Icons.event_note_rounded,
          color: AppTheme.accent,
        ),
      if (auth.isInternalUser && auth.canViewModule('purchases'))
        _moduleAction(
          auth: auth,
          moduleKey: 'purchases',
          title: 'Compras',
          subtitle: 'Pedidos y operaciones internas autorizadas.',
          icon: Icons.shopping_cart_checkout_rounded,
          color: AppTheme.info,
        ),
      if (auth.canViewModule('maintenance'))
        _moduleAction(
          auth: auth,
          moduleKey: 'maintenance',
          title: 'Mantenimiento',
          subtitle: 'Solicitudes y equipos visibles para tu unidad.',
          icon: Icons.build_circle_outlined,
          color: AppTheme.warning,
        ),
      if (auth.canViewModule('recruitment'))
        _moduleAction(
          auth: auth,
          moduleKey: 'recruitment',
          title: 'Oportunidades',
          subtitle: 'Procesos de selección disponibles para tu perfil.',
          icon: Icons.person_search_rounded,
          color: AppTheme.primary,
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
        title: 'Comunicaciones y formación personal',
        subtitle:
            'Autoservicio disponible para perfiles portal según la documentación de Odoo.',
        canView:
            auth.canViewModule('communications') ||
            auth.canViewModule('training'),
        canEdit:
            auth.canEditModule('communications') ||
            auth.canEditModule('training'),
      ),
      _PortalPermissionRow(
        title: 'Objetivos y planes',
        subtitle: 'Control del trabajo asignado y acciones derivadas.',
        canView:
            auth.canViewModule('goals') || auth.canViewModule('action_plans'),
        canEdit:
            auth.canEditModule('goals') || auth.canEditModule('action_plans'),
      ),
      _PortalPermissionRow(
        title: 'Incidencias y documentación',
        subtitle: 'Secciones gobernadas por permisos específicos del partner.',
        canView:
            auth.canViewModule('incidents') || auth.canViewModule('documents'),
        canEdit:
            auth.canEditModule('incidents') || auth.canEditModule('documents'),
      ),
      _PortalPermissionRow(
        title: 'Activos y cumplimiento',
        subtitle: 'Equipos, químicos, salud, normativa y proveedores.',
        canView:
            auth.canViewModule('equipment') ||
            auth.canViewModule('chemicals') ||
            auth.canViewModule('health') ||
            auth.canViewModule('normative') ||
            auth.canViewModule('suppliers'),
        canEdit:
            auth.canEditModule('equipment') ||
            auth.canEditModule('chemicals') ||
            auth.canEditModule('health') ||
            auth.canEditModule('normative') ||
            auth.canEditModule('suppliers'),
      ),
    ];
  }
}

class _PortalHero extends StatelessWidget {
  const _PortalHero({required this.partner, required this.auth});

  final Map<String, dynamic> partner;
  final AuthProvider auth;

  @override
  Widget build(BuildContext context) {
    final name = (partner['name'] ?? auth.userName).toString();
    final email = (partner['email'] ?? auth.userLogin).toString();
    final unidad = OdooValues.many2oneLabel(
      partner['unidad_id'],
      fallback: auth.unidadNombre,
    );

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
                      style: TextStyle(
                        color: AppTheme.textSecondaryFor(context),
                      ),
                    ),
                    if (unidad.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        'Unidad: $unidad',
                        style: TextStyle(color: AppTheme.textMutedFor(context)),
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
    return Semantics(
      button: true,
      label: '${action.title}. ${action.subtitle}',
      child: AppCard(
        onTap: action.onTap,
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            NeumorphicSurface(
              padding: const EdgeInsets.all(9),
              borderRadius: BorderRadius.circular(14),
              subtle: true,
              child: Icon(action.icon, color: action.color, size: 21),
            ),
            const SizedBox(width: 11),
            Expanded(
              child: Text(
                action.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimaryFor(context),
                ),
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              size: 19,
              color: AppTheme.textMutedFor(context),
            ),
          ],
        ),
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
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimaryFor(context),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  row.subtitle,
                  style: TextStyle(
                    color: AppTheme.textSecondaryFor(context),
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
                color: row.canView
                    ? AppTheme.success
                    : AppTheme.textMutedFor(context),
              ),
              const SizedBox(height: 8),
              AppStatusChip(
                label: row.canEdit ? 'Editar' : 'Solo lectura',
                color: row.canEdit
                    ? AppTheme.info
                    : AppTheme.textMutedFor(context),
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
