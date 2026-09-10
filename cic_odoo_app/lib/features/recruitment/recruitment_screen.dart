import 'package:flutter/material.dart';

import '../../app/screens/document_viewer_screen.dart';
import '../../app/ui/app_components.dart';
import '../../l10n/strings.dart';
import '../../services/attachment_service.dart';
import '../../services/odoo_service.dart';
import '../../services/odoo_values.dart';
import '../../services/portal_api_service.dart';
import '../../theme/app_theme.dart';

class RecruitmentScreen extends StatefulWidget {
  const RecruitmentScreen({super.key});

  @override
  State<RecruitmentScreen> createState() => _RecruitmentScreenState();
}

class _RecruitmentScreenState extends State<RecruitmentScreen> {
  final PortalApiService _portalApi = PortalApiService();
  final AttachmentService _attachments = AttachmentService();
  bool _loading = true;
  String? _error;
  List<Map<String, dynamic>> _jobs = [];
  List<Map<String, dynamic>> _applicants = [];

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
      // Recruitment always uses the scoped endpoint, including for internal
      // users. Direct ORM reads would bypass the interviewer/recruiter domain.
      final payload = await _portalApi.sectionPayload('recruitment');
      _jobs = _mapRows(payload['jobs']);
      _applicants = _mapRows(payload['applicants']);
    } catch (e) {
      _error = OdooService.prettyError(e);
    }
    if (mounted) setState(() => _loading = false);
  }

  List<Map<String, dynamic>> _mapRows(dynamic raw) {
    if (raw is! List) return [];
    return raw
        .whereType<Map>()
        .map((row) => OdooValues.map(row))
        .toList(growable: false);
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: AppScaffold(
        title: context.l10n.recruitment,
        actions: [
          IconButton(onPressed: _load, icon: Icon(Icons.refresh_rounded)),
        ],
        child: _loading
            ? const AppLoadingView()
            : _error != null
            ? AppEmptyState(
                title: context.l10n.error,
                subtitle: _error!,
                icon: Icons.error_outline_rounded,
              )
            : Column(
                children: [
                  TabBar(
                    tabs: [
                      Tab(text: context.l10n.vacancies),
                      Tab(text: context.l10n.applications),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: TabBarView(
                      children: [
                        _jobs.isEmpty
                            ? AppEmptyState(
                                title: context.l10n.noVacancies,
                                subtitle: context.l10n.noVacanciesHint,
                                icon: Icons.work_outline_rounded,
                              )
                            : ListView.builder(
                                itemCount: _jobs.length,
                                itemBuilder: (_, i) {
                                  final it = _jobs[i];
                                  final dept = OdooValues.many2oneLabel(
                                    it['department_id'],
                                    fallback: '—',
                                  );
                                  return Padding(
                                    padding: const EdgeInsets.only(bottom: 8),
                                    child: AppCard(
                                      onTap: () => _openJobDetail(it),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            OdooValues.string(
                                              it['name'],
                                              fallback: context.l10n.vacancy,
                                            ),
                                            style: TextStyle(
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                          const SizedBox(height: 6),
                                          Text(
                                            '${context.l10n.department}: $dept',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: AppTheme.textSecondaryFor(
                                                context,
                                              ),
                                            ),
                                          ),
                                          Text(
                                            context.l10n.vacancyCount(
                                              OdooValues.intValue(
                                                    it['no_of_recruitment'],
                                                  ) ??
                                                  0,
                                            ),
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: AppTheme.textSecondaryFor(
                                                context,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),
                        _applicants.isEmpty
                            ? AppEmptyState(
                                title: context.l10n.noApplications,
                                subtitle: context.l10n.noApplicationsHint,
                                icon: Icons.person_search_rounded,
                              )
                            : ListView.builder(
                                itemCount: _applicants.length,
                                itemBuilder: (_, i) {
                                  final it = _applicants[i];
                                  final job = OdooValues.many2oneLabel(
                                    it['job_id'],
                                    fallback: '—',
                                  );
                                  final stage = OdooValues.many2oneLabel(
                                    it['stage_id'],
                                    fallback: '—',
                                  );
                                  return Padding(
                                    padding: const EdgeInsets.only(bottom: 8),
                                    child: AppCard(
                                      onTap: () => _openApplicantDetail(it),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Expanded(
                                                child: Text(
                                                  OdooValues.string(
                                                    it['partner_name'],
                                                    fallback:
                                                        context.l10n.candidate,
                                                  ),
                                                  style: TextStyle(
                                                    fontWeight: FontWeight.w700,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 6),
                                          Text(
                                            '${context.l10n.job}: $job',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: AppTheme.textSecondaryFor(
                                                context,
                                              ),
                                            ),
                                          ),
                                          Text(
                                            '${context.l10n.status}: $stage',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: AppTheme.textSecondaryFor(
                                                context,
                                              ),
                                            ),
                                          ),
                                          Text(
                                            OdooValues.string(
                                              it['email_from'],
                                              fallback: '—',
                                            ),
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: AppTheme.textMutedFor(
                                                context,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),
                      ],
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  void _openJobDetail(Map<String, dynamic> job) {
    final jobId = (job['id'] as num?)?.toInt();
    final title = OdooValues.string(
      job['name'],
      fallback: context.l10n.vacancy,
    );
    final candidates = _applicants.where((applicant) {
      final ref = applicant['job_id'];
      return ref is List &&
          ref.isNotEmpty &&
          (ref.first as num?)?.toInt() == jobId;
    }).toList();
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.72,
        minChildSize: 0.35,
        maxChildSize: 0.92,
        builder: (context, controller) => ListView(
          controller: controller,
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
          children: [
            Text(title, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 6),
            Text(
              context.l10n.linkedApplications(candidates.length),
              style: TextStyle(color: AppTheme.textSecondaryFor(context)),
            ),
            const SizedBox(height: 14),
            if (candidates.isEmpty)
              AppEmptyState(
                title: context.l10n.noApplications,
                subtitle: context.l10n.noVisibleApplicationsHint,
                icon: Icons.person_search_rounded,
              )
            else
              ...candidates.map((candidate) {
                final stage = OdooValues.many2oneLabel(
                  candidate['stage_id'],
                  fallback: '—',
                );
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: AppListTile(
                    onTap: () => _openApplicantDetail(candidate),
                    title: OdooValues.string(
                      candidate['partner_name'],
                      fallback: context.l10n.candidate,
                    ),
                    subtitle: stage,
                    trailing: Icon(Icons.chevron_right_rounded),
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }

  void _openApplicantDetail(Map<String, dynamic> applicant) {
    final job = OdooValues.many2oneLabel(applicant['job_id'], fallback: '—');
    final stage = OdooValues.many2oneLabel(
      applicant['stage_id'],
      fallback: '—',
    );
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.55,
        minChildSize: 0.35,
        maxChildSize: 0.9,
        builder: (context, controller) => ListView(
          controller: controller,
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          children: [
            Text(
              OdooValues.string(
                applicant['partner_name'],
                fallback: context.l10n.candidate,
              ),
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text('${context.l10n.vacancy}: $job'),
            Text('${context.l10n.status}: $stage'),
            Text(
              '${context.l10n.email}: ${OdooValues.string(applicant['email_from'], fallback: '—')}',
            ),
            const SizedBox(height: 20),
            Text(
              context.l10n.providedDocuments,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 4),
            Text(
              context.l10n.documentsReadOnlyHint,
              style: TextStyle(color: AppTheme.textSecondaryFor(context)),
            ),
            const SizedBox(height: 12),
            ..._documentSpecs
                .where((document) => applicant[document.field] == true)
                .map(
                  (document) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: AppListTile(
                      onTap: () => _previewDocument(applicant, document),
                      title: _documentLabel(context, document),
                      subtitle: _documentName(context, applicant, document),
                      trailing: const Icon(Icons.visibility_rounded),
                    ),
                  ),
                ),
            if (!_documentSpecs.any(
              (document) => applicant[document.field] == true,
            ))
              AppEmptyState(
                title: context.l10n.noCandidateDocuments,
                subtitle: context.l10n.noCandidateDocumentsHint,
                icon: Icons.folder_off_outlined,
              ),
          ],
        ),
      ),
    );
  }

  static const _documentSpecs = [
    _CandidateDocument(
      'cic_documento_identidad',
      'cic_documento_identidad_filename',
      'DNI o pasaporte',
    ),
    _CandidateDocument('cic_cv', 'cic_cv_filename', 'Currículum'),
    _CandidateDocument(
      'cic_titulacion',
      'cic_titulacion_filename',
      'Titulación',
    ),
    _CandidateDocument(
      'cic_expedientes',
      'cic_expedientes_filename',
      'Expediente',
    ),
    _CandidateDocument(
      'cic_otros_documentos',
      'cic_otros_documentos_filename',
      'Otros documentos',
    ),
    _CandidateDocument(
      'cic_carta_presentacion',
      'cic_carta_presentacion_filename',
      'Carta de presentación',
    ),
  ];

  String _documentName(
    BuildContext context,
    Map<String, dynamic> applicant,
    _CandidateDocument document,
  ) {
    return OdooValues.string(
      applicant[document.fileNameField],
      fallback: context.uiText(
        'Documento disponible para consulta',
        'Document available for review',
      ),
    );
  }

  String _documentLabel(BuildContext context, _CandidateDocument document) {
    return switch (document.field) {
      'cic_documento_identidad' => context.uiText(
        'DNI o pasaporte',
        'ID or passport',
      ),
      'cic_cv' => context.uiText('Currículum', 'CV'),
      'cic_titulacion' => context.uiText('Titulación', 'Degree'),
      'cic_expedientes' => context.uiText('Expediente', 'Transcript'),
      'cic_otros_documentos' => context.uiText(
        'Otros documentos',
        'Other documents',
      ),
      'cic_carta_presentacion' => context.uiText(
        'Carta de presentación',
        'Cover letter',
      ),
      _ => document.label,
    };
  }

  Future<void> _previewDocument(
    Map<String, dynamic> applicant,
    _CandidateDocument document,
  ) async {
    final applicantId = OdooValues.intValue(applicant['id']);
    if (applicantId == null) return;
    try {
      final local = await _attachments.fetchAttachmentToCache(
        attachmentId: 0,
        defaultName: _documentName(context, applicant, document),
        portalSection: 'recruitment',
        portalRecordId: applicantId,
        portalFieldName: document.field,
        forcePortal: true,
      );
      if (!mounted) return;
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => DocumentViewerScreen(
            file: local.file,
            title: local.name,
            mimeType: local.mimeType,
            allowExternalOpen: false,
          ),
        ),
      );
      if (await local.file.exists()) await local.file.delete();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${context.l10n.couldNotPreviewDocument}: ${OdooService.prettyError(e)}',
          ),
        ),
      );
    }
  }
}

class _CandidateDocument {
  const _CandidateDocument(this.field, this.fileNameField, this.label);

  final String field;
  final String fileNameField;
  final String label;
}
