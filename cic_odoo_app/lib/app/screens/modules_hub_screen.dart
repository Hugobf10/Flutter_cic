import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/module_router.dart';
import '../core/module_registry.dart';
import '../models/app_module.dart';
import '../providers/app_state_provider.dart';
import '../ui/app_components.dart';
import '../widgets/module_tile.dart';
import '../../providers/auth_provider.dart';

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
      title: 'Módulos',
      child: Column(
        children: [
          AppSearchBar(
            controller: _searchCtrl,
            hintText: 'Buscar módulos...',
            onChanged: (value) =>
                setState(() => _query = value.trim().toLowerCase()),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return GridView.builder(
                  itemCount: modules.length,
                  gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 280,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                    mainAxisExtent: 164,
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
      'dashboard',
      'quality',
      'incidents',
      'training',
      'elearning',
      'documents',
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
      'portal',
      'organization',
      'maintenance',
    };
    return modules
        .where((m) => allowed.contains(m.key) && auth.canViewModule(m.key))
        .toList();
  }
}
