import 'package:flutter/material.dart';

import '../../services/odoo_service.dart';
import '../../theme/app_theme.dart';

class PermissionsCenterScreen extends StatefulWidget {
  const PermissionsCenterScreen({super.key});

  @override
  State<PermissionsCenterScreen> createState() => _PermissionsCenterScreenState();
}

class _PermissionsCenterScreenState extends State<PermissionsCenterScreen> {
  final OdooService _odoo = OdooService();
  bool _loading = true;
  String? _error;
  List<Map<String, dynamic>> _roles = [];
  List<Map<String, dynamic>> _approvals = [];

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
      final roles = await _odoo.searchRead(
        'calidad.perfil',
        fields: ['name'],
        order: 'id desc',
        limit: 30,
      );
      _roles = roles.map((e) => Map<String, dynamic>.from(e as Map)).toList();
    } catch (_) {
      _roles = [
        {'name': 'Administrador'},
        {'name': 'Responsable Calidad'},
        {'name': 'Técnico'},
      ];
    }

    try {
      final approvals = await _odoo.searchRead(
        'calidad.incidencia',
        fields: ['name', 'state', 'fecha'],
        domain: [
          ['state', 'in', ['abierta', 'en_proceso']],
        ],
        order: 'id desc',
        limit: 20,
      );
      _approvals = approvals.map((e) => Map<String, dynamic>.from(e as Map)).toList();
    } catch (_) {
      _approvals = [
        {'name': 'Evaluación de proveedor', 'state': 'pendiente', 'fecha': 'Hoy'},
        {'name': 'Solicitud de permiso', 'state': 'en_proceso', 'fecha': 'Ayer'},
      ];
    }

    if (mounted) {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (_error != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Permisos y roles')),
        body: Center(child: Text(_error!)),
      );
    }

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Permisos y roles'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Roles'),
              Tab(text: 'Aprobaciones'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
              itemCount: _roles.length,
              separatorBuilder: (_, index) => const SizedBox(height: 8),
              itemBuilder: (_, i) {
                final role = _roles[i];
                return Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: AppTheme.radiusMd,
                    border: Border.all(color: Theme.of(context).dividerColor.withValues(alpha: 0.5)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(
                          color: AppTheme.primary.withValues(alpha: 0.14),
                          borderRadius: AppTheme.radiusSm,
                        ),
                        child: const Icon(Icons.verified_user_rounded, size: 18, color: AppTheme.primary),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          role['name']?.toString() ?? 'Rol',
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ),
                      const Icon(Icons.chevron_right_rounded),
                    ],
                  ),
                );
              },
            ),
            ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
              itemCount: _approvals.length,
              separatorBuilder: (_, index) => const SizedBox(height: 8),
              itemBuilder: (_, i) {
                final item = _approvals[i];
                final state = item['state']?.toString() ?? 'pendiente';
                final color = state == 'abierta'
                    ? AppTheme.danger
                    : state == 'en_proceso'
                        ? AppTheme.warning
                        : AppTheme.info;
                return Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: AppTheme.radiusMd,
                    border: Border.all(color: Theme.of(context).dividerColor.withValues(alpha: 0.5)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              item['name']?.toString() ?? 'Aprobación',
                              style: const TextStyle(fontWeight: FontWeight.w700),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: color.withValues(alpha: 0.14),
                              borderRadius: AppTheme.radiusXl,
                            ),
                            child: Text(state, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w700)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(item['fecha']?.toString() ?? '', style: Theme.of(context).textTheme.bodySmall),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
