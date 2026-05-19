import 'package:flutter/material.dart';

import '../../features/forms/dynamic_form.dart';
import '../../services/odoo_service.dart';
import '../../theme/app_theme.dart';

class SuggestionsScreen extends StatefulWidget {
  const SuggestionsScreen({super.key});

  @override
  State<SuggestionsScreen> createState() => _SuggestionsScreenState();
}

class _SuggestionsScreenState extends State<SuggestionsScreen> {
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
        'calidad.comunicacion',
        domain: const [['tipo', '=', 'sugerencia']],
        fields: const ['name', 'descripcion', 'fecha', 'estado'],
        order: 'fecha desc, id desc',
        limit: 80,
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
            submitLabel: 'Enviar sugerencia',
            fields: const [
              DynamicFieldConfig(key: 'name', label: 'Título', required: true),
              DynamicFieldConfig(key: 'descripcion', label: 'Descripción', required: true, type: DynamicFieldType.multiline, maxLines: 4),
            ],
            onSubmit: (values) async {
              await _odoo.create('calidad.comunicacion', {
                'name': values['name'],
                'tipo': 'sugerencia',
                'descripcion': values['descripcion'],
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
        title: const Text('Sugerencias'),
        actions: [
          IconButton(onPressed: _openCreate, icon: const Icon(Icons.add_comment_rounded)),
          IconButton(onPressed: _load, icon: const Icon(Icons.refresh_rounded)),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Padding(padding: const EdgeInsets.all(16), child: Text(_error!)))
              : _rows.isEmpty
                  ? const Center(child: Text('Sin sugerencias enviadas.', style: TextStyle(color: AppTheme.textMuted)))
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
                      itemCount: _rows.length,
                      separatorBuilder: (_, i) => const SizedBox(height: 8),
                      itemBuilder: (_, i) {
                        final it = _rows[i];
                        return Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppTheme.surfaceCard,
                            borderRadius: AppTheme.radiusMd,
                            border: Border.all(color: AppTheme.divider.withValues(alpha: 0.6)),
                          ),
                          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text((it['name'] ?? '').toString(), style: const TextStyle(fontWeight: FontWeight.w700)),
                            const SizedBox(height: 4),
                            Text((it['descripcion'] ?? '').toString(), maxLines: 3, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                            const SizedBox(height: 4),
                            Text('Estado: ${it['estado'] ?? '-'} · ${it['fecha'] ?? ''}', style: const TextStyle(fontSize: 11, color: AppTheme.textMuted)),
                          ]),
                        );
                      },
                    ),
    );
  }
}
