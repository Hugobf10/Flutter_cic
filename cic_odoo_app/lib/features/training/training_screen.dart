import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../app/screens/document_viewer_screen.dart';
import '../../app/ui/app_components.dart';
import '../../l10n/strings.dart';
import '../../providers/auth_provider.dart';
import '../../services/attachment_service.dart';
import '../../services/odoo_service.dart';
import '../../services/odoo_values.dart';
import '../../services/portal_api_service.dart';
import '../../theme/app_theme.dart';
import 'register_external_training_screen.dart';

class TrainingScreen extends StatefulWidget {
  const TrainingScreen({super.key});

  @override
  State<TrainingScreen> createState() => _TrainingScreenState();
}

class _TrainingScreenState extends State<TrainingScreen> {
  final OdooService _odoo = OdooService();
  final PortalApiService _portalApi = PortalApiService();
  final AttachmentService _attachments = AttachmentService();
  bool _loading = true;
  String? _error;
  bool _limitedAccessMode = false;
  List<Map<String, dynamic>> _rows = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final auth = context.read<AuthProvider>();
    setState(() {
      _loading = true;
      _error = null;
      _limitedAccessMode = false;
    });
    try {
      final rows = _odoo.isPortalSession
          ? await _portalApi.section('training', limit: 200)
          : await _odoo.searchRead(
              'calidad.formacion.asistencia',
              domain: [
                ['partner_id', '=', auth.partnerId],
              ],
              fields: const [
                'formacion_id',
                'estado',
                'origen_formacion',
                'tipo_formacion',
                'fecha_prevista',
                'fecha_realizacion',
                'entidad',
                'lugar',
                'duracion',
                'descripcion_formacion',
                'certificado_attachment_id',
              ],
              order: 'fecha_realizacion desc, id desc',
              limit: 200,
            );
      _rows = rows.map((e) => Map<String, dynamic>.from(e as Map)).toList();
    } catch (e) {
      _error = OdooService.prettyError(e);
      _limitedAccessMode = OdooService.isAccessError(e);
      _rows = [];
    }
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    final t = context.l10n;
    final auth = context.watch<AuthProvider>();
    final pending = _rows
        .where((e) => (e['estado'] ?? '').toString() == 'pendiente')
        .length;
    final completed = _rows
        .where((e) => (e['estado'] ?? '').toString() == 'realizado')
        .length;
    final inProgress = _rows.where(_isInProgress).length;
    final pendingRows = _rows.where(_isPending).toList();

