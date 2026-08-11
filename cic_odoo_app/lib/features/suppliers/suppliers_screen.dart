import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app/ui/app_components.dart';
import '../../features/forms/dynamic_form.dart';
import '../../features/suppliers/supplier_detail_screen.dart';
import '../../features/workflow/workflow_stage.dart';
import '../../features/workflow/workflow_widgets.dart';
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
  bool _loading = true;
  String? _error;
  List<Map<String, dynamic>> _rows = [];

  static const _stages = [
    WorkflowStage(key: 'homologado', label: 'Homologado'),
    WorkflowStage(key: 'desestimado', label: 'Desestimado'),
  ];

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
      final rows = await _portalApi.section('suppliers', limit: 80);
      _rows = rows.map((e) => Map<String, dynamic>.from(e as Map)).toList();
    } catch (e) {
      _error = e.toString();
    }

    if (mounted) setState(() => _loading = false);
  }

  Future<void> _runAction(int id, String method) async {
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
          content: Text('No se pudo ejecutar acción: $e'),
          backgroundColor: AppTheme.danger,
        ),
      );
    }
  }

  Future<void> _openCreateDialog() async {
    List<DynamicFieldOption> partnerOptions = const [];
    String? optionsError;
    try {
      List<dynamic> rows;
      if (_odoo.isPortalSession) {
        final response = await _portalApi.action('supplier_options');
        rows = response['items'] is List ? response['items'] as List : const [];
      } else {
        // Internal users can use the same Odoo partner search as the native form.
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
    }

    if (!mounted) return;
    if (partnerOptions.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'No hay empresas proveedoras disponibles para crear un registro.',
          ),
        ),
      );
      if (optionsError != null && optionsError.isNotEmpty) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(optionsError)));
      }
      return;
    }

    final created = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.fromLTRB(
            16,
            8,
            16,
            16 + MediaQuery.of(ctx).viewInsets.bottom,
          ),
          child: DynamicForm(
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
        );
      },
    );

    if (created == true) {
      await _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    if (_loading) {
      return const Scaffold(body: AppLoadingView());
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Proveedores'),
        actions: [
          if (auth.canEditModule('suppliers'))
            IconButton(
              onPressed: _openCreateDialog,
              icon: Icon(Icons.add_rounded),
            ),
          IconButton(onPressed: _load, icon: Icon(Icons.refresh_rounded)),
        ],
      ),
      body: _error != null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(_error!),
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 100),
              itemCount: _rows.length,
              separatorBuilder: (_, index) => const SizedBox(height: 10),
              itemBuilder: (_, i) {
                final row = _rows[i];
                final id = (row['id'] as num?)?.toInt();
                return _SupplierCard(
                  row: row,
                  stages: _stages,
                  onAction: _runAction,
                  canEdit: auth.canEditModule('suppliers'),
                  onTap: id == null
                      ? null
                      : () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => SupplierDetailScreen(id: id),
                            ),
                          );
                        },
                );
              },
            ),
    );
  }
}

class _SupplierCard extends StatelessWidget {
  const _SupplierCard({
    required this.row,
    required this.stages,
    required this.onAction,
    required this.canEdit,
    this.onTap,
  });

  final Map<String, dynamic> row;
  final List<WorkflowStage> stages;
  final Future<void> Function(int id, String method) onAction;
  final bool canEdit;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final id = (row['id'] as num).toInt();
    final estado = (row['estado'] ?? 'homologado').toString();
    final proveedor = row['partner_id'] is List
        ? row['partner_id'][1].toString()
        : 'Proveedor';
    final motivo = estado == 'desestimado'
        ? (row['motivo_desestimacion']?.toString() ?? '')
        : (row['motivo_homologacion']?.toString() ?? '');
    final fecha = estado == 'desestimado'
        ? (row['fecha_desestimacion']?.toString() ?? '')
        : (row['fecha_homologacion']?.toString() ?? '');

    final color = estado == 'homologado' ? AppTheme.success : AppTheme.danger;

    return InkWell(
      borderRadius: AppTheme.radiusMd,
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: AppTheme.radiusMd,
          border: Border.all(
            color: Theme.of(context).dividerColor.withValues(alpha: 0.5),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    proveedor,
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
                WorkflowStateChip(label: estado, color: color),
              ],
            ),
            const SizedBox(height: 6),
            Text('Fecha: $fecha', style: Theme.of(context).textTheme.bodySmall),
            if (motivo.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(motivo, maxLines: 2, overflow: TextOverflow.ellipsis),
            ],
            const SizedBox(height: 10),
            WorkflowStepperBar(stages: stages, currentKey: estado),
            const SizedBox(height: 10),
            if (canEdit)
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  if (estado == 'homologado')
                    OutlinedButton(
                      onPressed: () => onAction(id, 'action_desestimar'),
                      child: Text('Desestimar'),
                    ),
                  if (estado == 'desestimado')
                    OutlinedButton(
                      onPressed: () => onAction(id, 'action_reactivar'),
                      child: Text('Reactivar'),
                    ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
