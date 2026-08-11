import 'package:flutter/material.dart';
import '../../app/ui/app_components.dart';
import '../../services/odoo_service.dart';
import '../../services/odoo_values.dart';
import '../../services/portal_api_service.dart';
import '../../theme/app_theme.dart';

class ChemicalReportScreen extends StatefulWidget {
  const ChemicalReportScreen({super.key});

  @override
  State<ChemicalReportScreen> createState() => _ChemicalReportScreenState();
}

class _ChemicalReportScreenState extends State<ChemicalReportScreen> {
  final OdooService _odoo = OdooService();
  final PortalApiService _portalApi = PortalApiService();
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
      final rows = _odoo.isPortalSession
          ? await _portalApi.section('chemical_report', limit: 5000)
          : await _odoo.searchRead(
              'calidad.quimico',
              fields: const [
                'name',
                'tipo',
                'es_peligroso',
                'categoria_peligro',
                'a_punto_agotarse',
                'fecha_caducidad',
                'unidad_id',
              ],
              order: 'id desc',
              limit: 5000,
            );
      _rows = rows.whereType<Map>().map(Map<String, dynamic>.from).toList();
    } catch (e) {
      _error = OdooService.prettyError(e);
    }
    if (mounted) setState(() => _loading = false);
  }

  int _count(bool Function(Map<String, dynamic>) test) =>
      _rows.where(test).length;

  @override
  Widget build(BuildContext context) {
    final dangerous = _count((r) => OdooValues.boolValue(r['es_peligroso']));
    final lowStock = _count((r) => OdooValues.boolValue(r['a_punto_agotarse']));
    final types = <String, int>{};
    final hazards = <String, int>{};
    for (final row in _rows) {
      final type = OdooValues.string(row['tipo'], fallback: 'otro');
      types[type] = (types[type] ?? 0) + 1;
      if (OdooValues.boolValue(row['es_peligroso'])) {
        final hazard = OdooValues.string(
          row['categoria_peligro'],
          fallback: 'otro',
        );
        hazards[hazard] = (hazards[hazard] ?? 0) + 1;
      }
    }
    return AppScaffold(
      title: 'Informe de químicos',
      actions: [IconButton(onPressed: _load, icon: const Icon(Icons.refresh))],
      child: _loading
          ? const AppLoadingView()
          : _error != null
          ? AppEmptyState(
              title: 'Error',
              subtitle: _error!,
              icon: Icons.error_outline_rounded,
            )
          : ListView(
              children: [
                Row(
                  children: [
                    Expanded(child: _metric('Total', _rows.length, Icons.science_outlined)),
                    const SizedBox(width: 8),
                    Expanded(child: _metric('Peligrosos', dangerous, Icons.warning_amber_rounded)),
                    const SizedBox(width: 8),
                    Expanded(child: _metric('A reponer', lowStock, Icons.inventory_2_outlined)),
                  ],
                ),
                const SizedBox(height: 12),
                _breakdown('Por tipo', types),
                const SizedBox(height: 12),
                _breakdown('Peligrosidad', hazards),
                if (_rows.isEmpty)
                  const Padding(
                    padding: EdgeInsets.only(top: 20),
                    child: AppEmptyState(
                      title: 'Sin datos',
                      subtitle: 'No hay químicos disponibles para este informe.',
                      icon: Icons.analytics_outlined,
                    ),
                  ),
              ],
            ),
    );
  }

  Widget _metric(String label, int value, IconData icon) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppTheme.info),
          const SizedBox(height: 8),
          Text('$value', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
          Text(label, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _breakdown(String title, Map<String, int> values) {
    final max = values.values.fold<int>(0, (a, b) => a > b ? a : b);
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 10),
          if (values.isEmpty)
            const Text('Sin datos', style: TextStyle(color: AppTheme.textMuted))
          else
            ...values.entries.map(
              (entry) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    SizedBox(width: 100, child: Text(entry.key.replaceAll('_', ' '))),
                    Expanded(
                      child: LinearProgressIndicator(
                        value: max == 0 ? 0 : entry.value / max,
                        minHeight: 8,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text('${entry.value}', style: const TextStyle(fontWeight: FontWeight.w700)),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
