import 'package:flutter/material.dart';

import '../ui/app_components.dart';
import '../../l10n/strings.dart';
import '../../services/odoo_service.dart';
import '../../theme/app_theme.dart';

class ApprovalsInboxScreen extends StatefulWidget {
  const ApprovalsInboxScreen({super.key});

  @override
  State<ApprovalsInboxScreen> createState() => _ApprovalsInboxScreenState();
}

class _ApprovalsInboxScreenState extends State<ApprovalsInboxScreen> {
  final OdooService _odoo = OdooService();
  final TextEditingController _searchController = TextEditingController();

  bool _loading = true;
  String _filter = 'Todas';
  List<_ApprovalItem> _items = const [];
  List<String> _errors = const [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final incidentFallback = context.uiText('Incidencia', 'Incident');
    final communicationFallback = context.uiText(
      'Comunicación',
      'Communication',
    );
    final supplierFallback = context.uiText('Proveedor', 'Supplier');
    final incidentsErrorPrefix = context.l10n.incidents;
    final communicationsErrorPrefix = context.l10n.communications;
    final suppliersErrorPrefix = context.uiText('Proveedores', 'Suppliers');
    setState(() => _loading = true);
    final items = <_ApprovalItem>[];
    final errors = <String>[];

    try {
      final rows = await _odoo.searchRead(
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
      for (final row in rows) {
        final record = Map<String, dynamic>.from(row as Map);
        items.add(
          _ApprovalItem(
            title: _display(record['name'], fallback: incidentFallback),
            section: 'Incidencias',
            state: _display(record['estado'], fallback: 'pendiente'),
            date: _display(record['fecha']),
          ),
        );
      }
    } catch (error) {
      errors.add('$incidentsErrorPrefix: ${OdooService.prettyError(error)}');
    }

    try {
      final rows = await _odoo.searchRead(
        'calidad.comunicacion',
        fields: ['name', 'estado', 'fecha'],
        domain: [
          [
            'estado',
            'in',
            ['recibida', 'en_analisis', 'tratada'],
          ],
        ],
        order: 'id desc',
        limit: 20,
      );
      for (final row in rows) {
        final record = Map<String, dynamic>.from(row as Map);
        items.add(
          _ApprovalItem(
            title: _display(record['name'], fallback: communicationFallback),
            section: 'Comunicaciones',
            state: _display(record['estado'], fallback: 'pendiente'),
            date: _display(record['fecha']),
          ),
        );
      }
    } catch (error) {
      errors.add(
        '$communicationsErrorPrefix: ${OdooService.prettyError(error)}',
      );
    }

    try {
      final rows = await _odoo.searchRead(
        'calidad.proveedor.unidad',
        fields: [
          'partner_id',
          'estado',
          'fecha_homologacion',
          'fecha_desestimacion',
        ],
        order: 'id desc',
        limit: 20,
      );
      for (final row in rows) {
        final record = Map<String, dynamic>.from(row as Map);
        items.add(
          _ApprovalItem(
            title: _many2oneLabel(
              record['partner_id'],
              fallback: supplierFallback,
            ),
            section: 'Proveedores',
            state: _display(record['estado'], fallback: 'pendiente'),
            date: _firstDisplay([
              record['fecha_desestimacion'],
              record['fecha_homologacion'],
            ]),
          ),
        );
      }
    } catch (error) {
      errors.add('$suppliersErrorPrefix: ${OdooService.prettyError(error)}');
    }

    if (mounted) {
      setState(() {
        _items = items;
        _errors = errors;
        _loading = false;
      });
    }
  }

  List<_ApprovalItem> get _visibleItems {
    final query = _searchController.text.trim().toLowerCase();
    return _items.where((item) {
      if (_filter != 'Todas' && item.section != _filter) return false;
      if (query.isEmpty) return true;
      return '${item.title} ${item.section} ${item.state}'
          .toLowerCase()
          .contains(query);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final incidents = _items
        .where((item) => item.section == 'Incidencias')
        .length;
    final communications = _items
        .where((item) => item.section == 'Comunicaciones')
        .length;
    final suppliers = _items
        .where((item) => item.section == 'Proveedores')
        .length;

    return AppScaffold(
      title: context.uiText('Aprobaciones', 'Approvals'),
      actions: [
        IconButton(
          tooltip: context.uiText('Actualizar', 'Refresh'),
          onPressed: _loading ? null : _load,
          icon: Icon(Icons.refresh_rounded),
        ),
      ],
      child: _loading
          ? AppLoadingView(
              label: context.uiText(
                'Cargando aprobaciones',
                'Loading approvals',
              ),
            )
          : _items.isEmpty && _errors.isNotEmpty
          ? AppEmptyState(
              title: context.uiText(
                'No se pudo cargar la bandeja',
                'Could not load inbox',
              ),
              subtitle: _errors.join('\n'),
              icon: Icons.lock_outline_rounded,
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
                      child: _ApprovalMetric(
                        label: context.l10n.incidents,
                        value: incidents,
                        icon: Icons.warning_amber_rounded,
                        color: AppTheme.danger,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _ApprovalMetric(
                        label: context.l10n.communications,
                        value: communications,
                        icon: Icons.forum_rounded,
                        color: AppTheme.warning,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _ApprovalMetric(
                        label: context.uiText('Proveedores', 'Suppliers'),
                        value: suppliers,
                        icon: Icons.storefront_rounded,
                        color: AppTheme.success,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                AppSearchBar(
                  controller: _searchController,
                  hintText: context.uiText(
                    'Buscar en la bandeja',
                    'Search inbox',
                  ),
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: 12),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      for (final section in const [
                        'Todas',
                        'Incidencias',
                        'Comunicaciones',
                        'Proveedores',
                      ]) ...[
                        AppChoicePill(
                          label: _filterLabel(context, section),
                          icon: _sectionIcon(section),
                          selected: _filter == section,
                          onTap: () => setState(() => _filter = section),
                        ),
                        if (section != 'Proveedores') const SizedBox(width: 8),
                      ],
                    ],
                  ),
                ),
                if (_errors.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  AppCard(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const AppIconSurface(
                          icon: Icons.lock_outline_rounded,
                          color: AppTheme.warning,
                          size: 40,
                          iconSize: 18,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                context.uiText(
                                  'Acceso parcial',
                                  'Partial access',
                                ),
                                style: TextStyle(
                                  color: AppTheme.textPrimaryFor(context),
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                context.uiText(
                                  'Hay áreas que Odoo no permite consultar con este usuario.',
                                  'There are areas that Odoo does not allow this user to query.',
                                ),
                                style: TextStyle(
                                  color: AppTheme.textSecondaryFor(context),
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 14),
                Expanded(child: _buildList()),
              ],
            ),
    );
  }

  Widget _buildList() {
    final items = _visibleItems;
    if (items.isEmpty) {
      final filtering = _filter != 'Todas' || _searchController.text.isNotEmpty;
      return AppEmptyState(
        title: filtering
            ? context.uiText('Sin coincidencias', 'No matches')
            : context.uiText('Bandeja al día', 'Inbox up to date'),
        subtitle: filtering
            ? context.uiText(
                'Cambia el filtro o prueba con otro término de búsqueda.',
                'Change the filter or try another search term.',
              )
            : context.uiText(
                'No hay elementos de seguimiento visibles para tu usuario.',
                'There are no tracking items visible for your user.',
              ),
        icon: filtering ? Icons.search_off_rounded : Icons.task_alt_rounded,
      );
    }

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.only(bottom: 28),
        itemCount: items.length + 1,
        separatorBuilder: (_, _) => const SizedBox(height: 10),
        itemBuilder: (context, index) {
          if (index == 0) {
            return AppSectionHeader(
              title: context.uiText(
                '${items.length} elementos',
                '${items.length} items',
              ),
              subtitle: context.uiText(
                'Actividad administrativa visible en las áreas conectadas.',
                'Administrative activity visible in connected areas.',
              ),
            );
          }
          return _ApprovalCard(item: items[index - 1]);
        },
      ),
    );
  }

  IconData _sectionIcon(String section) => switch (section) {
    'Incidencias' => Icons.warning_amber_rounded,
    'Comunicaciones' => Icons.forum_rounded,
    'Proveedores' => Icons.storefront_rounded,
    _ => Icons.apps_rounded,
  };

  String _filterLabel(BuildContext context, String section) =>
      switch (section) {
        'Todas' => context.uiText('Todas', 'All'),
        'Incidencias' => context.l10n.incidents,
        'Comunicaciones' => context.l10n.communications,
        'Proveedores' => context.uiText('Proveedores', 'Suppliers'),
        _ => section,
      };
}

class _ApprovalMetric extends StatelessWidget {
  const _ApprovalMetric({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String label;
  final int value;
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
            value.toString(),
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

class _ApprovalCard extends StatelessWidget {
  const _ApprovalCard({required this.item});

  final _ApprovalItem item;

  @override
  Widget build(BuildContext context) {
    final color = _stateColor(item.state);
    final date = item.date == '-'
        ? context.uiText('Sin fecha registrada', 'No date recorded')
        : item.date;
    return AppCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppIconSurface(
            icon: _itemIcon(item.section),
            color: _sectionColor(item.section),
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
                        item.title,
                        style: TextStyle(
                          color: AppTheme.textPrimaryFor(context),
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    AppStatusChip(
                      label: _stateLabel(context, item.state),
                      color: color,
                    ),
                  ],
                ),
                const SizedBox(height: 7),
                Text(
                  _sectionLabel(context, item.section),
                  style: TextStyle(
                    color: _sectionColor(item.section),
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 5),
                Row(
                  children: [
                    Icon(
                      Icons.calendar_today_rounded,
                      color: AppTheme.textMutedFor(context),
                      size: 13,
                    ),
                    const SizedBox(width: 5),
                    Expanded(
                      child: Text(
                        date,
                        style: TextStyle(
                          color: AppTheme.textSecondaryFor(context),
                          fontSize: 12,
                        ),
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

  Color _stateColor(String state) {
    if (state.contains('abierta') || state.contains('desestimado')) {
      return AppTheme.danger;
    }
    if (state.contains('analisis') ||
        state.contains('proceso') ||
        state.contains('recibida')) {
      return AppTheme.warning;
    }
    if (state.contains('homologado') || state.contains('respondida')) {
      return AppTheme.success;
    }
    return AppTheme.info;
  }

  Color _sectionColor(String section) => switch (section) {
    'Incidencias' => AppTheme.danger,
    'Comunicaciones' => AppTheme.warning,
    'Proveedores' => AppTheme.success,
    _ => AppTheme.info,
  };

  IconData _itemIcon(String section) => switch (section) {
    'Incidencias' => Icons.warning_amber_rounded,
    'Comunicaciones' => Icons.forum_rounded,
    'Proveedores' => Icons.storefront_rounded,
    _ => Icons.fact_check_rounded,
  };

  String _stateLabel(BuildContext context, String state) {
    final normalized = state.replaceAll('_', ' ').trim();
    if (normalized.isEmpty) return context.uiText('Pendiente', 'Pending');
    return switch (normalized) {
      'pendiente' => context.uiText('Pendiente', 'Pending'),
      'abierta' => context.uiText('Abierta', 'Open'),
      'en proceso' => context.uiText('En proceso', 'In progress'),
      'recibida' => context.uiText('Recibida', 'Received'),
      'en analisis' ||
      'en análisis' => context.uiText('En análisis', 'In analysis'),
      'tratada' => context.uiText('Tratada', 'Handled'),
      'respondida' => context.uiText('Respondida', 'Answered'),
      'homologado' => context.uiText('Homologado', 'Approved'),
      'desestimado' => context.uiText('Desestimado', 'Rejected'),
      _ => '${normalized[0].toUpperCase()}${normalized.substring(1)}',
    };
  }

  String _sectionLabel(BuildContext context, String section) =>
      switch (section) {
        'Incidencias' => context.l10n.incidents,
        'Comunicaciones' => context.l10n.communications,
        'Proveedores' => context.uiText('Proveedores', 'Suppliers'),
        _ => section,
      };
}

class _ApprovalItem {
  const _ApprovalItem({
    required this.title,
    required this.section,
    required this.state,
    required this.date,
  });

  final String title;
  final String section;
  final String state;
  final String date;
}

String _many2oneLabel(dynamic value, {String fallback = '-'}) {
  if (value is List && value.length > 1) return value[1].toString();
  return _display(value, fallback: fallback);
}

String _display(dynamic value, {String fallback = '-'}) {
  final text = value?.toString().trim() ?? '';
  return text.isEmpty || text == 'false' || text == 'null' ? fallback : text;
}

String _firstDisplay(List<dynamic> values, {String fallback = '-'}) {
  for (final value in values) {
    final display = _display(value);
    if (display != '-') return display;
  }
  return fallback;
}
