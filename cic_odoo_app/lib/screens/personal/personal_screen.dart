import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/data_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/section_header.dart';
import '../../widgets/shimmer_loading.dart';

/// Pantalla del directorio de personal (res.partner filtrado por personas).
class PersonalScreen extends StatefulWidget {
  const PersonalScreen({super.key});

  @override
  State<PersonalScreen> createState() => _PersonalScreenState();
}

class _PersonalScreenState extends State<PersonalScreen> {
  final DataProvider _provider = DataProvider();
  final TextEditingController _searchCtrl = TextEditingController();

  static const _fields = [
    'name', 'email', 'phone', 'mobile', 'unidad_id', 'puesto_ids',
    'formacion_pendiente_count', 'accidente_count', 'image_128',
  ];
  static const _baseDomain = [['is_company', '=', false], ['activo_en_sistema', '=', true]];

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
    final domain = List<dynamic>.from(_baseDomain);
    if (search != null && search.isNotEmpty) {
      domain.addAll(['|', ['name', 'ilike', search], ['email', 'ilike', search]]);
    }
    _provider.loadRecords('res.partner', domain: domain, fields: _fields, order: 'name', limit: 80);
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _provider,
      child: Scaffold(
        backgroundColor: AppTheme.surface,
        appBar: AppBar(title: const Text('Personal')),
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
          hintText: 'Buscar persona...',
          prefixIcon: const Icon(Icons.person_search_rounded, color: AppTheme.textMuted),
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
      return Center(child: Text('Error: ${p.errorMessage}', style: const TextStyle(color: AppTheme.textMuted)));
    }
    if (p.records.isEmpty) {
      return const Center(child: Text('No se encontró personal.', style: TextStyle(color: AppTheme.textMuted)));
    }

    return RefreshIndicator(
      onRefresh: () async => _loadData(search: _searchCtrl.text),
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 100),
        itemCount: p.records.length + 1,
        itemBuilder: (_, i) {
          if (i == 0) return SectionHeader(title: '${p.totalCount} personas', icon: Icons.people_rounded);
          return _buildCard(Map<String, dynamic>.from(p.records[i - 1] as Map));
        },
      ),
    );
  }

  Widget _buildCard(Map<String, dynamic> person) {
    final name = person['name']?.toString() ?? '';
    final email = person['email']?.toString() ?? '';
    final phone = person['mobile']?.toString() ?? person['phone']?.toString() ?? '';
    final unidad = person['unidad_id'] is List ? (person['unidad_id'] as List).last?.toString() ?? '' : '';
    final pendientes = _toInt(person['formacion_pendiente_count']);
    final accidentes = _toInt(person['accidente_count']);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.surfaceCard,
        borderRadius: AppTheme.radiusMd,
        border: Border.all(color: AppTheme.divider.withValues(alpha: 0.5)),
      ),
      child: Row(
        children: [
          // Avatar
          Container(
            width: 46, height: 46,
            decoration: BoxDecoration(
              gradient: AppTheme.primaryGradient,
              borderRadius: AppTheme.radiusMd,
            ),
            child: Center(
              child: Text(
                _initials(name),
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 16),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: const TextStyle(color: AppTheme.textPrimary, fontSize: 14, fontWeight: FontWeight.w600)),
                if (email.isNotEmpty && email != 'false') ...[
                  const SizedBox(height: 2),
                  Text(email, style: const TextStyle(color: AppTheme.textMuted, fontSize: 11)),
                ],
                const SizedBox(height: 4),
                Row(children: [
                  if (unidad.isNotEmpty) ...[
                    Icon(Icons.business_rounded, size: 12, color: AppTheme.primary.withValues(alpha: 0.6)),
                    const SizedBox(width: 3),
                    Flexible(child: Text(unidad, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11), overflow: TextOverflow.ellipsis)),
                    const SizedBox(width: 10),
                  ],
                  if (phone.isNotEmpty && phone != 'false') ...[
                    const Icon(Icons.phone_rounded, size: 12, color: AppTheme.textMuted),
                    const SizedBox(width: 3),
                    Text(phone, style: const TextStyle(color: AppTheme.textMuted, fontSize: 11)),
                  ],
                ]),
              ],
            ),
          ),
          // Badges
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (pendientes > 0)
                _buildBadge('$pendientes form.', AppTheme.warning),
              if (accidentes > 0) ...[
                const SizedBox(height: 4),
                _buildBadge('$accidentes acc.', AppTheme.danger),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: AppTheme.radiusXl),
      child: Text(text, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w700)),
    );
  }

  String _initials(String name) {
    final clean = name.trim();
    if (clean.isEmpty) return '?';
    final parts = clean.split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    return parts.first[0].toUpperCase();
  }

  int _toInt(dynamic value) {
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }
}
