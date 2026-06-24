import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app/ui/app_components.dart';
import '../../providers/auth_provider.dart';
import '../../services/odoo_service.dart';
import '../../theme/app_theme.dart';

class MaintenanceScreen extends StatefulWidget {
  const MaintenanceScreen({super.key});

  @override
  State<MaintenanceScreen> createState() => _MaintenanceScreenState();
}

class _MaintenanceScreenState extends State<MaintenanceScreen> {
  final OdooService _odoo = OdooService();

  bool _loading = true;
  String? _error;
  List<Map<String, dynamic>> _requests = [];
  List<Map<String, dynamic>> _equipment = [];

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
      final equipment = await _odoo.searchRead(
        'calidad.equipo',
        fields: const [
          'name',
          'codigo',
          'estado',
          'requiere_intervencion',
          'maintenance_equipment_id',
          'maintenance_request_count',
          'maintenance_open_request_count',
          'maintenance_last_request_date',
          'unidad_id',
        ],
        order: 'requiere_intervencion desc, maintenance_open_request_count desc, name asc',
        limit: 200,
      );
      final requests = await _odoo.searchRead(
        'maintenance.request',
        fields: const [
          'name',
          'maintenance_type',
          'request_date',
          'schedule_date',
          'close_date',
          'stage_id',
          'equipment_id',
          'user_id',
          'owner_user_id',
          'description',
          'calidad_equipo_id',
        ],
        order: 'close_date asc, request_date desc, id desc',
        limit: 200,
      );
      _equipment = equipment
          .map((item) => Map<String, dynamic>.from(item as Map))
          .toList();
      _requests = requests
          .map((item) => Map<String, dynamic>.from(item as Map))
          .toList();
    } catch (e) {
      _error = OdooService.prettyError(e);
    }

    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final openRequests = _requests.where((row) => !_isClosed(row)).length;
    final linkedEquipment =
        _equipment.where((row) => row['maintenance_equipment_id'] is List).length;
    final pendingInterventions = _equipment
        .where((row) => row['requiere_intervencion'] == true)
        .length;

    return DefaultTabController(
      length: 2,
      child: AppScaffold(
        title: 'Mantenimiento',
        actions: [
          IconButton(
            onPressed: _load,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
        child: _loading
            ? const AppLoadingView(label: 'Cargando mantenimiento...')
            : _error != null
                ? AppEmptyState(
                    title: 'No se pudo cargar mantenimiento',
                    subtitle: _error!,
                    icon: Icons.error_outline_rounded,
                    action: AppButton.primary(
                      label: 'Reintentar',
                      onPressed: _load,
                    ),
                  )
                : Column(
                    children: [
                      LayoutBuilder(
                        builder: (context, constraints) {
                          final width = constraints.maxWidth;
                          final compact = width < 760;

                          final cards = [
                            _MaintenanceStatCard(
                              label: 'Solicitudes abiertas',
                              value: openRequests.toString(),
                              icon: Icons.build_circle_outlined,
                              color: AppTheme.warning,
                            ),
                            _MaintenanceStatCard(
                              label: 'Equipos vinculados',
                              value: linkedEquipment.toString(),
                              icon: Icons.sync_alt_rounded,
                              color: AppTheme.primary,
                            ),
                            _MaintenanceStatCard(
                              label: 'Pendientes de intervención',
                              value: pendingInterventions.toString(),
                              icon: Icons.warning_amber_rounded,
                              color: AppTheme.danger,
                            ),
                          ];

                          if (compact) {
                            return Column(
                              children: [
                                for (final card in cards) ...[
                                  card,
                                  const SizedBox(height: 10),
                                ],
                              ],
                            );
                          }

                          return Row(
                            children: [
                              for (var i = 0; i < cards.length; i++) ...[
                                Expanded(child: cards[i]),
                                if (i < cards.length - 1)
                                  const SizedBox(width: 10),
                              ],
                            ],
                          );
                        },
                      ),
                      const SizedBox(height: 14),
                      AppCard(
                        child: Row(
                          children: [
                            const Expanded(
                              child: Text(
                                'La vista usa `maintenance.request` y el enlace real con `calidad.equipo` del addon `calidad_equipos_mantenimiento`.',
                                style: TextStyle(
                                  color: AppTheme.textSecondary,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            AppStatusChip(
                              label: auth.canEditModule('equipment')
                                  ? 'Edición permitida en Odoo'
                                  : 'Solo lectura',
                              color: auth.canEditModule('equipment')
                                  ? AppTheme.success
                                  : AppTheme.textMuted,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      const TabBar(
                        tabs: [
                          Tab(text: 'Solicitudes'),
                          Tab(text: 'Equipos'),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Expanded(
                        child: TabBarView(
                          children: [
                            _buildRequests(),
                            _buildEquipment(),
                          ],
                        ),
                      ),
                    ],
                  ),
      ),
    );
  }

  Widget _buildRequests() {
    if (_requests.isEmpty) {
      return const AppEmptyState(
        title: 'Sin solicitudes',
        subtitle:
            'No hay solicitudes de mantenimiento visibles para este usuario.',
        icon: Icons.build_outlined,
      );
    }

    return ListView.separated(
      itemCount: _requests.length,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final row = _requests[index];
        final equipment = row['equipment_id'] is List
            ? row['equipment_id'][1].toString()
            : 'Equipo no vinculado';
        final owner = row['owner_user_id'] is List
            ? row['owner_user_id'][1].toString()
            : row['user_id'] is List
                ? row['user_id'][1].toString()
                : 'Sin responsable';
        final stage = row['stage_id'] is List
            ? row['stage_id'][1].toString()
            : _isClosed(row)
                ? 'Cerrada'
                : 'Abierta';
        final qualityEquipment = row['calidad_equipo_id'] is List
            ? row['calidad_equipo_id'][1].toString()
            : '';

        return AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      (row['name'] ?? 'Solicitud de mantenimiento').toString(),
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                  ),
                  AppStatusChip(
                    label: _requestTypeLabel(
                      (row['maintenance_type'] ?? '').toString(),
                    ),
                    color: _requestTypeColor(
                      (row['maintenance_type'] ?? '').toString(),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                equipment,
                style: const TextStyle(color: AppTheme.textSecondary),
              ),
              if (qualityEquipment.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  'Equipo de calidad: $qualityEquipment',
                  style: const TextStyle(
                    color: AppTheme.textMuted,
                    fontSize: 12,
                  ),
                ),
              ],
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  AppStatusChip(
                    label: stage,
                    color: _isClosed(row) ? AppTheme.success : AppTheme.warning,
                  ),
                  AppStatusChip(
                    label: 'Responsable: $owner',
                    color: AppTheme.primary,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Solicitud: ${_formatValue(row['request_date'])}\nProgramada: ${_formatValue(row['schedule_date'])}\nCierre: ${_formatValue(row['close_date'])}',
                style: const TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 12,
                ),
              ),
              if ((row['description'] ?? '').toString().trim().isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  (row['description'] ?? '').toString().trim(),
                  style: const TextStyle(
                    color: AppTheme.textMuted,
                    fontSize: 12,
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildEquipment() {
    if (_equipment.isEmpty) {
      return const AppEmptyState(
        title: 'Sin equipos enlazados',
        subtitle:
            'Todavía no hay equipos de calidad sincronizados con mantenimiento.',
        icon: Icons.precision_manufacturing_outlined,
      );
    }

    return ListView.separated(
      itemCount: _equipment.length,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final row = _equipment[index];
        final unit = row['unidad_id'] is List
            ? row['unidad_id'][1].toString()
            : '';
        final openCount = (row['maintenance_open_request_count'] ?? 0).toString();
        final totalCount = (row['maintenance_request_count'] ?? 0).toString();
        final linked = row['maintenance_equipment_id'] is List;

        return AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      (row['name'] ?? 'Equipo').toString(),
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                  ),
                  AppStatusChip(
                    label: row['requiere_intervencion'] == true
                        ? 'Requiere intervención'
                        : 'Controlado',
                    color: row['requiere_intervencion'] == true
                        ? AppTheme.danger
                        : AppTheme.success,
                  ),
                ],
              ),
              const SizedBox(height: 6),
              if ((row['codigo'] ?? '').toString().trim().isNotEmpty)
                Text(
                  'Código: ${row['codigo']}',
                  style: const TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 12,
                  ),
                ),
              Text(
                'Estado: ${_equipmentStateLabel((row['estado'] ?? '').toString())}',
                style: const TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 12,
                ),
              ),
              if (unit.isNotEmpty)
                Text(
                  'Unidad: $unit',
                  style: const TextStyle(
                    color: AppTheme.textMuted,
                    fontSize: 12,
                  ),
                ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  AppStatusChip(
                    label: linked ? 'Vinculado a mantenimiento' : 'Sin vínculo',
                    color: linked ? AppTheme.primary : AppTheme.textMuted,
                  ),
                  AppStatusChip(
                    label: '$openCount abiertas',
                    color: AppTheme.warning,
                  ),
                  AppStatusChip(
                    label: '$totalCount totales',
                    color: AppTheme.info,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Última solicitud: ${_formatValue(row['maintenance_last_request_date'])}',
                style: const TextStyle(
                  color: AppTheme.textMuted,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  bool _isClosed(Map<String, dynamic> row) {
    return (row['close_date'] ?? '').toString().trim().isNotEmpty;
  }

  String _formatValue(Object? value) {
    final text = (value ?? '').toString().trim();
    return text.isEmpty ? '-' : text;
  }

  String _requestTypeLabel(String value) {
    switch (value) {
      case 'preventive':
        return 'Preventivo';
      case 'corrective':
        return 'Correctivo';
      default:
        return value.isEmpty ? 'Sin tipo' : value;
    }
  }

  Color _requestTypeColor(String value) {
    switch (value) {
      case 'preventive':
        return AppTheme.primary;
      case 'corrective':
        return AppTheme.danger;
      default:
        return AppTheme.textMuted;
    }
  }

  String _equipmentStateLabel(String value) {
    switch (value) {
      case 'operativo':
        return 'Operativo';
      case 'averiado':
        return 'Averiado';
      case 'retirado':
        return 'Retirado';
      default:
        return value.isEmpty ? '-' : value;
    }
  }
}

class _MaintenanceStatCard extends StatelessWidget {
  const _MaintenanceStatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: AppTheme.radiusSm,
            ),
            child: Icon(icon, color: color),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimary,
                  ),
                ),
                Text(
                  label,
                  style: const TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
