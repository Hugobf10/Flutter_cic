import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/module_router.dart';
import '../models/app_module.dart';
import '../providers/app_state_provider.dart';
import '../ui/app_components.dart';
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
    final appState = context.watch<AppStateProvider>();
    final auth = context.watch<AuthProvider>();
    final modules = _filter(_intranetModules(appState.availableModules, auth), _query)
      ..sort((a, b) => a.title.compareTo(b.title));

    return AppScaffold(
      title: 'Módulos',
      child: Column(
        children: [
          AppSearchBar(
            controller: _searchCtrl,
            hintText: 'Buscar módulos...',
            onChanged: (value) => setState(() => _query = value.trim().toLowerCase()),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final width = constraints.maxWidth;
                final crossAxisCount = width >= 1200 ? 4 : width >= 900 ? 3 : width >= 640 ? 3 : 2;
                return GridView.builder(
                  itemCount: modules.length,
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: crossAxisCount,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                    childAspectRatio: 1.45,
                  ),
                  itemBuilder: (_, i) {
                    final module = modules[i];
                    return AppCard(
                      onTap: () {
                        Navigator.of(context).push(MaterialPageRoute(
                          builder: (_) => ModuleRouter.build(module.key, module.title),
                        ));
                      },
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: module.color.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(module.icon, size: 18, color: module.color),
                          ),
                          const Spacer(),
                          Text(module.title, style: const TextStyle(fontWeight: FontWeight.w600)),
                          const SizedBox(height: 2),
                          Text(module.description ?? '', maxLines: 2, overflow: TextOverflow.ellipsis, style: Theme.of(context).textTheme.bodySmall),
                        ],
                      ),
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
        .where((m) =>
            m.title.toLowerCase().contains(query) ||
            m.key.toLowerCase().contains(query) ||
            (m.description ?? '').toLowerCase().contains(query))
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
      'recruitment',
    };
    return modules.where((m) => allowed.contains(m.key) && auth.canViewModule(m.key)).toList();
  }
}
