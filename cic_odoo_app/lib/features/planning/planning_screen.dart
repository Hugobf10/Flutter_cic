import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../services/odoo_service.dart';
import '../../services/odoo_values.dart';
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
      final auth = context.read<AuthProvider>();
      final domain = <dynamic>[];
      if (auth.isPortalUser && auth.partnerId > 0) {
        domain.add(['contacto_id', '=', auth.partnerId]);
      }
      final rows = await _odoo.searchRead(
        'reserva.reserva',
        domain: domain,
        fields: [
          'servicio_id',
          'fecha_inicio',
          'fecha_fin',
          'estado',
          'contacto_id',
        ],
        order: 'fecha_inicio asc',
        limit: 120,
      );
      _items = rows.map((e) => Map<String, dynamic>.from(e as Map)).toList();
    } catch (e) {
      _error = OdooService.prettyError(e);
    }
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Planificación'),
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
                'Sin reservas planificadas.',
                style: TextStyle(color: AppTheme.textMuted),
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
              itemCount: _items.length,
              separatorBuilder: (_, index) => const SizedBox(height: 8),
              itemBuilder: (_, i) {
                final it = _items[i];
                final servicio = OdooValues.many2oneLabel(
                  it['servicio_id'],
                  fallback: 'Servicio',
                );
                final contacto = OdooValues.many2oneLabel(
                  it['contacto_id'],
                  fallback: 'Usuario',
                );
                return Container(
                  decoration: BoxDecoration(
                    color: AppTheme.cardFor(context),
                    borderRadius: AppTheme.radiusMd,
                    border: Border.all(
                      color: AppTheme.dividerFor(
                        context,
                      ).withValues(alpha: 0.6),
                    ),
                  ),
                  child: ListTile(
                    onTap: () => _openReservationDetail(it),
                    title: Text(
                      servicio,
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textPrimaryFor(context),
                      ),
                    ),
                    subtitle: Text(
                      '${it['fecha_inicio'] ?? ''} -> ${it['fecha_fin'] ?? ''}\nResponsable: $contacto · Estado: ${it['estado'] ?? ''}',
                      style: TextStyle(
                        color: AppTheme.textSecondaryFor(context),
                        fontSize: 12,
                      ),
                    ),
                    trailing: const Icon(Icons.chevron_right_rounded),
                  ),
                );
              },
            ),
    );
  }

  void _openReservationDetail(Map<String, dynamic> item) {
    final servicio = OdooValues.many2oneLabel(
      item['servicio_id'],
      fallback: 'Servicio',
    );
    final contacto = OdooValues.many2oneLabel(
      item['contacto_id'],
      fallback: 'Usuario',
    );
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(servicio, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 10),
            Text('Inicio: ${item['fecha_inicio'] ?? '-'}'),
            Text('Fin: ${item['fecha_fin'] ?? '-'}'),
            Text('Responsable: $contacto'),
            Text('Estado: ${item['estado'] ?? '-'}'),
            const SizedBox(height: 12),
            Text(
              'Para editar o cancelar desde móvil se usarán las acciones disponibles cuando el perfil tenga permisos API de escritura sobre reservas.',
              style: TextStyle(
                color: AppTheme.textMutedFor(context),
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
