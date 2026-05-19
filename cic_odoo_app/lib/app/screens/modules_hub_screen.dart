import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/module_router.dart';
import '../models/app_module.dart';
import '../providers/app_state_provider.dart';
import '../widgets/module_tile.dart';
import '../../providers/auth_provider.dart';

class ModulesHubScreen extends StatefulWidget {
  const ModulesHubScreen({super.key});

  @override
  State<ModulesHubScreen> createState() => _ModulesHubScreenState();
}

class _ModulesHubScreenState extends State<ModulesHubScreen> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppStateProvider>();
    final auth = context.watch<AuthProvider>();
    final modules = _filter(_intranetModules(appState.availableModules, auth), _query)
      ..sort((a, b) {
        if (a.implemented == b.implemented) return a.title.compareTo(b.title);
        return a.implemented ? -1 : 1;
      });

    return Scaffold(
      appBar: AppBar(title: const Text('Módulos')),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          children: [
            TextField(
              decoration: const InputDecoration(
                hintText: 'Buscar módulos...',
                prefixIcon: Icon(Icons.search_rounded),
              ),
              onChanged: (value) => setState(() => _query = value.trim().toLowerCase()),
            ),
            const SizedBox(height: 14),
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final width = constraints.maxWidth;
                  final crossAxisCount = width >= 1500
                      ? 5
                      : width >= 1200
                          ? 4
                          : width >= 900
                              ? 3
                              : 2;
                  final childAspectRatio = width >= 1200 ? 1.45 : width >= 900 ? 1.3 : 1.32;

                  return GridView.builder(
                    itemCount: modules.length,
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: crossAxisCount,
                      crossAxisSpacing: 8,
                      mainAxisSpacing: 8,
                      childAspectRatio: childAspectRatio,
                    ),
                    itemBuilder: (_, i) {
                      final module = modules[i];
                      return ModuleTile(
                        module: module,
                        onTap: () {
                          if (!module.implemented) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('${module.title} estará disponible en la siguiente iteración.'),
                              ),
                            );
                          }
                          Navigator.of(context).push(MaterialPageRoute(
                            builder: (_) => ModuleRouter.build(module.key, module.title),
                          ));
                        },
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
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
      'planning',
      'health',
      'normative',
      'equipment',
      'chemicals',
      'suggestions',
      'communications',
      'suppliers',
    };
    return modules.where((m) => allowed.contains(m.key) && auth.canViewModule(m.key)).toList();
  }
}
