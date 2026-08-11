import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../services/app_logger.dart';
import '../../theme/app_motion.dart';
import '../../theme/app_theme.dart';
import '../core/module_router.dart';
import '../core/module_registry.dart';
import '../models/app_module.dart';
import '../providers/app_state_provider.dart';
import '../ui/app_components.dart';
import '../widgets/module_tile.dart';

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

    late final List<AppModule> modules;
    String? fatalError;
    try {
      modules = _filter(_intranetModules(ModuleRegistry.all, auth), _query)
        ..sort((a, b) => a.title.compareTo(b.title));
    } catch (e, stackTrace) {
      modules = const [];
      fatalError = 'No se pudo cargar el catalogo de modulos para este perfil.';
      AppLogger.error(
        'Error construyendo el catalogo de modulos',
        error: e,
        stackTrace: stackTrace,
        data: {
          'userId': auth.userId,
          'isInternalUser': auth.isInternalUser,
          'isPortalUser': auth.isPortalUser,
          'query': _query,
        },
        scope: 'modules',
      );
    }

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
              boxShadow: AppTheme.raisedShadowFor(context),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Módulos disponibles',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimaryFor(context),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Accede a las áreas habilitadas para tu perfil. Cada módulo aplica los permisos y operaciones definidos en Odoo.',
                  style: TextStyle(color: AppTheme.textSecondaryFor(context)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          if (fatalError != null)
            AppEmptyState(
              title: 'No se pudo cargar Modulos',
              subtitle: fatalError,
              icon: Icons.error_outline_rounded,
            )
          else ...[
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
                    gridDelegate:
                        const SliverGridDelegateWithMaxCrossAxisExtent(
                          maxCrossAxisExtent: 280,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                          mainAxisExtent: 188,
                        ),
                    itemBuilder: (_, i) {
                      final module = modules[i];
                      return ModuleTile(
                        key: ValueKey(module.key),
                        module: module,
                        animationDelay: Duration(
                          milliseconds:
                              AppMotion.stagger.inMilliseconds *
                              (i > 8 ? 8 : i),
                        ),
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
    if (auth.isAdmin) return modules.where((m) => m.implemented).toList();
    const hidden = {'organization', 'permissions'};
    return modules
        .where(
          (m) =>
              m.implemented &&
              !hidden.contains(m.key) &&
              auth.canViewModule(m.key),
        )
        .toList();
  }
}
