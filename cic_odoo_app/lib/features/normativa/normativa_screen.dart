import 'package:flutter/material.dart';

import '../../services/odoo_service.dart';
import '../../services/portal_api_service.dart';
import '../../theme/app_theme.dart';

class NormativaScreen extends StatefulWidget {
  const NormativaScreen({super.key});

  @override
  State<NormativaScreen> createState() => _NormativaScreenState();
}

class _NormativaScreenState extends State<NormativaScreen> {
  final OdooService _odoo = OdooService();
  final PortalApiService _portalApi = PortalApiService();
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
      final rows = _odoo.isPortalSession
          ? await _portalApi.section('normative', limit: 120)
          : await _odoo.searchRead(
              'calidad.normativa',
              fields: const [
                'name',
                'codigo',
                'fecha_publicacion',
                'unidad_id',
              ],
              order: 'fecha_publicacion desc, id desc',
              limit: 120,
            );
      _items = rows.map((e) => Map<String, dynamic>.from(e as Map)).toList();
    } catch (_) {
      try {
        final rows = await _odoo.searchRead(
          'calidad.normativa',
          fields: const ['name'],
          order: 'id desc',
          limit: 120,
        );
        _items = rows.map((e) => Map<String, dynamic>.from(e as Map)).toList();
      } catch (e) {
        _error = e.toString();
      }
    }
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Normativa'),
        actions: [
          IconButton(onPressed: _load, icon: const Icon(Icons.refresh_rounded)),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(_error!),
              ),
            )
          : _items.isEmpty
          ? const Center(
              child: Text(
                'Sin normativa disponible.',
                style: TextStyle(color: AppTheme.textMuted),
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
              itemCount: _items.length,
              separatorBuilder: (_, index) => const SizedBox(height: 8),
              itemBuilder: (_, i) {
                final it = _items[i];
                final unidad = it['unidad_id'] is List
                    ? it['unidad_id'][1].toString()
                    : '';
                return Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceCard,
                    borderRadius: AppTheme.radiusMd,
                    border: Border.all(
                      color: AppTheme.divider.withValues(alpha: 0.6),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if ((it['codigo'] ?? '').toString().isNotEmpty)
                        Text(
                          it['codigo'].toString(),
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppTheme.textMuted,
                          ),
                        ),
                      Text(
                        (it['name'] ?? '').toString(),
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      if ((it['fecha_publicacion'] ?? '').toString().isNotEmpty)
                        Text(
                          'Publicación: ${it['fecha_publicacion']}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                      if (unidad.isNotEmpty)
                        Text(
                          'Unidad: $unidad',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppTheme.textMuted,
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
