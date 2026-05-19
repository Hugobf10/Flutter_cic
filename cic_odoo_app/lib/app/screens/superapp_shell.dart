import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../features/communications/communications_screen.dart';
import '../../features/suggestions/suggestions_screen.dart';
import '../../features/suppliers/suppliers_screen.dart';
import '../../providers/auth_provider.dart';
import '../../screens/documentos/documentos_screen.dart';
import '../../screens/home/home_screen.dart';
import '../../screens/incidencias/incidencias_screen.dart';
import '../../screens/reservas/reservas_screen.dart';
import '../providers/app_state_provider.dart';
import 'approvals_inbox_screen.dart';
import 'modules_hub_screen.dart';
import 'notifications_screen.dart';
import 'profile_screen.dart';

class SuperAppShell extends StatefulWidget {
  const SuperAppShell({super.key});

  @override
  State<SuperAppShell> createState() => _SuperAppShellState();
}

class _SuperAppShellState extends State<SuperAppShell> {
  int _index = 0;

  static const _labels = ['Inicio', 'Módulos', 'Reservas', 'Avisos', 'Perfil'];
  static const _icons = [
    Icons.home_rounded,
    Icons.grid_view_rounded,
    Icons.calendar_month_rounded,
    Icons.notifications_none_rounded,
    Icons.account_circle_rounded,
  ];

  final _pages = const [
    HomeScreen(),
    ModulesHubScreen(),
    ReservasScreen(),
    NotificationsScreen(),
    ProfileScreen(),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AppStateProvider>().initialize();
    });
  }

  @override
  Widget build(BuildContext context) {
    final unread = context.watch<AppStateProvider>().unreadNotifications;

    return LayoutBuilder(
      builder: (context, constraints) {
        final desktop = constraints.maxWidth >= 1024;

        if (!desktop) {
          return Scaffold(
            body: IndexedStack(index: _index, children: _pages),
            floatingActionButton: FloatingActionButton(
              onPressed: _openQuickActions,
              child: const Icon(Icons.add_rounded),
            ),
            bottomNavigationBar: NavigationBar(
              selectedIndex: _index,
              onDestinationSelected: (v) => setState(() => _index = v),
              destinations: List.generate(_labels.length, (i) {
                final baseIcon = Icon(_icons[i]);
                final icon = i == 3 && unread > 0
                    ? Badge.count(count: unread > 99 ? 99 : unread, child: baseIcon)
                    : baseIcon;
                return NavigationDestination(icon: icon, label: _labels[i]);
              }),
            ),
          );
        }

        return Scaffold(
          floatingActionButton: FloatingActionButton.extended(
            onPressed: _openQuickActions,
            icon: const Icon(Icons.flash_on_rounded),
            label: const Text('Acceso rápido'),
          ),
          body: Row(
            children: [
              Container(
                width: 240,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  border: Border(right: BorderSide(color: Theme.of(context).dividerColor.withValues(alpha: 0.5))),
                ),
                child: Column(
                  children: [
                    const SizedBox(height: 24),
                    _buildBrand(context),
                    const SizedBox(height: 18),
                    ...List.generate(_labels.length, (i) {
                      final selected = _index == i;
                      return ListTile(
                        leading: i == 3 && unread > 0
                            ? Badge.count(count: unread > 99 ? 99 : unread, child: Icon(_icons[i]))
                            : Icon(_icons[i]),
                        title: Text(_labels[i]),
                        selected: selected,
                        onTap: () => setState(() => _index = i),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      );
                    }),
                    const Spacer(),
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: _buildUserCard(context),
                    ),
                  ],
                ),
              ),
              Expanded(child: IndexedStack(index: _index, children: _pages)),
            ],
          ),
        );
      },
    );
  }

  Future<void> _openQuickActions() async {
    final auth = context.read<AuthProvider>();
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Acceso rápido', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    if (auth.canViewModule('incidents'))
                      _quickAction('Nueva incidencia', Icons.warning_amber_rounded, const IncidenciasScreen()),
                    if (auth.canViewModule('documents'))
                      _quickAction('Nuevo documento', Icons.description_rounded, const DocumentosScreen()),
                    if (auth.canViewModule('communications'))
                      _quickAction('Nueva comunicación', Icons.chat_bubble_outline_rounded, const CommunicationsScreen()),
                    if (auth.canViewModule('suppliers'))
                      _quickAction('Nuevo proveedor', Icons.local_shipping_rounded, const SuppliersScreen()),
                    _quickAction('Nueva sugerencia', Icons.lightbulb_outline_rounded, const SuggestionsScreen()),
                    _quickAction('Nueva reserva', Icons.calendar_month_rounded, const ReservasScreen()),
                    if (auth.isAdmin) _quickAction('Aprobaciones', Icons.fact_check_rounded, const ApprovalsInboxScreen()),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _quickAction(String label, IconData icon, Widget page) {
    return Builder(
      builder: (context) {
        return InkWell(
          onTap: () {
            Navigator.of(context).pop();
            Navigator.of(this.context).push(MaterialPageRoute(builder: (_) => page));
          },
          borderRadius: BorderRadius.circular(12),
          child: Ink(
            width: 150,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Theme.of(context).dividerColor.withValues(alpha: 0.5)),
            ),
            child: Row(
              children: [
                Icon(icon, size: 18),
                const SizedBox(width: 8),
                Expanded(child: Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600))),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildBrand(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(Icons.hexagon_rounded, color: Theme.of(context).colorScheme.primary, size: 18),
          ),
          const SizedBox(width: 10),
          Text('CICancer', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }

  Widget _buildUserCard(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Theme.of(context).dividerColor.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          CircleAvatar(radius: 14, child: Text(_initials(auth.userName))),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              auth.userName.isEmpty ? 'Usuario' : auth.userName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  String _initials(String name) {
    final clean = name.trim();
    if (clean.isEmpty) return 'U';
    final parts = clean.split(RegExp(r'\s+')).where((e) => e.isNotEmpty).toList();
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
  }
}