    return DefaultTabController(
      length: 2,
      child: AppScaffold(
        title: t.training,
        actions: [
          if (auth.canEditModule('training'))
            IconButton(
              onPressed: () async {
                final saved = await Navigator.of(context).push<bool>(
                  MaterialPageRoute(
                    builder: (_) => const RegisterExternalTrainingScreen(),
                  ),
                );
                if (saved == true) _load();
              },
              icon: Icon(Icons.add_rounded),
            ),
          IconButton(onPressed: _load, icon: Icon(Icons.refresh_rounded)),
        ],
        child: Column(
          children: [
            TabBar(
              tabs: [
                Tab(text: t.pending),
                Tab(text: t.trainingHistory),
              ],
            ),
            const SizedBox(height: 12),
            Expanded(
              child: _loading
                  ? const AppLoadingView()
                  : _error != null && !_limitedAccessMode
                  ? AppEmptyState(
                      title: t.trainingLoadError,
                      subtitle: _error!,
                      icon: Icons.error_outline_rounded,
                    )
                  : TabBarView(
                      children: [
                        ListView(
                          children: [
                            if (_limitedAccessMode) ...[
                              AppCard(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.lock_outline_rounded,
                                          color: AppTheme.warning,
                                        ),
                                        SizedBox(width: 10),
                                        Expanded(
                                          child: Text(
                                            t.trainingLimitedAccess,
                                            style: TextStyle(
                                              fontWeight: FontWeight.w700,
                                              color: AppTheme.textPrimaryFor(
                                                context,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    SizedBox(height: 10),
                                    Text(
                                      t.trainingLimitedAccessHint,
                                      style: TextStyle(
                                        color: AppTheme.textSecondaryFor(
                                          context,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ] else ...[
                              _kpi(
                                t.pending,
                                pending.toString(),
                                AppTheme.warning,
                              ),
                              const SizedBox(height: 8),
                              _kpi(
                                t.inProgress,
                                inProgress.toString(),
                                AppTheme.info,
                              ),
                              const SizedBox(height: 8),
                              _kpi(
                                t.previewSuccess,
                                completed.toString(),
                                AppTheme.success,
                              ),
                            ],
                            const SizedBox(height: 12),
                            AppCard(
                              child: Text(
                                _limitedAccessMode
                                    ? t.trainingLimitedModeHint
                                    : t.trainingNormalModeHint,
                              ),
                            ),
                            const SizedBox(height: 12),
                            if (!_limitedAccessMode)
                              _buildTrainingList(
                                pendingRows,
                                emptyTitle: t.noPendingTraining,
                                emptySubtitle: t.noPendingTrainingHint,
                                auth: auth,
                              ),
                          ],
                        ),
                        _limitedAccessMode
                            ? AppEmptyState(
                                title: t.trainingHistoryUnavailable,
                                subtitle: t.trainingHistoryUnavailableHint,
                                icon: Icons.lock_outline_rounded,
                              )
                            : _buildTrainingList(
                                _rows,
                                emptyTitle: t.noTrainingHistory,
                                emptySubtitle: t.noTrainingHistoryHint,
                                auth: auth,
                              ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _kpi(String title, String value, Color color) {
    return AppCard(
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: AppTheme.radiusSm,
            ),
            child: Icon(Icons.school_rounded, color: color, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                color: AppTheme.textSecondaryFor(context),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: AppTheme.textPrimaryFor(context),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTrainingList(
    List<Map<String, dynamic>> rows, {
    required String emptyTitle,
    required String emptySubtitle,
    required AuthProvider auth,
  }) {
    if (rows.isEmpty) {
      return AppEmptyState(
        title: emptyTitle,
        subtitle: emptySubtitle,
        icon: Icons.school_outlined,
      );
    }
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: rows.length,
      itemBuilder: (context, index) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: _buildTrainingCard(rows[index], auth),
      ),
    );
  }

  Widget _buildTrainingCard(Map<String, dynamic> row, AuthProvider auth) {
    final t = context.l10n;
    final title = _trainingName(row);
    final completed = _isCompleted(row);
    final inProgress = _isInProgress(row);
    final status = completed
        ? t.previewSuccess
        : inProgress
        ? t.inProgress
        : t.pending;
    final color = completed
        ? AppTheme.success
        : inProgress
        ? AppTheme.info
        : AppTheme.warning;
    final plannedDate = _text(row['fecha_prevista']);
    final completionDate = _text(row['fecha_realizacion']);
    final entity = _text(row['entidad']);
    final place = _text(row['lugar']);
    final duration = _numberText(row['duracion']);
    final description = _text(row['descripcion_formacion']);
    final certificateId = OdooValues.many2oneId(
      row['certificado_attachment_id'],
    );
    final elearningUrl = _text(row['elearning_url']);
    final progress = _doubleValue(row['elearning_completion']);

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimaryFor(context),
                  ),
                ),
              ),
              AppStatusChip(label: status, color: color),
            ],
          ),
          const SizedBox(height: 8),
          if (plannedDate.isNotEmpty)
            _metadataLine(Icons.event_outlined, t.scheduled(plannedDate)),
          if (completionDate.isNotEmpty)
            _metadataLine(
              Icons.event_available_outlined,
              t.completedOn(completionDate),
            ),
          if (entity.isNotEmpty) _metadataLine(Icons.business_outlined, entity),
          if (place.isNotEmpty) _metadataLine(Icons.place_outlined, place),
          if (duration != null)
            _metadataLine(Icons.schedule_rounded, t.hours(duration)),
          if (progress != null) ...[
            const SizedBox(height: 8),
            LinearProgressIndicator(value: (progress / 100).clamp(0, 1)),
            const SizedBox(height: 4),
            Text(
              t.elearningProgress(progress.toStringAsFixed(0)),
              style: TextStyle(
                fontSize: 12,
                color: AppTheme.textSecondaryFor(context),
              ),
            ),
          ],
          if (description.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              description,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: AppTheme.textSecondaryFor(context)),
            ),
          ],
          if (certificateId != null ||
              elearningUrl.isNotEmpty ||
              (!completed && auth.canCompleteTraining)) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 4,
              runSpacing: 4,
              children: [
                if (certificateId != null)
                  TextButton.icon(
                    onPressed: () => _openCertificate(row, certificateId),
                    icon: const Icon(Icons.picture_as_pdf_outlined),
                    label: Text(t.certificate),
                  ),
                if (elearningUrl.isNotEmpty)
                  TextButton.icon(
                    onPressed: () => _openElearning(elearningUrl),
                    icon: const Icon(Icons.open_in_new_rounded),
                    label: Text(t.openCourse),
                  ),
                if (!completed && auth.canCompleteTraining)
                  TextButton.icon(
                    onPressed: () => _completeTraining(row),
                    icon: const Icon(Icons.task_alt_rounded),
                    label: Text(t.markCompleted),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _metadataLine(IconData icon, String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Icon(icon, size: 15, color: AppTheme.textMutedFor(context)),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: AppTheme.textSecondaryFor(context),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _openCertificate(
    Map<String, dynamic> row,
    int attachmentId,
  ) async {
    final recordId = OdooValues.intValue(row['id']);
    if (recordId == null) return;
    try {
      final local = await _attachments.fetchAttachmentToCache(
        attachmentId: attachmentId,
        defaultName: 'certificado_formacion_$recordId.pdf',
        portalSection: 'training',
        portalRecordId: recordId,
      );
      if (!mounted) return;
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => DocumentViewerScreen(
            file: local.file,
            title: local.name,
            mimeType: local.mimeType,
          ),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            context.l10n.couldNotOpenCertificate(
              OdooService.prettyError(error),
            ),
          ),
        ),
      );
    }
  }

  Future<void> _openElearning(String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null ||
        !await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.couldNotOpenElearning)),
      );
    }
  }

  Future<void> _completeTraining(Map<String, dynamic> row) async {
    final recordId = OdooValues.intValue(row['id']);
    if (recordId == null) return;
    var completedOn = DateTime.now();
    PickedUploadFile? certificate;
    var saving = false;
    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => StatefulBuilder(
        builder: (context, setSheetState) => SafeArea(
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              20,
              20,
              20,
              20 + MediaQuery.viewInsetsOf(context).bottom,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.l10n.completeTraining,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                Text(_trainingName(row)),
                const SizedBox(height: 16),
                AppCard(
                  child: Row(
                    children: [
                      const Icon(Icons.event_available_outlined),
                      const SizedBox(width: 8),
                      Expanded(child: Text(_formatDate(completedOn))),
                      TextButton(
                        onPressed: saving
                            ? null
                            : () async {
                                final picked = await showDatePicker(
                                  context: context,
                                  initialDate: completedOn,
                                  firstDate: DateTime(2000),
                                  lastDate: DateTime.now(),
                                );
                                if (picked != null) {
                                  setSheetState(() => completedOn = picked);
                                }
                              },
                        child: Text(context.l10n.change),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                AppCard(
                  child: Row(
                    children: [
                      const Icon(Icons.attach_file_rounded),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          certificate?.name ??
                              context.l10n.attachOptionalCertificate,
                        ),
                      ),
                      TextButton(
                        onPressed: saving
                            ? null
                            : () async {
                                final picked = await _attachments.pickPdf();
                                if (picked != null) {
                                  setSheetState(() => certificate = picked);
                                }
                              },
                        child: Text(context.l10n.upload),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                AppButton.primary(
                  label: context.l10n.confirmCompletion,
                  icon: Icons.task_alt_rounded,
                  loading: saving,
                  onPressed: saving
                      ? null
                      : () async {
                          setSheetState(() => saving = true);
                          try {
                            final values = {
                              'fecha_realizacion': _formatDate(completedOn),
                              if (certificate != null) ...{
                                'certificate_data': certificate!.base64Data,
                                'certificate_name': certificate!.name,
                              },
                            };
                            if (_odoo.isPortalSession) {
                              await _portalApi.action(
                                'training_complete',
                                recordId: recordId,
                                values: values,
                              );
                            } else {
                              await _odoo.write(
                                'calidad.formacion.asistencia',
                                recordId,
                                {
                                  'fecha_realizacion':
                                      values['fecha_realizacion'],
                                  if (certificate != null) ...{
                                    'certificado_name': certificate!.name,
                                    'certificado_data': certificate!.base64Data,
                                  },
                                },
                              );
                            }
                            if (sheetContext.mounted) {
                              Navigator.of(sheetContext).pop(true);
                            }
                          } catch (error) {
                            setSheetState(() => saving = false);
                            if (!mounted) return;
                            ScaffoldMessenger.of(this.context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  this.context.l10n.couldNotCompleteTraining(
                                    OdooService.prettyError(error),
                                  ),
                                ),
                              ),
                            );
                          }
                        },
                ),
              ],
            ),
          ),
        ),
      ),
    );
    if (confirmed == true) await _load();
  }

  bool _isCompleted(Map<String, dynamic> row) =>
      _text(row['estado']) == 'realizado';

  bool _isInProgress(Map<String, dynamic> row) {
    final progress = _doubleValue(row['elearning_completion']);
    return !_isCompleted(row) && progress != null && progress > 0;
  }

  bool _isPending(Map<String, dynamic> row) => !_isCompleted(row);

  String _trainingName(Map<String, dynamic> row) {
    final formacion = row['formacion_id'];
    if (formacion is List && formacion.length > 1) {
      return formacion[1].toString();
    }
    return _text(row['name']).isNotEmpty
        ? _text(row['name'])
        : context.l10n.training;
  }

  String _text(dynamic value) => value?.toString().trim() ?? '';

  double? _doubleValue(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse(_text(value));
  }

  String? _numberText(dynamic value) {
    final number = _doubleValue(value);
    if (number == null || number <= 0) return null;
    return number == number.roundToDouble()
        ? number.toStringAsFixed(0)
        : number.toStringAsFixed(1);
  }

  String _formatDate(DateTime date) {
    final year = date.year.toString().padLeft(4, '0');
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '$year-$month-$day';
  }
}
