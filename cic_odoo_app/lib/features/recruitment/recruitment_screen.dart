import 'package:flutter/material.dart';

import '../../app/ui/app_components.dart';
import '../../services/odoo_service.dart';
import '../../theme/app_theme.dart';

class RecruitmentScreen extends StatefulWidget {
  const RecruitmentScreen({super.key});

  @override
  State<RecruitmentScreen> createState() => _RecruitmentScreenState();
}

class _RecruitmentScreenState extends State<RecruitmentScreen> {
  final OdooService _odoo = OdooService();
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
      final jobs = await _odoo.searchRead(
        'hr.job',
        fields: const ['name', 'no_of_recruitment', 'expected_employees', 'company_id', 'department_id'],
        order: 'id desc',
        limit: 100,
      );
      final applicants = await _odoo.searchRead(
        'hr.applicant',
        fields: const ['partner_name', 'email_from', 'job_id', 'stage_id', 'priority'],
        order: 'id desc',
        limit: 120,
      );
      _jobs = jobs.map((e) => Map<String, dynamic>.from(e as Map)).toList();
      _applicants = applicants.map((e) => Map<String, dynamic>.from(e as Map)).toList();
    } catch (e) {
      _error = OdooService.prettyError(e);
    }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _rateCandidate(int id, String currentPriority) async {
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
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('No se pudo evaluar: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: AppScaffold(
        title: 'Reclutamiento',
        actions: [IconButton(onPressed: _load, icon: const Icon(Icons.refresh_rounded))],
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? AppEmptyState(title: 'Error', subtitle: _error!, icon: Icons.error_outline_rounded)
                : Column(
                    children: [
                      const TabBar(tabs: [Tab(text: 'Vacantes'), Tab(text: 'Candidaturas')]),
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
                                      final dept = it['department_id'] is List ? it['department_id'][1].toString() : '-';
                                      return Padding(
                                        padding: const EdgeInsets.only(bottom: 8),
                                        child: AppCard(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text((it['name'] ?? '').toString(),
                                                  style: const TextStyle(fontWeight: FontWeight.w700)),
                                              const SizedBox(height: 6),
                                              Text('Departamento: $dept',
                                                  style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                                              Text('Vacantes: ${(it['no_of_recruitment'] ?? 0)}',
                                                  style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
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
                                      final job = it['job_id'] is List ? it['job_id'][1].toString() : '-';
                                      final stage = it['stage_id'] is List ? it['stage_id'][1].toString() : '-';
                                      final id = (it['id'] as num).toInt();
                                      final priority = (it['priority'] ?? '0').toString();
                                      return Padding(
                                        padding: const EdgeInsets.only(bottom: 8),
                                        child: AppCard(
                                          onTap: () => _rateCandidate(id, priority),
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                children: [
                                                  Expanded(
                                                    child: Text((it['partner_name'] ?? 'Candidato').toString(),
                                                        style: const TextStyle(fontWeight: FontWeight.w700)),
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
                                              Text('Puesto: $job',
                                                  style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                                              Text('Estado: $stage',
                                                  style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                                              Text((it['email_from'] ?? '-').toString(),
                                                  style: const TextStyle(fontSize: 12, color: AppTheme.textMuted)),
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
}

