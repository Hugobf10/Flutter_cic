import 'package:flutter/material.dart';

import '../../app/ui/app_components.dart';
import '../../services/odoo_service.dart';
import '../../services/odoo_values.dart';
import '../../services/portal_api_service.dart';

class PortalSectionScreen extends StatefulWidget {
  const PortalSectionScreen({
    required this.section,
    required this.title,
    super.key,
  });

  final String section;
  final String title;

  @override
  State<PortalSectionScreen> createState() => _PortalSectionScreenState();
}

class _PortalSectionScreenState extends State<PortalSectionScreen> {
  final PortalApiService _api = PortalApiService();
  bool _loading = true;
  String? _error;
  List<Map<String, dynamic>> _items = const [];

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
      _items = await _api.section(widget.section);
    } catch (error) {
      _error = OdooService.prettyError(error);
    }
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: widget.title,
      actions: [
        IconButton(onPressed: _load, icon: Icon(Icons.refresh_rounded)),
      ],
      child: _loading
          ? const AppLoadingView(label: 'Cargando intranet...')
          : _error != null
          ? AppEmptyState(
              title: 'No se pudo cargar ${widget.title.toLowerCase()}',
              subtitle: _error!,
              icon: Icons.error_outline_rounded,
              action: AppButton.primary(label: 'Reintentar', onPressed: _load),
            )
          : _items.isEmpty
          ? AppEmptyState(
              title: 'Sin registros',
              subtitle: 'No hay información disponible para tu cuenta.',
              icon: Icons.inbox_outlined,
            )
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView.separated(
                padding: const EdgeInsets.only(bottom: 24),
                itemCount: _items.length,
                separatorBuilder: (_, _) => const SizedBox(height: 8),
                itemBuilder: (_, index) => _buildItem(_items[index]),
              ),
            ),
    );
  }

  Widget _buildItem(Map<String, dynamic> item) {
    final title = OdooValues.string(
      item['name'] ?? item['title'],
      fallback: 'Registro ${item['id'] ?? ''}',
    );
    final excluded = {'id', 'name', 'title', 'abstract'};
    final details = item.entries
        .where((entry) => !excluded.contains(entry.key))
        .map((entry) {
          final value = entry.value;
          if (value == null || value == false || value.toString().isEmpty) {
            return null;
          }
          final label = entry.key.replaceAll('_', ' ');
          return '$label: ${OdooValues.many2oneLabel(value, fallback: value.toString())}';
        })
        .whereType<String>()
        .take(4)
        .join('\n');
    return AppCard(
      child: ListTile(
        contentPadding: EdgeInsets.zero,
        leading: CircleAvatar(
          backgroundColor: Theme.of(context).colorScheme.primaryContainer,
          child: Icon(_iconFor(widget.section)),
        ),
        title: Text(title),
        subtitle: details.isEmpty ? null : Text(details),
      ),
    );
  }

  IconData _iconFor(String section) {
    switch (section) {
      case 'security':
        return Icons.shield_outlined;
      case 'information':
        return Icons.inventory_2_outlined;
      case 'publications':
        return Icons.article_outlined;
      default:
        return Icons.folder_outlined;
    }
  }
}
