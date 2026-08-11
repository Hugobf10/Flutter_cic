import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../app/ui/app_components.dart';
import '../../features/forms/dynamic_form.dart';
import '../../features/incidents/incidence_detail_screen.dart';
import '../../providers/auth_provider.dart';
import '../../services/odoo_service.dart';
import '../../services/odoo_values.dart';
import '../../services/portal_api_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/section_header.dart';

/// Pantalla de listado de incidencias de calidad (calidad.incidencia).
class IncidenciasScreen extends StatefulWidget {
  const IncidenciasScreen({super.key});

  @override
  State<IncidenciasScreen> createState() => _IncidenciasScreenState();
}

class _IncidenciasScreenState extends State<IncidenciasScreen> {
  final OdooService _odoo = OdooService();
  final PortalApiService _portalApi = PortalApiService();
  String _filtroEstado = 'todas';
  bool _portalLoading = false;
  String? _portalError;
  List<Map<String, dynamic>> _portalRows = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    _loadPortalData();
  }

  Future<void> _loadPortalData() async {
    if (!mounted) return;
    setState(() {
      _portalLoading = true;
      _portalError = null;
    });
    try {
      final rows = await _portalApi.section('incidents', limit: 200);
      final filtered = _filtroEstado == 'todas'
          ? rows
          : rows.where((row) => row['estado']?.toString() == _filtroEstado).toList();
      if (!mounted) return;
      setState(() {
        _portalRows = filtered.map((row) => Map<String, dynamic>.from(row)).toList();
        _portalLoading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _portalError = OdooService.prettyError(error);
        _portalLoading = false;
      });
    }
  }

  Future<void> _openCreateDialog() async {
    final partnerId = context.read<AuthProvider>().partnerId;
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
            submitLabel: 'Crear incidencia',
            fields: const [
              DynamicFieldConfig(key: 'name', label: 'Título', required: true),
              DynamicFieldConfig(
                key: 'tipo',
                label: 'Tipo',
                type: DynamicFieldType.select,
                initialValue: 'nc',
                required: true,
                options: [
                  DynamicFieldOption(value: 'nc', label: 'No conformidad'),
                  DynamicFieldOption(
                    value: 'om',
                    label: 'Oportunidad de mejora',
                  ),
                ],
              ),
              DynamicFieldConfig(
                key: 'categoria',
                label: 'Categoría',
                type: DynamicFieldType.select,
                initialValue: 'calidad',
                required: true,
                options: [
                  DynamicFieldOption(value: 'calidad', label: 'Calidad'),
                  DynamicFieldOption(value: 'prl', label: 'PRL'),
                ],
              ),
              DynamicFieldConfig(
                key: 'subtipo',
                label: 'Subtipo',
                type: DynamicFieldType.select,
                initialValue: 'interna',
                required: true,
                options: [
                  DynamicFieldOption(value: 'interna', label: 'Interna'),
                  DynamicFieldOption(value: 'proveedor', label: 'Proveedor'),
                  DynamicFieldOption(value: 'auditoria', label: 'Auditoría'),
                  DynamicFieldOption(
                    value: 'reclamacion',
                    label: 'Reclamación',
                  ),
                  DynamicFieldOption(value: 'otra', label: 'Otra'),
                ],
              ),
              DynamicFieldConfig(
                key: 'fecha',
                label: 'Fecha',
                type: DynamicFieldType.date,
                required: true,
              ),
              DynamicFieldConfig(
                key: 'descripcion',
                label: 'Descripción',
                type: DynamicFieldType.multiline,
                maxLines: 4,
              ),
            ],
            onSubmit: (values) async {
              final date = values['fecha'] as DateTime?;
              final y = date?.year.toString().padLeft(4, '0');
              final m = date?.month.toString().padLeft(2, '0');
              final d = date?.day.toString().padLeft(2, '0');
              final payload = <String, dynamic>{
                'name': values['name'],
                'tipo': values['tipo'],
                'categoria': values['categoria'],
                'subtipo': values['subtipo'],
                'descripcion': values['descripcion'],
                'partner_id': partnerId,
                if (date != null) 'fecha': '$y-$m-$d',
              };
              if (_odoo.isPortalSession) {
                await _portalApi.action('incident_create', values: payload);
              } else {
                await _odoo.create('calidad.incidencia', payload);
              }
            },
          ),
        );
      },
    );

    if (created == true) {
      _loadData();
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    return Scaffold(
      backgroundColor: AppTheme.surface,
      appBar: AppBar(
        title: const Text('Incidencias'),
        actions: [
          if (auth.canEditModule('incidents'))
            IconButton(
              icon: const Icon(Icons.add_rounded),
              onPressed: _openCreateDialog,
            ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _loadData,
          ),
        ],
      ),
      body: Column(
        children: [
          _buildFilterChips(),
          Expanded(child: _buildPortalList()),
        ],
      ),
    );
  }

  Widget _buildFilterChips() {
    final filters = {
      'todas': 'Todas',
      'abierta': 'Abiertas',
      'en_proceso': 'En proceso',
      'cerrada': 'Cerradas',
    };
    return Container(
      height: 52,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: filters.entries.map((e) {
          final selected = _filtroEstado == e.key;
          return Padding(
            padding: const EdgeInsets.only(right: 8, top: 8, bottom: 8),
            child: FilterChip(
              label: Text(e.value),
              selected: selected,
              onSelected: (_) {
                setState(() => _filtroEstado = e.key);
                _loadData();
              },
              selectedColor: AppTheme.primary.withValues(alpha: 0.2),
              checkmarkColor: AppTheme.primary,
              labelStyle: TextStyle(
                color: selected ? AppTheme.primary : AppTheme.textSecondary,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                fontSize: 13,
              ),
              backgroundColor: AppTheme.surfaceCard,
              side: BorderSide(
                color: selected
                    ? AppTheme.primary.withValues(alpha: 0.5)
                    : AppTheme.divider,
              ),
              shape: RoundedRectangleBorder(borderRadius: AppTheme.radiusXl),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildPortalList() {
    if (_portalLoading && _portalRows.isEmpty) {
      return const AppLoadingView();
    }
    if (_portalError != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, color: AppTheme.danger, size: 40),
            const SizedBox(height: 8),
            Text(_portalError!, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            ElevatedButton(onPressed: _loadPortalData, child: const Text('Reintentar')),
          ],
        ),
      );
    }
    if (_portalRows.isEmpty) {
      return const Center(child: Text('No hay incidencias.', style: TextStyle(color: AppTheme.textMuted)));
    }
    return RefreshIndicator(
      onRefresh: _loadPortalData,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 100),
        itemCount: _portalRows.length + 1,
        itemBuilder: (_, index) => index == 0
            ? SectionHeader(title: '${_portalRows.length} incidencias', subtitle: 'De tu unidad, ordenadas por fecha')
            : _buildCard(_portalRows[index - 1]),
      ),
    );
  }

  Widget _buildCard(Map<String, dynamic> inc) {
    final id = (inc['id'] as num?)?.toInt();
    final tipo = inc['tipo']?.toString() ?? '';
    final estado = inc['estado']?.toString() ?? '';
    final avance = OdooValues.number(inc['avance']);
    final unidad = inc['unidad_id'] is List
        ? (inc['unidad_id'] as List).last?.toString() ?? ''
        : '';

    Color estadoColor;
    switch (estado) {
      case 'abierta':
        estadoColor = AppTheme.danger;
        break;
      case 'en_proceso':
        estadoColor = AppTheme.warning;
        break;
      case 'cerrada':
        estadoColor = AppTheme.success;
        break;
      default:
        estadoColor = AppTheme.textMuted;
    }

    return InkWell(
      borderRadius: AppTheme.radiusMd,
      onTap: id == null
          ? null
          : () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => IncidenceDetailScreen(id: id),
                ),
              );
            },
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.surfaceCard,
          borderRadius: AppTheme.radiusMd,
          border: Border.all(color: AppTheme.divider.withValues(alpha: 0.5)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: (tipo == 'nc' ? AppTheme.danger : AppTheme.info)
                        .withValues(alpha: 0.15),
                    borderRadius: AppTheme.radiusXl,
                  ),
                  child: Text(
                    tipo == 'nc' ? 'NC' : 'OM',
                    style: TextStyle(
                      color: tipo == 'nc' ? AppTheme.danger : AppTheme.info,
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: estadoColor.withValues(alpha: 0.15),
                    borderRadius: AppTheme.radiusXl,
                  ),
                  child: Text(
                    estado.replaceAll('_', ' '),
                    style: TextStyle(
                      color: estadoColor,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const Spacer(),
                Text(
                  inc['fecha']?.toString() ?? '',
                  style: const TextStyle(
                    color: AppTheme.textMuted,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              inc['name']?.toString() ?? '',
              style: const TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (unidad.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                unidad,
                style: const TextStyle(color: AppTheme.textMuted, fontSize: 11),
              ),
            ],
            if (avance > 0) ...[
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: ClipRRect(
                      borderRadius: AppTheme.radiusXl,
                      child: LinearProgressIndicator(
                        value: avance / 100,
                        backgroundColor: AppTheme.divider,
                        valueColor: AlwaysStoppedAnimation(
                          avance >= 100 ? AppTheme.success : AppTheme.primary,
                        ),
                        minHeight: 5,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${avance.toStringAsFixed(0)}%',
                    style: const TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
