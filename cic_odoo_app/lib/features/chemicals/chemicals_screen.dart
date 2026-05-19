import 'package:flutter/material.dart';

import '../../features/forms/dynamic_form.dart';
import '../../services/odoo_service.dart';
import '../../theme/app_theme.dart';

class ChemicalsScreen extends StatefulWidget {
  const ChemicalsScreen({super.key});

  @override
  State<ChemicalsScreen> createState() => _ChemicalsScreenState();
}

class _ChemicalsScreenState extends State<ChemicalsScreen> {
  final OdooService _odoo = OdooService();
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
      final rows = await _odoo.searchRead(
        'calidad.quimico',
        fields: const ['name', 'tipo', 'codigo', 'fecha_caducidad', 'es_peligroso', 'unidad_id'],
        order: 'fecha_caducidad asc, id desc',
        limit: 160,
      );
      _rows = rows.map((e) => Map<String, dynamic>.from(e as Map)).toList();
    } catch (e) {
      _error = e.toString();
    }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _openCreate() async {
    final created = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.fromLTRB(16, 8, 16, 16 + MediaQuery.of(ctx).viewInsets.bottom),
          child: DynamicForm(
            submitLabel: 'Registrar químico',
            fields: const [
              DynamicFieldConfig(key: 'name', label: 'Nombre', required: true),
              DynamicFieldConfig(key: 'codigo', label: 'Código'),
              DynamicFieldConfig(key: 'tipo', label: 'Tipo'),
              DynamicFieldConfig(key: 'fecha_caducidad', label: 'Fecha caducidad', type: DynamicFieldType.date),
            ],
            onSubmit: (values) async {
              final date = values['fecha_caducidad'] as DateTime?;
              final y = date?.year.toString().padLeft(4, '0');
              final m = date?.month.toString().padLeft(2, '0');
              final d = date?.day.toString().padLeft(2, '0');
              await _odoo.create('calidad.quimico', {
                'name': values['name'],
                'codigo': values['codigo'],
                'tipo': (values['tipo']?.toString().trim().isEmpty ?? true) ? 'otro' : values['tipo'],
                if (date != null) 'fecha_caducidad': '$y-$m-$d',
              });
            },
          ),
        );
      },
    );
    if (created == true) _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Químicos'),
        actions: [
          IconButton(onPressed: _openCreate, icon: const Icon(Icons.add_rounded)),
          IconButton(onPressed: _load, icon: const Icon(Icons.refresh_rounded)),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Padding(padding: const EdgeInsets.all(16), child: Text(_error!)))
              : _rows.isEmpty
                  ? const Center(child: Text('Sin productos químicos.', style: TextStyle(color: AppTheme.textMuted)))
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
                      itemCount: _rows.length,
                      separatorBuilder: (_, i) => const SizedBox(height: 8),
                      itemBuilder: (_, i) {
                        final it = _rows[i];
                        final unidad = it['unidad_id'] is List ? it['unidad_id'][1].toString() : '';
                        return Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppTheme.surfaceCard,
                            borderRadius: AppTheme.radiusMd,
                            border: Border.all(color: AppTheme.divider.withValues(alpha: 0.6)),
                          ),
                          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text((it['name'] ?? '').toString(), style: const TextStyle(fontWeight: FontWeight.w700)),
                            Text('Tipo: ${it['tipo'] ?? '-'} · Peligroso: ${it['es_peligroso'] == true ? 'Sí' : 'No'}', style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                            if ((it['fecha_caducidad'] ?? '').toString().isNotEmpty)
                              Text('Caducidad: ${it['fecha_caducidad']}', style: const TextStyle(fontSize: 12, color: AppTheme.textMuted)),
                            if (unidad.isNotEmpty)
                              Text('Unidad: $unidad', style: const TextStyle(fontSize: 12, color: AppTheme.textMuted)),
                          ]),
                        );
                      },
                    ),
    );
  }
}
