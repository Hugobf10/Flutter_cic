import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app/ui/app_components.dart';
import '../../features/forms/dynamic_form.dart';
import '../../providers/auth_provider.dart';
import '../../services/attachment_service.dart';
import '../../services/odoo_service.dart';
import '../../services/odoo_values.dart';
import '../../services/portal_api_service.dart';
import '../../theme/app_theme.dart';

class IncidenceDetailScreen extends StatefulWidget {
  const IncidenceDetailScreen({super.key, required this.id});

  final int id;

  @override
  State<IncidenceDetailScreen> createState() => _IncidenceDetailScreenState();
}

class _IncidenceDetailScreenState extends State<IncidenceDetailScreen> {
  final OdooService _odoo = OdooService();
  final PortalApiService _portalApi = PortalApiService();
  final AttachmentService _attachments = AttachmentService();
  bool _loading = true;
  Map<String, dynamic>? _record;
  String? _error;

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
      if (_odoo.isPortalSession) {
        final rows = await _portalApi.section(
          'incidents',
          recordId: widget.id,
          limit: 1,
        );
        if (rows.isEmpty) throw StateError('La incidencia no está disponible.');
        _record = rows.first;
      } else {
        final rows = await _portalApi.section(
          'incidents',
          recordId: widget.id,
          limit: 1,
        );
        if (rows.isEmpty) throw StateError('La incidencia no está disponible.');
        _record = rows.first;
      }
    } catch (e) {
      _error = OdooService.prettyError(e);
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
                key: 'name',
                label: 'Título',
                required: true,
                initialValue: _record!['name'],
              ),
              DynamicFieldConfig(
                key: 'tipo',
                label: 'Tipo',
                type: DynamicFieldType.select,
                initialValue: _record!['tipo'],
                required: true,
                options: const [
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
                initialValue: _record!['categoria'],
                required: true,
                options: const [
                  DynamicFieldOption(value: 'calidad', label: 'Calidad'),
                  DynamicFieldOption(value: 'prl', label: 'PRL'),
                ],
              ),
              DynamicFieldConfig(
                key: 'subtipo',
                label: 'Subtipo',
                type: DynamicFieldType.select,
                initialValue: _record!['subtipo'],
                required: true,
                options: const [
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
                key: 'estado',
                label: 'Estado',
                type: DynamicFieldType.select,
                initialValue: _record!['estado'],
                required: true,
                options: const [
                  DynamicFieldOption(value: 'abierta', label: 'Abierta'),
                  DynamicFieldOption(value: 'en_proceso', label: 'En proceso'),
                  DynamicFieldOption(value: 'cerrada', label: 'Cerrada'),
                ],
              ),
              DynamicFieldConfig(
                key: 'descripcion',
                label: 'Descripción',
                type: DynamicFieldType.multiline,
                initialValue: _record!['descripcion'],
                maxLines: 4,
              ),
              DynamicFieldConfig(
                key: 'analisis',
                label: 'Análisis',
                type: DynamicFieldType.multiline,
                initialValue: _record!['analisis'],
                maxLines: 4,
              ),
              DynamicFieldConfig(
                key: 'tratamiento',
                label: 'Tratamiento',
                type: DynamicFieldType.multiline,
                initialValue: _record!['tratamiento'],
                maxLines: 4,
              ),
            ],
            onSubmit: (values) async {
              final payload = <String, dynamic>{
                'name': values['name'],
                'tipo': values['tipo'],
                'categoria': values['categoria'],
                'subtipo': values['subtipo'],
                'estado': values['estado'],
                'descripcion': values['descripcion'],
                'analisis': values['analisis'],
                'tratamiento': values['tratamiento'],
              };
              if (_odoo.isPortalSession) {
                await _portalApi.action('incident_update', recordId: widget.id, values: payload);
              } else {
                await _odoo.write('calidad.incidencia', widget.id, payload);
              }
            },
          ),
        );
      },
    );

    if (created == true) await _load();
  }

  Future<void> _createCorrectiveAction() async {
    final created = await showModalBottomSheet<bool>(
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
          submitLabel: 'Crear acción correctiva',
          fields: const [
            DynamicFieldConfig(key: 'name', label: 'Título', required: true),
            DynamicFieldConfig(
              key: 'descripcion',
              label: 'Descripción',
              type: DynamicFieldType.multiline,
              maxLines: 4,
            ),
          ],
          onSubmit: (values) async {
            await _portalApi.action(
              'corrective_action_create',
              values: {
                'incidence_id': widget.id,
                'name': values['name'],
                'descripcion': values['descripcion'],
                'responsable_id': context.read<AuthProvider>().partnerId,
                'estado': 'pendiente',
                'eficacia': 'pendiente',
              },
            );
          },
        ),
      ),
    );
    if (created == true) await _load();
  }

  Future<void> _closeIncident() async {
    try {
      if (_odoo.isPortalSession) {
        await _portalApi.action(
          'incident_update',
          recordId: widget.id,
          values: const {'estado': 'cerrada'},
        );
      } else {
        await _odoo.write('calidad.incidencia', widget.id, const {'estado': 'cerrada'});
      }
      await _load();
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(OdooService.prettyError(error))),
        );
      }
    }
  }

  Future<void> _uploadAttachment() async {
    final picked = await _attachments.pickAnyFile();
    if (picked == null) return;
    try {
      if (_odoo.isPortalSession) {
        await _portalApi.action(
          'incident_attachment_create',
          recordId: widget.id,
          values: {
            'name': picked.name,
            'mimetype': picked.mimeType,
            'datas': picked.base64Data,
          },
        );
      } else {
        final attachmentId = await _attachments.createAttachment(
          name: picked.name,
          mimeType: picked.mimeType,
          base64Data: picked.base64Data,
          resModel: 'calidad.incidencia',
          resId: widget.id,
        );
        await _odoo.write('calidad.incidencia', widget.id, {
          'documento_ids': [
            [4, attachmentId],
          ],
        });
      }
      await _load();
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(OdooService.prettyError(error))),
        );
      }
    }
  }

  Future<void> _editCorrectiveAction(Map<String, dynamic> action) async {
    final id = OdooValues.intValue(action['id']);
    if (id == null) return;
    final edited = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(16, 8, 16, 16 + MediaQuery.of(ctx).viewInsets.bottom),
        child: DynamicForm(
          submitLabel: 'Guardar acción',
          fields: [
            DynamicFieldConfig(key: 'name', label: 'Título', required: true, initialValue: action['name']),
            DynamicFieldConfig(key: 'descripcion', label: 'Descripción', type: DynamicFieldType.multiline, maxLines: 4, initialValue: action['descripcion']),
            DynamicFieldConfig(
              key: 'estado', label: 'Estado', type: DynamicFieldType.select, required: true,
              initialValue: action['estado'] ?? 'pendiente',
              options: const [
                DynamicFieldOption(value: 'pendiente', label: 'Pendiente'),
                DynamicFieldOption(value: 'en_proceso', label: 'En proceso'),
                DynamicFieldOption(value: 'finalizada', label: 'Finalizada'),
              ],
            ),
            DynamicFieldConfig(
              key: 'eficacia', label: 'Eficacia', type: DynamicFieldType.select, required: true,
              initialValue: action['eficacia'] ?? 'pendiente',
              options: const [
                DynamicFieldOption(value: 'pendiente', label: 'Pendiente'),
                DynamicFieldOption(value: 'eficaz', label: 'Eficaz'),
                DynamicFieldOption(value: 'no_eficaz', label: 'No eficaz'),
              ],
            ),
          ],
          onSubmit: (values) async {
            await _portalApi.action('corrective_action_update', recordId: id, values: {
              'name': values['name'],
              'descripcion': values['descripcion'],
              'estado': values['estado'],
              'eficacia': values['eficacia'],
            });
          },
        ),
      ),
    );
    if (edited == true) await _load();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    if (_loading) {
      return const Scaffold(body: AppLoadingView());
    }
    if (_error != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Incidencia')),
        body: Center(child: Text(_error!)),
      );
    }

    final r = _record!;
    final estado = (r['estado'] ?? '').toString();
    final avance = OdooValues.number(r['avance']);
    final correctiveActions = r['corrective_actions'] is List
        ? r['corrective_actions'] as List
        : const [];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalle incidencia'),
        actions: [
          if (auth.canEditModule('incidents'))
            IconButton(
              tooltip: 'Añadir acción correctiva',
              onPressed: _createCorrectiveAction,
              icon: const Icon(Icons.add_task_rounded),
            ),
          if (auth.canEditModule('incidents'))
            IconButton(onPressed: _edit, icon: const Icon(Icons.edit_rounded)),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
        children: [
          Text(
            r['name']?.toString() ?? '-',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [
              _chip('Tipo: ${r['tipo'] ?? '-'}'),
              _chip('Estado: $estado'),
              _chip('Categoría: ${r['categoria'] ?? '-'}'),
            ],
          ),
          if (auth.canEditModule('incidents') && estado != 'cerrada') ...[
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerLeft,
              child: OutlinedButton.icon(
                onPressed: _closeIncident,
                icon: const Icon(Icons.task_alt_rounded),
                label: const Text('Cerrar incidencia'),
              ),
            ),
          ],
          const SizedBox(height: 12),
          Text('Descripción', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 4),
          Text(r['descripcion']?.toString() ?? '-'),
          const SizedBox(height: 12),
          Text('Análisis', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 4),
          Text(r['analisis']?.toString() ?? '-'),
          const SizedBox(height: 12),
          Text('Tratamiento', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 4),
          Text(r['tratamiento']?.toString() ?? '-'),
          const SizedBox(height: 12),
          Text('Adjuntos', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 4),
          ..._attachmentTiles(r['documento_ids']),
          if (auth.canEditModule('incidents'))
            Align(
              alignment: Alignment.centerLeft,
              child: OutlinedButton.icon(
                onPressed: _uploadAttachment,
                icon: const Icon(Icons.attach_file_rounded),
                label: const Text('Subir archivo'),
              ),
            ),
          const SizedBox(height: 12),
          Text('Avance: ${avance.toStringAsFixed(0)}%'),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: AppTheme.radiusXl,
            child: LinearProgressIndicator(
              minHeight: 7,
              value: (avance / 100).clamp(0, 1),
              backgroundColor: AppTheme.divider,
              valueColor: AlwaysStoppedAnimation(
                estado == 'cerrada' ? AppTheme.success : AppTheme.primary,
              ),
            ),
          ),
          if (correctiveActions.isNotEmpty) ...[
            const SizedBox(height: 18),
            Text(
              'Acciones correctivas',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            ..._correctiveActionTiles(correctiveActions, auth.canEditModule('incidents')),
          ],
        ],
      ),
    );
  }

  Widget _chip(String t) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    decoration: BoxDecoration(
      color: AppTheme.surfaceElevated,
      borderRadius: AppTheme.radiusXl,
    ),
    child: Text(
      t,
      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
    ),
  );

  List<Widget> _attachmentTiles(dynamic raw) {
    if (raw is! List || raw.isEmpty) {
      return const [Text('Sin adjuntos', style: TextStyle(color: AppTheme.textMuted))];
    }
    return raw.whereType<List>().map((item) {
      final label = item.length > 1 ? item[1].toString() : 'Archivo';
      return ListTile(
        contentPadding: EdgeInsets.zero,
        leading: const Icon(Icons.insert_drive_file_outlined),
        title: Text(label),
      );
    }).toList();
  }

  List<Widget> _correctiveActionTiles(dynamic raw, bool canEdit) {
    if (raw is! List || raw.isEmpty) {
      return const [Text('Sin acciones correctivas', style: TextStyle(color: AppTheme.textMuted))];
    }
    return raw.whereType<Map>().map((item) {
      final action = Map<String, dynamic>.from(item);
      return ListTile(
        contentPadding: EdgeInsets.zero,
        leading: const Icon(Icons.task_alt_rounded),
        title: Text(OdooValues.string(action['name'])),
        subtitle: Text('Estado: ${OdooValues.string(action['estado'], fallback: 'pendiente')}'),
        trailing: canEdit
            ? IconButton(
                tooltip: 'Editar acción',
                icon: const Icon(Icons.edit_outlined),
                onPressed: () => _editCorrectiveAction(action),
              )
            : null,
      );
    }).toList();
  }
}
