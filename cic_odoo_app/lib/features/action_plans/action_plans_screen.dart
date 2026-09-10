import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app/ui/app_components.dart';
import '../../features/forms/dynamic_form.dart';
import '../../l10n/strings.dart';
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
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(context.l10n.goalRequiredForPlan)));
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
                labelText: context.l10n.planName,
                prefixIcon: Icons.task_alt_rounded,
              ),
              const SizedBox(height: 8),
              AppInput(
                controller: descCtrl,
                labelText: context.l10n.description,
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
                decoration: InputDecoration(labelText: context.l10n.goals),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                initialValue: estado,
                items: [
                  DropdownMenuItem(
                    value: 'pendiente',
                    child: Text(context.l10n.pending),
                  ),
                  DropdownMenuItem(
                    value: 'en_proceso',
                    child: Text(context.l10n.inProgress),
                  ),
                  DropdownMenuItem(
                    value: 'realizado',
                    child: Text(context.l10n.previewSuccess),
                  ),
                ],
                onChanged: (v) => setModal(() => estado = v ?? 'pendiente'),
                decoration: InputDecoration(labelText: context.l10n.status),
              ),
              const SizedBox(height: 12),
              AppButton.primary(
                label: context.l10n.createPlan,
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
    final currentGoal = row['objetivo_id'] is List
        ? (row['objetivo_id'] as List).first
        : row['objetivo_id'];
    final edited = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(
          16,
          8,
          16,
          16 + MediaQuery.of(ctx).viewInsets.bottom,
        ),
        child: SingleChildScrollView(
          child: DynamicForm(
            submitLabel: context.l10n.savePlan,
            fields: [
              DynamicFieldConfig(
                key: 'name',
                label: context.l10n.name,
                required: true,
                initialValue: row['name'],
              ),
              DynamicFieldConfig(
                key: 'descripcion',
                label: context.l10n.description,
                type: DynamicFieldType.multiline,
                maxLines: 3,
                initialValue: row['descripcion'],
              ),
              DynamicFieldConfig(
                key: 'tipo',
                label: context.l10n.type,
                type: DynamicFieldType.select,
                initialValue: row['tipo'] ?? 'accion',
                options: [
                  DynamicFieldOption(
                    value: 'accion',
                    label: context.l10n.action,
                  ),
                  DynamicFieldOption(
                    value: 'preventiva',
                    label: context.l10n.preventiveFeminine,
                  ),
                ],
              ),
              DynamicFieldConfig(
                key: 'objetivo_id',
                label: context.l10n.goals,
                type: DynamicFieldType.select,
                required: true,
                initialValue: currentGoal,
                options: _goals
                    .map(
                      (g) => DynamicFieldOption(
                        value: (g['id'] as num).toInt(),
                        label: (g['name'] ?? '').toString(),
                      ),
                    )
                    .toList(),
              ),
              DynamicFieldConfig(
                key: 'estado',
                label: context.l10n.status,
                type: DynamicFieldType.select,
                initialValue: row['estado'] ?? 'pendiente',
                options: [
                  DynamicFieldOption(
                    value: 'pendiente',
                    label: context.l10n.pending,
                  ),
                  DynamicFieldOption(
                    value: 'en_proceso',
                    label: context.l10n.inProgress,
                  ),
                  DynamicFieldOption(
                    value: 'realizado',
                    label: context.l10n.previewSuccess,
                  ),
                ],
              ),
              DynamicFieldConfig(
                key: 'fecha_inicio',
                label: context.l10n.startDate,
                type: DynamicFieldType.date,
                initialValue: _dateValue(row['fecha_inicio']),
              ),
              DynamicFieldConfig(
                key: 'fecha_fin',
                label: context.l10n.endDate,
                type: DynamicFieldType.date,
                initialValue: _dateValue(row['fecha_fin']),
              ),
              DynamicFieldConfig(
                key: 'observaciones',
                label: context.l10n.observations,
                type: DynamicFieldType.multiline,
                maxLines: 3,
                initialValue: row['observaciones'],
              ),
            ],
            onSubmit: (values) async {
              final payload = <String, dynamic>{
                'name': values['name'],
                'descripcion': values['descripcion'],
                'tipo': values['tipo'],
                'objetivo_id': values['objetivo_id'],
                'estado': values['estado'],
                'observaciones': values['observaciones'],
                if (_datePayload(values['fecha_inicio']).isNotEmpty)
                  'fecha_inicio': _datePayload(values['fecha_inicio']),
                if (_datePayload(values['fecha_fin']).isNotEmpty)
                  'fecha_fin': _datePayload(values['fecha_fin']),
              };
              if (_odoo.isPortalSession) {
                await _portalApi.action(
                  'action_plan_update',
                  recordId: id,
                  values: payload,
                );
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
      title: context.l10n.actionPlans,
      actions: [
        if (auth.canEditModule('action_plans'))
          IconButton(onPressed: _newPlan, icon: Icon(Icons.add_rounded)),
        IconButton(onPressed: _load, icon: Icon(Icons.refresh_rounded)),
      ],
      child: _loading
          ? const AppLoadingView()
          : _error != null
          ? AppEmptyState(
              title: context.l10n.error,
              subtitle: _error!,
              icon: Icons.error_outline_rounded,
            )
          : _rows.isEmpty
          ? AppEmptyState(
              title: context.l10n.noPlans,
              subtitle: context.l10n.noPlansHint,
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
                    : AppTheme.textMutedFor(context);
                final objetivo = row['objetivo_id'] is List
                    ? row['objetivo_id'][1].toString()
                    : '-';
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: AppCard(
                    onTap: auth.canEditModule('action_plans')
                        ? () => _editPlan(row)
                        : null,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                (row['name'] ?? '').toString(),
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  color: AppTheme.textPrimaryFor(context),
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
                          context.l10n.goalLabel(objetivo),
                          style: TextStyle(
                            color: AppTheme.textSecondaryFor(context),
                            fontSize: 12,
                          ),
                        ),
                        Text(
                          context.l10n.dueDate(
                            (row['fecha_fin'] ?? '-').toString(),
                          ),
                          style: TextStyle(
                            color: AppTheme.textSecondaryFor(context),
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          (row['descripcion'] ?? '').toString(),
                          style: TextStyle(
                            color: AppTheme.textMutedFor(context),
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
