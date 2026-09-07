import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app/ui/app_components.dart';
import '../../l10n/strings.dart';
import '../../providers/auth_provider.dart';
import '../../services/odoo_service.dart';
import '../../services/portal_api_service.dart';
import '../../theme/app_theme.dart';

class HealthScreen extends StatefulWidget {
  const HealthScreen({super.key});

  @override
  State<HealthScreen> createState() => _HealthScreenState();
}

class _HealthScreenState extends State<HealthScreen> {
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
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final currentRows = _odoo.isPortalSession
          ? await _portalApi.section('health', limit: 120)
          : await _odoo.searchRead(
              'calidad.salud.reconocimiento',
              fields: const [
                'name',
                'fecha_prevista',
                'fecha_realizacion',
                'estado',
                'observaciones',
                'recomendaciones',
              ],
              order: 'fecha_prevista desc, id desc',
              limit: 120,
            );

      // The historical CIC module uses cic.salud.registro.  It is exposed
      // through the restricted mobile endpoint so a person can only see
      // their own historical records, just as in the intranet portal.
      var historyRows = <dynamic>[];
      try {
        historyRows = await _portalApi.section('health_history', limit: 120);
      } catch (_) {
        // The historical module is optional in existing installations.
      }

      _rows = [
        ...currentRows.map(
          (row) => <String, dynamic>{
            ...Map<String, dynamic>.from(row as Map),
            '_healthSource': 'current',
          },
        ),
        ...historyRows.map(
          (row) => <String, dynamic>{
            ...Map<String, dynamic>.from(row as Map),
            '_healthSource': 'history',
          },
        ),
      ];
      _rows.sort(
        (left, right) => _recordDate(right).compareTo(_recordDate(left)),
      );
    } catch (e) {
      _error = OdooService.prettyError(e);
    }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _newForm() async {
    final auth = context.read<AuthProvider>();
    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) =>
          _HealthMultiStepForm(partnerId: auth.partnerId, odoo: _odoo),
    );
    if (saved == true) _load();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    return AppScaffold(
      title: context.l10n.healthSurveillance,
      actions: [
        if (auth.canEditModule('health'))
          IconButton(onPressed: _newForm, icon: Icon(Icons.add_rounded)),
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
              title: context.l10n.noHealthForms,
              subtitle: context.l10n.noHealthFormsHint,
              icon: Icons.monitor_heart_outlined,
            )
          : ListView.separated(
              itemCount: _rows.length,
              separatorBuilder: (_, _) => const SizedBox(height: 8),
              itemBuilder: (_, i) {
                final it = _rows[i];
                final historical = it['_healthSource'] == 'history';
                final estado =
                    (historical ? it['salud_apto'] : it['estado'])
                        ?.toString() ??
                    '-';
                final color = _statusColor(estado, historical, context);
                final date = historical
                    ? it['salud_fecha_reconocimiento']
                    : it['fecha_realizacion'] ?? it['fecha_prevista'];
                final title = historical
                    ? context.l10n.historicalCicCheckup
                    : (it['name'] ?? context.l10n.healthCheckup).toString();
                return AppCard(
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
                          AppStatusChip(
                            label: _statusLabel(estado, context),
                            color: color,
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        historical
                            ? context.l10n.checkupDate('${date ?? '-'}')
                            : '${context.l10n.scheduled('${it['fecha_prevista'] ?? '-'}')}\n'
                                  '${context.l10n.realisationDate('${it['fecha_realizacion'] ?? '-'}')}',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppTheme.textSecondaryFor(context),
                        ),
                      ),
                      if (historical &&
                          (it['salud_empresa']?.toString().isNotEmpty ?? false))
                        Text(
                          it['salud_empresa'].toString(),
                          style: TextStyle(
                            fontSize: 12,
                            color: AppTheme.textSecondaryFor(context),
                          ),
                        ),
                    ],
                  ),
                );
              },
            ),
    );
  }

  String _recordDate(Map<String, dynamic> record) {
    final historical = record['_healthSource'] == 'history';
    return (historical
                ? record['salud_fecha_reconocimiento']
                : record['fecha_realizacion'] ?? record['fecha_prevista'])
            ?.toString() ??
        '';
  }

  Color _statusColor(String status, bool historical, BuildContext context) {
    if (historical) {
      return switch (status) {
        'si' => AppTheme.success,
        'no' => AppTheme.error,
        'pendiente' => AppTheme.warning,
        _ => AppTheme.textMutedFor(context),
      };
    }
    return switch (status) {
      'apto' => AppTheme.success,
      'apto_limitaciones' => AppTheme.warning,
      'no_apto' => AppTheme.error,
      _ => AppTheme.textMutedFor(context),
    };
  }

  String _statusLabel(String status, BuildContext context) => switch (status) {
    'si' || 'apto' => context.l10n.fit,
    'no' || 'no_apto' => context.l10n.notFit,
    'no_realizado' => context.l10n.notCompleted,
    'apto_limitaciones' => context.l10n.fitWithLimitations,
    _ => status.replaceAll('_', ' '),
  };
}

