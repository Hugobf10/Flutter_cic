import 'package:flutter/material.dart';

import '../../app/ui/app_components.dart';
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
  final OdooService _odoo = OdooService();
  final PortalApiService _portalApi = PortalApiService();
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
      if (_odoo.isPortalSession) {
        final payload = await _portalApi.sectionPayload('recruitment');
        _jobs = _mapRows(payload['jobs']);
        _applicants = _mapRows(payload['applicants']);
        if (mounted) setState(() => _loading = false);
        return;
      }
      final jobs = await _odoo.searchRead(
        'hr.job',
        fields: const [
          'name',
          'no_of_recruitment',
          'expected_employees',
          'company_id',
          'department_id',
        ],
        order: 'id desc',
        limit: 100,
      );
      final applicants = await _odoo.searchRead(
        'hr.applicant',
        fields: const [
          'partner_name',
          'email_from',
          'job_id',
          'stage_id',
          'priority',
        ],
        order: 'id desc',
        limit: 120,
      );
      _jobs = jobs.map((e) => Map<String, dynamic>.from(e as Map)).toList();
      _applicants = applicants
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();
    } catch (e) {
      _error = OdooService.prettyError(e);
    }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _rateCandidate(int id, String currentPriority) async {
    if (_odoo.isPortalSession) {
      final current = double.tryParse(currentPriority) ?? 0;
      final next = current >= 25 ? 0 : (current + 5);
      final applicant = _applicants.firstWhere(
        (item) => (item['id'] as num?)?.toInt() == id,
        orElse: () => const <String, dynamic>{},
      );
      final jobId = OdooValues.many2oneId(applicant['job_id']);
      if (jobId == null) return;
      try {
        await _portalApi.action(
          'recruitment_rate',
          values: {
            'job_id': jobId,
            'applicant_id': id,
            'cic_puntuacion_entrevista': next,
          },
        );
        await _load();
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('No se pudo evaluar: ${OdooService.prettyError(e)}'),
          ),
        );
      }
      return;
    }
    final next = currentPriority == '0'
        ? '1'
        : currentPriority == '1'
        ? '2'
        : currentPriority == '2'
        ? '3'
        : '0';
    try {
      await _odoo.write('hr.applicant', id, {'priority': next});
      _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('No se pudo evaluar: $e')));
    }
  }

  List<Map<String, dynamic>> _mapRows(dynamic raw) {
    if (raw is! List) return const [];
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
          IconButton(onPressed: _load, icon: const Icon(Icons.refresh_rounded)),
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
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                          const SizedBox(height: 6),
                                          Text(
                                            'Departamento: $dept',
                                            style: const TextStyle(
                                              fontSize: 12,
                                              color: AppTheme.textSecondary,
                                            ),
                                          ),
                                          Text(
                                            'Vacantes: ${(it['no_of_recruitment'] ?? 0)}',
                                            style: const TextStyle(
                                              fontSize: 12,
                                              color: AppTheme.textSecondary,
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
                                  final id = (it['id'] as num).toInt();
                                  final priority = (it['priority'] ?? '0')
                                      .toString();
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
                                                  style: const TextStyle(
                                                    fontWeight: FontWeight.w700,
                                                  ),
                                                ),
                                              ),
                                              AppStatusChip(
                                                label: 'Valoración: $priority',
                                                color: priority == '0'
                                                    ? AppTheme.textMuted
                                                    : priority == '1'
                                                    ? AppTheme.warning
                                                    : priority == '2'
                                                    ? AppTheme.info
                                                    : AppTheme.success,
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 6),
                                          Text(
                                            'Puesto: $job',
                                            style: const TextStyle(
                                              fontSize: 12,
                                              color: AppTheme.textSecondary,
                                            ),
                                          ),
                                          Text(
                                            'Estado: $stage',
                                            style: const TextStyle(
                                              fontSize: 12,
                                              color: AppTheme.textSecondary,
                                            ),
                                          ),
                                          Text(
                                            (it['email_from'] ?? '-')
                                                .toString(),
                                            style: const TextStyle(
                                              fontSize: 12,
                                              color: AppTheme.textMuted,
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          Align(
                                            alignment: Alignment.centerRight,
                                            child: OutlinedButton.icon(
                                              onPressed: () =>
                                                  _rateCandidate(id, priority),
                                              icon: const Icon(
                                                Icons.star_rate_rounded,
                                                size: 16,
                                              ),
                                              label: const Text('Valorar'),
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
                    trailing: const Icon(Icons.chevron_right_rounded),
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }

  void _openApplicantDetail(Map<String, dynamic> applicant) {
    final id = (applicant['id'] as num?)?.toInt();
    final priority = (applicant['priority'] ?? '0').toString();
    final job = applicant['job_id'] is List
        ? applicant['job_id'][1].toString()
        : '-';
    final stage = applicant['stage_id'] is List
        ? applicant['stage_id'][1].toString()
        : '-';
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
              (applicant['partner_name'] ?? 'Candidato').toString(),
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text('Vacante: $job'),
            Text('Estado: $stage'),
            Text('Email: ${(applicant['email_from'] ?? '-')}'),
            const SizedBox(height: 12),
            AppStatusChip(
              label: 'Valoración actual: ${_priorityLabel(priority)}',
              color: _priorityColor(priority),
            ),
            const SizedBox(height: 12),
            AppButton.primary(
              label: 'Subir valoración',
              icon: Icons.star_rate_rounded,
              onPressed: id == null
                  ? null
                  : () {
                      Navigator.of(context).pop();
                      _rateCandidate(id, priority);
                    },
            ),
          ],
        ),
      ),
    );
  }

  String _priorityLabel(String priority) {
    switch (priority) {
      case '1':
        return 'Baja';
      case '2':
        return 'Media';
      case '3':
        return 'Alta';
      default:
        return 'Sin valorar';
    }
  }

  Color _priorityColor(String priority) {
    switch (priority) {
      case '1':
        return AppTheme.warning;
      case '2':
        return AppTheme.info;
      case '3':
        return AppTheme.success;
      default:
        return AppTheme.textMuted;
    }
  }
}
