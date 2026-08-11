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
  bool _editing = false;
  bool _changingState = false;
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
      _error = OdooService.prettyError(e);
    }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _edit() async {
    if (_record == null || _editing) return;
    setState(() => _editing = true);
    final edited = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (ctx) {
        return SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(
            20,
            4,
            20,
            20 + MediaQuery.of(ctx).viewInsets.bottom,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _SupplierFormHeader(),
              const SizedBox(height: 18),
              DynamicForm(
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
            ],
          ),
        );
      },
    );

    if (mounted) setState(() => _editing = false);
    if (edited == true) await _load();
  }

  Future<void> _changeState(String action) async {
    if (_changingState) return;
    setState(() => _changingState = true);
    try {
      await _portalApi.action(action, recordId: widget.id);
      await _load();
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(OdooService.prettyError(error))));
      }
    } finally {
      if (mounted) setState(() => _changingState = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final canEdit = auth.canEditModule('suppliers');

    return AppScaffold(
      title: 'Proveedor',
      actions: [
        if (!_loading)
          IconButton(
            tooltip: 'Actualizar',
            onPressed: _load,
            icon: Icon(Icons.refresh_rounded),
          ),
        if (canEdit && _record != null)
          IconButton(
            tooltip: 'Editar proveedor',
            onPressed: _editing ? null : _edit,
            icon: _editing
                ? const AppLoadingIndicator(size: 22)
                : Icon(Icons.edit_rounded),
          ),
      ],
      child: _loading
          ? const AppLoadingView(label: 'Cargando proveedor')
          : _error != null
          ? AppEmptyState(
              title: 'No se pudo abrir el proveedor',
              subtitle: _error!,
              icon: Icons.cloud_off_rounded,
              action: AppButton.primary(label: 'Reintentar', onPressed: _load),
            )
          : _buildDetail(canEdit),
    );
  }

  Widget _buildDetail(bool canEdit) {
    final record = _record!;
    final state = (record['estado'] ?? '').toString();
    final homologated = state == 'homologado';
    final color = homologated ? AppTheme.success : AppTheme.danger;
    final supplier = _many2oneLabel(
      record['partner_id'],
      fallback: 'Proveedor',
    );
    final unit = _many2oneLabel(record['unidad_id']);
    final currentDate = homologated
        ? _display(record['fecha_homologacion'])
        : _display(record['fecha_desestimacion']);

    return ListView(
      padding: const EdgeInsets.only(bottom: 32),
      children: [
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppIconSurface(
                    icon: homologated
                        ? Icons.verified_rounded
                        : Icons.block_rounded,
                    color: color,
                    size: 56,
                    iconSize: 26,
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          supplier,
                          style: TextStyle(
                            color: AppTheme.textPrimaryFor(context),
                            fontSize: 22,
                            height: 1.12,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          unit == '-' ? 'Unidad no indicada' : unit,
                          style: TextStyle(
                            color: AppTheme.textSecondaryFor(context),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  AppStatusChip(label: _stateLabel(state), color: color),
                ],
              ),
              const SizedBox(height: 16),
              NeumorphicSurface(
                subtle: true,
                showBorder: false,
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                child: Row(
                  children: [
                    Icon(Icons.event_available_rounded, color: color, size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        currentDate == '-'
                            ? 'Sin fecha registrada para el estado actual'
                            : '${homologated ? 'Homologado' : 'Desestimado'} el $currentDate',
                        style: TextStyle(
                          color: AppTheme.textPrimaryFor(context),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              if (canEdit) ...[
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  child: AppButton.outline(
                    label: homologated
                        ? 'Desestimar proveedor'
                        : 'Reactivar proveedor',
                    icon: homologated
                        ? Icons.block_rounded
                        : Icons.restart_alt_rounded,
                    loading: _changingState,
                    onPressed: _changingState
                        ? null
                        : () => _changeState(
                            homologated
                                ? 'supplier_reject'
                                : 'supplier_reactivate',
                          ),
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 22),
        const AppSectionHeader(
          title: 'Ficha de homologación',
          subtitle: 'Información sincronizada con el registro de Odoo.',
        ),
        LayoutBuilder(
          builder: (context, constraints) {
            final dates = _SupplierDetailSection(
              icon: Icons.calendar_month_rounded,
              color: AppTheme.primary,
              title: 'Fechas y unidad',
              children: [
                _SupplierInfoRow(label: 'Unidad', value: unit),
                _SupplierInfoRow(
                  label: 'Fecha homologación',
                  value: _display(record['fecha_homologacion']),
                ),
                _SupplierInfoRow(
                  label: 'Fecha desestimación',
                  value: _display(record['fecha_desestimacion']),
                ),
              ],
            );
            final history = _SupplierDetailSection(
              icon: Icons.history_rounded,
              color: AppTheme.accent,
              title: 'Historial',
              children: [
                _SupplierInfoRow(
                  label: 'Movimientos',
                  value: _display(record['historial_count'], fallback: '0'),
                ),
                _SupplierInfoRow(
                  label: 'Último movimiento',
                  value: _display(record['ultima_fecha_evento']),
                ),
                _SupplierInfoRow(
                  label: 'Año homologación',
                  value: _display(record['anio_homologacion']),
                ),
                _SupplierInfoRow(
                  label: 'Año desestimación',
                  value: _display(record['anio_desestimacion']),
                ),
              ],
            );
            if (constraints.maxWidth < 720) {
              return Column(
                children: [dates, const SizedBox(height: 12), history],
              );
            }
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: dates),
                const SizedBox(width: 12),
                Expanded(child: history),
              ],
            );
          },
        ),
        const SizedBox(height: 12),
        _SupplierDetailSection(
          icon: homologated
              ? Icons.thumb_up_alt_rounded
              : Icons.do_not_disturb_alt_rounded,
          color: color,
          title: 'Motivos',
          children: [
            _SupplierTextBlock(
              label: 'Motivo de homologación',
              value: _display(record['motivo_homologacion']),
              highlighted: homologated,
            ),
            const SizedBox(height: 12),
            _SupplierTextBlock(
              label: 'Motivo de desestimación',
              value: _display(record['motivo_desestimacion']),
              highlighted: !homologated,
            ),
          ],
        ),
        const SizedBox(height: 12),
        _SupplierDetailSection(
          icon: Icons.notes_rounded,
          color: AppTheme.warning,
          title: 'Observaciones',
          children: [
            Text(
              _display(record['observaciones']),
              style: TextStyle(
                color: AppTheme.textSecondaryFor(context),
                height: 1.5,
              ),
            ),
          ],
        ),
      ],
    );
  }

  DateTime? _asDate(dynamic value) {
    if (value is DateTime) return value;
    return DateTime.tryParse(value?.toString() ?? '');
  }

  String _stateLabel(String state) => switch (state) {
    'homologado' => 'Homologado',
    'desestimado' => 'Desestimado',
    _ => state.isEmpty ? 'Sin estado' : state,
  };

  String? _dateString(dynamic value) {
    if (value is! DateTime) return null;
    final y = value.year.toString().padLeft(4, '0');
    final m = value.month.toString().padLeft(2, '0');
    final d = value.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }
}

class _SupplierDetailSection extends StatelessWidget {
  const _SupplierDetailSection({
    required this.icon,
    required this.color,
    required this.title,
    required this.children,
  });

  final IconData icon;
  final Color color;
  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              AppIconSurface(icon: icon, color: color, size: 42, iconSize: 19),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    color: AppTheme.textPrimaryFor(context),
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }
}

class _SupplierInfoRow extends StatelessWidget {
  const _SupplierInfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color: AppTheme.textSecondaryFor(context),
                fontSize: 12,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: TextStyle(
                color: AppTheme.textPrimaryFor(context),
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SupplierTextBlock extends StatelessWidget {
  const _SupplierTextBlock({
    required this.label,
    required this.value,
    required this.highlighted,
  });

  final String label;
  final String value;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    return NeumorphicSurface(
      subtle: true,
      showBorder: false,
      color: highlighted
          ? Color.alphaBlend(
              AppTheme.primary.withValues(
                alpha: AppTheme.isDark(context) ? 0.12 : 0.06,
              ),
              AppTheme.cardFor(context),
            )
          : null,
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: highlighted
                  ? AppTheme.primary
                  : AppTheme.textSecondaryFor(context),
              fontSize: 11,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              color: AppTheme.textPrimaryFor(context),
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }
}

class _SupplierFormHeader extends StatelessWidget {
  const _SupplierFormHeader();

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const AppIconSurface(
          icon: Icons.edit_note_rounded,
          color: AppTheme.primary,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Editar homologación',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 4),
              Text(
                'Actualiza las fechas, motivos y observaciones del registro.',
                style: TextStyle(color: AppTheme.textSecondaryFor(context)),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

String _many2oneLabel(dynamic value, {String fallback = '-'}) {
  if (value is List && value.length > 1) return value[1].toString();
  final text = value?.toString().trim() ?? '';
  return text.isEmpty || text == 'false' ? fallback : text;
}

String _display(dynamic value, {String fallback = '-'}) {
  final text = value?.toString().trim() ?? '';
  return text.isEmpty || text == 'false' || text == 'null' ? fallback : text;
}
