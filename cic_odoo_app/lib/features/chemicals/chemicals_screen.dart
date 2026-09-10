import 'package:flutter/material.dart';
import 'package:open_filex/open_filex.dart';
import 'package:provider/provider.dart';

import '../../app/screens/document_viewer_screen.dart';
import '../../app/ui/app_components.dart';
import '../../features/forms/dynamic_form.dart';
import '../../l10n/strings.dart';
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
            submitLabel: context.l10n.registerChemical,
            fields: [
              DynamicFieldConfig(
                key: 'name',
                label: context.l10n.name,
                required: true,
              ),
              DynamicFieldConfig(key: 'codigo', label: context.l10n.codeLabel),
              DynamicFieldConfig(
                key: 'tipo',
                label: context.l10n.type,
                type: DynamicFieldType.select,
                initialValue: 'otro',
                options: [
                  DynamicFieldOption(
                    value: 'reactivo',
                    label: context.l10n.reagent,
                  ),
                  DynamicFieldOption(
                    value: 'producto',
                    label: context.l10n.product,
                  ),
                  DynamicFieldOption(value: 'otro', label: context.l10n.other),
                ],
              ),
              DynamicFieldConfig(
                key: 'fecha_caducidad',
                label: context.l10n.expiryDate,
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
                throw FormatException(context.l10n.chemicalNameRequired);
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
        title: Text(context.l10n.chemicals),
        actions: [
          if (auth.canEditModule('chemicals'))
            IconButton(onPressed: _openCreate, icon: Icon(Icons.add_rounded)),
          IconButton(onPressed: _load, icon: Icon(Icons.refresh_rounded)),
        ],
      ),
      body: _loading
          ? const AppLoadingView()
          : _error != null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(_error!),
              ),
            )
          : _rows.isEmpty
          ? Center(
              child: Text(
                context.l10n.noChemicals,
                style: TextStyle(color: AppTheme.textMutedFor(context)),
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
                    color: AppTheme.cardFor(context),
                    borderRadius: AppTheme.radiusMd,
                    border: Border.all(
                      color: AppTheme.dividerFor(
                        context,
                      ).withValues(alpha: 0.6),
                    ),
                    boxShadow: AppTheme.subtleShadowFor(context),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        (it['name'] ?? '').toString(),
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                      Text(
                        context.l10n.chemicalTypeDangerous(
                          OdooValues.string(it['tipo'], fallback: '-'),
                          OdooValues.boolValue(it['es_peligroso'])
                              ? context.l10n.yes
                              : context.l10n.no,
                        ),
                        style: TextStyle(
                          fontSize: 12,
                          color: AppTheme.textSecondaryFor(context),
                        ),
                      ),
                      if (OdooValues.string(it['fecha_caducidad']).isNotEmpty)
                        Text(
                          context.l10n.expiry(
                            OdooValues.string(it['fecha_caducidad']),
                          ),
                          style: TextStyle(
                            fontSize: 12,
                            color: AppTheme.textMutedFor(context),
                          ),
                        ),
                      if (unidad.isNotEmpty)
                        Text(
                          context.l10n.chemicalUnit(unidad),
                          style: TextStyle(
                            fontSize: 12,
                            color: AppTheme.textMutedFor(context),
                          ),
                        ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          OutlinedButton.icon(
                            onPressed: () => _openDetails(it),
                            icon: Icon(Icons.info_outline_rounded, size: 16),
                            label: Text(context.l10n.details),
                          ),
                          const SizedBox(width: 8),
                          OutlinedButton.icon(
                            onPressed: () => _openSafetySheet(it),
                            icon: Icon(Icons.description_outlined, size: 16),
                            label: Text(context.l10n.safetySheet),
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
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text(
              context.l10n.code(OdooValues.string(it['codigo'], fallback: '-')),
            ),
            Text(
              context.l10n.incidentType(
                OdooValues.string(it['tipo'], fallback: '-'),
              ),
            ),
            Text(
              context.l10n.chemicalTypeDangerous(
                OdooValues.string(it['tipo'], fallback: '-'),
                OdooValues.boolValue(it['es_peligroso'])
                    ? context.l10n.yes
                    : context.l10n.no,
              ),
            ),
            Text(
              context.l10n.expiry(
                OdooValues.string(it['fecha_caducidad'], fallback: '-'),
              ),
            ),
            if (context.read<AuthProvider>().canEditModule('chemicals')) ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.of(context).pop();
                    _openEdit(it);
                  },
                  icon: Icon(Icons.edit_outlined),
                  label: Text(context.l10n.editChemical),
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
        padding: EdgeInsets.fromLTRB(
          16,
          8,
          16,
          16 + MediaQuery.of(ctx).viewInsets.bottom,
        ),
        child: SingleChildScrollView(
          child: DynamicForm(
            submitLabel: context.l10n.saveChemical,
            fields: [
              DynamicFieldConfig(
                key: 'name',
                label: context.l10n.name,
                required: true,
                initialValue: chemical['name'],
              ),
              DynamicFieldConfig(
                key: 'codigo',
                label: context.l10n.codeLabel,
                initialValue: chemical['codigo'],
              ),
              DynamicFieldConfig(
                key: 'referencia',
                label: context.l10n.reference,
                initialValue: chemical['referencia'],
              ),
              DynamicFieldConfig(
                key: 'tipo',
                label: context.l10n.type,
                type: DynamicFieldType.select,
                initialValue: chemical['tipo'] ?? 'reactivo',
                options: [
                  DynamicFieldOption(
                    value: 'reactivo',
                    label: context.l10n.reagent,
                  ),
                  DynamicFieldOption(
                    value: 'producto',
                    label: context.l10n.product,
                  ),
                  DynamicFieldOption(value: 'otro', label: context.l10n.other),
                ],
              ),
              DynamicFieldConfig(
                key: 'descripcion',
                label: context.l10n.description,
                type: DynamicFieldType.multiline,
                maxLines: 3,
                initialValue: chemical['descripcion'],
              ),
              DynamicFieldConfig(
                key: 'almacenamiento',
                label: context.l10n.storage,
                type: DynamicFieldType.multiline,
                maxLines: 2,
                initialValue: chemical['almacenamiento'],
              ),
              DynamicFieldConfig(
                key: 'fecha_caducidad',
                label: context.l10n.expiryDate,
                type: DynamicFieldType.date,
                initialValue: _dateValue(chemical['fecha_caducidad']),
              ),
              DynamicFieldConfig(
                key: 'unidades',
                label: context.l10n.units,
                initialValue: chemical['unidades'],
              ),
              DynamicFieldConfig(
                key: 'a_punto_agotarse',
                label: context.l10n.runningLow,
                type: DynamicFieldType.select,
                initialValue: OdooValues.boolValue(
                  chemical['a_punto_agotarse'],
                ),
                options: [
                  DynamicFieldOption(value: false, label: context.l10n.no),
                  DynamicFieldOption(value: true, label: context.l10n.yes),
                ],
              ),
              DynamicFieldConfig(
                key: 'es_peligroso',
                label: context.l10n.dangerous,
                type: DynamicFieldType.select,
                initialValue: OdooValues.boolValue(chemical['es_peligroso']),
                options: [
                  DynamicFieldOption(value: false, label: context.l10n.no),
                  DynamicFieldOption(value: true, label: context.l10n.yes),
                ],
              ),
              DynamicFieldConfig(
                key: 'categoria_peligro',
                label: context.l10n.hazardCategory,
                type: DynamicFieldType.select,
                initialValue: chemical['categoria_peligro'],
                options: [
                  DynamicFieldOption(
                    value: 'explosivo',
                    label: context.l10n.explosive,
                  ),
                  DynamicFieldOption(
                    value: 'inflamable',
                    label: context.l10n.flammable,
                  ),
                  DynamicFieldOption(
                    value: 'toxico',
                    label: context.l10n.toxic,
                  ),
                  DynamicFieldOption(
                    value: 'corrosivo',
                    label: context.l10n.corrosive,
                  ),
                  DynamicFieldOption(
                    value: 'peligro_ambiental',
                    label: context.l10n.environmental,
                  ),
                  DynamicFieldOption(value: 'otro', label: context.l10n.other),
                ],
              ),
              DynamicFieldConfig(
                key: 'peligrosidad',
                label: context.l10n.hazard,
                type: DynamicFieldType.multiline,
                maxLines: 2,
                initialValue: chemical['peligrosidad'],
              ),
              DynamicFieldConfig(
                key: 'frases_h',
                label: context.l10n.hStatements,
                initialValue: chemical['frases_h'],
              ),
              DynamicFieldConfig(
                key: 'frases_p',
                label: context.l10n.pStatements,
                initialValue: chemical['frases_p'],
              ),
            ],
            onSubmit: (values) async {
              final payload = <String, dynamic>{
                'name': values['name'],
                'codigo': values['codigo'],
                'referencia': values['referencia'],
                'tipo': values['tipo'],
                'descripcion': values['descripcion'],
                'almacenamiento': values['almacenamiento'],
                'unidades':
                    double.tryParse(
                      values['unidades'].toString().replaceAll(',', '.'),
                    ) ??
                    0,
                'a_punto_agotarse': values['a_punto_agotarse'],
                'es_peligroso': values['es_peligroso'],
                'categoria_peligro': values['categoria_peligro'],
                'peligrosidad': values['peligrosidad'],
                'frases_h': values['frases_h'],
                'frases_p': values['frases_p'],
                if (_datePayload(values['fecha_caducidad']).isNotEmpty)
                  'fecha_caducidad': _datePayload(values['fecha_caducidad']),
              };
              if (_odoo.isPortalSession) {
                await _portalApi.action(
                  'chemical_update',
                  recordId: id,
                  values: payload,
                );
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
        throw Exception(context.l10n.safetySheetsUnavailable);
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.couldNotOpenSafetySheet('$e'))),
      );
    }
  }
}
