import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../app/core/module_navigation.dart';
import '../../app/models/app_notification.dart';
import '../../app/providers/app_state_provider.dart';
import '../../app/screens/notifications_screen.dart';
import '../../app/ui/app_components.dart';
import '../../config/app_config.dart';
import '../../features/goals/goals_screen.dart';
import '../../features/payroll/payroll_screen.dart';
import '../../features/training/training_screen.dart';
import '../../providers/auth_provider.dart';
import '../../providers/dashboard_provider.dart';
import '../documentos/documentos_screen.dart';
import '../../theme/app_theme.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final dashboard = context.read<DashboardProvider>();
      dashboard.loadDashboard();
      dashboard.loadFilterOptions();
    });
  }

  Future<void> _onRefresh() async {
    await context.read<DashboardProvider>().loadDashboard();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final dashboard = context.watch<DashboardProvider>();
    final appState = context.watch<AppStateProvider>();

    return AppScaffold(
      title: 'Inicio',
      actions: [
        IconButton(
          onPressed: _onRefresh,
          icon: const Icon(Icons.refresh_rounded),
        ),
      ],
      child: RefreshIndicator(
        onRefresh: _onRefresh,
        child: ListView(
          children: [
            _Greeting(auth: auth),
            const SizedBox(height: 14),
            const AppSectionHeader(title: 'Accesos rápidos'),
            const _QuickActions(),
            const SizedBox(height: 16),
            if (dashboard.permissionDenied)
              _PortalBanner(onOpen: () => _openPortalIntranet(auth)),
            if (dashboard.state == DashboardState.loading &&
                dashboard.dashboardData == null)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 40),
                child: AppLoadingView(label: 'Cargando inicio...'),
              )
            else if (dashboard.state == DashboardState.error)
              AppEmptyState(
                title: 'No se pudo cargar el inicio',
                subtitle: dashboard.errorMessage ?? 'Error desconocido',
                icon: Icons.cloud_off_rounded,
                action: SizedBox(
                  width: 170,
                  child: AppButton.primary(
                    label: 'Reintentar',
                    icon: Icons.refresh_rounded,
                    onPressed: _onRefresh,
                  ),
                ),
              )
            else ...[
              const AppSectionHeader(
                title: 'Pendientes',
                subtitle: 'Lo más importante hoy',
              ),
              _PendingList(kpis: dashboard.kpis, auth: auth),
            ],
            const SizedBox(height: 14),
            AppSectionHeader(
              title: 'Actividad reciente',
              action: TextButton(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const NotificationsScreen(),
                  ),
                ),
                child: const Text('Ver todo'),
              ),
            ),
            _ActivityList(items: appState.notifications, auth: auth),
            const SizedBox(height: 90),
          ],
        ),
      ),
    );
  }

  Future<void> _openPortalIntranet(AuthProvider auth) async {
    final base =
        (auth.serverUrl.isNotEmpty ? auth.serverUrl : AppConfig.odooBaseUrl)
            .trim();
    final uri = Uri.parse('$base/my/calidad');
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}

class _Greeting extends StatelessWidget {
  const _Greeting({required this.auth});

  final AuthProvider auth;

