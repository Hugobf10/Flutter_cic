import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../app/models/app_notification.dart';
import '../../app/providers/app_state_provider.dart';
import '../../app/screens/notifications_screen.dart';
import '../../config/app_config.dart';
import '../../providers/auth_provider.dart';
import '../../providers/dashboard_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/kpi_card.dart';
import '../../widgets/alert_banner.dart';
import '../../widgets/section_header.dart';
import '../../widgets/shimmer_loading.dart';

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

  String _getInitials(String name) {
    if (name.isEmpty) return '?';
    final parts = name.trim().split(' ');
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    return parts[0][0].toUpperCase();
  }

  IconData _mapKpiIcon(String key) {
    const map = {
      'accidentes': Icons.warning_rounded,
      'incidencias_abiertas': Icons.report_problem_rounded,
      'acciones_correctivas': Icons.build_rounded,
      'objetivos_activos': Icons.track_changes_rounded,
      'formaciones_pendientes': Icons.school_rounded,
      'documentos_revision': Icons.description_rounded,
      'proveedores_homologacion': Icons.local_shipping_rounded,
      'equipos_mantenimiento': Icons.settings_rounded,
      'quimicos_activos': Icons.science_rounded,
      'normativa_pendiente': Icons.gavel_rounded,
      'salud_pendiente': Icons.favorite_rounded,
    };
    return map[key] ?? Icons.analytics_rounded;
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final dashboard = context.watch<DashboardProvider>();
    final appState = context.watch<AppStateProvider>();

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _onRefresh,
        color: AppTheme.primary,
        backgroundColor: AppTheme.surfaceCard,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
          slivers: [
            _buildAppBar(auth),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1320),
                    child: _buildBody(dashboard, auth, appState),
                  ),
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 100)),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar(AuthProvider auth) {
    return SliverAppBar(
      expandedHeight: 160,
      floating: false,
      pinned: true,
      backgroundColor: AppTheme.surface,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: const BoxDecoration(gradient: AppTheme.heroGradient),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 44, height: 44,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: AppTheme.radiusMd,
                        ),
                        child: Center(
                          child: Text(_getInitials(auth.userName),
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 16)),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('¡Hola, ${auth.userName.split(' ').first}!',
                                style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700)),
                            Text(auth.userLogin,
                                style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 12)),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.refresh_rounded, color: Colors.white.withValues(alpha: 0.8)),
                        onPressed: _onRefresh,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.12),
                      borderRadius: AppTheme.radiusMd,
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.dashboard_rounded, color: Colors.white70, size: 18),
                        const SizedBox(width: 8),
                        const Text('Dashboard Ejecutivo',
                            style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppTheme.success.withValues(alpha: 0.25),
                            borderRadius: AppTheme.radiusXl,
                          ),
                          child: const Text('En línea',
                              style: TextStyle(color: AppTheme.success, fontSize: 10, fontWeight: FontWeight.w700)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBody(DashboardProvider dashboard, AuthProvider auth, AppStateProvider appState) {
    if (dashboard.state == DashboardState.loading && dashboard.dashboardData == null) {
      return const Padding(padding: EdgeInsets.only(top: 20), child: ShimmerList(count: 6, itemHeight: 100));
    }
    if (dashboard.state == DashboardState.error) {
      return _buildError(dashboard);
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (dashboard.permissionDenied) ...[
          _buildPortalModeBanner(auth),
          const SizedBox(height: 8),
        ],
        if (dashboard.alerts.isNotEmpty) ...[
          const SectionHeader(title: 'Alertas activas', icon: Icons.notification_important_rounded),
          ...dashboard.alerts.take(3).map((a) {
              final alert = Map<String, dynamic>.from(a as Map);
              return AlertBanner(
                title: alert['title']?.toString() ?? '',
                value: _toInt(alert['value']),
                tone: alert['tone']?.toString() ?? 'warning',
              );
            }),
          if (dashboard.alerts.length > 3)
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: () {
                  Navigator.of(context).push(MaterialPageRoute(builder: (_) => const NotificationsScreen()));
                },
                icon: const Icon(Icons.arrow_forward_rounded, size: 16),
                label: const Text('Ver más'),
              ),
            ),
        ],
        const SectionHeader(title: 'Indicadores Clave', subtitle: 'Resumen del periodo activo', icon: Icons.insights_rounded),
        _buildKpiGrid(dashboard.kpis),
        const SectionHeader(title: 'Notificaciones recientes', icon: Icons.notifications_active_rounded),
        _buildNotificationPreview(appState.notifications),
        if (dashboard.summaryByUnit.isNotEmpty) ...[
          SectionHeader(
            title: auth.isAdmin ? 'Resumen por Unidad' : 'Mi unidad',
            icon: Icons.account_tree_rounded,
          ),
          _buildUnitTable(
            auth.isAdmin
                ? dashboard.summaryByUnit
                : _filterToUserUnit(dashboard.summaryByUnit, auth.unidadNombre),
            emptyLabel: auth.unidadNombre.isEmpty
                ? 'Tu perfil no tiene unidad asignada.'
                : 'No hay datos para tu unidad.',
          ),
        ],
      ],
    );
  }

  Widget _buildNotificationPreview(List<AppNotification> all) {
    if (all.isEmpty) {
      return const Padding(
        padding: EdgeInsets.only(bottom: 8),
        child: Text('Sin notificaciones.', style: TextStyle(color: AppTheme.textMuted)),
      );
    }
    final top = all.take(3).toList();
    return Column(
      children: [
        ...top.map((n) => Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.surfaceCard,
                borderRadius: AppTheme.radiusMd,
                border: Border.all(color: AppTheme.divider.withValues(alpha: 0.6)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    n.level == 'high' ? Icons.error_outline_rounded : Icons.notifications_none_rounded,
                    size: 18,
                    color: n.level == 'high' ? AppTheme.danger : AppTheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(n.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w700)),
                        Text(n.subtitle, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                      ],
                    ),
                  ),
                  Text(n.createdAtLabel, style: const TextStyle(fontSize: 11, color: AppTheme.textMuted)),
                ],
              ),
            )),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton.icon(
            onPressed: () {
              Navigator.of(context).push(MaterialPageRoute(builder: (_) => const NotificationsScreen()));
            },
            icon: const Icon(Icons.arrow_forward_rounded, size: 16),
            label: const Text('Ver más'),
          ),
        ),
      ],
    );
  }

  Widget _buildKpiGrid(List<dynamic> kpis) {
    if (kpis.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(32),
        child: const Center(child: Text('Sin datos disponibles.', style: TextStyle(color: AppTheme.textMuted))),
      );
    }
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final crossAxisCount = width > 1200 ? 4 : width > 900 ? 3 : 2;
        final childAspect = width > 1200 ? 2.0 : width > 900 ? 1.7 : 1.45;
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: kpis.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            childAspectRatio: childAspect,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
          ),
          itemBuilder: (_, i) {
            final kpi = Map<String, dynamic>.from(kpis[i] as Map);
            return KpiCard(
              title: kpi['title']?.toString() ?? '',
              value: (kpi['value'] ?? 0).toString(),
              badge: kpi['badge_label']?.toString(),
              helper: kpi['helper']?.toString(),
              icon: _mapKpiIcon(kpi['key']?.toString() ?? ''),
              tone: kpi['tone']?.toString() ?? 'info',
            );
          },
        );
      },
    );
  }

  Widget _buildUnitTable(List<dynamic> units, {String emptyLabel = 'Sin datos de unidad.'}) {
    if (units.isEmpty) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(emptyLabel, style: const TextStyle(color: AppTheme.textMuted)),
      );
    }
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surfaceCard, borderRadius: AppTheme.radiusMd,
        border: Border.all(color: AppTheme.divider),
      ),
      child: ClipRRect(
        borderRadius: AppTheme.radiusMd,
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            headingRowColor: WidgetStateProperty.all(AppTheme.surfaceElevated),
            columnSpacing: 20,
            columns: const [
              DataColumn(label: Text('Unidad', style: TextStyle(fontWeight: FontWeight.w700, color: AppTheme.textPrimary))),
              DataColumn(label: Text('Acc.', style: TextStyle(fontWeight: FontWeight.w700, color: AppTheme.textPrimary))),
              DataColumn(label: Text('NC', style: TextStyle(fontWeight: FontWeight.w700, color: AppTheme.textPrimary))),
              DataColumn(label: Text('Form.', style: TextStyle(fontWeight: FontWeight.w700, color: AppTheme.textPrimary))),
              DataColumn(label: Text('Equip.', style: TextStyle(fontWeight: FontWeight.w700, color: AppTheme.textPrimary))),
            ],
            rows: units.map((u) {
              final unit = Map<String, dynamic>.from(u as Map);
              return DataRow(cells: [
                DataCell(Text(unit['unit_name']?.toString() ?? '', style: const TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w500))),
                _countCell(unit['accidents'] ?? 0),
                _countCell(unit['open_nc'] ?? 0),
                _countCell(unit['pending_training'] ?? 0),
                _countCell(unit['pending_equipment'] ?? 0),
              ]);
            }).toList(),
          ),
        ),
      ),
    );
  }

  DataCell _countCell(dynamic v) {
    final c = _toInt(v);
    final color = c == 0 ? AppTheme.textMuted : c > 3 ? AppTheme.danger : AppTheme.warning;
    return DataCell(Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: c > 0 ? color.withValues(alpha: 0.12) : Colors.transparent, borderRadius: AppTheme.radiusSm),
      child: Text(c.toString(), style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 13)),
    ));
  }

  int _toInt(dynamic v) {
    if (v == null) return 0;
    if (v is num) return v.toInt();
    return int.tryParse(v.toString()) ?? 0;
  }

  List<dynamic> _filterToUserUnit(List<dynamic> units, String unitName) {
    final target = unitName.trim().toLowerCase();
    if (target.isEmpty) return const [];
    return units.where((u) {
      final unit = Map<String, dynamic>.from(u as Map);
      return (unit['unit_name'] ?? '').toString().trim().toLowerCase() == target;
    }).toList();
  }

  Widget _buildError(DashboardProvider d) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 60),
      child: Column(children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(color: AppTheme.danger.withValues(alpha: 0.1), shape: BoxShape.circle),
          child: const Icon(Icons.cloud_off_rounded, color: AppTheme.danger, size: 40),
        ),
        const SizedBox(height: 16),
        const Text('Error al cargar el dashboard', style: TextStyle(color: AppTheme.textPrimary, fontSize: 16, fontWeight: FontWeight.w600)),
        const SizedBox(height: 6),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Text(d.errorMessage ?? '', textAlign: TextAlign.center, style: const TextStyle(color: AppTheme.textMuted, fontSize: 12)),
        ),
        const SizedBox(height: 20),
        ElevatedButton.icon(onPressed: () => d.loadDashboard(), icon: const Icon(Icons.refresh_rounded, size: 18), label: const Text('Reintentar')),
      ]),
    );
  }

  Widget _buildPortalModeBanner(AuthProvider auth) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 14),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.info.withValues(alpha: 0.08),
        borderRadius: AppTheme.radiusMd,
        border: Border.all(color: AppTheme.info.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline_rounded, color: AppTheme.info, size: 18),
          const SizedBox(width: 8),
          const Expanded(
            child: Text(
              'Modo intranet portal activo. Algunas métricas avanzadas solo están disponibles para perfiles con permisos de gestión.',
              style: TextStyle(color: AppTheme.textSecondary, fontSize: 12),
            ),
          ),
          TextButton(
            onPressed: () => _openPortalIntranet(auth),
            child: const Text('Abrir intranet'),
          ),
        ],
      ),
    );
  }

  Future<void> _openPortalIntranet(AuthProvider auth) async {
    final base = (auth.serverUrl.isNotEmpty ? auth.serverUrl : AppConfig.odooBaseUrl).trim();
    final uri = Uri.parse('$base/my/calidad');
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}
