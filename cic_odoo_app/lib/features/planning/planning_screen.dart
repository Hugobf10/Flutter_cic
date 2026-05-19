import 'package:flutter/material.dart';

import '../../services/odoo_service.dart';
import '../../theme/app_theme.dart';

class PlanningScreen extends StatefulWidget {
  const PlanningScreen({super.key});

  @override
  State<PlanningScreen> createState() => _PlanningScreenState();
}

class _PlanningScreenState extends State<PlanningScreen> {
  final OdooService _odoo = OdooService();
  bool _loading = true;
  String? _error;
  List<Map<String, dynamic>> _items = [];

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
      final rows = await _odoo.searchRead(
        'reserva.reserva',
        fields: ['servicio_id', 'fecha_inicio', 'fecha_fin', 'estado', 'contacto_id'],
        order: 'fecha_inicio asc',
        limit: 120,
      );
      _items = rows.map((e) => Map<String, dynamic>.from(e as Map)).toList();
    } catch (e) {
      _error = e.toString();
    }
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Planificación'),
        actions: [IconButton(onPressed: _load, icon: const Icon(Icons.refresh_rounded))],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Padding(padding: const EdgeInsets.all(16), child: Text(_error!)))
              : _items.isEmpty
                  ? const Center(child: Text('Sin reservas planificadas.', style: TextStyle(color: AppTheme.textMuted)))
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
                      itemCount: _items.length,
                      separatorBuilder: (_, index) => const SizedBox(height: 8),
                      itemBuilder: (_, i) {
                        final it = _items[i];
                        final servicio = it['servicio_id'] is List ? it['servicio_id'][1].toString() : 'Servicio';
                        final contacto = it['contacto_id'] is List ? it['contacto_id'][1].toString() : 'Usuario';
                        return Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppTheme.surfaceCard,
                            borderRadius: AppTheme.radiusMd,
                            border: Border.all(color: AppTheme.divider.withValues(alpha: 0.6)),
                          ),
                          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text(servicio, style: const TextStyle(fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
                            const SizedBox(height: 4),
                            Text('${it['fecha_inicio'] ?? ''} -> ${it['fecha_fin'] ?? ''}', style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                            const SizedBox(height: 2),
                            Text('Responsable: $contacto · Estado: ${it['estado'] ?? ''}', style: const TextStyle(color: AppTheme.textMuted, fontSize: 12)),
                          ]),
                        );
                      },
                    ),
    );
  }
}
