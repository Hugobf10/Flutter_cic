import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import '../../l10n/strings.dart';

import '../../features/communications/communications_screen.dart';
import '../../features/suppliers/suppliers_screen.dart';
import '../../providers/auth_provider.dart';
import '../../screens/documentos/documentos_screen.dart';
import '../../screens/home/home_screen.dart';
import '../../screens/reservas/reservation_entry_target.dart';
import '../../screens/incidencias/incidencias_screen.dart';
import '../../screens/reservas/reservas_screen.dart';
import '../../services/push_notifications_service.dart';
import '../../theme/app_motion.dart';
import '../../theme/app_theme.dart';
import '../providers/app_state_provider.dart';
import '../ui/app_components.dart';
import 'approvals_inbox_screen.dart';
import 'modules_hub_screen.dart';
import 'notifications_screen.dart';
import 'profile_screen.dart';

class SuperAppShell extends StatefulWidget {
  const SuperAppShell({super.key});

  @override
  State<SuperAppShell> createState() => _SuperAppShellState();
}

class _SuperAppShellState extends State<SuperAppShell>
    with WidgetsBindingObserver {
  int _index = 0;
  final Set<int> _visitedPages = {0};
  bool _openingPendingReservation = false;

  List<String> get _labels => [
    context.l10n.home,
    context.l10n.modules,
    context.l10n.activity,
    context.l10n.profile,
  ];
  static const _icons = [
    Icons.home_rounded,
    Icons.grid_view_rounded,
    Icons.notifications_none_rounded,
    Icons.account_circle_rounded,
  ];

  final _pages = const [
    HomeScreen(),
    ModulesHubScreen(),
    NotificationsScreen(),
    ProfileScreen(),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AppStateProvider>().initialize().whenComplete(() {
        if (!mounted) return;
        PushNotificationsService.instance.configure(
          onMessage: (_) {
            context.read<AppStateProvider>().loadNotifications();
          },
        );
      });
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    PushNotificationsService.instance.stop();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed || !mounted) return;
    // Las notificaciones remotas requieren FCM/APNs. Mientras la app está
    // activa, esta recarga permite reflejar incidencias y comunicaciones
    // nuevas nada más volver a ella.
    context.read<AppStateProvider>().loadNotifications();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final unread = context.watch<AppStateProvider>().unreadNotifications;
    final pendingReservation = context
        .watch<AppStateProvider>()
        .pendingReservationTarget;

    if (pendingReservation != null && !_openingPendingReservation) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _openPendingReservation(pendingReservation);
      });
    }

    // Do not fetch profiles and other hidden tab content during home startup.
    // Once visited, a page stays mounted and keeps its scroll/form state.
    _visitedPages.add(_index);
    final pages = List<Widget>.generate(
      _pages.length,
      (index) => _visitedPages.contains(index)
          ? _pages[index]
          : const SizedBox.shrink(),
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final desktop = constraints.maxWidth >= 1024;

        if (!desktop) {
          return Scaffold(
            body: AppAnimatedIndexedStack(index: _index, children: pages),
            floatingActionButton: FloatingActionButton(
              onPressed: _openQuickActions,
              backgroundColor: AppTheme.primaryDark,
              foregroundColor: Colors.white,
              child: Icon(Icons.add_rounded),
            ),
            bottomNavigationBar: AppBottomNavigation(
              currentIndex: _index,
              onTap: (v) => setState(() => _index = v),
              items: List.generate(_labels.length, (i) {
                final badge = i == 2 && unread > 0
                    ? Badge.count(
                        count: unread > 99 ? 99 : unread,
                        child: Icon(
                          _icons[i],
                          size: 20,
                          color: i == _index
                              ? AppTheme.primary
                              : AppTheme.textSecondaryFor(context),
                        ),
                      )
                    : null;
                return (label: _labels[i], icon: _icons[i], badge: badge);
              }),
            ),
          );
        }

        return Scaffold(
          floatingActionButton: FloatingActionButton.extended(
            onPressed: _openQuickActions,
            backgroundColor: AppTheme.primaryDark,
            icon: Icon(Icons.flash_on_rounded),
            label: Text(context.uiText('Acciones', 'Actions')),
          ),
          body: Row(
            children: [
              Container(
                width: 248,
                decoration: BoxDecoration(
                  gradient: AppTheme.heroGradientFor(context),
                  border: Border(
                    right: BorderSide(color: AppTheme.dividerFor(context)),
                  ),
                ),
                child: Column(
                  children: [
                    const SizedBox(height: 24),
                    _buildBrand(context),
                    const SizedBox(height: 14),
                    ...List.generate(_labels.length, (i) {
                      final selected = _index == i;
                      return AnimatedContainer(
                        duration: AppMotion.adaptive(
                          context,
                          AppMotion.standard,
                        ),
                        curve: AppMotion.enterCurve,
                        margin: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: selected
                              ? AppTheme.primary.withValues(
                                  alpha: AppTheme.isDark(context) ? 0.20 : 0.12,
                                )
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: ListTile(
                          leading: i == 2 && unread > 0
                              ? Badge.count(
                                  count: unread > 99 ? 99 : unread,
                                  child: Icon(_icons[i]),
                                )
                              : Icon(_icons[i]),
                          title: Text(_labels[i]),
                          selected: selected,
                          onTap: () => setState(() => _index = i),
                          selectedColor: AppTheme.primary,
                          iconColor: selected
                              ? AppTheme.primary
                              : AppTheme.textSecondaryFor(context),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                      );
                    }),
                    if (auth.canViewModule('reservas'))
                      ListTile(
                        leading: Icon(Icons.calendar_month_rounded),
                        title: Text(context.l10n.reservations),
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const ReservasScreen(),
                            ),
                          );
                        },
                      ),
                    const Spacer(),
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: _buildUserCard(context),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: AppAnimatedIndexedStack(index: _index, children: pages),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _openPendingReservation(ReservationEntryTarget target) async {
    if (!mounted || _openingPendingReservation) return;
    if (!context.read<AuthProvider>().canViewModule('reservas')) {
      context.read<AppStateProvider>().consumePendingReservationTarget();
      return;
    }
    _openingPendingReservation = true;
    final consumed = context
        .read<AppStateProvider>()
        .consumePendingReservationTarget();
    if (consumed == null) {
      _openingPendingReservation = false;
      return;
    }

    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ReservasScreen(initialTarget: consumed),
      ),
    );

    if (mounted) {
      _openingPendingReservation = false;
    }
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
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const AppIconSurface(
                      icon: Icons.bolt_rounded,
                      color: AppTheme.primary,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            context.uiText('Acceso rápido', 'Quick access'),
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: 3),
                          Text(
                            context.uiText(
                              'Crea y revisa elementos sin perder el contexto.',
                              'Create and review items without losing context.',
                            ),
                            style: TextStyle(
                              color: AppTheme.textSecondaryFor(context),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    if (auth.canEditModule('incidents'))
                      _quickAction(
                        context.uiText('Nueva incidencia', 'New incident'),
                        Icons.warning_amber_rounded,
                        const IncidenciasScreen(),
                      ),
                    if (auth.canEditModule('documents'))
                      _quickAction(
                        context.uiText('Nuevo documento', 'New document'),
                        Icons.description_rounded,
                        const DocumentosScreen(),
                      ),
                    if (auth.canEditModule('communications'))
                      _quickAction(
                        context.uiText(
                          'Nueva comunicación',
                          'New communication',
                        ),
                        Icons.chat_bubble_outline_rounded,
                        const CommunicationsScreen(),
                      ),
                    if (auth.canEditModule('suppliers'))
                      _quickAction(
                        context.uiText('Nuevo proveedor', 'New supplier'),
                        Icons.local_shipping_rounded,
                        const SuppliersScreen(),
                      ),
                    if (auth.canEditModule('reservas'))
                      _quickAction(
                        context.uiText('Nueva reserva', 'New reservation'),
                        Icons.calendar_month_rounded,
                        const ReservasScreen(),
                      ),
                    if (auth.isAdmin)
                      _quickAction(
                        context.uiText('Aprobaciones', 'Approvals'),
                        Icons.fact_check_rounded,
                        const ApprovalsInboxScreen(),
                      ),
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
        final screenWidth = MediaQuery.of(context).size.width;
        final tileWidth = screenWidth >= 720
            ? 180.0
            : ((screenWidth - 48) / 2).clamp(140.0, 220.0);
        return NeumorphicSurface(
          width: tileWidth,
          subtle: true,
          onTap: () {
            Navigator.of(context).pop();
            Navigator.of(
              this.context,
            ).push(MaterialPageRoute(builder: (_) => page));
          },
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              AppIconSurface(
                icon: icon,
                color: AppTheme.primary,
                size: 36,
                iconSize: 17,
              ),
              const SizedBox(width: 9),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    color: AppTheme.textPrimaryFor(context),
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBrand(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            padding: const EdgeInsets.all(7),
            decoration: AppTheme.neumorphicDecoration(
              context,
              borderRadius: BorderRadius.circular(14),
            ),
            child: SvgPicture.asset(
              'assets/branding/cic_mark.svg',
              fit: BoxFit.contain,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'CICAPP',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  context.uiText('Espacio de trabajo', 'Workspace'),
                  style: TextStyle(
                    color: AppTheme.textMutedFor(context),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserCard(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: AppTheme.neumorphicDecoration(
        context,
        borderRadius: BorderRadius.circular(18),
        subtle: true,
      ),
      child: Row(
        children: [
          AppAvatar(
            name: auth.userName,
            size: 30,
            imageBase64: auth.profileImageBase64,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              auth.userName.isEmpty
                  ? context.uiText('Usuario', 'User')
                  : auth.userName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
