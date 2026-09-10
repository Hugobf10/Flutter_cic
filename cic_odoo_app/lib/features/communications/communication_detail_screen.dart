import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app/ui/app_components.dart';
import '../../l10n/strings.dart';
import '../forms/dynamic_form.dart';
import '../../providers/auth_provider.dart';
import '../../services/attachment_service.dart';
import '../../services/odoo_service.dart';
import '../../services/portal_api_service.dart';
import '../../services/odoo_values.dart';

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
    final unavailableMessage = context.uiText(
      'La comunicación no está disponible.',
      'The communication is not available.',
    );
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
      if (rows.isEmpty) throw StateError(unavailableMessage);
      _record = rows.first;
    } catch (error) {
      _error = OdooService.prettyError(error);
    }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _edit() async {
    final record = _record;
    if (record == null) return;
    final requiresWorkflow = OdooValues.boolValue(
      record['requiere_tramitacion'],
      fallback: true,
    );
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
          submitLabel: context.uiText('Guardar cambios', 'Save changes'),
          fields: [
            DynamicFieldConfig(
              key: 'name',
              label: context.l10n.title,
              required: true,
              initialValue: record['name'],
            ),
            DynamicFieldConfig(
              key: 'tipo',
              label: context.l10n.type,
              type: DynamicFieldType.select,
              required: true,
              initialValue: record['tipo'],
              options: [
                DynamicFieldOption(
                  value: 'sugerencia',
                  label: context.l10n.suggestion,
                ),
                DynamicFieldOption(
                  value: 'comunicacion',
                  label: context.l10n.communication,
                ),
              ],
            ),
            DynamicFieldConfig(
              key: 'fecha',
              label: context.l10n.date,
              type: DynamicFieldType.date,
              initialValue: _asDate(record['fecha']),
              required: true,
            ),
            DynamicFieldConfig(
              key: 'descripcion',
              label: context.l10n.description,
              type: DynamicFieldType.multiline,
              required: true,
              maxLines: 4,
              initialValue: record['descripcion'],
            ),
            if (requiresWorkflow)
              DynamicFieldConfig(
                key: 'analisis',
                label: context.uiText('Análisis', 'Analysis'),
                type: DynamicFieldType.multiline,
                maxLines: 4,
                initialValue: record['analisis'],
              ),
            if (requiresWorkflow)
              DynamicFieldConfig(
                key: 'tratamiento',
                label: context.uiText(
                  'Tratamiento previsto',
                  'Planned treatment',
                ),
                type: DynamicFieldType.multiline,
                maxLines: 4,
                initialValue: record['tratamiento'],
              ),
            if (requiresWorkflow)
              DynamicFieldConfig(
                key: 'respuesta',
                label: context.uiText(
                  'Respuesta al trabajador',
                  'Response to employee',
                ),
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
                if (requiresWorkflow) 'analisis': values['analisis'],
                if (requiresWorkflow) 'tratamiento': values['tratamiento'],
                if (requiresWorkflow) 'respuesta': values['respuesta'],
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
        appBar: AppBar(title: Text(context.l10n.communication)),
        body: Center(
          child: Text(
            _error ??
                context.uiText(
                  'No se encontró el registro.',
                  'Record not found.',
                ),
          ),
        ),
      );
    }

    final record = _record!;
    final state = (record['estado'] ?? 'recibida').toString();
    final requiresWorkflow = OdooValues.boolValue(
      record['requiere_tramitacion'],
      fallback: true,
    );
    final canEdit = auth.canEditModule('communications');
    final canSend = auth.canSendCommunications;
    final responseSent = record['respuesta_enviada'] == true;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          context.uiText('Detalle de comunicación', 'Communication details'),
        ),
        actions: [
          if (canEdit)
            IconButton(
              tooltip: context.l10n.edit,
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
              _chip('${context.l10n.type}: ${_typeLabel(record['tipo'])}'),
              if (requiresWorkflow)
                _chip('${context.l10n.status}: ${_stateLabel(state)}'),
              _chip('${context.l10n.date}: ${record['fecha'] ?? '-'}'),
            ],
          ),
          if (canEdit && requiresWorkflow) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (state == 'recibida')
                  _actionButton(
                    context.uiText('Pasar a análisis', 'Move to analysis'),
                    'communication_mark_en_analisis',
                  ),
                if (state == 'en_analisis')
                  _actionButton(
                    context.uiText('Marcar tratada', 'Mark as handled'),
                    'communication_mark_tratada',
                  ),
                if (!responseSent && state != 'cerrada')
                  _actionButton(
                    context.uiText('Enviar respuesta', 'Send response'),
                    'communication_send_response',
                  ),
                if ((state == 'tratada' || state == 'respondida') &&
                    state != 'cerrada')
                  _actionButton(
                    context.uiText('Cerrar', 'Close'),
                    'communication_close',
                  ),
              ],
            ),
          ],
          if (canSend &&
              record['notificacion_enviada'] != true &&
              (_many2oneLabels(record['destino_unidad_ids']).isNotEmpty ||
                  _many2oneLabels(record['destino_puesto_ids']).isNotEmpty))
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: _actionButton(
                context.uiText('Enviar notificación', 'Send notification'),
                'communication_send_notification',
              ),
            ),
          _section(context.l10n.description, record['descripcion']),
          if (requiresWorkflow)
            _section(
              context.uiText('Análisis', 'Analysis'),
              record['analisis'],
            ),
          if (requiresWorkflow)
            _section(
              context.uiText('Tratamiento previsto', 'Planned treatment'),
              record['tratamiento'],
            ),
          if (requiresWorkflow)
            _section(
              context.uiText('Respuesta', 'Response'),
              record['respuesta'],
            ),
          _recipientSummary(record),
          const SizedBox(height: 12),
          Text(
            context.uiText('Documentos', 'Documents'),
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 4),
          ..._attachmentTiles(record['attachment_ids']),
          if (canEdit)
            Align(
              alignment: Alignment.centerLeft,
              child: OutlinedButton.icon(
                onPressed: _uploadAttachment,
                icon: Icon(Icons.attach_file_rounded),
                label: Text(context.uiText('Subir archivo', 'Upload file')),
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
          Text(OdooValues.string(value, fallback: '—')),
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
          Text(
            context.uiText('Destinatarios', 'Recipients'),
            style: Theme.of(context).textTheme.titleMedium,
          ),
          if (units.isNotEmpty)
            _recipientLine(context.uiText('Unidades', 'Units'), units),
          if (posts.isNotEmpty)
            _recipientLine(
              context.uiText('Puestos funcionales', 'Functional positions'),
              posts,
            ),
          Text(
            sent
                ? context.uiText(
                    'Notificación enviada por correo y disponible en la aplicación.',
                    'Notification sent by email and available in the app.',
                  )
                : context.uiText(
                    'Notificación pendiente de envío.',
                    'Notification pending delivery.',
                  ),
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
      return [
        Text(
          context.uiText('Sin documentos', 'No documents'),
          style: TextStyle(color: Colors.grey),
        ),
      ];
    }
    return raw.whereType<List>().map((item) {
      final name = item.length > 1
          ? item[1].toString()
          : context.uiText('Archivo', 'File');
      return ListTile(
        contentPadding: EdgeInsets.zero,
        leading: Icon(Icons.insert_drive_file_outlined),
        title: Text(name),
      );
    }).toList();
  }

  Widget _chip(String text) => Chip(label: Text(text));

  String _stateLabel(String state) => switch (state) {
    'recibida' => context.uiText('Recibida', 'Received'),
    'en_analisis' => context.uiText('En análisis', 'In analysis'),
    'tratada' => context.uiText('Tratada', 'Handled'),
    'respondida' => context.uiText('Respondida', 'Answered'),
    'cerrada' => context.uiText('Cerrada', 'Closed'),
    _ => state,
  };

  String _typeLabel(dynamic value) => switch (value?.toString()) {
    'sugerencia' => context.l10n.suggestion,
    'comunicacion' => context.l10n.communication,
    null || '' => '-',
    _ => value.toString(),
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
