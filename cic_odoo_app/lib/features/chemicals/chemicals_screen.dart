import 'package:flutter/material.dart';
import 'package:open_filex/open_filex.dart';
import 'package:provider/provider.dart';

import '../../app/screens/document_viewer_screen.dart';
import '../../features/forms/dynamic_form.dart';
import '../../providers/auth_provider.dart';
import '../../services/attachment_service.dart';
import '../../services/odoo_service.dart';
import '../../services/odoo_values.dart';
import '../../theme/app_theme.dart';

class ChemicalsScreen extends StatefulWidget {
  const ChemicalsScreen({super.key});

  @override
  State<ChemicalsScreen> createState() => _ChemicalsScreenState();
}

class _ChemicalsScreenState extends State<ChemicalsScreen> {
  final OdooService _odoo = OdooService();
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
      final rows = await _odoo.searchRead(
        'calidad.quimico',
        fields: const [
          'name',
          'tipo',
          'codigo',
          'fecha_caducidad',
          'es_peligroso',
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
              await _odoo.create('calidad.quimico', payload);
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
            Text(
              'Caducidad: ${OdooValues.string(it['fecha_caducidad'], fallback: '-')}',
            ),
          ],
        ),
      ),
    );
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
