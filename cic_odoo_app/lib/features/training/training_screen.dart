import 'package:flutter/material.dart';

import '../../services/odoo_service.dart';
import '../../theme/app_theme.dart';

class TrainingScreen extends StatefulWidget {
  const TrainingScreen({super.key});

  @override
  State<TrainingScreen> createState() => _TrainingScreenState();
}

class _TrainingScreenState extends State<TrainingScreen> {
  final OdooService _odoo = OdooService();
  bool _loading = true;
  String? _error;
  int _pending = 0;
  int _completed = 0;

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
      final data = await _odoo.getDashboardData();
      final kpis = List<dynamic>.from((data['kpis'] ?? []) as List);
      int readKpi(String key) {
        final raw = kpis.cast<Map>().firstWhere(
          (e) => e['key']?.toString() == key,
          orElse: () => const {},
        );
        final v = raw['value'];
        return v is num ? v.toInt() : int.tryParse(v?.toString() ?? '') ?? 0;
      }
      _pending = readKpi('formaciones_pendientes');
      _completed = readKpi('formaciones_completadas');
    } catch (e) {
      _error = e.toString();
    }
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Formación'),
        actions: [IconButton(onPressed: _load, icon: const Icon(Icons.refresh_rounded))],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Padding(padding: const EdgeInsets.all(16), child: Text(_error!)))
              : ListView(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                  children: [
                    _kpi('Pendientes', _pending.toString(), Icons.school_rounded, AppTheme.warning),
                    _kpi('Completadas', _completed.toString(), Icons.verified_rounded, AppTheme.success),
                    const SizedBox(height: 10),
                    const Text(
                      'Resumen obtenido desde el dashboard de Odoo para seguimiento de formación.',
                      style: TextStyle(color: AppTheme.textMuted),
                    ),
                  ],
                ),
    );
  }

  Widget _kpi(String title, String value, IconData icon, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.surfaceCard,
        borderRadius: AppTheme.radiusMd,
        border: Border.all(color: AppTheme.divider.withValues(alpha: 0.6)),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: AppTheme.radiusSm,
            ),
            child: Icon(icon, color: color),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title, style: const TextStyle(color: AppTheme.textSecondary)),
              Text(value, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: AppTheme.textPrimary)),
            ]),
          ),
        ],
      ),
    );
  }
}
