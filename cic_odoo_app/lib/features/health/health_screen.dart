import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app/ui/app_components.dart';
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
      final rows = _odoo.isPortalSession
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
      _rows = rows.map((e) => Map<String, dynamic>.from(e as Map)).toList();
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
      title: 'Vigilancia de la salud',
      actions: [
        if (auth.canEditModule('health'))
          IconButton(onPressed: _newForm, icon: const Icon(Icons.add_rounded)),
        IconButton(onPressed: _load, icon: const Icon(Icons.refresh_rounded)),
      ],
      child: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? AppEmptyState(
              title: 'Error',
              subtitle: _error!,
              icon: Icons.error_outline_rounded,
            )
          : _rows.isEmpty
          ? const AppEmptyState(
              title: 'Sin formularios',
              subtitle: 'No hay reconocimientos registrados.',
              icon: Icons.monitor_heart_outlined,
            )
          : ListView.separated(
              itemCount: _rows.length,
              separatorBuilder: (_, _) => const SizedBox(height: 8),
              itemBuilder: (_, i) {
                final it = _rows[i];
                final estado = (it['estado'] ?? '-').toString();
                final color = estado == 'apto'
                    ? AppTheme.success
                    : estado == 'apto_limitaciones'
                    ? AppTheme.warning
                    : estado == 'no_apto'
                    ? AppTheme.error
                    : AppTheme.textMuted;
                return AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              (it['name'] ?? 'Reconocimiento').toString(),
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          AppStatusChip(
                            label: estado.replaceAll('_', ' '),
                            color: color,
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Prevista: ${it['fecha_prevista'] ?? '-'}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                      Text(
                        'Realización: ${it['fecha_realizacion'] ?? '-'}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }
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
      ).showSnackBar(SnackBar(content: Text('No se pudo enviar: $e')));
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
                child: Text(_step < 2 ? 'Siguiente' : 'Enviar'),
              ),
              const SizedBox(width: 8),
              if (_step > 0)
                OutlinedButton(
                  onPressed: _saving ? null : details.onStepCancel,
                  child: const Text('Atrás'),
                ),
            ],
          );
        },
        steps: [
          Step(
            title: const Text('Fecha'),
            isActive: _step >= 0,
            content: AppCard(
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      _plannedDate == null
                          ? 'Sin fecha'
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
                    child: const Text('Elegir'),
                  ),
                ],
              ),
            ),
          ),
          Step(
            title: const Text('Estado'),
            isActive: _step >= 1,
            content: DropdownButtonFormField<String>(
              initialValue: _estado,
              items: const [
                DropdownMenuItem(value: 'pendiente', child: Text('Pendiente')),
                DropdownMenuItem(
                  value: 'no_realizado',
                  child: Text('No realizado'),
                ),
                DropdownMenuItem(value: 'apto', child: Text('Apto')),
                DropdownMenuItem(
                  value: 'apto_limitaciones',
                  child: Text('Apto con limitaciones'),
                ),
                DropdownMenuItem(value: 'no_apto', child: Text('No apto')),
              ],
              onChanged: (v) => setState(() => _estado = v ?? 'pendiente'),
              decoration: const InputDecoration(
                labelText: 'Estado del reconocimiento',
              ),
            ),
          ),
          Step(
            title: const Text('Observaciones'),
            isActive: _step >= 2,
            content: Column(
              children: [
                AppInput(
                  controller: _obsCtrl,
                  labelText: 'Observaciones',
                  prefixIcon: Icons.notes_rounded,
                ),
                const SizedBox(height: 8),
                AppInput(
                  controller: _recCtrl,
                  labelText: 'Recomendaciones',
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