  @override
  Widget build(BuildContext context) {
    final name = auth.userName.trim().isEmpty ? 'Usuario' : auth.userName;
    return AppCard(
      child: Row(
        children: [
          AppAvatar(name: name, size: 48),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Hola, ${name.split(' ').first}',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 2),
                Text(
                  auth.userLogin,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickActions extends StatelessWidget {
  const _QuickActions();

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final actions = <({String title, IconData icon, VoidCallback onTap})>[
      if (auth.canViewModule('documents'))
        (
          title: 'Documentos',
          icon: Icons.description_rounded,
          onTap: () => Navigator.of(
            context,
          ).push(MaterialPageRoute(builder: (_) => const DocumentosScreen())),
        ),
      if (auth.canViewModule('training'))
        (
          title: 'Formación',
          icon: Icons.school_rounded,
          onTap: () => Navigator.of(
            context,
          ).push(MaterialPageRoute(builder: (_) => const TrainingScreen())),
        ),
      if (auth.canViewModule('goals'))
        (
          title: 'Objetivos',
          icon: Icons.track_changes_rounded,
          onTap: () => Navigator.of(
            context,
          ).push(MaterialPageRoute(builder: (_) => const GoalsScreen())),
        ),
      if (auth.canViewModule('payroll'))
        (
          title: 'Nóminas',
          icon: Icons.receipt_long_rounded,
          onTap: () => Navigator.of(
            context,
          ).push(MaterialPageRoute(builder: (_) => const PayrollScreen())),
        ),
    ];

    if (actions.isEmpty) {
      return const AppEmptyState(
        title: 'Sin accesos rápidos',
        subtitle: 'No hay módulos destacados disponibles para este usuario.',
        icon: Icons.apps_outlined,
      );
    }

    return LayoutBuilder(
      builder: (context, c) {
        final cols = c.maxWidth < 560 ? 2 : 4;
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: actions.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: cols,
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            childAspectRatio: 2.2,
          ),
          itemBuilder: (_, i) {
            final a = actions[i];
            return AppListTile(
              onTap: a.onTap,
              leading: Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: AppTheme.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(a.icon, color: AppTheme.primary, size: 18),
              ),
              title: a.title,
              trailing: const Icon(
                Icons.chevron_right_rounded,
                size: 18,
                color: AppTheme.textMuted,
              ),
            );
          },
        );
      },
    );
  }
}

class _PendingList extends StatelessWidget {
  const _PendingList({required this.kpis, required this.auth});

  final List<dynamic> kpis;
  final AuthProvider auth;

  @override
  Widget build(BuildContext context) {
    if (kpis.isEmpty) {
      return const AppEmptyState(
        title: 'Sin pendientes',
        subtitle: 'No hay tareas críticas en este momento.',
        icon: Icons.task_alt_rounded,
      );
    }

    final top = kpis
        .take(4)
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();
    return Column(
      children: top.map((kpi) {
        final value = (kpi['value'] ?? 0).toString();
        final title = (kpi['title'] ?? 'Indicador').toString();
        final helper = (kpi['helper'] ?? '').toString();
        final moduleKey = ModuleNavigation.inferModuleKeyFromKpi(kpi);
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: AppListTile(
            onTap: moduleKey == null
                ? null
                : () => ModuleNavigation.openModule(
                    context,
                    auth: auth,
                    moduleKey: moduleKey,
                  ),
            title: title,
            subtitle: helper.isEmpty ? 'Pendiente' : helper,
            leading: Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: AppTheme.primaryLight,
                borderRadius: AppTheme.radiusSm,
              ),
              child: const Icon(
                Icons.analytics_rounded,
                size: 16,
                color: AppTheme.primary,
              ),
            ),
            trailing: Text(
              value,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppTheme.textPrimary,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _ActivityList extends StatelessWidget {
  const _ActivityList({required this.items, required this.auth});

  final List<AppNotification> items;
  final AuthProvider auth;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const AppEmptyState(
        title: 'Sin actividad reciente',
        subtitle: 'Cuando haya novedades aparecerán aquí.',
        icon: Icons.notifications_none_rounded,
      );
    }

    final top = items.take(4).toList();
    return Column(
      children: top.map((n) {
        final color = n.level == 'high'
            ? AppTheme.error
            : n.level == 'medium'
            ? AppTheme.warning
            : AppTheme.primary;
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: AppListTile(
            onTap: () => ModuleNavigation.openModule(
              context,
              auth: auth,
              moduleKey: n.moduleKey,
            ),
            leading: Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            title: n.title,
            subtitle: '${n.subtitle} · ${n.createdAtLabel}',
          ),
        );
      }).toList(),
    );
  }
}

class _PortalBanner extends StatelessWidget {
  const _PortalBanner({required this.onOpen});

  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: AppCard(
        child: Row(
          children: [
            const Icon(
              Icons.info_outline_rounded,
              size: 18,
              color: AppTheme.primary,
            ),
            const SizedBox(width: 8),
            const Expanded(
              child: Text(
                'Vista intranet portal activa. Algunas métricas globales requieren permisos de gestión.',
                style: TextStyle(color: AppTheme.textSecondary, fontSize: 12),
              ),
            ),
            TextButton(onPressed: onOpen, child: const Text('Abrir')),
          ],
        ),
      ),
    );
  }
}
