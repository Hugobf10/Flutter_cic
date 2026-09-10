import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app/ui/app_components.dart';
import '../../features/forms/dynamic_form.dart';
import '../../l10n/strings.dart';
import '../../providers/auth_provider.dart';
import '../../services/odoo_service.dart';
import '../../services/odoo_values.dart';
import '../../services/portal_api_service.dart';
import '../../theme/app_theme.dart';

class GoalsScreen extends StatefulWidget {
  const GoalsScreen({super.key});

  @override
  State<GoalsScreen> createState() => _GoalsScreenState();
}

class _GoalsScreenState extends State<GoalsScreen> {
  final OdooService _odoo = OdooService();
  final PortalApiService _portalApi = PortalApiService();
  bool _loading = true;
  String? _error;
  List<Map<String, dynamic>> _rows = [];

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
      final rows = _odoo.isPortalSession
          ? await _portalApi.section('goals', limit: 200)
          : await _odoo.searchRead(
              'calidad.objetivo',
              domain: [
                '|',
                ['responsable_id', '=', auth.partnerId],
                ['partner_id', '=', auth.partnerId],
              ],
              fields: const [
                'name',
                'tipo',
                'estado',
                'avance',
                'anio',
                'indicador',
                'valor_objetivo',
                'valor_real',
                'fecha_fin',
                'fecha_inicio',
                'responsable_id',
                'descripcion',
                'observaciones',
              ],
              order: 'anio desc, fecha_fin asc, id desc',
              limit: 200,
            );
      _rows = rows.whereType<Map>().map((e) {
        final row = Map<String, dynamic>.from(e);
        row['avance'] = OdooValues.number(row['avance']);
        return row;
      }).toList();
    } catch (e) {
      _error = OdooService.prettyError(e);
    }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _createGoal() async {
    final nameCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    String tipo = 'calidad';
    String estado = 'pendiente';
    final year = DateTime.now().year;

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
                labelText: context.l10n.goalName,
                prefixIcon: Icons.flag_outlined,
              ),
              const SizedBox(height: 8),
              AppInput(
                controller: descCtrl,
                labelText: context.l10n.description,
                prefixIcon: Icons.notes_rounded,
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                initialValue: tipo,
                items: [
                  DropdownMenuItem(
                    value: 'calidad',
                    child: Text(context.l10n.quality),
                  ),
                  DropdownMenuItem(value: 'prl', child: Text('PRL')),
                ],
                onChanged: (v) => setModal(() => tipo = v ?? 'calidad'),
                decoration: InputDecoration(labelText: context.l10n.type),
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
                    child: Text(context.l10n.completedFeminine),
                  ),
                ],
                onChanged: (v) => setModal(() => estado = v ?? 'pendiente'),
                decoration: InputDecoration(labelText: context.l10n.status),
              ),
              const SizedBox(height: 12),
              AppButton.primary(
                label: context.l10n.createGoal,
                icon: Icons.check_rounded,
                onPressed: () async {
                  if (nameCtrl.text.trim().isEmpty) return;
                  try {
                    final auth = context.read<AuthProvider>();
                    final values = <String, dynamic>{
                      'name': nameCtrl.text.trim(),
                      'descripcion': descCtrl.text.trim(),
                      'tipo': tipo,
                      'estado': estado,
                      'anio': year,
                      'responsable_id': auth.partnerId,
                    };
                    if (_odoo.isPortalSession) {
                      await _portalApi.action('goal_create', values: values);
                    } else {
                      await _odoo.create('calidad.objetivo', values);
                    }
                    if (ctx.mounted) Navigator.of(ctx).pop(true);
                  } catch (error) {
                    if (ctx.mounted) {
                      ScaffoldMessenger.of(ctx).showSnackBar(
                        SnackBar(content: Text(OdooService.prettyError(error))),
                      );
                    }
                  }
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
    if (value is DateTime) return value;
    final text = value?.toString() ?? '';
    return text.isEmpty ? null : DateTime.tryParse(text);
  }

  String _datePayload(dynamic value) {
    if (value is! DateTime) return '';
    return '${value.year.toString().padLeft(4, '0')}-${value.month.toString().padLeft(2, '0')}-${value.day.toString().padLeft(2, '0')}';
  }

  Future<void> _editGoal(Map<String, dynamic> goal) async {
    final id = (goal['id'] as num?)?.toInt();
    if (id == null) return;
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
            submitLabel: context.l10n.saveGoal,
            fields: [
              DynamicFieldConfig(
                key: 'name',
                label: context.l10n.name,
                required: true,
                initialValue: goal['name'],
              ),
              DynamicFieldConfig(
                key: 'descripcion',
                label: context.l10n.description,
                type: DynamicFieldType.multiline,
                maxLines: 3,
                initialValue: goal['descripcion'],
              ),
              DynamicFieldConfig(
                key: 'indicador',
                label: context.l10n.indicator,
                initialValue: goal['indicador'],
              ),
              DynamicFieldConfig(
                key: 'valor_objetivo',
                label: context.l10n.targetValue,
                initialValue: goal['valor_objetivo'],
              ),
              DynamicFieldConfig(
                key: 'valor_real',
                label: context.l10n.actualValue,
                initialValue: goal['valor_real'],
              ),
              DynamicFieldConfig(
                key: 'tipo',
                label: context.l10n.type,
                type: DynamicFieldType.select,
                initialValue: goal['tipo'] ?? 'calidad',
                options: [
                  DynamicFieldOption(
                    value: 'calidad',
                    label: context.l10n.quality,
                  ),
                  DynamicFieldOption(value: 'prl', label: 'PRL'),
                ],
              ),
              DynamicFieldConfig(
                key: 'estado',
                label: context.l10n.status,
                type: DynamicFieldType.select,
                initialValue: goal['estado'] ?? 'pendiente',
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
                    label: context.l10n.completedFeminine,
                  ),
                ],
              ),
              DynamicFieldConfig(
                key: 'fecha_inicio',
                label: context.l10n.startDate,
                type: DynamicFieldType.date,
                initialValue: _dateValue(goal['fecha_inicio']),
              ),
              DynamicFieldConfig(
                key: 'fecha_fin',
                label: context.l10n.endDate,
                type: DynamicFieldType.date,
                initialValue: _dateValue(goal['fecha_fin']),
              ),
              DynamicFieldConfig(
                key: 'observaciones',
                label: context.l10n.observations,
                type: DynamicFieldType.multiline,
                maxLines: 3,
                initialValue: goal['observaciones'],
              ),
            ],
            onSubmit: (values) async {
              final payload = <String, dynamic>{
                'name': values['name'],
                'descripcion': values['descripcion'],
                'indicador': values['indicador'],
                'estado': values['estado'],
                'observaciones': values['observaciones'],
                if (values['valor_objetivo'].toString().trim().isNotEmpty)
                  'valor_objetivo': double.tryParse(
                    values['valor_objetivo'].toString().replaceAll(',', '.'),
                  ),
                if (values['valor_real'].toString().trim().isNotEmpty)
                  'valor_real': double.tryParse(
                    values['valor_real'].toString().replaceAll(',', '.'),
                  ),
                if (_datePayload(values['fecha_inicio']).isNotEmpty)
                  'fecha_inicio': _datePayload(values['fecha_inicio']),
                if (_datePayload(values['fecha_fin']).isNotEmpty)
                  'fecha_fin': _datePayload(values['fecha_fin']),
                'tipo': values['tipo'],
              };
              if (_odoo.isPortalSession) {
                await _portalApi.action(
                  'goal_update',
                  recordId: id,
                  values: payload,
                );
              } else {
                await _odoo.write('calidad.objetivo', id, payload);
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
    final completed = _rows
        .where((e) => (e['estado'] ?? '').toString() == 'realizado')
        .length;
    final progress = _rows.isEmpty ? 0.0 : completed / _rows.length;
    return AppScaffold(
      title: context.l10n.goals,
      actions: [
        if (auth.canEditModule('goals'))
          IconButton(onPressed: _createGoal, icon: Icon(Icons.add_rounded)),
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
          : ListView(
              children: [
                AppCard(
                  child: Row(
                    children: [
                      SizedBox(
                        width: 72,
                        height: 72,
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            CircularProgressIndicator(
                              value: progress,
                              strokeWidth: 8,
                              backgroundColor: AppTheme.elevatedFor(context),
                            ),
                            Center(
                              child: Text(
                                '${(progress * 100).toStringAsFixed(0)}%',
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  color: AppTheme.textPrimaryFor(context),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              context.l10n.overallProgress,
                              style: TextStyle(
                                color: AppTheme.textSecondaryFor(context),
                              ),
                            ),
                            Text(
                              context.l10n.goalsProgress(
                                completed,
                                _rows.length,
                              ),
                              style: TextStyle(
                                color: AppTheme.textPrimaryFor(context),
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                if (_rows.isEmpty)
                  AppEmptyState(
                    title: context.l10n.noGoals,
                    subtitle: context.l10n.noGoalsHint,
                    icon: Icons.flag_outlined,
                  ),
                ..._rows.map((goal) {
                  // Odoo puede serializar un Float como número o como texto
                  // según el controlador/versión. Nunca dejemos que un valor
                  // válido de la API rompa el árbol de widgets.
                  final pct =
                      OdooValues.number(
                        goal['avance'],
                      ).clamp(0, 100).toDouble() /
                      100;
                  final estado = (goal['estado'] ?? 'pendiente').toString();
                  final color = estado == 'realizado'
                      ? AppTheme.success
                      : estado == 'en_proceso'
                      ? AppTheme.info
                      : AppTheme.warning;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: AppCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  (goal['name'] ?? '').toString(),
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    color: AppTheme.textPrimaryFor(context),
                                  ),
                                ),
                              ),
                              AppStatusChip(
                                label: estado.replaceAll('_', ' '),
                                color: color,
                              ),
                              if (auth.canEditModule('goals'))
                                IconButton(
                                  tooltip: context.l10n.edit,
                                  onPressed: () => _editGoal(goal),
                                  icon: Icon(Icons.edit_outlined, size: 19),
                                ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          LinearProgressIndicator(value: pct, minHeight: 6),
                        ],
                      ),
                    ),
                  );
                }),
              ],
            ),
    );
  }
}
