import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../features/forms/dynamic_form.dart';
import '../../providers/auth_provider.dart';
import '../../services/odoo_service.dart';
import '../../theme/app_theme.dart';

class SupplierDetailScreen extends StatefulWidget {
  const SupplierDetailScreen({super.key, required this.id});

  final int id;

  @override
  State<SupplierDetailScreen> createState() => _SupplierDetailScreenState();
}

class _SupplierDetailScreenState extends State<SupplierDetailScreen> {
  final OdooService _odoo = OdooService();
  bool _loading = true;
  String? _error;
  Map<String, dynamic>? _record;

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
        'calidad.proveedor.unidad',
        widget.id,
        fields: [
          'partner_id',
          'estado',
          'fecha_homologacion',
          'fecha_desestimacion',
          'motivo_homologacion',
          'motivo_desestimacion',
          'observaciones',
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
          padding: EdgeInsets.fromLTRB(
            16,
            8,
            16,
            16 + MediaQuery.of(ctx).viewInsets.bottom,
          ),
          child: DynamicForm(
            submitLabel: 'Guardar cambios',
            fields: [
              DynamicFieldConfig(
                key: 'estado',
                label: 'Estado',
                type: DynamicFieldType.select,
                initialValue: _record!['estado'],
                required: true,
                options: const [
                  DynamicFieldOption(value: 'homologado', label: 'Homologado'),
                  DynamicFieldOption(
                    value: 'desestimado',
                    label: 'Desestimado',
                  ),
                ],
              ),
              DynamicFieldConfig(
                key: 'motivo_homologacion',
                label: 'Motivo homologación',
                type: DynamicFieldType.multiline,
                initialValue: _record!['motivo_homologacion'],
                maxLines: 3,
              ),
              DynamicFieldConfig(
                key: 'motivo_desestimacion',
                label: 'Motivo desestimación',
                type: DynamicFieldType.multiline,
                initialValue: _record!['motivo_desestimacion'],
                maxLines: 3,
              ),
              DynamicFieldConfig(
                key: 'observaciones',
                label: 'Observaciones',
                type: DynamicFieldType.multiline,
                initialValue: _record!['observaciones'],
                maxLines: 3,
              ),
            ],
            onSubmit: (values) async {
              await _odoo.write('calidad.proveedor.unidad', widget.id, {
                'estado': values['estado'],
                'motivo_homologacion': values['motivo_homologacion'],
                'motivo_desestimacion': values['motivo_desestimacion'],
                'observaciones': values['observaciones'],
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
    final auth = context.watch<AuthProvider>();
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (_error != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Proveedor')),
        body: Center(child: Text(_error!)),
      );
    }

    final r = _record!;
    final estado = (r['estado'] ?? '').toString();
    final proveedor = r['partner_id'] is List
        ? r['partner_id'][1].toString()
        : 'Proveedor';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalle proveedor'),
        actions: [
          if (auth.canEditModule('suppliers'))
            IconButton(onPressed: _edit, icon: const Icon(Icons.edit_rounded)),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
        children: [
          Text(proveedor, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color:
                  (estado == 'homologado' ? AppTheme.success : AppTheme.danger)
                      .withValues(alpha: 0.14),
              borderRadius: AppTheme.radiusXl,
            ),
            child: Text(
              estado,
              style: TextStyle(
                color: estado == 'homologado'
                    ? AppTheme.success
                    : AppTheme.danger,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Motivo homologación',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 4),
          Text(r['motivo_homologacion']?.toString() ?? '-'),
          const SizedBox(height: 12),
          Text(
            'Motivo desestimación',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 4),
          Text(r['motivo_desestimacion']?.toString() ?? '-'),
          const SizedBox(height: 12),
          Text('Observaciones', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 4),
          Text(r['observaciones']?.toString() ?? '-'),
        ],
      ),
    );
  }
}
