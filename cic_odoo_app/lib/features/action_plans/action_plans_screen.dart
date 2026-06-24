import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app/ui/app_components.dart';
import '../../providers/auth_provider.dart';
import '../../services/odoo_service.dart';
import '../../theme/app_theme.dart';

class ActionPlansScreen extends StatefulWidget {
  const ActionPlansScreen({super.key});

  @override
  State<ActionPlansScreen> createState() => _ActionPlansScreenState();
}

class _ActionPlansScreenState extends State<ActionPlansScreen> {
  final OdooService _odoo = OdooService();
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
      final goals = await _odoo.searchRead(
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
      final rows = await _odoo.searchRead(
        'calidad.plan.accion',
        fields: const [
          'name',
          'descripcion',
          'estado',
          'objetivo_id',
          'fecha_fin',
          'responsable_id',
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
                  await _odoo.create('calidad.plan.accion', {
                    'name': nameCtrl.text.trim(),
                    'descripcion': descCtrl.text.trim(),
                    'estado': estado,
                    'objetivo_id': goalId,
                    'responsable_id': auth.partnerId,
                  });
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

  Future<void> _updateStatus(int id, String current) async {
    final next = current == 'pendiente'
        ? 'en_proceso'
        : current == 'en_proceso'
        ? 'realizado'
        : 'pendiente';
    try {
      await _odoo.write('calidad.plan.accion', id, {'estado': next});
      _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('No se pudo actualizar: $e')));
    }
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
          ? const Center(child: CircularProgressIndicator())
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
                final id = (row['id'] as num).toInt();
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
                    onTap: auth.canEditModule('action_plans')
                        ? () => _updateStatus(id, estado)
                        : null,
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