class _HealthMultiStepForm extends StatefulWidget {
  const _HealthMultiStepForm({required this.partnerId, required this.odoo});

  final int partnerId;
  final OdooService odoo;

  @override
  State<_HealthMultiStepForm> createState() => _HealthMultiStepFormState();
}

class _HealthMultiStepFormState extends State<_HealthMultiStepForm> {
  int _step = 0;
  bool _saving = false;
  DateTime? _plannedDate = DateTime.now();
  String _estado = 'pendiente';
  final TextEditingController _obsCtrl = TextEditingController();
  final TextEditingController _recCtrl = TextEditingController();

  @override
  void dispose() {
    _obsCtrl.dispose();
    _recCtrl.dispose();
    super.dispose();
  }

  String _dateToString(DateTime d) {
    final y = d.year.toString().padLeft(4, '0');
    final m = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    return '$y-$m-$day';
  }

  Future<void> _submit() async {
    if (_plannedDate == null) return;
    setState(() => _saving = true);
    try {
      await widget.odoo.create('calidad.salud.reconocimiento', {
        'partner_id': widget.partnerId,
        'fecha_prevista': _dateToString(_plannedDate!),
        'estado': _estado,
        'observaciones': _obsCtrl.text.trim(),
        'recomendaciones': _recCtrl.text.trim(),
      });
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(context.l10n.couldNotSend('$e'))));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        8,
        0,
        8,
        8 + MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Stepper(
        currentStep: _step,
        onStepContinue: () {
          if (_step < 2) {
            setState(() => _step += 1);
          } else {
            _submit();
          }
        },
        onStepCancel: () {
          if (_step > 0) setState(() => _step -= 1);
        },
        controlsBuilder: (context, details) {
          return Row(
            children: [
              ElevatedButton(
                onPressed: _saving ? null : details.onStepContinue,
                child: Text(_step < 2 ? context.l10n.next : context.l10n.send),
              ),
              const SizedBox(width: 8),
              if (_step > 0)
                OutlinedButton(
                  onPressed: _saving ? null : details.onStepCancel,
                  child: Text(context.l10n.back),
                ),
            ],
          );
        },
        steps: [
          Step(
            title: Text(context.l10n.date),
            isActive: _step >= 0,
            content: AppCard(
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      _plannedDate == null
                          ? context.l10n.noDate
                          : _dateToString(_plannedDate!),
                    ),
                  ),
                  TextButton(
                    onPressed: () async {
                      final now = DateTime.now();
                      final date = await showDatePicker(
                        context: context,
                        initialDate: _plannedDate ?? now,
                        firstDate: DateTime(now.year - 2),
                        lastDate: DateTime(now.year + 3),
                      );
                      if (date != null) setState(() => _plannedDate = date);
                    },
                    child: Text(context.l10n.choose),
                  ),
                ],
              ),
            ),
          ),
          Step(
            title: Text(context.l10n.status),
            isActive: _step >= 1,
            content: DropdownButtonFormField<String>(
              initialValue: _estado,
              items: [
                DropdownMenuItem(
                  value: 'pendiente',
                  child: Text(context.l10n.pending),
                ),
                DropdownMenuItem(
                  value: 'no_realizado',
                  child: Text(context.l10n.notCompleted),
                ),
                DropdownMenuItem(value: 'apto', child: Text(context.l10n.fit)),
                DropdownMenuItem(
                  value: 'apto_limitaciones',
                  child: Text(context.l10n.fitWithLimitations),
                ),
                DropdownMenuItem(
                  value: 'no_apto',
                  child: Text(context.l10n.notFit),
                ),
              ],
              onChanged: (v) => setState(() => _estado = v ?? 'pendiente'),
              decoration: InputDecoration(
                labelText: context.l10n.healthCheckupStatus,
              ),
            ),
          ),
          Step(
            title: Text(context.l10n.observations),
            isActive: _step >= 2,
            content: Column(
              children: [
                AppInput(
                  controller: _obsCtrl,
                  labelText: context.l10n.observations,
                  prefixIcon: Icons.notes_rounded,
                ),
                const SizedBox(height: 8),
                AppInput(
                  controller: _recCtrl,
                  labelText: context.l10n.recommendations,
                  prefixIcon: Icons.health_and_safety_rounded,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
