import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app/ui/app_components.dart';
import '../forms/dynamic_form.dart';
import '../../providers/auth_provider.dart';
import '../../services/attachment_service.dart';
import '../../services/odoo_service.dart';
import '../../services/portal_api_service.dart';

class CommunicationDetailScreen extends StatefulWidget {
  const CommunicationDetailScreen({super.key, required this.id});

  final int id;

  @override
  State<CommunicationDetailScreen> createState() =>
      _CommunicationDetailScreenState();
}

class _CommunicationDetailScreenState extends State<CommunicationDetailScreen> {
  final PortalApiService _portalApi = PortalApiService();
  final AttachmentService _attachments = AttachmentService();
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
      var rows = <Map<String, dynamic>>[];
      try {
        rows = await _portalApi.section(
          'communications',
          recordId: widget.id,
          limit: 1,
        );
      } catch (_) {}
      if (rows.isEmpty) {
        rows = await _portalApi.section(
          'suggestions',
          recordId: widget.id,
          limit: 1,
        );
      }
      if (rows.isEmpty) throw StateError('La comunicación no está disponible.');
      _record = rows.first;
    } catch (error) {
      _error = OdooService.prettyError(error);
    }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _edit() async {
    final record = _record;
    if (record == null) return;
    final edited = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (ctx) => Padding(
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
              key: 'name',
              label: 'Título',
              required: true,
              initialValue: record['name'],
            ),
            DynamicFieldConfig(
              key: 'tipo',
              label: 'Tipo',
              type: DynamicFieldType.select,
              required: true,
              initialValue: record['tipo'],
              options: const [
                DynamicFieldOption(value: 'sugerencia', label: 'Sugerencia'),
                DynamicFieldOption(
                  value: 'comunicacion',
                  label: 'Comunicación',
                ),
              ],
            ),
            DynamicFieldConfig(
              key: 'fecha',
              label: 'Fecha',
              type: DynamicFieldType.date,
              initialValue: _asDate(record['fecha']),
              required: true,
            ),
            DynamicFieldConfig(
              key: 'descripcion',
              label: 'Descripción',
              type: DynamicFieldType.multiline,
              required: true,
              maxLines: 4,
              initialValue: record['descripcion'],
            ),
            DynamicFieldConfig(
              key: 'analisis',
              label: 'Análisis',
              type: DynamicFieldType.multiline,
              maxLines: 4,
              initialValue: record['analisis'],
            ),
            DynamicFieldConfig(
              key: 'tratamiento',
              label: 'Tratamiento previsto',
              type: DynamicFieldType.multiline,
              maxLines: 4,
              initialValue: record['tratamiento'],
            ),
            DynamicFieldConfig(
              key: 'respuesta',
              label: 'Respuesta al trabajador',
              type: DynamicFieldType.multiline,
              maxLines: 4,
              initialValue: record['respuesta'],
            ),
          ],
          onSubmit: (values) async {
            await _portalApi.action(
              'communication_update',
              recordId: widget.id,
              values: {
                'name': values['name'],
                'tipo': values['tipo'],
                'fecha': _dateString(values['fecha']),
                'descripcion': values['descripcion'],
                'analisis': values['analisis'],
                'tratamiento': values['tratamiento'],
                'respuesta': values['respuesta'],
              },
            );
          },
        ),
      ),
    );
    if (edited == true) await _load();
  }

  Future<void> _runAction(String action) async {
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

  Future<void> _uploadAttachment() async {
    final picked = await _attachments.pickAnyFile();
    if (picked == null) return;
    try {
      await _portalApi.action(
        'communication_attachment_create',
        recordId: widget.id,
        values: {
          'name': picked.name,
          'mimetype': picked.mimeType,
          'datas': picked.base64Data,
        },
      );
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
    if (_error != null || _record == null) {
      return Scaffold(
        appBar: AppBar(title: Text('Comunicación')),
        body: Center(child: Text(_error ?? 'No se encontró el registro.')),
      );
    }

    final record = _record!;
    final state = (record['estado'] ?? 'recibida').toString();
    final canEdit = auth.canEditModule('communications');
    final responseSent = record['respuesta_enviada'] == true;

    return Scaffold(
      appBar: AppBar(
        title: Text('Detalle de comunicación'),
        actions: [
          if (canEdit)
            IconButton(
              tooltip: 'Editar',
              onPressed: _edit,
              icon: Icon(Icons.edit_rounded),
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
        children: [
          Text(
            record['name']?.toString() ?? '-',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [
              _chip('Tipo: ${record['tipo'] ?? '-'}'),
              _chip('Estado: ${_stateLabel(state)}'),
              _chip('Fecha: ${record['fecha'] ?? '-'}'),
            ],
          ),
          if (canEdit) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (state == 'recibida')
                  _actionButton(
                    'Pasar a análisis',
                    'communication_mark_en_analisis',
                  ),
                if (state == 'en_analisis')
                  _actionButton('Marcar tratada', 'communication_mark_tratada'),
                if (!responseSent && state != 'cerrada')
                  _actionButton(
                    'Enviar respuesta',
                    'communication_send_response',
                  ),
                if (record['notificacion_enviada'] != true &&
                    (_many2oneLabels(record['destino_unidad_ids']).isNotEmpty ||
                        _many2oneLabels(
                          record['destino_puesto_ids'],
                        ).isNotEmpty))
                  _actionButton(
                    'Enviar notificación',
                    'communication_send_notification',
                  ),
                if ((state == 'tratada' || state == 'respondida') &&
                    state != 'cerrada')
                  _actionButton('Cerrar', 'communication_close'),
              ],
            ),
          ],
          _section('Descripción', record['descripcion']),
          _section('Análisis', record['analisis']),
          _section('Tratamiento previsto', record['tratamiento']),
          _section('Respuesta', record['respuesta']),
          _recipientSummary(record),
          const SizedBox(height: 12),
          Text('Documentos', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 4),
          ..._attachmentTiles(record['attachment_ids']),
          if (canEdit)
            Align(
              alignment: Alignment.centerLeft,
              child: OutlinedButton.icon(
                onPressed: _uploadAttachment,
                icon: Icon(Icons.attach_file_rounded),
                label: Text('Subir archivo'),
              ),
            ),
        ],
      ),
    );
  }

  Widget _actionButton(String label, String action) {
    return OutlinedButton(
      onPressed: () => _runAction(action),
      child: Text(label),
    );
  }

  Widget _section(String title, dynamic value) {
    return Padding(
      padding: const EdgeInsets.only(top: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 4),
          Text(
            (value?.toString().trim().isNotEmpty ?? false)
                ? value.toString()
                : '-',
          ),
        ],
      ),
    );
  }

  Widget _recipientSummary(Map<String, dynamic> record) {
    final units = _many2oneLabels(record['destino_unidad_ids']);
    final posts = _many2oneLabels(record['destino_puesto_ids']);
    final sent = record['notificacion_enviada'] == true;
    if (units.isEmpty && posts.isEmpty && !sent) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Destinatarios', style: Theme.of(context).textTheme.titleMedium),
          if (units.isNotEmpty) _recipientLine('Unidades', units),
          if (posts.isNotEmpty) _recipientLine('Puestos funcionales', posts),
          Text(
            sent
                ? 'Notificación enviada por correo y disponible en la aplicación.'
                : 'Notificación pendiente de envío.',
            style: TextStyle(color: Colors.grey.shade700),
          ),
        ],
      ),
    );
  }

  Widget _recipientLine(String title, List<String> values) {
    return Padding(
      padding: const EdgeInsets.only(top: 5),
      child: Text('$title: ${values.join(', ')}'),
    );
  }

  List<String> _many2oneLabels(dynamic raw) {
    if (raw is! List) return const [];
    return raw
        .whereType<List>()
        .where((item) => item.length > 1)
        .map((item) => item[1].toString())
        .toList();
  }

  List<Widget> _attachmentTiles(dynamic raw) {
    if (raw is! List || raw.isEmpty) {
      return [Text('Sin documentos', style: TextStyle(color: Colors.grey))];
    }
    return raw.whereType<List>().map((item) {
      final name = item.length > 1 ? item[1].toString() : 'Archivo';
      return ListTile(
        contentPadding: EdgeInsets.zero,
        leading: Icon(Icons.insert_drive_file_outlined),
        title: Text(name),
      );
    }).toList();
  }

  Widget _chip(String text) => Chip(label: Text(text));

  String _stateLabel(String state) => switch (state) {
    'recibida' => 'Recibida',
    'en_analisis' => 'En análisis',
    'tratada' => 'Tratada',
    'respondida' => 'Respondida',
    'cerrada' => 'Cerrada',
    _ => state,
  };

  DateTime? _asDate(dynamic value) =>
      DateTime.tryParse(value?.toString() ?? '');

  String? _dateString(dynamic value) {
    if (value is! DateTime) return null;
    final y = value.year.toString().padLeft(4, '0');
    final m = value.month.toString().padLeft(2, '0');
    final d = value.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }
}
