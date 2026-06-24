import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../features/workflow/workflow_stage.dart';
import '../../features/workflow/workflow_widgets.dart';
import '../../features/forms/dynamic_form.dart';
import '../../providers/auth_provider.dart';
import '../../services/odoo_service.dart';
import '../../theme/app_theme.dart';

class CommunicationsScreen extends StatefulWidget {
  const CommunicationsScreen({super.key});

  @override
  State<CommunicationsScreen> createState() => _CommunicationsScreenState();
}

class _CommunicationsScreenState extends State<CommunicationsScreen> {
  final OdooService _odoo = OdooService();
  bool _loading = true;
  String? _error;
  List<Map<String, dynamic>> _rows = [];

  static const _stages = [
    WorkflowStage(key: 'recibida', label: 'Recibida'),
    WorkflowStage(key: 'en_analisis', label: 'Análisis'),
    WorkflowStage(key: 'tratada', label: 'Tratada'),
    WorkflowStage(key: 'respondida', label: 'Respondida'),
    WorkflowStage(key: 'cerrada', label: 'Cerrada'),
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
        'calidad.comunicacion',
        fields: [
          'name',
          'tipo',
          'fecha',
          'estado',
          'partner_id',
          'descripcion',
        ],
        order: 'fecha desc, id desc',
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
      await _odoo.callRecordMethod('calidad.comunicacion', [id], method);
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
    final partnerId = context.read<AuthProvider>().partnerId;
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
            submitLabel: 'Crear comunicación',
            fields: const [
              DynamicFieldConfig(key: 'name', label: 'Título', required: true),
              DynamicFieldConfig(
                key: 'tipo',
                label: 'Tipo',
                type: DynamicFieldType.select,
                required: true,
                initialValue: 'comunicacion',
                options: [
                  DynamicFieldOption(
                    value: 'comunicacion',
                    label: 'Comunicación',
                  ),
                  DynamicFieldOption(value: 'sugerencia', label: 'Sugerencia'),
                ],
              ),
              DynamicFieldConfig(
                key: 'fecha',
                label: 'Fecha',
                type: DynamicFieldType.date,
                required: true,
              ),
              DynamicFieldConfig(
                key: 'descripcion',
                label: 'Descripción',
                type: DynamicFieldType.multiline,
                required: true,
                maxLines: 4,
              ),
            ],
            onSubmit: (values) async {
              final date = values['fecha'] as DateTime?;
              final y = date?.year.toString().padLeft(4, '0');
              final m = date?.month.toString().padLeft(2, '0');
              final d = date?.day.toString().padLeft(2, '0');
              await _odoo.create('calidad.comunicacion', {
                'name': values['name'],
                'tipo': values['tipo'],
                'descripcion': values['descripcion'],
                'partner_id': partnerId,
                if (date != null) 'fecha': '$y-$m-$d',
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
    final auth = context.watch<AuthProvider>();
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Comunicaciones'),
        actions: [
          if (auth.canEditModule('communications'))
            IconButton(
              onPressed: _openCreateDialog,
              icon: const Icon(Icons.add_rounded),
            ),
          IconButton(onPressed: _load, icon: const Icon(Icons.refresh_rounded)),
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
                return _CommunicationCard(
                  row: row,
                  stages: _stages,
                  onAction: _runAction,
                  canEdit: auth.canEditModule('communications'),
                );
              },
            ),
    );
  }
}

class _CommunicationCard extends StatelessWidget {
  const _CommunicationCard({
    required this.row,
    required this.stages,
    required this.onAction,
    required this.canEdit,
  });

  final Map<String, dynamic> row;
  final List<WorkflowStage> stages;
  final Future<void> Function(int id, String method) onAction;
  final bool canEdit;

  @override
  Widget build(BuildContext context) {
    final id = (row['id'] as num).toInt();
    final estado = (row['estado'] ?? 'recibida').toString();
    final title = row['name']?.toString() ?? 'Comunicación';
    final desc = row['descripcion']?.toString() ?? '';
    final tipo = row['tipo']?.toString() ?? '';
    final fecha = row['fecha']?.toString() ?? '';
    final partner = row['partner_id'] is List
        ? row['partner_id'][1].toString()
        : '';

    final color = switch (estado) {
      'recibida' => AppTheme.warning,
      'en_analisis' => AppTheme.info,
      'tratada' => const Color(0xFF8B5CF6),
      'respondida' => AppTheme.success,
      'cerrada' => AppTheme.textMuted,
      _ => AppTheme.textMuted,
    };

    return Container(
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
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
              WorkflowStateChip(label: estado, color: color),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            '$tipo · $partner · $fecha',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          if (desc.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(desc, maxLines: 2, overflow: TextOverflow.ellipsis),
          ],
          const SizedBox(height: 10),
          WorkflowStepperBar(stages: stages, currentKey: estado),
          const SizedBox(height: 10),
          if (canEdit)
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (estado == 'recibida')
                  _ActionBtn(
                    label: 'Analizar',
                    onTap: () => onAction(id, 'action_marcar_en_analisis'),
                  ),
                if (estado == 'en_analisis')
                  _ActionBtn(
                    label: 'Marcar tratada',
                    onTap: () => onAction(id, 'action_marcar_tratada'),
                  ),
                if (estado == 'tratada' || estado == 'respondida')
                  _ActionBtn(
                    label: 'Cerrar',
                    onTap: () => onAction(id, 'action_cerrar'),
                  ),
              ],
            ),
        ],
      ),
    );
  }
}

class _ActionBtn extends StatelessWidget {
  const _ActionBtn({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(onPressed: onTap, child: Text(label));
  }
}
