import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app/ui/app_components.dart';
import '../../features/forms/dynamic_form.dart';
import '../../l10n/strings.dart';
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
    final t = context.l10n;
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
        if (rows.isEmpty) throw StateError(t.incidentUnavailable);
        _record = rows.first;
      } else {
        final rows = await _portalApi.section(
          'incidents',
          recordId: widget.id,
          limit: 1,
        );
        if (rows.isEmpty) throw StateError(t.incidentUnavailable);
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
            submitLabel: context.l10n.saveChanges,
            fields: [
              DynamicFieldConfig(
                key: 'name',
                label: context.l10n.title,
                required: true,
                initialValue: _record!['name'],
              ),
              DynamicFieldConfig(
                key: 'tipo',
                label: context.l10n.type,
                type: DynamicFieldType.select,
                initialValue: _record!['tipo'],
                required: true,
                options: [
                  DynamicFieldOption(
                    value: 'nc',
                    label: context.l10n.nonConformity,
                  ),
                  DynamicFieldOption(
                    value: 'om',
                    label: context.l10n.improvementOpportunity,
                  ),
                ],
              ),
              DynamicFieldConfig(
                key: 'categoria',
                label: context.l10n.category,
                type: DynamicFieldType.select,
                initialValue: _record!['categoria'],
                required: true,
                options: [
                  DynamicFieldOption(
                    value: 'calidad',
                    label: context.l10n.quality,
                  ),
                  DynamicFieldOption(
                    value: 'prl',
                    label: context.l10n.healthSafety,
                  ),
                ],
              ),
              DynamicFieldConfig(
                key: 'subtipo',
                label: context.l10n.subtype,
                type: DynamicFieldType.select,
                initialValue: _record!['subtipo'],
                required: true,
                options: [
                  DynamicFieldOption(
                    value: 'interna',
                    label: context.l10n.internal,
                  ),
                  DynamicFieldOption(
                    value: 'proveedor',
                    label: context.l10n.supplier,
                  ),
                  DynamicFieldOption(
                    value: 'auditoria',
                    label: context.l10n.audit,
                  ),
                  DynamicFieldOption(
                    value: 'reclamacion',
                    label: context.l10n.claim,
                  ),
                  DynamicFieldOption(value: 'otra', label: context.l10n.other),
                ],
              ),
              DynamicFieldConfig(
                key: 'estado',
                label: context.l10n.status,
                type: DynamicFieldType.select,
                initialValue: _record!['estado'],
                required: true,
                options: [
                  DynamicFieldOption(
                    value: 'abierta',
                    label: context.l10n.openFeminine,
                  ),
                  DynamicFieldOption(
                    value: 'en_proceso',
                    label: context.l10n.inProgress,
                  ),
                  DynamicFieldOption(
                    value: 'cerrada',
                    label: context.l10n.closedFeminine,
                  ),
                ],
              ),
              DynamicFieldConfig(
                key: 'descripcion',
                label: context.l10n.description,
                type: DynamicFieldType.multiline,
                initialValue: _record!['descripcion'],
                maxLines: 4,
              ),
              DynamicFieldConfig(
                key: 'analisis',
                label: context.l10n.analysis,
                type: DynamicFieldType.multiline,
                initialValue: _record!['analisis'],
                maxLines: 4,
              ),
              DynamicFieldConfig(
                key: 'tratamiento',
                label: context.l10n.treatment,
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
                await _portalApi.action(
                  'incident_update',
                  recordId: widget.id,
                  values: payload,
                );
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
          submitLabel: context.l10n.createCorrectiveAction,
          fields: [
            DynamicFieldConfig(
              key: 'name',
              label: context.l10n.title,
              required: true,
            ),
            DynamicFieldConfig(
              key: 'descripcion',
              label: context.l10n.description,
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
        await _odoo.write('calidad.incidencia', widget.id, const {
          'estado': 'cerrada',
        });
      }
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
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(OdooService.prettyError(error))));
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
        padding: EdgeInsets.fromLTRB(
          16,
          8,
          16,
          16 + MediaQuery.of(ctx).viewInsets.bottom,
        ),
        child: DynamicForm(
          submitLabel: context.l10n.saveAction,
          fields: [
            DynamicFieldConfig(
              key: 'name',
              label: context.l10n.title,
              required: true,
              initialValue: action['name'],
            ),
            DynamicFieldConfig(
              key: 'descripcion',
              label: context.l10n.description,
              type: DynamicFieldType.multiline,
              maxLines: 4,
              initialValue: action['descripcion'],
            ),
            DynamicFieldConfig(
              key: 'estado',
              label: context.l10n.status,
              type: DynamicFieldType.select,
              required: true,
              initialValue: action['estado'] ?? 'pendiente',
              options: [
                DynamicFieldOption(
                  value: 'pendiente',
                  label: context.l10n.pending,
                ),
                DynamicFieldOption(
                  value: 'en_proceso',
                  label: context.l10n.inProgress,
                ),
                DynamicFieldOption(
                  value: 'finalizada',
                  label: context.l10n.completedFeminine,
                ),
              ],
            ),
            DynamicFieldConfig(
              key: 'eficacia',
              label: context.l10n.effectiveness,
              type: DynamicFieldType.select,
              required: true,
              initialValue: action['eficacia'] ?? 'pendiente',
              options: [
                DynamicFieldOption(
                  value: 'pendiente',
                  label: context.l10n.pending,
                ),
                DynamicFieldOption(
                  value: 'eficaz',
                  label: context.l10n.effective,
                ),
                DynamicFieldOption(
                  value: 'no_eficaz',
                  label: context.l10n.notEffective,
                ),
              ],
            ),
          ],
          onSubmit: (values) async {
            await _portalApi.action(
              'corrective_action_update',
              recordId: id,
              values: {
                'name': values['name'],
                'descripcion': values['descripcion'],
                'estado': values['estado'],
                'eficacia': values['eficacia'],
              },
            );
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
        appBar: AppBar(title: Text(context.l10n.incidents)),
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
        title: Text(context.l10n.incidentDetail),
        actions: [
          if (auth.canEditModule('incidents'))
            IconButton(
              tooltip: context.l10n.createCorrectiveAction,
              onPressed: _createCorrectiveAction,
              icon: Icon(Icons.add_task_rounded),
            ),
          if (auth.canEditModule('incidents'))
            IconButton(onPressed: _edit, icon: Icon(Icons.edit_rounded)),
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
              _chip(context.l10n.incidentType('${r['tipo'] ?? '-'}')),
              _chip(context.l10n.incidentStatus(estado)),
              _chip(context.l10n.incidentCategory('${r['categoria'] ?? '-'}')),
            ],
          ),
          if (auth.canEditModule('incidents') && estado != 'cerrada') ...[
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerLeft,
              child: OutlinedButton.icon(
                onPressed: _closeIncident,
                icon: Icon(Icons.task_alt_rounded),
                label: Text(context.l10n.closeIncident),
              ),
            ),
          ],
          const SizedBox(height: 12),
          Text(
            context.l10n.description,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 4),
          Text(r['descripcion']?.toString() ?? '-'),
          const SizedBox(height: 12),
          Text(
            context.l10n.analysis,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 4),
          Text(r['analisis']?.toString() ?? '-'),
          const SizedBox(height: 12),
          Text(
            context.l10n.treatment,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 4),
          Text(r['tratamiento']?.toString() ?? '-'),
          const SizedBox(height: 12),
          Text(
            context.l10n.attachments,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 4),
          ..._attachmentTiles(r['documento_ids']),
          if (auth.canEditModule('incidents'))
            Align(
              alignment: Alignment.centerLeft,
              child: OutlinedButton.icon(
                onPressed: _uploadAttachment,
                icon: Icon(Icons.attach_file_rounded),
                label: Text(context.l10n.uploadFile),
              ),
            ),
          const SizedBox(height: 12),
          Text(context.l10n.progress(avance.toStringAsFixed(0))),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: AppTheme.radiusXl,
            child: LinearProgressIndicator(
              minHeight: 7,
              value: (avance / 100).clamp(0, 1),
              backgroundColor: AppTheme.dividerFor(context),
              valueColor: AlwaysStoppedAnimation(
                estado == 'cerrada' ? AppTheme.success : AppTheme.primary,
              ),
            ),
          ),
          if (correctiveActions.isNotEmpty) ...[
            const SizedBox(height: 18),
            Text(
              context.l10n.correctiveActions,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            ..._correctiveActionTiles(
              correctiveActions,
              auth.canEditModule('incidents'),
            ),
          ],
        ],
      ),
    );
  }

  Widget _chip(String t) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    decoration: BoxDecoration(
      color: AppTheme.elevatedFor(context),
      borderRadius: AppTheme.radiusXl,
    ),
    child: Text(t, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
  );

  List<Widget> _attachmentTiles(dynamic raw) {
    if (raw is! List || raw.isEmpty) {
      return [
        Text(
          context.l10n.noAttachments,
          style: TextStyle(color: AppTheme.textMutedFor(context)),
        ),
      ];
    }
    return raw.whereType<List>().map((item) {
      final label = item.length > 1 ? item[1].toString() : context.l10n.file;
      return ListTile(
        contentPadding: EdgeInsets.zero,
        leading: Icon(Icons.insert_drive_file_outlined),
        title: Text(label),
      );
    }).toList();
  }

  List<Widget> _correctiveActionTiles(dynamic raw, bool canEdit) {
    if (raw is! List || raw.isEmpty) {
      return [
        Text(
          context.l10n.noCorrectiveActions,
          style: TextStyle(color: AppTheme.textMutedFor(context)),
        ),
      ];
    }
    return raw.whereType<Map>().map((item) {
      final action = Map<String, dynamic>.from(item);
      return ListTile(
        contentPadding: EdgeInsets.zero,
        leading: Icon(Icons.task_alt_rounded),
        title: Text(OdooValues.string(action['name'])),
        subtitle: Text(
          context.l10n.incidentStatus(
            OdooValues.string(action['estado'], fallback: context.l10n.pending),
          ),
        ),
        trailing: canEdit
            ? IconButton(
                tooltip: context.l10n.editAction,
                icon: Icon(Icons.edit_outlined),
                onPressed: () => _editCorrectiveAction(action),
              )
            : null,
      );
    }).toList();
  }
}
