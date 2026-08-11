import 'package:flutter/material.dart';

import '../../app/ui/app_components.dart';
import '../../services/odoo_service.dart';
import '../../services/portal_api_service.dart';
import '../../theme/app_theme.dart';

class EquipmentScreen extends StatefulWidget {
  const EquipmentScreen({super.key});

  @override
  State<EquipmentScreen> createState() => _EquipmentScreenState();
}

class _EquipmentScreenState extends State<EquipmentScreen> {
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
          ? await _portalApi.section('equipment', limit: 160)
          : await _odoo.searchRead(
              'calidad.equipo',
              fields: const [
                'name',
                'codigo',
                'estado',
                'requiere_intervencion',
                'unidad_id',
              ],
              order: 'name',
              limit: 160,
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
      appBar: AppBar(
        title: Text('Equipos'),
        actions: [
          IconButton(onPressed: _load, icon: Icon(Icons.refresh_rounded)),
        ],
      ),
      body: _loading
          ? const AppLoadingView()
          : _error != null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(_error!),
              ),
            )
          : _rows.isEmpty
          ? Center(
              child: Text(
                'Sin equipos visibles.',
                style: TextStyle(color: AppTheme.textMutedFor(context)),
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
              itemCount: _rows.length,
              separatorBuilder: (_, i) => const SizedBox(height: 8),
              itemBuilder: (_, i) {
                final it = _rows[i];
                final unidad = it['unidad_id'] is List
                    ? it['unidad_id'][1].toString()
                    : '';
                return Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.cardFor(context),
                    borderRadius: AppTheme.radiusMd,
                    border: Border.all(
                      color: AppTheme.dividerFor(
                        context,
                      ).withValues(alpha: 0.6),
                    ),
                    boxShadow: AppTheme.subtleShadowFor(context),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        (it['name'] ?? '').toString(),
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                      if ((it['codigo'] ?? '').toString().isNotEmpty)
                        Text(
                          'Código: ${it['codigo']}',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppTheme.textSecondaryFor(context),
                          ),
                        ),
                      Text(
                        'Estado: ${it['estado'] ?? '-'}',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppTheme.textSecondaryFor(context),
                        ),
                      ),
                      Text(
                        'Intervención: ${(it['requiere_intervencion'] == true) ? 'Sí' : 'No'}',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppTheme.textMutedFor(context),
                        ),
                      ),
                      if (unidad.isNotEmpty)
                        Text(
                          'Unidad: $unidad',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppTheme.textMutedFor(context),
                          ),
                        ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}
