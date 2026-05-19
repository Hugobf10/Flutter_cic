import 'package:flutter/material.dart';

import '../../features/forms/dynamic_form.dart';
import '../../services/odoo_service.dart';
import '../../theme/app_theme.dart';

class IncidenceDetailScreen extends StatefulWidget {
  const IncidenceDetailScreen({super.key, required this.id});

  final int id;

  @override
  State<IncidenceDetailScreen> createState() => _IncidenceDetailScreenState();
}

class _IncidenceDetailScreenState extends State<IncidenceDetailScreen> {
  final OdooService _odoo = OdooService();
  bool _loading = true;
  Map<String, dynamic>? _record;
  String? _error;

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
      _record = await _odoo.read(
        'calidad.incidencia',
        widget.id,
        fields: [
          'name',
          'descripcion',
          'tipo',
          'categoria',
          'subtipo',
          'fecha',
          'estado',
          'avance',
          'analisis',
          'tratamiento',
          'requiere_accion_correctiva',
        ],
      );
    } catch (e) {
      _error = e.toString();
    }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _edit() async {
    if (_record == null) return;
    final created = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.fromLTRB(16, 8, 16, 16 + MediaQuery.of(ctx).viewInsets.bottom),
          child: DynamicForm(
            submitLabel: 'Guardar cambios',
            fields: [
              DynamicFieldConfig(key: 'name', label: 'Título', required: true, initialValue: _record!['name']),
              DynamicFieldConfig(
                key: 'tipo',
                label: 'Tipo',
                type: DynamicFieldType.select,
                initialValue: _record!['tipo'],
                required: true,
                options: const [
                  DynamicFieldOption(value: 'nc', label: 'No conformidad'),
                  DynamicFieldOption(value: 'om', label: 'Oportunidad de mejora'),
                ],
              ),
              DynamicFieldConfig(
                key: 'categoria',
                label: 'Categoría',
                type: DynamicFieldType.select,
                initialValue: _record!['categoria'],
                required: true,
                options: const [
                  DynamicFieldOption(value: 'calidad', label: 'Calidad'),
                  DynamicFieldOption(value: 'prl', label: 'PRL'),
                ],
              ),
              DynamicFieldConfig(
                key: 'subtipo',
                label: 'Subtipo',
                type: DynamicFieldType.select,
                initialValue: _record!['subtipo'],
                required: true,
                options: const [
                  DynamicFieldOption(value: 'interna', label: 'Interna'),
                  DynamicFieldOption(value: 'proveedor', label: 'Proveedor'),
                  DynamicFieldOption(value: 'auditoria', label: 'Auditoría'),
                  DynamicFieldOption(value: 'reclamacion', label: 'Reclamación'),
                  DynamicFieldOption(value: 'otra', label: 'Otra'),
                ],
              ),
              DynamicFieldConfig(
                key: 'estado',
                label: 'Estado',
                type: DynamicFieldType.select,
                initialValue: _record!['estado'],
                required: true,
                options: const [
                  DynamicFieldOption(value: 'abierta', label: 'Abierta'),
                  DynamicFieldOption(value: 'en_proceso', label: 'En proceso'),
                  DynamicFieldOption(value: 'cerrada', label: 'Cerrada'),
                ],
              ),
              DynamicFieldConfig(
                key: 'descripcion',
                label: 'Descripción',
                type: DynamicFieldType.multiline,
                initialValue: _record!['descripcion'],
                maxLines: 4,
              ),
              DynamicFieldConfig(
                key: 'analisis',
                label: 'Análisis',
                type: DynamicFieldType.multiline,
                initialValue: _record!['analisis'],
                maxLines: 4,
              ),
              DynamicFieldConfig(
                key: 'tratamiento',
                label: 'Tratamiento',
                type: DynamicFieldType.multiline,
                initialValue: _record!['tratamiento'],
                maxLines: 4,
              ),
            ],
            onSubmit: (values) async {
              await _odoo.write('calidad.incidencia', widget.id, {
                'name': values['name'],
                'tipo': values['tipo'],
                'categoria': values['categoria'],
                'subtipo': values['subtipo'],
                'estado': values['estado'],
                'descripcion': values['descripcion'],
                'analisis': values['analisis'],
                'tratamiento': values['tratamiento'],
              });
            },
          ),
        );
      },
    );

    if (created == true) await _load();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    if (_error != null) return Scaffold(appBar: AppBar(title: const Text('Incidencia')), body: Center(child: Text(_error!)));

    final r = _record!;
    final estado = (r['estado'] ?? '').toString();
    final avance = (r['avance'] as num?)?.toDouble() ?? 0;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalle incidencia'),
        actions: [IconButton(onPressed: _edit, icon: const Icon(Icons.edit_rounded))],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
        children: [
          Text(r['name']?.toString() ?? '-', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [
              _chip('Tipo: ${r['tipo'] ?? '-'}'),
              _chip('Estado: $estado'),
              _chip('Categoría: ${r['categoria'] ?? '-'}'),
            ],
          ),
          const SizedBox(height: 12),
          Text('Descripción', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 4),
          Text(r['descripcion']?.toString() ?? '-'),
          const SizedBox(height: 12),
          Text('Análisis', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 4),
          Text(r['analisis']?.toString() ?? '-'),
          const SizedBox(height: 12),
          Text('Tratamiento', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 4),
          Text(r['tratamiento']?.toString() ?? '-'),
          const SizedBox(height: 12),
          Text('Avance: ${avance.toStringAsFixed(0)}%'),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: AppTheme.radiusXl,
            child: LinearProgressIndicator(
              minHeight: 7,
              value: (avance / 100).clamp(0, 1),
              backgroundColor: AppTheme.divider,
              valueColor: AlwaysStoppedAnimation(estado == 'cerrada' ? AppTheme.success : AppTheme.primary),
            ),
          ),
        ],
      ),
    );
  }

  Widget _chip(String t) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(color: AppTheme.surfaceElevated, borderRadius: AppTheme.radiusXl),
        child: Text(t, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
      );
}
