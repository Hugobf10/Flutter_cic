import 'package:flutter/material.dart';

import '../../services/odoo_service.dart';
import '../../theme/app_theme.dart';

class HealthScreen extends StatefulWidget {
  const HealthScreen({super.key});

  @override
  State<HealthScreen> createState() => _HealthScreenState();
}

class _HealthScreenState extends State<HealthScreen> {
  final OdooService _odoo = OdooService();
  bool _loading = true;
  String? _error;
  List<Map<String, dynamic>> _rows = [];

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
        'calidad.salud.reconocimiento',
        fields: const ['name', 'fecha_prevista', 'fecha_realizada', 'estado'],
        order: 'fecha_prevista desc, id desc',
        limit: 120,
      );
      _rows = rows.map((e) => Map<String, dynamic>.from(e as Map)).toList();
    } catch (e) {
      _error = e.toString();
    }
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Vigilancia de la salud'), actions: [IconButton(onPressed: _load, icon: const Icon(Icons.refresh_rounded))]),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Padding(padding: const EdgeInsets.all(16), child: Text(_error!)))
              : _rows.isEmpty
                  ? const Center(child: Text('Sin reconocimientos registrados.', style: TextStyle(color: AppTheme.textMuted)))
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
                      itemCount: _rows.length,
                      separatorBuilder: (_, i) => const SizedBox(height: 8),
                      itemBuilder: (_, i) {
                        final it = _rows[i];
                        return Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppTheme.surfaceCard,
                            borderRadius: AppTheme.radiusMd,
                            border: Border.all(color: AppTheme.divider.withValues(alpha: 0.6)),
                          ),
                          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text((it['name'] ?? 'Reconocimiento').toString(), style: const TextStyle(fontWeight: FontWeight.w700)),
                            const SizedBox(height: 4),
                            Text('Prevista: ${it['fecha_prevista'] ?? '-'}', style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                            Text('Realizada: ${it['fecha_realizada'] ?? '-'}', style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                            Text('Estado: ${it['estado'] ?? '-'}', style: const TextStyle(fontSize: 12, color: AppTheme.textMuted)),
                          ]),
                        );
                      },
                    ),
    );
  }
}
