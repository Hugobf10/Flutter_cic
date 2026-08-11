import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app/ui/app_components.dart';
import '../../features/forms/dynamic_form.dart';
import '../../features/suppliers/supplier_detail_screen.dart';
import '../../providers/auth_provider.dart';
import '../../services/odoo_service.dart';
import '../../services/portal_api_service.dart';
import '../../theme/app_theme.dart';

class SuppliersScreen extends StatefulWidget {
  const SuppliersScreen({super.key});

  @override
  State<SuppliersScreen> createState() => _SuppliersScreenState();
}

class _SuppliersScreenState extends State<SuppliersScreen> {
  final OdooService _odoo = OdooService();
  final PortalApiService _portalApi = PortalApiService();
  final TextEditingController _searchController = TextEditingController();
  final Set<int> _busyIds = <int>{};

  bool _loading = true;
  bool _openingCreate = false;
  String? _error;
  String _filter = 'todos';
  List<Map<String, dynamic>> _rows = [];

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
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final rows = await _portalApi.section('suppliers', limit: 80);
      _rows = rows.map((e) => Map<String, dynamic>.from(e as Map)).toList();
    } catch (e) {
      _error = OdooService.prettyError(e);
    }

    if (mounted) setState(() => _loading = false);
  }

  Future<void> _runAction(int id, String method) async {
    if (_busyIds.contains(id)) return;
    setState(() => _busyIds.add(id));
    try {
      await _portalApi.action(
        method == 'action_desestimar'
            ? 'supplier_reject'
            : 'supplier_reactivate',
        recordId: id,
      );
      await _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'No se pudo ejecutar la acción: ${OdooService.prettyError(e)}',
          ),
          backgroundColor: AppTheme.danger,
        ),
      );
    } finally {
      if (mounted) setState(() => _busyIds.remove(id));
    }
  }

  Future<void> _openCreateDialog() async {
    if (_openingCreate) return;
    setState(() => _openingCreate = true);
    List<DynamicFieldOption> partnerOptions = const [];
    String? optionsError;
    try {
      List<dynamic> rows;
      if (_odoo.isPortalSession) {
        final response = await _portalApi.action('supplier_options');
        rows = response['items'] is List ? response['items'] as List : const [];
      } else {
        rows = await _odoo.searchRead(
          'res.partner',
          domain: const [
            ['active', '=', true],
            '|',
            ['company_type', '=', 'company'],
            ['is_company', '=', true],
          ],
          fields: const ['name'],
          order: 'name',
          limit: 200,
        );
      }
      partnerOptions = rows
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .map(
            (m) => DynamicFieldOption(
              value: m['id'],
              label: m['name']?.toString() ?? 'Proveedor',
            ),
          )
          .toList();
    } catch (error) {
      optionsError = OdooService.prettyError(error);
    } finally {
      if (mounted) setState(() => _openingCreate = false);
    }

    if (!mounted) return;
    if (partnerOptions.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            optionsError?.isNotEmpty == true
                ? optionsError!
                : 'No hay empresas proveedoras disponibles para crear un registro.',
          ),
        ),
      );
      return;
    }

    final created = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (ctx) {
        return SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(
            20,
            4,
            20,
            20 + MediaQuery.of(ctx).viewInsets.bottom,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _FormHeader(
                icon: Icons.add_business_rounded,
                title: 'Nueva homologación',
                subtitle:
                    'Selecciona una empresa y registra los datos iniciales.',
              ),
              const SizedBox(height: 18),
              DynamicForm(
                submitLabel: 'Crear homologación',
                fields: [
                  DynamicFieldConfig(
                    key: 'partner_id',
                    label: 'Proveedor',
                    type: DynamicFieldType.select,
                    required: true,
                    options: partnerOptions,
                  ),
                  const DynamicFieldConfig(
                    key: 'fecha_homologacion',
                    label: 'Fecha homologación',
                    type: DynamicFieldType.date,
                    required: true,
                  ),
                  const DynamicFieldConfig(
                    key: 'motivo_homologacion',
                    label: 'Motivo homologación',
                    type: DynamicFieldType.multiline,
                    maxLines: 3,
                  ),
                  const DynamicFieldConfig(
                    key: 'observaciones',
                    label: 'Observaciones',
                    type: DynamicFieldType.multiline,
                    maxLines: 3,
                  ),
                ],
                onSubmit: (values) async {
                  final date = values['fecha_homologacion'] as DateTime?;
                  final y = date?.year.toString().padLeft(4, '0');
                  final m = date?.month.toString().padLeft(2, '0');
                  final d = date?.day.toString().padLeft(2, '0');
                  final payload = <String, dynamic>{
                    'partner_id': values['partner_id'],
                    'estado': 'homologado',
                    if (date != null) 'fecha_homologacion': '$y-$m-$d',
                    'motivo_homologacion': values['motivo_homologacion'],
                    'observaciones': values['observaciones'],
                  };
                  await _portalApi.action('supplier_create', values: payload);
                },
              ),
            ],
          ),
        );
      },
    );

    if (created == true) await _load();
  }

  List<Map<String, dynamic>> get _visibleRows {
    final query = _searchController.text.trim().toLowerCase();
    return _rows.where((row) {
      final state = (row['estado'] ?? 'homologado').toString();
      if (_filter != 'todos' && state != _filter) return false;
      if (query.isEmpty) return true;
      final searchable = [
        _many2oneLabel(row['partner_id']),
        _many2oneLabel(row['unidad_id']),
        row['motivo_homologacion'],
        row['motivo_desestimacion'],
        row['observaciones'],
      ].join(' ').toLowerCase();
      return searchable.contains(query);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final canEdit = auth.canEditModule('suppliers');
    final homologated = _rows
        .where((row) => row['estado']?.toString() == 'homologado')
        .length;
    final rejected = _rows
        .where((row) => row['estado']?.toString() == 'desestimado')
        .length;

    return AppScaffold(
      title: 'Proveedores',
      actions: [
        IconButton(
          tooltip: 'Actualizar',
          onPressed: _loading ? null : _load,
          icon: Icon(Icons.refresh_rounded),
        ),
      ],
      floatingActionButton: canEdit
          ? FloatingActionButton.extended(
              onPressed: _openingCreate ? null : _openCreateDialog,
              icon: _openingCreate
                  ? const AppLoadingIndicator(size: 22)
                  : Icon(Icons.add_business_rounded),
              label: Text(_openingCreate ? 'Preparando' : 'Homologar'),
            )
          : null,
      child: _loading
          ? const AppLoadingView(label: 'Cargando proveedores')
          : _error != null
          ? AppEmptyState(
              title: 'No se pudieron cargar los proveedores',
              subtitle: _error!,
              icon: Icons.cloud_off_rounded,
              action: AppButton.primary(label: 'Reintentar', onPressed: _load),
            )
          : Column(
              children: [
                LayoutBuilder(
                  builder: (context, constraints) {
                    final cards = [
                      _SupplierStatCard(
                        label: 'Visibles',
                        value: _rows.length.toString(),
                        icon: Icons.storefront_rounded,
                        color: AppTheme.primary,
                      ),
                      _SupplierStatCard(
                        label: 'Homologados',
                        value: homologated.toString(),
                        icon: Icons.verified_rounded,
                        color: AppTheme.success,
                      ),
                      _SupplierStatCard(
                        label: 'Desestimados',
                        value: rejected.toString(),
                        icon: Icons.block_rounded,
                        color: AppTheme.danger,
                      ),
                    ];
                    if (constraints.maxWidth < 700) {
                      return Row(
                        children: [
                          for (var i = 0; i < cards.length; i++) ...[
                            Expanded(child: cards[i]),
                            if (i < cards.length - 1) const SizedBox(width: 8),
                          ],
                        ],
                      );
                    }
                    return Row(
                      children: [
                        for (var i = 0; i < cards.length; i++) ...[
                          Expanded(child: cards[i]),
                          if (i < cards.length - 1) const SizedBox(width: 12),
                        ],
                      ],
                    );
                  },
                ),
                const SizedBox(height: 16),
                AppSearchBar(
                  controller: _searchController,
                  hintText: 'Buscar proveedor, unidad o motivo',
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: 12),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      AppChoicePill(
                        label: 'Todos',
                        icon: Icons.apps_rounded,
                        selected: _filter == 'todos',
                        onTap: () => setState(() => _filter = 'todos'),
                      ),
                      const SizedBox(width: 8),
                      AppChoicePill(
                        label: 'Homologados',
                        icon: Icons.verified_rounded,
                        selected: _filter == 'homologado',
                        onTap: () => setState(() => _filter = 'homologado'),
                      ),
                      const SizedBox(width: 8),
                      AppChoicePill(
                        label: 'Desestimados',
                        icon: Icons.block_rounded,
                        selected: _filter == 'desestimado',
                        onTap: () => setState(() => _filter = 'desestimado'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Expanded(child: _buildList(canEdit)),
              ],
            ),
    );
  }

  Widget _buildList(bool canEdit) {
    final rows = _visibleRows;
    if (rows.isEmpty) {
      final filtering = _filter != 'todos' || _searchController.text.isNotEmpty;
      return AppEmptyState(
        title: filtering ? 'Sin coincidencias' : 'Sin proveedores',
        subtitle: filtering
            ? 'Prueba con otra búsqueda o cambia el filtro de estado.'
            : 'No hay proveedores visibles para este usuario.',
        icon: filtering
            ? Icons.search_off_rounded
            : Icons.store_mall_directory_outlined,
      );
    }

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.separated(
        padding: const EdgeInsets.only(bottom: 96),
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: rows.length,
        separatorBuilder: (_, _) => const SizedBox(height: 12),
        itemBuilder: (_, index) {
          final row = rows[index];
          final id = (row['id'] as num?)?.toInt();
          return _SupplierCard(
            row: row,
            onAction: _runAction,
            canEdit: canEdit,
            busy: id != null && _busyIds.contains(id),
            onTap: id == null
                ? null
                : () async {
                    await Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => SupplierDetailScreen(id: id),
                      ),
                    );
                    if (mounted) await _load();
                  },
          );
        },
      ),
    );
  }
}

