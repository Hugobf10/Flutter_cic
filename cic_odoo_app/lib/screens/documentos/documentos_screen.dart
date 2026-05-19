import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../providers/data_provider.dart';
import '../../services/odoo_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/section_header.dart';
import '../../widgets/shimmer_loading.dart';

/// Pantalla de documentos controlados (calidad.documento).
class DocumentosScreen extends StatefulWidget {
  const DocumentosScreen({super.key});

  @override
  State<DocumentosScreen> createState() => _DocumentosScreenState();
}

class _DocumentosScreenState extends State<DocumentosScreen> {
  final DataProvider _provider = DataProvider();
  final OdooService _odoo = OdooService();
  final TextEditingController _searchCtrl = TextEditingController();

  static const _fields = ['name', 'codigo', 'tipo_id', 'publico', 'version_count', 'descarga_count', 'unidad_id'];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _loadData({String? search}) {
    final domain = <dynamic>[];
    if (search != null && search.isNotEmpty) {
      domain.addAll(['|', ['name', 'ilike', search], ['codigo', 'ilike', search]]);
    }
    _provider.loadRecords('calidad.documento', domain: domain, fields: _fields, order: 'codigo, name', limit: 80);
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _provider,
      child: Scaffold(
        backgroundColor: AppTheme.surface,
        appBar: AppBar(title: const Text('Documentos')),
        body: Column(
          children: [
            _buildSearchBar(),
            Expanded(child: Consumer<DataProvider>(builder: (context, p, child) => _buildList(p))),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: TextField(
        controller: _searchCtrl,
        style: const TextStyle(color: AppTheme.textPrimary, fontSize: 14),
        decoration: InputDecoration(
          hintText: 'Buscar por título o código...',
          prefixIcon: const Icon(Icons.search_rounded, color: AppTheme.textMuted),
          suffixIcon: _searchCtrl.text.isNotEmpty
              ? IconButton(icon: const Icon(Icons.close_rounded, size: 18), onPressed: () { _searchCtrl.clear(); _loadData(); })
              : null,
        ),
        onSubmitted: (v) => _loadData(search: v),
        onChanged: (v) { if (v.isEmpty) _loadData(); setState(() {}); },
      ),
    );
  }

  Widget _buildList(DataProvider p) {
    if (p.isLoading && p.records.isEmpty) return const Padding(padding: EdgeInsets.all(16), child: ShimmerList());
    if (p.errorMessage != null) {
      return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
        const Icon(Icons.error_outline, color: AppTheme.danger, size: 40),
        const SizedBox(height: 8),
        Text(p.errorMessage!, style: const TextStyle(color: AppTheme.textMuted, fontSize: 12)),
      ]));
    }
    if (p.records.isEmpty) {
      return const Center(child: Text('No se encontraron documentos.', style: TextStyle(color: AppTheme.textMuted)));
    }

    return RefreshIndicator(
      onRefresh: () async => _loadData(search: _searchCtrl.text),
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 100),
        itemCount: p.records.length + 1,
        itemBuilder: (_, i) {
          if (i == 0) return SectionHeader(title: '${p.totalCount} documentos', icon: Icons.folder_rounded);
          return _buildCard(Map<String, dynamic>.from(p.records[i - 1] as Map));
        },
      ),
    );
  }

  Widget _buildCard(Map<String, dynamic> doc) {
    final publico = doc['publico'] == true;
    final tipoId = doc['tipo_id'];
    final tipo = tipoId is List ? tipoId.last?.toString() ?? '' : '';
    final unidad = doc['unidad_id'] is List ? (doc['unidad_id'] as List).last?.toString() ?? '' : '';
    final versions = (doc['version_count'] as num?)?.toInt() ?? 0;
    final downloads = (doc['descarga_count'] as num?)?.toInt() ?? 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceCard,
        borderRadius: AppTheme.radiusMd,
        border: Border.all(color: AppTheme.divider.withValues(alpha: 0.5)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42, height: 42,
            decoration: BoxDecoration(
              color: AppTheme.primary.withValues(alpha: 0.12),
              borderRadius: AppTheme.radiusSm,
            ),
            child: Icon(
              publico ? Icons.public_rounded : Icons.lock_outline_rounded,
              color: publico ? AppTheme.primary : AppTheme.textMuted,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (doc['codigo'] != null && doc['codigo'].toString().isNotEmpty)
                  Text(doc['codigo'].toString(), style: TextStyle(color: AppTheme.primary.withValues(alpha: 0.8), fontSize: 11, fontWeight: FontWeight.w700)),
                Text(doc['name']?.toString() ?? '', style: const TextStyle(color: AppTheme.textPrimary, fontSize: 14, fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                Row(children: [
                  if (tipo.isNotEmpty) ...[
                    Icon(Icons.label_outline_rounded, size: 12, color: AppTheme.textMuted),
                    const SizedBox(width: 3),
                    Text(tipo, style: const TextStyle(color: AppTheme.textMuted, fontSize: 11)),
                    const SizedBox(width: 10),
                  ],
                  if (unidad.isNotEmpty) ...[
                    Icon(Icons.business_rounded, size: 12, color: AppTheme.textMuted),
                    const SizedBox(width: 3),
                    Flexible(child: Text(unidad, style: const TextStyle(color: AppTheme.textMuted, fontSize: 11), overflow: TextOverflow.ellipsis)),
                  ],
                ]),
                const SizedBox(height: 8),
                Row(children: [
                  _buildStat(Icons.history_rounded, '$versions vers.'),
                  const SizedBox(width: 14),
                  _buildStat(Icons.download_rounded, '$downloads desc.'),
                ]),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Descargar',
            onPressed: () => _downloadDocument((doc['id'] as num?)?.toInt()),
            icon: const Icon(Icons.download_for_offline_rounded, color: AppTheme.primary),
          ),
        ],
      ),
    );
  }

  Future<void> _downloadDocument(int? id) async {
    if (id == null) return;
    try {
      final result = await _odoo.callRecordMethod('calidad.documento', [id], 'action_descargar');
      String? url;
      if (result is String && result.startsWith('http')) {
        url = result;
      } else if (result is Map && result['url'] != null) {
        url = result['url'].toString();
      }
      url ??= '${_odoo.baseUrl}/my/calidad/documentos/$id/descargar';

      final uri = Uri.tryParse(url);
      if (uri == null) throw Exception('URL inválida');
      final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!ok && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No se pudo abrir la descarga.')));
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo descargar: $e')),
      );
    }
  }

  Widget _buildStat(IconData icon, String text) {
    return Row(children: [
      Icon(icon, size: 13, color: AppTheme.textMuted),
      const SizedBox(width: 3),
      Text(text, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11)),
    ]);
  }
}
