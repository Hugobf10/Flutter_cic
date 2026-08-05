import 'package:flutter/material.dart';
import 'package:open_filex/open_filex.dart';
import 'package:provider/provider.dart';

import '../../app/screens/document_viewer_screen.dart';
import '../../features/forms/dynamic_form.dart';
import '../../providers/auth_provider.dart';
import '../../services/attachment_service.dart';
import '../../services/odoo_service.dart';
import '../../services/odoo_values.dart';
import '../../services/portal_api_service.dart';
import '../../theme/app_theme.dart';

class ChemicalsScreen extends StatefulWidget {
  const ChemicalsScreen({super.key});

  @override
  State<ChemicalsScreen> createState() => _ChemicalsScreenState();
}

class _ChemicalsScreenState extends State<ChemicalsScreen> {
  final OdooService _odoo = OdooService();
  final PortalApiService _portalApi = PortalApiService();
  final AttachmentService _attachments = AttachmentService();
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
          ? await _portalApi.section('chemicals', limit: 160)
          : await _odoo.searchRead(
              'calidad.quimico',
              fields: const [
                'name',
                'tipo',
                'codigo',
                'referencia',
                'descripcion',
                'almacenamiento',
                'fecha_caducidad',
                'unidades',
                'a_punto_agotarse',
                'es_peligroso',
                'categoria_peligro',
                'peligrosidad',
                'frases_h',
                'frases_p',
                'unidad_id',
                'ficha_seguridad_attachment_id',
              ],
              order: 'fecha_caducidad asc, id desc',
              limit: 160,
            );
      _rows = rows.whereType<Map>().map(Map<String, dynamic>.from).toList();
    } catch (e) {
      _error = OdooService.prettyError(e);
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
          padding: EdgeInsets.fromLTRB(
            16,
            8,
            16,
            16 + MediaQuery.of(ctx).viewInsets.bottom,
          ),
          child: DynamicForm(
            submitLabel: 'Registrar químico',
            fields: const [
              DynamicFieldConfig(key: 'name', label: 'Nombre', required: true),
              DynamicFieldConfig(key: 'codigo', label: 'Código'),
              DynamicFieldConfig(key: 'tipo', label: 'Tipo'),
              DynamicFieldConfig(
                key: 'fecha_caducidad',
                label: 'Fecha caducidad',
                type: DynamicFieldType.date,
              ),
            ],
            onSubmit: (values) async {
              final date = values['fecha_caducidad'] as DateTime?;
              final y = date?.year.toString().padLeft(4, '0');
              final m = date?.month.toString().padLeft(2, '0');
              final d = date?.day.toString().padLeft(2, '0');
              final name = values['name']?.toString().trim() ?? '';
              if (name.isEmpty) {
                throw const FormatException(
                  'El nombre del químico es obligatorio.',
                );
              }
              final code = values['codigo']?.toString().trim() ?? '';
              final type = values['tipo']?.toString().trim() ?? '';
              final unitId = OdooValues.many2oneId(
                context.read<AuthProvider>().partnerProfile['unidad_id'],
              );
              final payload = <String, dynamic>{
                'name': name,
                if (code.isNotEmpty) 'codigo': code,
                if (type.isNotEmpty) 'tipo': type,
                if (date != null) 'fecha_caducidad': '$y-$m-$d',
              };
              if (unitId != null) payload['unidad_id'] = unitId;
              if (_odoo.isPortalSession) {
                await _portalApi.action('chemical_create', values: payload);
              } else {
                await _odoo.create('calidad.quimico', payload);
              }
            },
          ),
        );
      },
    );
    if (created == true) _load();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Químicos'),
        actions: [
          if (auth.canEditModule('chemicals'))
            IconButton(
              onPressed: _openCreate,
              icon: const Icon(Icons.add_rounded),
            ),
          IconButton(onPressed: _load, icon: const Icon(Icons.refresh_rounded)),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(_error!),
              ),
            )
          : _rows.isEmpty
          ? const Center(
              child: Text(
                'Sin productos químicos.',
                style: TextStyle(color: AppTheme.textMuted),
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
              itemCount: _rows.length,
              separatorBuilder: (_, i) => const SizedBox(height: 8),
              itemBuilder: (_, i) {
                final it = _rows[i];
                final unidad = OdooValues.many2oneLabel(it['unidad_id']);
                return Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceCard,
                    borderRadius: AppTheme.radiusMd,
                    border: Border.all(
                      color: AppTheme.divider.withValues(alpha: 0.6),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        (it['name'] ?? '').toString(),
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      Text(
                        'Tipo: ${OdooValues.string(it['tipo'], fallback: '-')} · Peligroso: ${OdooValues.boolValue(it['es_peligroso']) ? 'Sí' : 'No'}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                      if (OdooValues.string(it['fecha_caducidad']).isNotEmpty)
                        Text(
                          'Caducidad: ${OdooValues.string(it['fecha_caducidad'])}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppTheme.textMuted,
                          ),
                        ),
                      if (unidad.isNotEmpty)
                        Text(
                          'Unidad: $unidad',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppTheme.textMuted,
                          ),
                        ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          OutlinedButton.icon(
                            onPressed: () => _openDetails(it),
                            icon: const Icon(
                              Icons.info_outline_rounded,
                              size: 16,
                            ),
                            label: const Text('Detalle'),
                          ),
                          const SizedBox(width: 8),
                          OutlinedButton.icon(
                            onPressed: () => _openSafetySheet(it),
                            icon: const Icon(
                              Icons.description_outlined,
                              size: 16,
                            ),
                            label: const Text('Ficha'),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }

  Future<void> _openDetails(Map<String, dynamic> it) async {
    if (!mounted) return;
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              (it['name'] ?? '').toString(),
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text('Código: ${OdooValues.string(it['codigo'], fallback: '-')}'),
            Text('Tipo: ${OdooValues.string(it['tipo'], fallback: '-')}'),
            Text(
              'Peligroso: ${OdooValues.boolValue(it['es_peligroso']) ? 'Sí' : 'No'}',
            ),
            Text('Caducidad: ${OdooValues.string(it['fecha_caducidad'], fallback: '-')}'),
            if (context.read<AuthProvider>().canEditModule('chemicals')) ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.of(context).pop();
                    _openEdit(it);
                  },
                  icon: const Icon(Icons.edit_outlined),
                  label: const Text('Editar químico'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  DateTime? _dateValue(dynamic value) {
    final text = value?.toString() ?? '';
    return text.isEmpty ? null : DateTime.tryParse(text);
  }

  String _datePayload(dynamic value) {
    if (value is! DateTime) return '';
    return '${value.year.toString().padLeft(4, '0')}-${value.month.toString().padLeft(2, '0')}-${value.day.toString().padLeft(2, '0')}';
  }

  Future<void> _openEdit(Map<String, dynamic> chemical) async {
    final id = (chemical['id'] as num?)?.toInt();
    if (id == null) return;
    final edited = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(16, 8, 16, 16 + MediaQuery.of(ctx).viewInsets.bottom),
        child: SingleChildScrollView(
          child: DynamicForm(
            submitLabel: 'Guardar químico',
            fields: [
              DynamicFieldConfig(key: 'name', label: 'Nombre', required: true, initialValue: chemical['name']),
              DynamicFieldConfig(key: 'codigo', label: 'Código', initialValue: chemical['codigo']),
              DynamicFieldConfig(key: 'referencia', label: 'Referencia', initialValue: chemical['referencia']),
              DynamicFieldConfig(key: 'tipo', label: 'Tipo', type: DynamicFieldType.select, initialValue: chemical['tipo'] ?? 'reactivo', options: const [DynamicFieldOption(value: 'reactivo', label: 'Reactivo'), DynamicFieldOption(value: 'producto', label: 'Producto'), DynamicFieldOption(value: 'otro', label: 'Otro')]),
              DynamicFieldConfig(key: 'descripcion', label: 'Descripción', type: DynamicFieldType.multiline, maxLines: 3, initialValue: chemical['descripcion']),
              DynamicFieldConfig(key: 'almacenamiento', label: 'Almacenamiento', type: DynamicFieldType.multiline, maxLines: 2, initialValue: chemical['almacenamiento']),
              DynamicFieldConfig(key: 'fecha_caducidad', label: 'Fecha de caducidad', type: DynamicFieldType.date, initialValue: _dateValue(chemical['fecha_caducidad'])),
              DynamicFieldConfig(key: 'unidades', label: 'Unidades', initialValue: chemical['unidades']),
              DynamicFieldConfig(key: 'a_punto_agotarse', label: 'A punto de agotarse', type: DynamicFieldType.select, initialValue: OdooValues.boolValue(chemical['a_punto_agotarse']), options: const [DynamicFieldOption(value: false, label: 'No'), DynamicFieldOption(value: true, label: 'Sí')]),
              DynamicFieldConfig(key: 'es_peligroso', label: 'Peligroso', type: DynamicFieldType.select, initialValue: OdooValues.boolValue(chemical['es_peligroso']), options: const [DynamicFieldOption(value: false, label: 'No'), DynamicFieldOption(value: true, label: 'Sí')]),
              DynamicFieldConfig(key: 'categoria_peligro', label: 'Categoría de peligro', type: DynamicFieldType.select, initialValue: chemical['categoria_peligro'], options: const [DynamicFieldOption(value: 'explosivo', label: 'Explosivo'), DynamicFieldOption(value: 'inflamable', label: 'Inflamable'), DynamicFieldOption(value: 'toxico', label: 'Tóxico'), DynamicFieldOption(value: 'corrosivo', label: 'Corrosivo'), DynamicFieldOption(value: 'peligro_ambiental', label: 'Ambiental'), DynamicFieldOption(value: 'otro', label: 'Otro')]),
              DynamicFieldConfig(key: 'peligrosidad', label: 'Peligrosidad', type: DynamicFieldType.multiline, maxLines: 2, initialValue: chemical['peligrosidad']),
              DynamicFieldConfig(key: 'frases_h', label: 'Frases H', initialValue: chemical['frases_h']),
              DynamicFieldConfig(key: 'frases_p', label: 'Frases P', initialValue: chemical['frases_p']),
            ],
            onSubmit: (values) async {
              final payload = <String, dynamic>{
                'name': values['name'],
                'codigo': values['codigo'],
                'referencia': values['referencia'],
                'tipo': values['tipo'],
                'descripcion': values['descripcion'],
                'almacenamiento': values['almacenamiento'],
                'unidades': double.tryParse(values['unidades'].toString().replaceAll(',', '.')) ?? 0,
                'a_punto_agotarse': values['a_punto_agotarse'],
                'es_peligroso': values['es_peligroso'],
                'categoria_peligro': values['categoria_peligro'],
                'peligrosidad': values['peligrosidad'],
                'frases_h': values['frases_h'],
                'frases_p': values['frases_p'],
                if (_datePayload(values['fecha_caducidad']).isNotEmpty) 'fecha_caducidad': _datePayload(values['fecha_caducidad']),
              };
              if (_odoo.isPortalSession) {
                await _portalApi.action('chemical_update', recordId: id, values: payload);
              } else {
                await _odoo.write('calidad.quimico', id, payload);
              }
            },
          ),
        ),
      ),
    );
    if (edited == true) _load();
  }

  Future<void> _openSafetySheet(Map<String, dynamic> it) async {
    try {
      final attachmentId = OdooValues.many2oneId(
        it['ficha_seguridad_attachment_id'],
      );
      if (attachmentId == null) {
        throw Exception('No hay fichas de seguridad adjuntas.');
      }
      final file = await _attachments.fetchAttachmentToCache(
        attachmentId: attachmentId,
        defaultName: 'ficha_seguridad_${it['id']}',
      );
      if (!mounted) return;
      if (file.mimeType.contains('pdf') || file.mimeType.startsWith('image/')) {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => DocumentViewerScreen(
              file: file.file,
              title: file.name,
              mimeType: file.mimeType,
            ),
          ),
        );
      } else {
        await OpenFilex.open(file.file.path);
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('No se pudo abrir la ficha: $e')));
    }
  }
}
