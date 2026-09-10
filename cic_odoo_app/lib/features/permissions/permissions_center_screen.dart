import 'package:flutter/material.dart';

import '../../app/ui/app_components.dart';
import '../../l10n/strings.dart';
import '../../services/odoo_service.dart';
import '../../theme/app_theme.dart';

class PermissionsCenterScreen extends StatefulWidget {
  const PermissionsCenterScreen({super.key});

  @override
  State<PermissionsCenterScreen> createState() =>
      _PermissionsCenterScreenState();
}

class _PermissionsCenterScreenState extends State<PermissionsCenterScreen> {
  final OdooService _odoo = OdooService();
  bool _loading = true;
  String? _error;
  String? _rolesError;
  String? _trackingError;
  List<Map<String, dynamic>> _roles = [];
  List<Map<String, dynamic>> _tracking = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
      _rolesError = null;
      _trackingError = null;
    });

    try {
      final roles = await _odoo.searchRead(
        'calidad.perfil',
        fields: ['name'],
        order: 'id desc',
        limit: 30,
      );
      _roles = roles.map((e) => Map<String, dynamic>.from(e as Map)).toList();
    } catch (e) {
      _rolesError = OdooService.prettyError(e);
      _roles = [];
    }

    try {
      final tracking = await _odoo.searchRead(
        'calidad.incidencia',
        fields: ['name', 'estado', 'fecha'],
        domain: [
          [
            'estado',
            'in',
            ['abierta', 'en_proceso'],
          ],
        ],
        order: 'id desc',
        limit: 20,
      );
      _tracking = tracking
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();
    } catch (e) {
      _trackingError = OdooService.prettyError(e);
      _tracking = [];
    }

    if (_roles.isEmpty && _tracking.isEmpty) {
      _error = _rolesError ?? _trackingError;
    }

    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    final open = _tracking
        .where((row) => row['estado']?.toString() == 'abierta')
        .length;
    final inProgress = _tracking
        .where((row) => row['estado']?.toString() == 'en_proceso')
        .length;

    return DefaultTabController(
      length: 2,
      child: AppScaffold(
        title: context.uiText('Permisos y roles', 'Permissions and roles'),
        actions: [
          IconButton(
            tooltip: context.uiText('Actualizar', 'Refresh'),
            onPressed: _loading ? null : _load,
            icon: Icon(Icons.refresh_rounded),
          ),
        ],
        appBarBottom: TabBar(
          tabs: [
            Tab(
              icon: Icon(Icons.admin_panel_settings_rounded),
              text: context.uiText('Roles', 'Roles'),
            ),
            Tab(
              icon: Icon(Icons.fact_check_rounded),
              text: context.uiText('Seguimiento', 'Tracking'),
            ),
          ],
        ),
        child: _loading
            ? AppLoadingView(
                label: context.uiText(
                  'Cargando permisos y roles',
                  'Loading permissions and roles',
                ),
              )
            : _error != null
            ? AppEmptyState(
                title: context.uiText(
                  'No se pudo cargar la administración',
                  'Could not load administration',
                ),
                subtitle: _error!,
                icon: Icons.admin_panel_settings_outlined,
                action: AppButton.primary(
                  label: context.uiText('Reintentar', 'Retry'),
                  onPressed: _load,
                ),
              )
            : Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _PermissionMetric(
                          label: context.uiText('Perfiles', 'Profiles'),
                          value: _roles.length.toString(),
                          icon: Icons.verified_user_rounded,
                          color: AppTheme.primary,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _PermissionMetric(
                          label: context.uiText('Abiertas', 'Open'),
                          value: open.toString(),
                          icon: Icons.error_outline_rounded,
                          color: AppTheme.danger,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _PermissionMetric(
                          label: context.uiText('En proceso', 'In progress'),
                          value: inProgress.toString(),
                          icon: Icons.pending_actions_rounded,
                          color: AppTheme.warning,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: TabBarView(
                      children: [_buildRoles(), _buildTracking()],
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildRoles() {
    if (_roles.isEmpty) {
      return AppEmptyState(
        title: context.uiText(
          'Sin perfiles disponibles',
          'No profiles available',
        ),
        subtitle:
            _rolesError ??
            context.uiText(
              'Odoo no ha devuelto perfiles de permisos para mostrar.',
              'Odoo did not return permission profiles to display.',
            ),
        icon: _rolesError == null
            ? Icons.manage_accounts_outlined
            : Icons.lock_outline_rounded,
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.only(bottom: 28),
      itemCount: _roles.length + 1,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        if (index == 0) {
          return AppSectionHeader(
            title: context.uiText(
              'Perfiles configurados',
              'Configured profiles',
            ),
            subtitle: context.uiText(
              'Roles de acceso definidos en calidad.perfil.',
              'Access roles defined in calidad.perfil.',
            ),
          );
        }
        final role = _roles[index - 1];
        final id = (role['id'] as num?)?.toInt();
        return AppListTile(
          title: _display(
            role['name'],
            fallback: context.uiText('Rol sin nombre', 'Unnamed role'),
          ),
          subtitle: id == null
              ? context.uiText('Perfil de permisos', 'Permission profile')
              : '${context.uiText('Perfil de permisos', 'Permission profile')} · #$id',
          leading: const AppIconSurface(
            icon: Icons.verified_user_rounded,
            color: AppTheme.primary,
            size: 44,
            iconSize: 20,
          ),
          trailing: AppStatusChip(
            label: context.uiText('Configurado', 'Configured'),
            color: AppTheme.success,
          ),
        );
      },
    );
  }

  Widget _buildTracking() {
    if (_tracking.isEmpty) {
      return AppEmptyState(
        title: context.uiText('Sin incidencias activas', 'No active incidents'),
        subtitle:
            _trackingError ??
            context.uiText(
              'No hay incidencias abiertas o en proceso que requieran seguimiento.',
              'There are no open or in-progress incidents requiring tracking.',
            ),
        icon: _trackingError == null
            ? Icons.task_alt_rounded
            : Icons.lock_outline_rounded,
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.only(bottom: 28),
      itemCount: _tracking.length + 1,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        if (index == 0) {
          return AppSectionHeader(
            title: context.uiText(
              'Seguimiento administrativo',
              'Administrative tracking',
            ),
            subtitle: context.uiText(
              'Incidencias abiertas o en proceso visibles para este usuario.',
              'Open or in-progress incidents visible to this user.',
            ),
          );
        }
        return _TrackingCard(item: _tracking[index - 1]);
      },
    );
  }
}

class _PermissionMetric extends StatelessWidget {
  const _PermissionMetric({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppIconSurface(icon: icon, color: color, size: 36, iconSize: 17),
          const SizedBox(height: 9),
          Text(
            value,
            style: TextStyle(
              color: AppTheme.textPrimaryFor(context),
              fontSize: 21,
              fontWeight: FontWeight.w800,
            ),
          ),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: AppTheme.textSecondaryFor(context),
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _TrackingCard extends StatelessWidget {
  const _TrackingCard({required this.item});

  final Map<String, dynamic> item;

  @override
  Widget build(BuildContext context) {
    final state = (item['estado'] ?? 'pendiente').toString();
    final open = state == 'abierta';
    final color = open ? AppTheme.danger : AppTheme.warning;
    final stateLabel = open
        ? context.uiText('Abierta', 'Open')
        : context.uiText('En proceso', 'In progress');
    final date = _display(item['fecha']);

    return AppCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppIconSurface(
            icon: open
                ? Icons.report_problem_rounded
                : Icons.pending_actions_rounded,
            color: color,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        _display(
                          item['name'],
                          fallback: context.uiText('Incidencia', 'Incident'),
                        ),
                        style: TextStyle(
                          color: AppTheme.textPrimaryFor(context),
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    AppStatusChip(label: stateLabel, color: color),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      Icons.calendar_today_rounded,
                      color: AppTheme.textMutedFor(context),
                      size: 14,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      date == '-'
                          ? context.uiText(
                              'Sin fecha registrada',
                              'No date recorded',
                            )
                          : date,
                      style: TextStyle(
                        color: AppTheme.textSecondaryFor(context),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

String _display(dynamic value, {String fallback = '-'}) {
  final text = value?.toString().trim() ?? '';
  return text.isEmpty || text == 'false' || text == 'null' ? fallback : text;
}
