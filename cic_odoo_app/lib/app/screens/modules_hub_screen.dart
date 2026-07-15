import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/module_router.dart';
import '../core/module_registry.dart';
import '../models/app_module.dart';
import '../providers/app_state_provider.dart';
import '../ui/app_components.dart';
import '../widgets/module_tile.dart';
import '../../providers/auth_provider.dart';
import '../../theme/app_theme.dart';

class ModulesHubScreen extends StatefulWidget {
  const ModulesHubScreen({super.key});

  @override
  State<ModulesHubScreen> createState() => _ModulesHubScreenState();
}

class _ModulesHubScreenState extends State<ModulesHubScreen> {
  String _query = '';
  final TextEditingController _searchCtrl = TextEditingController();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    context.watch<AppStateProvider>();
    final auth = context.watch<AuthProvider>();
    final modules = _filter(_intranetModules(ModuleRegistry.all, auth), _query)
      ..sort((a, b) => a.title.compareTo(b.title));

    return AppScaffold(
      title: 'Explorar',
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: AppTheme.cardGradientFor(context),
              borderRadius: AppTheme.radiusLg,
              border: Border.all(color: AppTheme.dividerFor(context)),
              boxShadow: AppTheme.softShadow,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Todos tus módulos',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimaryFor(context),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Busca rápido y abre solo lo que realmente usa este perfil.',
                  style: TextStyle(color: AppTheme.textSecondaryFor(context)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          AppSearchBar(
            controller: _searchCtrl,
            hintText: 'Buscar módulos...',
            onChanged: (value) =>
                setState(() => _query = value.trim().toLowerCase()),
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              '${modules.length} módulos disponibles',
              style: TextStyle(
                color: AppTheme.textMutedFor(context),
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return GridView.builder(
                  itemCount: modules.length,
                  gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 280,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    mainAxisExtent: 188,
                  ),
                  itemBuilder: (_, i) {
                    final module = modules[i];
                    return ModuleTile(
                      module: module,
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) =>
                                ModuleRouter.build(module.key, module.title),
                          ),
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  List<AppModule> _filter(List<AppModule> modules, String query) {
    if (query.isEmpty) return modules;
    return modules
        .where(
          (m) =>
              m.title.toLowerCase().contains(query) ||
              m.key.toLowerCase().contains(query) ||
              (m.description ?? '').toLowerCase().contains(query),
        )
        .toList();
  }

  List<AppModule> _intranetModules(List<AppModule> modules, AuthProvider auth) {
    if (auth.isAdmin) return modules;
    const allowed = {
      'incidents',
      'training',
      'elearning',
      'documents',
      'payroll',
      'goals',
      'reservas',
      'planning',
      'health',
      'normative',
      'equipment',
      'chemicals',
      'suggestions',
      'communications',
      'suppliers',
      'purchases',
      'recruitment',
      'maintenance',
    };
    return modules
        .where((m) => allowed.contains(m.key) && auth.canViewModule(m.key))
        .toList();
  }
}
