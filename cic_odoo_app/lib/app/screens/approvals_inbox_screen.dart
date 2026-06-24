import 'package:flutter/material.dart';

import '../../services/odoo_service.dart';
import '../../theme/app_theme.dart';

class ApprovalsInboxScreen extends StatefulWidget {
  const ApprovalsInboxScreen({super.key});

  @override
  State<ApprovalsInboxScreen> createState() => _ApprovalsInboxScreenState();
}

class _ApprovalsInboxScreenState extends State<ApprovalsInboxScreen> {
  final OdooService _odoo = OdooService();
  bool _loading = true;
  List<_ApprovalItem> _items = const [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final items = <_ApprovalItem>[];

    try {
      final inc = await _odoo.searchRead(
        'calidad.incidencia',
        fields: ['name', 'estado', 'fecha'],
        domain: [
          [
            'estado',
            'in',
            ['abierta', 'en_proceso'],
          ],
        ],
        order: 'id desc',
        limit: 20,
      );
      for (final r in inc) {
        final m = Map<String, dynamic>.from(r as Map);
        items.add(
          _ApprovalItem(
            title: m['name']?.toString() ?? 'Incidencia',
            subtitle: 'Incidencias',
            state: m['estado']?.toString() ?? 'pendiente',
            date: m['fecha']?.toString() ?? '',
          ),
        );
      }
    } catch (_) {}

    try {
      final com = await _odoo.searchRead(
        'calidad.comunicacion',
        fields: ['name', 'estado', 'fecha'],
        domain: [
          [
            'estado',
            'in',
            ['recibida', 'en_analisis', 'tratada'],
          ],
        ],
        order: 'id desc',
        limit: 20,
      );
      for (final r in com) {
        final m = Map<String, dynamic>.from(r as Map);
        items.add(
          _ApprovalItem(
            title: m['name']?.toString() ?? 'Comunicación',
            subtitle: 'Comunicaciones',
            state: m['estado']?.toString() ?? 'pendiente',
            date: m['fecha']?.toString() ?? '',
          ),
        );
      }
    } catch (_) {}

    try {
      final sup = await _odoo.searchRead(
        'calidad.proveedor.unidad',
        fields: [
          'partner_id',
          'estado',
          'fecha_homologacion',
          'fecha_desestimacion',
        ],
        order: 'id desc',
        limit: 20,
      );
      for (final r in sup) {
        final m = Map<String, dynamic>.from(r as Map);
        items.add(
          _ApprovalItem(
            title: m['partner_id'] is List
                ? m['partner_id'][1].toString()
                : 'Proveedor',
            subtitle: 'Proveedores',
            state: m['estado']?.toString() ?? 'pendiente',
            date: (m['fecha_desestimacion'] ?? m['fecha_homologacion'] ?? '')
                .toString(),
          ),
        );
      }
    } catch (_) {}

    if (mounted) {
      setState(() {
        _items = items;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Aprobaciones'),
        actions: [
          IconButton(onPressed: _load, icon: const Icon(Icons.refresh_rounded)),
        ],
      ),
      body: _items.isEmpty
          ? const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'No hay aprobaciones pendientes para tu usuario.',
                  textAlign: TextAlign.center,
                ),
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 100),
              itemCount: _items.length,
              separatorBuilder: (_, index) => const SizedBox(height: 8),
              itemBuilder: (_, i) {
                final item = _items[i];
                final c = _color(item.state);
                return Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    borderRadius: AppTheme.radiusMd,
                    border: Border.all(
                      color: Theme.of(
                        context,
                      ).dividerColor.withValues(alpha: 0.5),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: c,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.title,
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              '${item.subtitle} · ${item.date}',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: c.withValues(alpha: 0.15),
                          borderRadius: AppTheme.radiusXl,
                        ),
                        child: Text(
                          item.state,
                          style: TextStyle(
                            color: c,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }

  Color _color(String state) {
    if (state.contains('abierta') || state.contains('desestimado')) {
      return AppTheme.danger;
    }
    if (state.contains('analisis') ||
        state.contains('proceso') ||
        state.contains('recibida')) {
      return AppTheme.warning;
    }
    if (state.contains('homologado') || state.contains('respondida')) {
      return AppTheme.success;
    }
    return AppTheme.info;
  }
}

class _ApprovalItem {
  const _ApprovalItem({
    required this.title,
    required this.subtitle,
    required this.state,
    required this.date,
  });

  final String title;
  final String subtitle;
  final String state;
  final String date;
}
