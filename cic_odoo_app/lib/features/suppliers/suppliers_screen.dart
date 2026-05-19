import 'package:flutter/material.dart';

import '../../features/forms/dynamic_form.dart';
import '../../features/suppliers/supplier_detail_screen.dart';
import '../../features/workflow/workflow_stage.dart';
import '../../features/workflow/workflow_widgets.dart';
import '../../services/odoo_service.dart';
import '../../theme/app_theme.dart';

class SuppliersScreen extends StatefulWidget {
  const SuppliersScreen({super.key});

  @override
  State<SuppliersScreen> createState() => _SuppliersScreenState();
}

class _SuppliersScreenState extends State<SuppliersScreen> {
  final OdooService _odoo = OdooService();
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
      final rows = await _odoo.searchRead(
        'calidad.proveedor.unidad',
        fields: [
          'partner_id',
          'estado',
          'fecha_homologacion',
          'fecha_desestimacion',
          'motivo_homologacion',
          'motivo_desestimacion',
          'observaciones',
        ],
        order: 'id desc',
        limit: 80,
      );
      _rows = rows.map((e) => Map<String, dynamic>.from(e as Map)).toList();
    } catch (e) {
      _error = e.toString();
    }

    if (mounted) setState(() => _loading = false);
  }

  Future<void> _runAction(int id, String method) async {
    try {
      await _odoo.callRecordMethod('calidad.proveedor.unidad', [id], method);
      await _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo ejecutar acción: $e'), backgroundColor: AppTheme.danger),
      );
    }
  }

  Future<void> _openCreateDialog() async {
    List<DynamicFieldOption> partnerOptions = const [];
    try {
      final rows = await _odoo.searchRead(
        'res.partner',
        domain: [
          ['company_type', '=', 'company'],
        ],
        fields: ['name'],
        order: 'name',
        limit: 200,
      );
      partnerOptions = rows
          .map((e) => Map<String, dynamic>.from(e as Map))
          .map((m) => DynamicFieldOption(value: m['id'], label: m['name']?.toString() ?? 'Proveedor'))
          .toList();
    } catch (_) {}

    if (!mounted) return;
    if (partnerOptions.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudieron cargar proveedores para crear un registro.')),
      );
      return;
    }

    final created = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.fromLTRB(16, 8, 16, 16 + MediaQuery.of(ctx).viewInsets.bottom),
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
              await _odoo.create('calidad.proveedor.unidad', {
                'partner_id': values['partner_id'],
                'estado': 'homologado',
                if (date != null) 'fecha_homologacion': '$y-$m-$d',
                'motivo_homologacion': values['motivo_homologacion'],
                'observaciones': values['observaciones'],
              });
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
    if (_loading) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Proveedores'),
        actions: [
          IconButton(onPressed: _openCreateDialog, icon: const Icon(Icons.add_rounded)),
          IconButton(onPressed: _load, icon: const Icon(Icons.refresh_rounded)),
        ],
      ),
      body: _error != null
          ? Center(child: Padding(padding: const EdgeInsets.all(16), child: Text(_error!)))
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
                  onTap: id == null
                      ? null
                      : () {
                          Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => SupplierDetailScreen(id: id)),
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
    this.onTap,
  });

  final Map<String, dynamic> row;
  final List<WorkflowStage> stages;
  final Future<void> Function(int id, String method) onAction;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final id = (row['id'] as num).toInt();
    final estado = (row['estado'] ?? 'homologado').toString();
    final proveedor = row['partner_id'] is List ? row['partner_id'][1].toString() : 'Proveedor';
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
          border: Border.all(color: Theme.of(context).dividerColor.withValues(alpha: 0.5)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
          Row(
            children: [
              Expanded(child: Text(proveedor, style: const TextStyle(fontWeight: FontWeight.w700))),
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
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (estado == 'homologado')
                OutlinedButton(onPressed: () => onAction(id, 'action_desestimar'), child: const Text('Desestimar')),
              if (estado == 'desestimado')
                OutlinedButton(onPressed: () => onAction(id, 'action_reactivar'), child: const Text('Reactivar')),
            ],
          ),
          ],
        ),
      ),
    );
  }
}
