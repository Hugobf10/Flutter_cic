import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../app/ui/app_components.dart';
import '../../providers/data_provider.dart';
import '../../theme/app_theme.dart';

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
    'name',
    'email',
    'phone',
    'mobile',
    'unidad_id',
    'puesto_ids',
    'formacion_pendiente_count',
    'accidente_count',
    'image_128',
  ];
  static const _baseDomain = [
    ['is_company', '=', false],
    ['activo_en_sistema', '=', true],
  ];

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
      domain.addAll([
        '|',
        ['name', 'ilike', search],
        ['email', 'ilike', search],
      ]);
    }
    _provider.loadRecords(
      'res.partner',
      domain: domain,
      fields: _fields,
      order: 'name',
      limit: 80,
    );
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _provider,
      child: AppScaffold(
        title: 'Personal',
        padding: EdgeInsets.zero,
        child: Column(
          children: [
            _buildSearchBar(),
            Expanded(
              child: Consumer<DataProvider>(
                builder: (context, p, child) => _buildList(p),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
      child: AppSearchBar(
        controller: _searchCtrl,
        hintText: 'Buscar persona...',
        onSubmitted: (v) => _loadData(search: v),
        onChanged: (v) {
          if (v.isEmpty) _loadData();
          setState(() {});
        },
      ),
    );
  }

  Widget _buildList(DataProvider p) {
    if (p.isLoading && p.records.isEmpty) return const AppLoadingView();
    if (p.errorMessage != null) {
      return AppEmptyState(
        title: 'No se pudo cargar el personal',
        subtitle: p.errorMessage!,
        icon: Icons.cloud_off_rounded,
        action: AppButton.primary(label: 'Reintentar', onPressed: _loadData),
      );
    }
    if (p.records.isEmpty) {
      return const AppEmptyState(
        title: 'Sin resultados',
        subtitle: 'No se encontró personal con esos datos.',
        icon: Icons.person_search_rounded,
      );
    }

    return RefreshIndicator(
      onRefresh: () async => _loadData(search: _searchCtrl.text),
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 100),
        itemCount: p.records.length + 1,
        itemBuilder: (_, i) {
          if (i == 0) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: AppSectionHeader(
                title: '${p.totalCount} personas',
                subtitle: 'Directorio interno disponible para tu perfil.',
              ),
            );
          }
          return _buildCard(Map<String, dynamic>.from(p.records[i - 1] as Map));
        },
      ),
    );
  }

  Widget _buildCard(Map<String, dynamic> person) {
    final name = person['name']?.toString() ?? '';
    final email = person['email']?.toString() ?? '';
    final phone =
        person['mobile']?.toString() ?? person['phone']?.toString() ?? '';
    final unidad = person['unidad_id'] is List
        ? (person['unidad_id'] as List).last?.toString() ?? ''
        : '';
    final pendientes = _toInt(person['formacion_pendiente_count']);
    final accidentes = _toInt(person['accidente_count']);

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: AppCard(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            AppAvatar(
              name: name,
              size: 48,
              imageBase64: person['image_128']?.toString(),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: TextStyle(
                      color: AppTheme.textPrimaryFor(context),
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (email.isNotEmpty && email != 'false') ...[
                    const SizedBox(height: 2),
                    Text(
                      email,
                      style: TextStyle(
                        color: AppTheme.textMutedFor(context),
                        fontSize: 11,
                      ),
                    ),
                  ],
                  const SizedBox(height: 5),
                  Row(
                    children: [
                      if (unidad.isNotEmpty) ...[
                        Icon(
                          Icons.business_rounded,
                          size: 12,
                          color: AppTheme.primary,
                        ),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            unidad,
                            style: TextStyle(
                              color: AppTheme.textSecondaryFor(context),
                              fontSize: 11,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 10),
                      ],
                      if (phone.isNotEmpty && phone != 'false') ...[
                        Icon(
                          Icons.phone_rounded,
                          size: 12,
                          color: AppTheme.textMutedFor(context),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          phone,
                          style: TextStyle(
                            color: AppTheme.textMutedFor(context),
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (pendientes > 0)
                  AppStatusChip(
                    label: '$pendientes form.',
                    color: AppTheme.warning,
                  ),
                if (accidentes > 0) ...[
                  const SizedBox(height: 5),
                  AppStatusChip(
                    label: '$accidentes acc.',
                    color: AppTheme.danger,
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  int _toInt(dynamic value) {
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }
}
