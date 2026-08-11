import 'package:flutter/material.dart';

import '../../app/ui/app_components.dart';
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
        title: Text('Normativa'),
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
          : _items.isEmpty
          ? Center(
              child: Text(
                'Sin normativa disponible.',
                style: TextStyle(color: AppTheme.textMutedFor(context)),
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
                      if ((it['codigo'] ?? '').toString().isNotEmpty)
                        Text(
                          it['codigo'].toString(),
                          style: TextStyle(
                            fontSize: 11,
                            color: AppTheme.textMutedFor(context),
                          ),
                        ),
                      Text(
                        (it['name'] ?? '').toString(),
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textPrimaryFor(context),
                        ),
                      ),
                      if ((it['fecha_publicacion'] ?? '').toString().isNotEmpty)
                        Text(
                          'Publicación: ${it['fecha_publicacion']}',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppTheme.textSecondaryFor(context),
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
