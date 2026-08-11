import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app/ui/app_components.dart';
import '../../features/forms/dynamic_form.dart';
import '../../providers/auth_provider.dart';
import '../../services/odoo_service.dart';
import '../../services/portal_api_service.dart';
import '../../theme/app_theme.dart';

class ActionPlansScreen extends StatefulWidget {
  const ActionPlansScreen({super.key});

  @override
  State<ActionPlansScreen> createState() => _ActionPlansScreenState();
}

class _ActionPlansScreenState extends State<ActionPlansScreen> {
  final OdooService _odoo = OdooService();
  final PortalApiService _portalApi = PortalApiService();
  bool _loading = true;
  String? _error;
  List<Map<String, dynamic>> _rows = [];
  List<Map<String, dynamic>> _goals = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final auth = context.read<AuthProvider>();
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final goals = _odoo.isPortalSession
          ? await _portalApi.section('goals', limit: 200)
          : await _odoo.searchRead(
              'calidad.objetivo',
              domain: [
                '|',
                ['responsable_id', '=', auth.partnerId],
                ['partner_id', '=', auth.partnerId],
              ],
              fields: const ['name'],
              order: 'id desc',
              limit: 200,
            );
      final rows = _odoo.isPortalSession
          ? await _portalApi.section('action_plans', limit: 200)
          : await _odoo.searchRead(
              'calidad.plan.accion',
              fields: const [
                'name',
                'descripcion',
                'tipo',
                'anio',
                'estado',
                'objetivo_id',
                'fecha_inicio',
                'fecha_fin',
                'responsable_id',
                'observaciones',
              ],
              order: 'fecha_fin asc, id desc',
              limit: 200,
            );
      _goals = goals.map((e) => Map<String, dynamic>.from(e as Map)).toList();
      _rows = rows.map((e) => Map<String, dynamic>.from(e as Map)).toList();
    } catch (e) {
      _error = OdooService.prettyError(e);
    }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _newPlan() async {
    if (_goals.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Necesitas al menos un objetivo para crear un plan.'),
        ),
      );
      return;
    }
    final nameCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    int goalId = (_goals.first['id'] as num).toInt();
    String estado = 'pendiente';

    final ok = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModal) => Padding(
          padding: EdgeInsets.fromLTRB(
            16,
            8,
            16,
            16 + MediaQuery.of(ctx).viewInsets.bottom,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppInput(
                controller: nameCtrl,
                labelText: 'Nombre del plan',
                prefixIcon: Icons.task_alt_rounded,
              ),
              const SizedBox(height: 8),
              AppInput(
                controller: descCtrl,
                labelText: 'Descripción',
                prefixIcon: Icons.notes_rounded,
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<int>(
                initialValue: goalId,
                items: _goals
                    .map(
                      (g) => DropdownMenuItem<int>(
                        value: (g['id'] as num).toInt(),
                        child: Text((g['name'] ?? '').toString()),
                      ),
                    )
                    .toList(),
                onChanged: (v) => setModal(() => goalId = v ?? goalId),
                decoration: const InputDecoration(labelText: 'Objetivo'),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                initialValue: estado,
                items: const [
                  DropdownMenuItem(
                    value: 'pendiente',
                    child: Text('Pendiente'),
                  ),
                  DropdownMenuItem(
                    value: 'en_proceso',
                    child: Text('En progreso'),
                  ),
                  DropdownMenuItem(
                    value: 'realizado',
                    child: Text('Completado'),
                  ),
                ],
                onChanged: (v) => setModal(() => estado = v ?? 'pendiente'),
                decoration: const InputDecoration(labelText: 'Estado'),
              ),
              const SizedBox(height: 12),
              AppButton.primary(
                label: 'Crear plan',
                icon: Icons.check_rounded,
                onPressed: () async {
                  if (nameCtrl.text.trim().isEmpty) return;
                  final auth = context.read<AuthProvider>();
                  final values = <String, dynamic>{
                    'name': nameCtrl.text.trim(),
                    'descripcion': descCtrl.text.trim(),
                    'estado': estado,
                    'objetivo_id': goalId,
                    'responsable_id': auth.partnerId,
                  };
                  if (_odoo.isPortalSession) {
                    await _portalApi.action(
                      'action_plan_create',
                      values: values,
                    );
                  } else {
                    await _odoo.create('calidad.plan.accion', values);
                  }
                  if (ctx.mounted) Navigator.of(ctx).pop(true);
                },
              ),
            ],
          ),
        ),
      ),
    );

    nameCtrl.dispose();
    descCtrl.dispose();
    if (ok == true) _load();
  }

  DateTime? _dateValue(dynamic value) {
    final text = value?.toString() ?? '';
    return text.isEmpty ? null : DateTime.tryParse(text);
  }

  String _datePayload(dynamic value) {
    if (value is! DateTime) return '';
    return '${value.year.toString().padLeft(4, '0')}-${value.month.toString().padLeft(2, '0')}-${value.day.toString().padLeft(2, '0')}';
  }

  Future<void> _editPlan(Map<String, dynamic> row) async {
    final id = (row['id'] as num?)?.toInt();
    if (id == null) return;
    final currentGoal = row['objetivo_id'] is List ? (row['objetivo_id'] as List).first : row['objetivo_id'];
    final edited = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(16, 8, 16, 16 + MediaQuery.of(ctx).viewInsets.bottom),
        child: SingleChildScrollView(
          child: DynamicForm(
            submitLabel: 'Guardar plan',
            fields: [
              DynamicFieldConfig(key: 'name', label: 'Nombre', required: true, initialValue: row['name']),
              DynamicFieldConfig(key: 'descripcion', label: 'Descripción', type: DynamicFieldType.multiline, maxLines: 3, initialValue: row['descripcion']),
              DynamicFieldConfig(key: 'tipo', label: 'Tipo', type: DynamicFieldType.select, initialValue: row['tipo'] ?? 'accion', options: const [DynamicFieldOption(value: 'accion', label: 'Acción'), DynamicFieldOption(value: 'preventiva', label: 'Preventiva')]),
              DynamicFieldConfig(key: 'objetivo_id', label: 'Objetivo', type: DynamicFieldType.select, required: true, initialValue: currentGoal, options: _goals.map((g) => DynamicFieldOption(value: (g['id'] as num).toInt(), label: (g['name'] ?? '').toString())).toList()),
              DynamicFieldConfig(key: 'estado', label: 'Estado', type: DynamicFieldType.select, initialValue: row['estado'] ?? 'pendiente', options: const [DynamicFieldOption(value: 'pendiente', label: 'Pendiente'), DynamicFieldOption(value: 'en_proceso', label: 'En proceso'), DynamicFieldOption(value: 'realizado', label: 'Realizado')]),
              DynamicFieldConfig(key: 'fecha_inicio', label: 'Fecha de inicio', type: DynamicFieldType.date, initialValue: _dateValue(row['fecha_inicio'])),
              DynamicFieldConfig(key: 'fecha_fin', label: 'Fecha fin', type: DynamicFieldType.date, initialValue: _dateValue(row['fecha_fin'])),
              DynamicFieldConfig(key: 'observaciones', label: 'Observaciones', type: DynamicFieldType.multiline, maxLines: 3, initialValue: row['observaciones']),
            ],
            onSubmit: (values) async {
              final payload = <String, dynamic>{
                'name': values['name'],
                'descripcion': values['descripcion'],
                'tipo': values['tipo'],
                'objetivo_id': values['objetivo_id'],
                'estado': values['estado'],
                'observaciones': values['observaciones'],
                if (_datePayload(values['fecha_inicio']).isNotEmpty) 'fecha_inicio': _datePayload(values['fecha_inicio']),
                if (_datePayload(values['fecha_fin']).isNotEmpty) 'fecha_fin': _datePayload(values['fecha_fin']),
              };
              if (_odoo.isPortalSession) {
                await _portalApi.action('action_plan_update', recordId: id, values: payload);
              } else {
                await _odoo.write('calidad.plan.accion', id, payload);
              }
            },
          ),
        ),
      ),
    );
    if (edited == true) _load();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    return AppScaffold(
      title: 'Planes de acción',
      actions: [
        if (auth.canEditModule('action_plans'))
          IconButton(onPressed: _newPlan, icon: const Icon(Icons.add_rounded)),
        IconButton(onPressed: _load, icon: const Icon(Icons.refresh_rounded)),
      ],
      child: _loading
          ? const AppLoadingView()
          : _error != null
          ? AppEmptyState(
              title: 'Error',
              subtitle: _error!,
              icon: Icons.error_outline_rounded,
            )
          : _rows.isEmpty
          ? const AppEmptyState(
              title: 'Sin planes',
              subtitle: 'Crea tu primer plan de acción desde el botón +.',
              icon: Icons.task_alt_rounded,
            )
          : ListView.builder(
              itemCount: _rows.length,
              itemBuilder: (context, index) {
                final row = _rows[index];
                final estado = (row['estado'] ?? 'pendiente').toString();
                final color = estado == 'realizado'
                    ? AppTheme.success
                    : estado == 'en_proceso'
                    ? AppTheme.warning
                    : AppTheme.textMuted;
                final objetivo = row['objetivo_id'] is List
                    ? row['objetivo_id'][1].toString()
                    : '-';
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: AppCard(
                    onTap: auth.canEditModule('action_plans') ? () => _editPlan(row) : null,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                (row['name'] ?? '').toString(),
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  color: AppTheme.textPrimary,
                                ),
                              ),
                            ),
                            AppStatusChip(
                              label: estado.replaceAll('_', ' '),
                              color: color,
                            ),
                            if (auth.canEditModule('action_plans'))
                              const Padding(
                                padding: EdgeInsets.only(left: 6),
                                child: Icon(Icons.edit_outlined, size: 18),
                              ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Objetivo: $objetivo',
                          style: const TextStyle(
                            color: AppTheme.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                        Text(
                          'Fecha límite: ${(row['fecha_fin'] ?? '-').toString()}',
                          style: const TextStyle(
                            color: AppTheme.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          (row['descripcion'] ?? '').toString(),
                          style: const TextStyle(
                            color: AppTheme.textMuted,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
