import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app/ui/app_components.dart';
import '../../features/workflow/workflow_stage.dart';
import '../../features/workflow/workflow_widgets.dart';
import '../../features/forms/dynamic_form.dart';
import 'communication_detail_screen.dart';
import '../../providers/auth_provider.dart';
import '../../services/odoo_service.dart';
import '../../services/portal_api_service.dart';
import '../../theme/app_theme.dart';

enum _CommunicationFilter { all, communications, suggestions }

class CommunicationsScreen extends StatefulWidget {
  const CommunicationsScreen({super.key});

  @override
  State<CommunicationsScreen> createState() => _CommunicationsScreenState();
}

class _CommunicationsScreenState extends State<CommunicationsScreen> {
  final OdooService _odoo = OdooService();
  final PortalApiService _portalApi = PortalApiService();
  bool _loading = true;
  String? _error;
  List<Map<String, dynamic>> _rows = [];
  _CommunicationFilter _filter = _CommunicationFilter.all;

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
      final List<Map<String, dynamic>> rows;
      if (_odoo.isPortalSession) {
        // Communications and suggestions are two views of the same Odoo
        // model. Load both restricted portal sections and merge them here.
        final merged = <Map<String, dynamic>>[];
        try {
          merged.addAll(await _portalApi.section('communications', limit: 80));
        } catch (_) {}
        try {
          merged.addAll(await _portalApi.section('suggestions', limit: 80));
        } catch (_) {}
        final seenIds = <int>{};
        rows = merged.where((row) {
          final id = (row['id'] as num?)?.toInt();
          return id == null || seenIds.add(id);
        }).toList();
      } else {
        rows = await _portalApi.section('communications', limit: 80);
      }
      _rows = rows.map((e) => Map<String, dynamic>.from(e as Map)).toList();
    } catch (e) {
      _error = e.toString();
    }

    if (mounted) setState(() => _loading = false);
  }

  Future<void> _runAction(int id, String method) async {
    try {
      final action = switch (method) {
        'action_marcar_en_analisis' => 'communication_mark_en_analisis',
        'action_marcar_tratada' => 'communication_mark_tratada',
        'action_cerrar' => 'communication_close',
        _ => method,
      };
      await _portalApi.action(action, recordId: id);
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
              final payload = <String, dynamic>{
                'name': values['name'],
                'tipo': values['tipo'],
                'descripcion': values['descripcion'],
                'partner_id': partnerId,
                if (date != null) 'fecha': '$y-$m-$d',
              };
              if (values['tipo'] == 'sugerencia') {
                await _portalApi.action(
                  'suggestion_create',
                  values: {
                    'name': values['name'],
                    'descripcion': values['descripcion'],
                  },
                );
              } else {
                await _portalApi.action(
                  'communication_create',
                  values: payload,
                );
              }
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
    final visibleRows = _rows.where((row) {
      final type = row['tipo']?.toString().toLowerCase();
      return switch (_filter) {
        _CommunicationFilter.all => true,
        _CommunicationFilter.communications => type != 'sugerencia',
        _CommunicationFilter.suggestions => type == 'sugerencia',
      };
    }).toList();
    if (_loading) {
      return const Scaffold(body: AppLoadingView());
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Comunicaciones'),
        actions: [
          if (auth.canEditModule('communications'))
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
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 2),
                  child: Wrap(
                    spacing: 8,
                    children: [
                      ChoiceChip(
                        label: Text('Todas'),
                        selected: _filter == _CommunicationFilter.all,
                        onSelected: (_) =>
                            setState(() => _filter = _CommunicationFilter.all),
                      ),
                      ChoiceChip(
                        label: Text('Comunicaciones'),
                        selected:
                            _filter == _CommunicationFilter.communications,
                        onSelected: (_) => setState(
                          () => _filter = _CommunicationFilter.communications,
                        ),
                      ),
                      ChoiceChip(
                        label: Text('Sugerencias'),
                        selected: _filter == _CommunicationFilter.suggestions,
                        onSelected: (_) => setState(
                          () => _filter = _CommunicationFilter.suggestions,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                    itemCount: visibleRows.length,
                    separatorBuilder: (_, index) => const SizedBox(height: 10),
                    itemBuilder: (_, i) {
                      final row = visibleRows[i];
                      return _CommunicationCard(
                        row: row,
                        stages: _stages,
                        onAction: _runAction,
                        canEdit: auth.canEditModule('communications'),
                        onTap: () {
                          final id = (row['id'] as num?)?.toInt();
                          if (id == null) return;
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => CommunicationDetailScreen(id: id),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
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
      'cerrada' => AppTheme.textMutedFor(context),
      _ => AppTheme.textMutedFor(context),
    };

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
                    title,
                    style: TextStyle(fontWeight: FontWeight.w700),
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
