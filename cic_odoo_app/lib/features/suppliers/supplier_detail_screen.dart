import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app/ui/app_components.dart';
import '../../features/forms/dynamic_form.dart';
import '../../providers/auth_provider.dart';
import '../../services/odoo_service.dart';
import '../../services/portal_api_service.dart';
import '../../theme/app_theme.dart';

class SupplierDetailScreen extends StatefulWidget {
  const SupplierDetailScreen({super.key, required this.id});

  final int id;

  @override
  State<SupplierDetailScreen> createState() => _SupplierDetailScreenState();
}

class _SupplierDetailScreenState extends State<SupplierDetailScreen> {
  final PortalApiService _portalApi = PortalApiService();
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
      final rows = await _portalApi.section(
        'suppliers',
        recordId: widget.id,
        limit: 1,
      );
      if (rows.isEmpty) throw StateError('El proveedor no está disponible.');
      _record = rows.first;
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
                key: 'fecha_homologacion',
                label: 'Fecha de homologación',
                type: DynamicFieldType.date,
                initialValue: _asDate(_record!['fecha_homologacion']),
              ),
              DynamicFieldConfig(
                key: 'fecha_desestimacion',
                label: 'Fecha de desestimación',
                type: DynamicFieldType.date,
                initialValue: _asDate(_record!['fecha_desestimacion']),
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
              await _portalApi.action(
                'supplier_update',
                recordId: widget.id,
                values: {
                  'fecha_homologacion': _dateString(
                    values['fecha_homologacion'],
                  ),
                  'fecha_desestimacion': _dateString(
                    values['fecha_desestimacion'],
                  ),
                  'motivo_homologacion': values['motivo_homologacion'],
                  'motivo_desestimacion': values['motivo_desestimacion'],
                  'observaciones': values['observaciones'],
                },
              );
            },
          ),
        );
      },
    );

    if (created == true) await _load();
  }

  Future<void> _changeState(String action) async {
    try {
      await _portalApi.action(action, recordId: widget.id);
      await _load();
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(OdooService.prettyError(error))));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    if (_loading) {
      return const Scaffold(body: AppLoadingView());
    }
    if (_error != null) {
      return Scaffold(
        appBar: AppBar(title: Text('Proveedor')),
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
        title: Text('Detalle proveedor'),
        actions: [
          if (auth.canEditModule('suppliers'))
            IconButton(onPressed: _edit, icon: Icon(Icons.edit_rounded)),
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
              _stateLabel(estado),
              style: TextStyle(
                color: estado == 'homologado'
                    ? AppTheme.success
                    : AppTheme.danger,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          if (auth.canEditModule('suppliers')) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              children: [
                if (estado == 'homologado')
                  OutlinedButton(
                    onPressed: () => _changeState('supplier_reject'),
                    child: Text('Desestimar'),
                  ),
                if (estado == 'desestimado')
                  OutlinedButton(
                    onPressed: () => _changeState('supplier_reactivate'),
                    child: Text('Reactivar'),
                  ),
              ],
            ),
          ],
          const SizedBox(height: 12),
          Text('Unidad', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 4),
          Text(_many2oneLabel(r['unidad_id'])),
          const SizedBox(height: 12),
          Text('Fechas', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 4),
          Text('Homologación: ${r['fecha_homologacion'] ?? '-'}'),
          Text('Desestimación: ${r['fecha_desestimacion'] ?? '-'}'),
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
          const SizedBox(height: 12),
          Text('Historial', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 4),
          Text('Movimientos registrados: ${r['historial_count'] ?? 0}'),
          Text('Último movimiento: ${r['ultima_fecha_evento'] ?? '-'}'),
        ],
      ),
    );
  }

  DateTime? _asDate(dynamic value) {
    if (value is DateTime) return value;
    return DateTime.tryParse(value?.toString() ?? '');
  }

  String _stateLabel(String state) => switch (state) {
    'homologado' => 'Homologado',
    'desestimado' => 'Desestimado',
    _ => state,
  };

  String _many2oneLabel(dynamic value) {
    if (value is List && value.length > 1) return value[1].toString();
    return value?.toString() ?? '-';
  }

  String? _dateString(dynamic value) {
    if (value is! DateTime) return null;
    final y = value.year.toString().padLeft(4, '0');
    final m = value.month.toString().padLeft(2, '0');
    final d = value.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }
}
