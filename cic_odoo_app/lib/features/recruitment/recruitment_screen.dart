import 'package:flutter/material.dart';

import '../../app/screens/document_viewer_screen.dart';
import '../../app/ui/app_components.dart';
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
        title: 'Reclutamiento',
        actions: [
          IconButton(onPressed: _load, icon: Icon(Icons.refresh_rounded)),
        ],
        child: _loading
            ? const AppLoadingView()
            : _error != null
            ? AppEmptyState(
                title: 'Error',
                subtitle: _error!,
                icon: Icons.error_outline_rounded,
              )
            : Column(
                children: [
                  const TabBar(
                    tabs: [
                      Tab(text: 'Vacantes'),
                      Tab(text: 'Candidaturas'),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: TabBarView(
                      children: [
                        _jobs.isEmpty
                            ? const AppEmptyState(
                                title: 'Sin vacantes',
                                subtitle: 'No hay posiciones abiertas.',
                                icon: Icons.work_outline_rounded,
                              )
                            : ListView.builder(
                                itemCount: _jobs.length,
                                itemBuilder: (_, i) {
                                  final it = _jobs[i];
                                  final dept = it['department_id'] is List
                                      ? it['department_id'][1].toString()
                                      : '-';
                                  return Padding(
                                    padding: const EdgeInsets.only(bottom: 8),
                                    child: AppCard(
                                      onTap: () => _openJobDetail(it),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            (it['name'] ?? '').toString(),
                                            style: TextStyle(
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                          const SizedBox(height: 6),
                                          Text(
                                            'Departamento: $dept',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: AppTheme.textSecondaryFor(
                                                context,
                                              ),
                                            ),
                                          ),
                                          Text(
                                            'Vacantes: ${(it['no_of_recruitment'] ?? 0)}',
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
                            ? const AppEmptyState(
                                title: 'Sin candidaturas',
                                subtitle: 'No hay candidaturas registradas.',
                                icon: Icons.person_search_rounded,
                              )
                            : ListView.builder(
                                itemCount: _applicants.length,
                                itemBuilder: (_, i) {
                                  final it = _applicants[i];
                                  final job = it['job_id'] is List
                                      ? it['job_id'][1].toString()
                                      : '-';
                                  final stage = it['stage_id'] is List
                                      ? it['stage_id'][1].toString()
                                      : '-';
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
                                                  (it['partner_name'] ??
                                                          'Candidato')
                                                      .toString(),
                                                  style: TextStyle(
                                                    fontWeight: FontWeight.w700,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 6),
                                          Text(
                                            'Puesto: $job',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: AppTheme.textSecondaryFor(
                                                context,
                                              ),
                                            ),
                                          ),
                                          Text(
                                            'Estado: $stage',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: AppTheme.textSecondaryFor(
                                                context,
                                              ),
                                            ),
                                          ),
                                          Text(
                                            (it['email_from'] ?? '-')
                                                .toString(),
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
    final title = (job['name'] ?? 'Vacante').toString();
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
              '${candidates.length} candidaturas vinculadas',
              style: TextStyle(color: AppTheme.textSecondaryFor(context)),
            ),
            const SizedBox(height: 14),
            if (candidates.isEmpty)
              const AppEmptyState(
                title: 'Sin candidaturas',
                subtitle: 'Esta vacante no tiene candidaturas visibles.',
                icon: Icons.person_search_rounded,
              )
            else
              ...candidates.map((candidate) {
                final stage = candidate['stage_id'] is List
                    ? candidate['stage_id'][1].toString()
                    : '-';
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: AppListTile(
                    onTap: () => _openApplicantDetail(candidate),
                    title: (candidate['partner_name'] ?? 'Candidato')
                        .toString(),
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
    final job = applicant['job_id'] is List
        ? applicant['job_id'][1].toString()
        : '-';
    final stage = applicant['stage_id'] is List
        ? applicant['stage_id'][1].toString()
        : '-';
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
              (applicant['partner_name'] ?? 'Candidato').toString(),
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text('Vacante: $job'),
            Text('Estado: $stage'),
            Text('Email: ${(applicant['email_from'] ?? '-')}'),
            const SizedBox(height: 20),
            Text(
              'Documentación aportada',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 4),
            Text(
              'Consulta en modo lectura. No se permite descargar ni compartir archivos.',
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
                      title: document.label,
                      subtitle: _documentName(applicant, document),
                      trailing: const Icon(Icons.visibility_rounded),
                    ),
                  ),
                ),
            if (!_documentSpecs.any(
              (document) => applicant[document.field] == true,
            ))
              const AppEmptyState(
                title: 'Sin documentación',
                subtitle: 'La candidatura no tiene documentos disponibles.',
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
    Map<String, dynamic> applicant,
    _CandidateDocument document,
  ) {
    final name = (applicant[document.fileNameField] ?? '').toString().trim();
    return name.isEmpty ? 'Documento disponible para consulta' : name;
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
        defaultName: _documentName(applicant, document),
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
            'No se pudo visualizar el documento: ${OdooService.prettyError(e)}',
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