class _SupplierStatCard extends StatelessWidget {
  const _SupplierStatCard({
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
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppIconSurface(icon: icon, color: color, size: 38, iconSize: 18),
          const SizedBox(height: 10),
          Text(
            value,
            style: TextStyle(
              color: AppTheme.textPrimaryFor(context),
              fontSize: 22,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: AppTheme.textSecondaryFor(context),
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _SupplierCard extends StatelessWidget {
  const _SupplierCard({
    required this.row,
    required this.onAction,
    required this.canEdit,
    required this.busy,
    this.onTap,
  });

  final Map<String, dynamic> row;
  final Future<void> Function(int id, String method) onAction;
  final bool canEdit;
  final bool busy;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final id = (row['id'] as num).toInt();
    final state = (row['estado'] ?? 'homologado').toString();
    final supplier = _many2oneLabel(row['partner_id'], fallback: 'Proveedor');
    final unit = _many2oneLabel(row['unidad_id']);
    final reason = state == 'desestimado'
        ? _display(row['motivo_desestimacion'])
        : _display(row['motivo_homologacion']);
    final date = state == 'desestimado'
        ? _display(row['fecha_desestimacion'])
        : _display(row['fecha_homologacion']);
    final color = state == 'homologado' ? AppTheme.success : AppTheme.danger;

    return AppCard(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppIconSurface(
                icon: state == 'homologado'
                    ? Icons.storefront_rounded
                    : Icons.storefront_outlined,
                color: color,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      supplier,
                      style: TextStyle(
                        color: AppTheme.textPrimaryFor(context),
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      unit == '-' ? 'Unidad no indicada' : unit,
                      style: TextStyle(
                        color: AppTheme.textSecondaryFor(context),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              AppStatusChip(
                label: state == 'homologado' ? 'Homologado' : 'Desestimado',
                color: color,
              ),
            ],
          ),
          const SizedBox(height: 14),
          NeumorphicSurface(
            subtle: true,
            showBorder: false,
            padding: const EdgeInsets.all(12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.event_rounded, size: 17, color: color),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        date == '-' ? 'Sin fecha registrada' : date,
                        style: TextStyle(
                          color: AppTheme.textPrimaryFor(context),
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                        ),
                      ),
                      if (reason != '-') ...[
                        const SizedBox(height: 4),
                        Text(
                          reason,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: AppTheme.textSecondaryFor(context),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                if (onTap != null)
                  Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 14,
                    color: AppTheme.textMutedFor(context),
                  ),
              ],
            ),
          ),
          if (canEdit) ...[
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: AppButton.outline(
                label: state == 'homologado' ? 'Desestimar' : 'Reactivar',
                icon: state == 'homologado'
                    ? Icons.block_rounded
                    : Icons.restart_alt_rounded,
                loading: busy,
                onPressed: busy
                    ? null
                    : () => onAction(
                        id,
                        state == 'homologado'
                            ? 'action_desestimar'
                            : 'action_reactivar',
                      ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _FormHeader extends StatelessWidget {
  const _FormHeader({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppIconSurface(icon: icon, color: AppTheme.primary),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: TextStyle(color: AppTheme.textSecondaryFor(context)),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

String _many2oneLabel(dynamic value, {String fallback = '-'}) {
  if (value is List && value.length > 1) return value[1].toString();
  final text = value?.toString().trim() ?? '';
  return text.isEmpty || text == 'false' ? fallback : text;
}

String _display(dynamic value) {
  final text = value?.toString().trim() ?? '';
  return text.isEmpty || text == 'false' || text == 'null' ? '-' : text;
}
