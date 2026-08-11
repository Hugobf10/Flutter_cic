import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app/ui/app_components.dart';
import '../../features/forms/dynamic_form.dart';
import '../../providers/auth_provider.dart';
import '../../services/odoo_service.dart';
import '../../services/portal_api_service.dart';
import '../../theme/app_theme.dart';

class SuggestionsScreen extends StatefulWidget {
  const SuggestionsScreen({super.key});

  @override
  State<SuggestionsScreen> createState() => _SuggestionsScreenState();
}

class _SuggestionsScreenState extends State<SuggestionsScreen> {
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
    final auth = context.read<AuthProvider>();
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      if (_odoo.isPortalSession) {
        _rows = await _portalApi.section('suggestions');
        if (mounted) setState(() => _loading = false);
        return;
      }
      final domain = <dynamic>[
        ['tipo', '=', 'sugerencia'],
      ];
      if (auth.isPortalUser) {
        domain.add(['partner_id', '=', auth.partnerId]);
      }
      final rows = await _odoo.searchRead(
        'calidad.comunicacion',
        domain: domain,
        fields: const ['name', 'descripcion', 'fecha', 'estado'],
        order: 'fecha desc, id desc',
        limit: 80,
      );
      _rows = rows.map((e) => Map<String, dynamic>.from(e as Map)).toList();
    } catch (e) {
      _error = OdooService.prettyError(e);
    }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _openCreate() async {
    final created = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.fromLTRB(
            16,
            8,
            16,
            16 + MediaQuery.of(ctx).viewInsets.bottom,
          ),
          child: DynamicForm(
            submitLabel: 'Enviar sugerencia',
            fields: const [
              DynamicFieldConfig(key: 'name', label: 'Título', required: true),
              DynamicFieldConfig(
                key: 'descripcion',
                label: 'Descripción',
                required: true,
                type: DynamicFieldType.multiline,
                maxLines: 4,
              ),
            ],
            onSubmit: (values) async {
              if (_odoo.isPortalSession) {
                await _portalApi.action(
                  'suggestion_create',
                  values: {
                    'name': values['name'],
                    'descripcion': values['descripcion'],
                  },
                );
              } else {
                await _odoo.create('calidad.comunicacion', {
                  'name': values['name'],
                  'tipo': 'sugerencia',
                  'descripcion': values['descripcion'],
                });
              }
            },
          ),
        );
      },
    );
    if (created == true) _load();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    return Scaffold(
      appBar: AppBar(
        title: Text('Sugerencias'),
        actions: [
          if (auth.canEditModule('suggestions'))
            IconButton(
              onPressed: _openCreate,
              icon: Icon(Icons.add_comment_rounded),
            ),
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
                'Sin sugerencias enviadas.',
                style: TextStyle(color: AppTheme.textMutedFor(context)),
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
              itemCount: _rows.length,
              separatorBuilder: (_, i) => const SizedBox(height: 8),
              itemBuilder: (_, i) {
                final it = _rows[i];
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
                      const SizedBox(height: 4),
                      Text(
                        (it['descripcion'] ?? '').toString(),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12,
                          color: AppTheme.textSecondaryFor(context),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Estado: ${it['estado'] ?? '-'} · ${it['fecha'] ?? ''}',
                        style: TextStyle(
                          fontSize: 11,
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
