import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app/ui/app_components.dart';
import '../../providers/auth_provider.dart';
import '../../services/odoo_service.dart';
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
                'fecha_realizacion',
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
    final auth = context.watch<AuthProvider>();
    final pending = _rows
        .where((e) => (e['estado'] ?? '').toString() == 'pendiente')
        .length;
    final completed = _rows
        .where((e) => (e['estado'] ?? '').toString() == 'realizado')
        .length;
    final inProgress = _rows
        .where((e) => (e['estado'] ?? '').toString() == 'en_proceso')
        .length;

    return DefaultTabController(
      length: 2,
      child: AppScaffold(
        title: 'Formación',
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
              icon: const Icon(Icons.add_rounded),
            ),
          IconButton(onPressed: _load, icon: const Icon(Icons.refresh_rounded)),
        ],
        child: Column(
          children: [
            const TabBar(
              tabs: [
                Tab(text: 'Mis formaciones'),
                Tab(text: 'Historial'),
              ],
            ),
            const SizedBox(height: 12),
            Expanded(
              child: _loading
                  ? const AppLoadingView()
                  : _error != null && !_limitedAccessMode
                  ? AppEmptyState(
                      title: 'Error al cargar formación',
                      subtitle: _error!,
                      icon: Icons.error_outline_rounded,
                    )
                  : TabBarView(
                      children: [
                        ListView(
                          children: [
                            if (_limitedAccessMode) ...[
                              const AppCard(
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
                                            'Formación con acceso limitado',
                                            style: TextStyle(
                                              fontWeight: FontWeight.w700,
                                              color: AppTheme.textPrimary,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    SizedBox(height: 10),
                                    Text(
                                      'Este perfil no puede consultar el historial completo de formaciones por API con sus permisos actuales.',
                                      style: TextStyle(
                                        color: AppTheme.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ] else ...[
                              _kpi(
                                'Pendientes',
                                pending.toString(),
                                AppTheme.warning,
                              ),
                              const SizedBox(height: 8),
                              _kpi(
                                'En progreso',
                                inProgress.toString(),
                                AppTheme.info,
                              ),
                              const SizedBox(height: 8),
                              _kpi(
                                'Completadas',
                                completed.toString(),
                                AppTheme.success,
                              ),
                            ],
                            const SizedBox(height: 12),
                            AppCard(
                              child: Text(
                                _limitedAccessMode
                                    ? 'La app sigue disponible en modo limitado. Si este perfil debe consultar el historial o certificados, hay que habilitar permisos API de formación en Odoo.'
                                    : 'Registra formación externa y adjunta certificados desde el botón +.',
                              ),
                            ),
                          ],
                        ),
                        _limitedAccessMode
                            ? const AppEmptyState(
                                title: 'Historial no disponible',
                                subtitle:
                                    'Este perfil no puede cargar asistencias de formación por API con sus permisos actuales.',
                                icon: Icons.lock_outline_rounded,
                              )
                            : _rows.isEmpty
                            ? const AppEmptyState(
                                title: 'Sin historial',
                                subtitle:
                                    'Aún no tienes asistencias de formación.',
                                icon: Icons.school_outlined,
                              )
                            : ListView.builder(
                                itemCount: _rows.length,
                                itemBuilder: (context, index) {
                                  final it = _rows[index];
                                  final formacion = it['formacion_id'] is List
                                      ? it['formacion_id'][1].toString()
                                      : 'Formación';
                                  final estado = (it['estado'] ?? '-')
                                      .toString();
                                  final color = estado == 'realizado'
                                      ? AppTheme.success
                                      : estado == 'en_proceso'
                                      ? AppTheme.info
                                      : AppTheme.warning;
                                  final cert =
                                      (it['certificado_attachment_id']
                                          is List &&
                                      (it['certificado_attachment_id'] as List)
                                          .isNotEmpty);
                                  return Padding(
                                    padding: const EdgeInsets.only(bottom: 8),
                                    child: AppCard(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Expanded(
                                                child: Text(
                                                  formacion,
                                                  style: const TextStyle(
                                                    fontWeight: FontWeight.w700,
                                                    color: AppTheme.textPrimary,
                                                  ),
                                                ),
                                              ),
                                              AppStatusChip(
                                                label: estado.replaceAll(
                                                  '_',
                                                  ' ',
                                                ),
                                                color: color,
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 6),
                                          Text(
                                            'Fecha: ${it['fecha_realizacion'] ?? '-'}',
                                            style: const TextStyle(
                                              fontSize: 12,
                                              color: AppTheme.textSecondary,
                                            ),
                                          ),
                                          if (cert)
                                            Text(
                                              'Certificado adjunto',
                                              style: const TextStyle(
                                                fontSize: 12,
                                                color: AppTheme.textMuted,
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
              style: const TextStyle(
                color: AppTheme.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: AppTheme.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
