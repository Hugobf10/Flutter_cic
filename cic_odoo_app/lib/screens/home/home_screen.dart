import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../app/core/module_navigation.dart';
import '../../app/models/app_notification.dart';
import '../../app/providers/app_state_provider.dart';
import '../../app/screens/modules_hub_screen.dart';
import '../../app/screens/notifications_screen.dart';
import '../../app/screens/profile_screen.dart';
import '../../app/ui/app_components.dart';
import '../../config/app_config.dart';
import '../../features/purchases/purchases_screen.dart';
import '../../features/quality/quality_center_screen.dart';
import '../../providers/auth_provider.dart';
import '../../providers/dashboard_provider.dart';
import '../../theme/app_motion.dart';
import '../../theme/app_theme.dart';
import '../personal/personal_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late Future<List<_WordPressPost>> _newsFuture;

  @override
  void initState() {
    super.initState();
    _newsFuture = _loadNews();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final dashboard = context.read<DashboardProvider>();
      dashboard.loadDashboard();
      dashboard.loadFilterOptions();
    });
  }

  Future<void> _onRefresh() async {
    setState(() {
      _newsFuture = _loadNews();
    });
    await context.read<DashboardProvider>().loadDashboard();
  }

  Future<List<_WordPressPost>> _loadNews() async {
    final uri = Uri.tryParse(AppConfig.wordpressApiUrl);
    if (uri == null) return [_WordPressPost.mock];
    try {
      final response = await http
          .get(uri)
          .timeout(const Duration(seconds: AppConfig.httpTimeoutSeconds));
      if (response.statusCode < 200 || response.statusCode >= 300) {
        return [_WordPressPost.mock];
      }
      final decoded = jsonDecode(response.body);
      if (decoded is! List) return [_WordPressPost.mock];
      final posts = decoded
          .whereType<Map>()
          .map((raw) => _WordPressPost.fromJson(Map<String, dynamic>.from(raw)))
          .where((post) => post.title.isNotEmpty)
          .toList();
      return [_WordPressPost.mock, ...posts].take(5).toList();
    } catch (_) {
      return [_WordPressPost.mock];
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final dashboard = context.watch<DashboardProvider>();
    final appState = context.watch<AppStateProvider>();

    return AppScaffold(
      title: 'Inicio',
      showAppBar: false,
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 20),
      child: RefreshIndicator(
        onRefresh: _onRefresh,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            _HomeHero(auth: auth, unreadCount: appState.unreadNotifications),
            const SizedBox(height: 24),
            _DashboardMetrics(
              kpis: dashboard.kpis,
              auth: auth,
              loading:
                  dashboard.state == DashboardState.loading &&
                  dashboard.dashboardData == null,
            ),
            if (dashboard.state == DashboardState.error) ...[
              const SizedBox(height: 12),
              _DashboardStatusBanner(
                message: dashboard.errorMessage ?? 'Error desconocido',
                onRetry: _onRefresh,
              ),
            ],
            const SizedBox(height: 26),
            AppSectionHeader(
              title: 'Accesos rápidos',
              action: TextButton.icon(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const ModulesHubScreen()),
                ),
                icon: const Icon(Icons.arrow_forward_rounded, size: 16),
                label: const Text('Ver todos'),
              ),
            ),
            const _QuickActions(),
            const SizedBox(height: 24),
            _NewsSection(newsFuture: _newsFuture),
            const SizedBox(height: 20),
            if (dashboard.permissionDenied) const _AccessScopeBanner(),
            AppSectionHeader(
              title: 'Actividad reciente',
              action: TextButton(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const NotificationsScreen(),
                  ),
                ),
                child: Text('Ver todo'),
              ),
            ),
            _ActivityList(items: appState.notifications, auth: auth),
            const SizedBox(height: 90),
          ],
        ),
      ),
    );
  }
}

class _HomeHero extends StatelessWidget {
  const _HomeHero({required this.auth, required this.unreadCount});

  final AuthProvider auth;
  final int unreadCount;

  @override
  Widget build(BuildContext context) {
    final name = auth.userName.trim().isEmpty ? 'Usuario' : auth.userName;
    final firstName = name.split(' ').first;
    final hour = DateTime.now().hour;
    final greeting = hour < 12
        ? 'Buenos días'
        : hour < 20
        ? 'Buenas tardes'
        : 'Buenas noches';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            SvgPicture.asset(
              'assets/branding/cic_mark.svg',
              width: 38,
              height: 30,
            ),
            const SizedBox(width: 8),
            Text(
              'CIC',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontSize: 24,
                letterSpacing: -0.8,
                fontWeight: FontWeight.w800,
                color: AppTheme.textPrimaryFor(context),
              ),
            ),
            const Spacer(),
            SizedBox(
              width: 48,
              height: 48,
              child: NeumorphicSurface(
                padding: const EdgeInsets.all(11),
                borderRadius: BorderRadius.circular(17),
                subtle: true,
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const NotificationsScreen(),
                  ),
                ),
                child: Badge.count(
                  count: unreadCount > 99 ? 99 : unreadCount,
                  isLabelVisible: unreadCount > 0,
                  child: Icon(
                    Icons.notifications_none_rounded,
                    color: AppTheme.textSecondaryFor(context),
                    size: 23,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            SizedBox(
              width: 50,
              height: 50,
              child: NeumorphicSurface(
                padding: const EdgeInsets.all(3),
                borderRadius: AppTheme.radiusXl,
                subtle: true,
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const ProfileScreen()),
                ),
                child: AppAvatar(
                  name: name,
                  size: 42,
                  imageBase64: auth.profileImageBase64,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 36),
        Text(
          '$greeting, $firstName',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            fontSize: 30,
            letterSpacing: -0.9,
            color: AppTheme.textPrimaryFor(context),
          ),
        ),
        const SizedBox(height: 7),
        Text(
          'Aquí tienes un resumen de lo importante.',
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            color: AppTheme.textSecondaryFor(context),
          ),
        ),
      ],
    );
  }
}

class _DashboardMetrics extends StatelessWidget {
  const _DashboardMetrics({
    required this.kpis,
    required this.auth,
    required this.loading,
  });

  final List<dynamic> kpis;
  final AuthProvider auth;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final definitions = <_MetricDefinition>[
      const _MetricDefinition(
        title: 'Incidencias',
        moduleKey: 'incidents',
        helper: 'Abiertas',
        icon: Icons.warning_amber_rounded,
        color: AppTheme.primary,
      ),
      const _MetricDefinition(
        title: 'Reservas',
        moduleKey: 'reservas',
        helper: 'Hoy',
        icon: Icons.calendar_month_rounded,
        color: AppTheme.info,
      ),
      const _MetricDefinition(
        title: 'Formación',
        moduleKey: 'training',
        helper: 'Pendientes',
        icon: Icons.school_rounded,
        color: AppTheme.accent,
      ),
    ].where((definition) => auth.canViewModule(definition.moduleKey)).toList();

    if (definitions.isEmpty) {
      return const AppEmptyState(
        title: 'Todo al día',
        subtitle: 'No hay indicadores disponibles para este perfil.',
        icon: Icons.task_alt_rounded,
      );
    }

    return Row(
      children: List.generate(definitions.length, (index) {
        final definition = definitions[index];
        final kpi = _findKpi(definition.moduleKey);
        final value = loading ? '···' : (kpi?['value'] ?? '—').toString();
        final helper = (kpi?['helper'] ?? kpi?['subtitle'] ?? definition.helper)
            .toString();
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(
              right: index == definitions.length - 1 ? 0 : 10,
            ),
            child: AppReveal(
              delay: Duration(
                milliseconds: AppMotion.stagger.inMilliseconds * index,
              ),
              child: SizedBox(
                height: 156,
                child: AppCard(
                  padding: const EdgeInsets.all(13),
                  onTap: () => ModuleNavigation.openModule(
                    context,
                    auth: auth,
                    moduleKey: definition.moduleKey,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          NeumorphicSurface(
                            padding: const EdgeInsets.all(8),
                            borderRadius: BorderRadius.circular(13),
                            subtle: true,
                            child: Icon(
                              definition.icon,
                              size: 19,
                              color: definition.color,
                            ),
                          ),
                          const Spacer(),
                          Icon(
                            Icons.chevron_right_rounded,
                            size: 18,
                            color: AppTheme.textMutedFor(context),
                          ),
                        ],
                      ),
                      const Spacer(),
                      Text(
                        definition.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: AppTheme.textSecondaryFor(context),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        value,
                        style: TextStyle(
                          color: AppTheme.textPrimaryFor(context),
                          fontSize: 28,
                          height: 1,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 7),
                      Text(
                        helper,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: AppTheme.textMutedFor(context),
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      }),
    );
  }

  Map<String, dynamic>? _findKpi(String moduleKey) {
    for (final raw in kpis) {
      if (raw is! Map) continue;
      final kpi = Map<String, dynamic>.from(raw);
      if (ModuleNavigation.inferModuleKeyFromKpi(kpi) == moduleKey) return kpi;
    }
    return null;
  }
}

class _MetricDefinition {
  const _MetricDefinition({
    required this.title,
    required this.moduleKey,
    required this.helper,
    required this.icon,
    required this.color,
  });

  final String title;
  final String moduleKey;
  final String helper;
  final IconData icon;
  final Color color;
}

class _DashboardStatusBanner extends StatelessWidget {
  const _DashboardStatusBanner({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return NeumorphicSurface(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      subtle: true,
      child: Row(
        children: [
          const Icon(
            Icons.cloud_off_rounded,
            color: AppTheme.warning,
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: AppTheme.textSecondaryFor(context),
                fontSize: 12,
              ),
            ),
          ),
          IconButton(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded, size: 18),
            tooltip: 'Reintentar',
          ),
        ],
      ),
    );
  }
}

class _QuickActions extends StatelessWidget {
  const _QuickActions();

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final internalActions =
        <({String title, IconData icon, Color color, VoidCallback onTap})>[
          if (auth.isInternalUser)
            (
              title: 'Personal',
              icon: Icons.people_alt_rounded,
              color: AppTheme.accent,
              onTap: () => Navigator.of(
                context,
              ).push(MaterialPageRoute(builder: (_) => const PersonalScreen())),
            ),
          if (auth.canViewModule('documents'))
            (
              title: 'Documentos',
              icon: Icons.description_rounded,
              color: AppTheme.primary,
              onTap: () => ModuleNavigation.openModule(
                context,
                auth: auth,
                moduleKey: 'documents',
              ),
            ),
          if (auth.canViewModule('purchases'))
            (
              title: 'Compras',
              icon: Icons.shopping_cart_checkout_rounded,
              color: AppTheme.info,
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const PurchasesScreen()),
              ),
            ),
          if (auth.canViewModule('communications'))
            (
              title: 'Calidad',
              icon: Icons.verified_user_rounded,
              color: AppTheme.success,
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const QualityCenterScreen()),
              ),
            ),
        ];
    final portalActions =
        <({String title, IconData icon, Color color, VoidCallback onTap})>[
          if (auth.canViewModule('portal'))
            (
              title: 'Mi espacio',
              icon: Icons.person_rounded,
              color: AppTheme.accent,
              onTap: () => ModuleNavigation.openModule(
                context,
                auth: auth,
                moduleKey: 'portal',
              ),
            ),
          if (auth.canViewModule('documents'))
            (
              title: 'Documentos',
              icon: Icons.description_rounded,
              color: AppTheme.primary,
              onTap: () => ModuleNavigation.openModule(
                context,
                auth: auth,
                moduleKey: 'documents',
              ),
            ),
          if (auth.canViewModule('reservas'))
            (
              title: 'Reservas',
              icon: Icons.calendar_month_rounded,
              color: AppTheme.success,
              onTap: () => ModuleNavigation.openModule(
                context,
                auth: auth,
                moduleKey: 'reservas',
              ),
            ),
          if (auth.canViewModule('training'))
            (
              title: 'Formación',
              icon: Icons.school_rounded,
              color: AppTheme.info,
              onTap: () => ModuleNavigation.openModule(
                context,
                auth: auth,
                moduleKey: 'training',
              ),
            ),
          if (auth.canViewModule('communications'))
            (
              title: 'Comunicaciones',
              icon: Icons.campaign_rounded,
              color: AppTheme.warning,
              onTap: () => ModuleNavigation.openModule(
                context,
                auth: auth,
                moduleKey: 'communications',
              ),
            ),
          if (auth.canViewModule('payroll'))
            (
              title: 'Nóminas',
              icon: Icons.receipt_long_rounded,
              color: AppTheme.success,
              onTap: () => ModuleNavigation.openModule(
                context,
                auth: auth,
                moduleKey: 'payroll',
              ),
            ),
        ];
    final actions = auth.isPortalOnlyUser
        ? portalActions.take(4).toList()
        : internalActions;

    if (actions.isEmpty) {
      return const AppEmptyState(
        title: 'Sin accesos rápidos',
        subtitle: 'No hay módulos destacados disponibles para este usuario.',
        icon: Icons.apps_outlined,
      );
    }

    return LayoutBuilder(
      builder: (context, c) {
        final compact = c.maxWidth < 620;
        final cols = compact ? 2 : 4;
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: actions.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: cols,
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: compact ? 1.7 : 1.45,
          ),
          itemBuilder: (_, i) {
            final a = actions[i];
            return AppReveal(
              delay: Duration(
                milliseconds: AppMotion.stagger.inMilliseconds * i,
              ),
              child: AppCard(
                padding: const EdgeInsets.all(12),
                onTap: a.onTap,
                child: Row(
                  children: [
                    AppIconSurface(
                      icon: a.icon,
                      color: a.color,
                      size: 42,
                      iconSize: 21,
                    ),
                    const SizedBox(width: 11),
                    Expanded(
                      child: Text(
                        a.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textPrimaryFor(context),
                        ),
                      ),
                    ),
                    Icon(
                      Icons.chevron_right_rounded,
                      size: 19,
                      color: AppTheme.textMutedFor(context),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _NewsSection extends StatefulWidget {
  const _NewsSection({required this.newsFuture});

  final Future<List<_WordPressPost>> newsFuture;

  @override
  State<_NewsSection> createState() => _NewsSectionState();
}

class _NewsSectionState extends State<_NewsSection> {
  final PageController _controller = PageController(viewportFraction: 0.96);
  int _page = 0;

  @override
  void didUpdateWidget(covariant _NewsSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.newsFuture == widget.newsFuture) return;
    _page = 0;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _controller.hasClients) _controller.jumpToPage(0);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<_WordPressPost>>(
      future: widget.newsFuture,
      builder: (context, snapshot) {
        final posts = snapshot.data ?? const <_WordPressPost>[];
        if (posts.isEmpty &&
            snapshot.connectionState != ConnectionState.waiting) {
          return const SizedBox.shrink();
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const AppSectionHeader(title: 'Novedades'),
            if (snapshot.connectionState == ConnectionState.waiting)
              const AppCard(
                child: SizedBox(
                  height: 184,
                  child: AppLoadingView(label: 'Cargando noticias...'),
                ),
              )
            else ...[
              SizedBox(
                height: 218,
                child: PageView.builder(
                  controller: _controller,
                  padEnds: false,
                  itemCount: posts.length,
                  onPageChanged: (value) => setState(() => _page = value),
                  itemBuilder: (context, index) {
                    final post = posts[index];
                    return Padding(
                      padding: EdgeInsets.only(
                        right: index == posts.length - 1 ? 0 : 10,
                      ),
                      child: AppCard(
                        padding: const EdgeInsets.all(12),
                        onTap: () => _openNews(context, post),
                        child: Row(
                          children: [
                            SizedBox(
                              width: 116,
                              height: double.infinity,
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(16),
                                child: _NewsVisual(post: post),
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 9,
                                          vertical: 5,
                                        ),
                                        decoration: BoxDecoration(
                                          color: AppTheme.primary.withValues(
                                            alpha: AppTheme.isDark(context)
                                                ? 0.20
                                                : 0.11,
                                          ),
                                          borderRadius: AppTheme.radiusXl,
                                        ),
                                        child: const Text(
                                          'COMUNICADO',
                                          style: TextStyle(
                                            color: AppTheme.primary,
                                            fontSize: 10,
                                            letterSpacing: 0.7,
                                            fontWeight: FontWeight.w800,
                                          ),
                                        ),
                                      ),
                                      const Spacer(),
                                      Icon(
                                        Icons.chevron_right_rounded,
                                        color: AppTheme.textMutedFor(context),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    post.title,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: AppTheme.textPrimaryFor(context),
                                      fontSize: 16,
                                      height: 1.25,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    post.excerpt,
                                    maxLines: 3,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: AppTheme.textSecondaryFor(context),
                                      fontSize: 12,
                                      height: 1.35,
                                    ),
                                  ),
                                  const Spacer(),
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.calendar_today_outlined,
                                        size: 13,
                                        color: AppTheme.textMutedFor(context),
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        post.dateLabel,
                                        style: TextStyle(
                                          color: AppTheme.textMutedFor(context),
                                          fontSize: 11,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              if (posts.length > 1) ...[
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(posts.length, (index) {
                    final selected = index == _page;
                    return AnimatedContainer(
                      duration: AppMotion.adaptive(context, AppMotion.standard),
                      curve: AppMotion.enterCurve,
                      width: selected ? 18 : 7,
                      height: 7,
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      decoration: BoxDecoration(
                        color: selected
                            ? AppTheme.primary
                            : AppTheme.dividerFor(context),
                        borderRadius: AppTheme.radiusXl,
                      ),
                    );
                  }),
                ),
              ],
            ],
          ],
        );
      },
    );
  }

  void _openNews(BuildContext context, _WordPressPost post) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (post.imageUrl != null) ...[
                ClipRRect(
                  borderRadius: AppTheme.radiusMd,
                  child: Image.network(
                    post.imageUrl.toString(),
                    width: double.infinity,
                    height: 190,
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(height: 16),
              ],
              Text(post.title, style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 12),
              Text(
                post.content.isEmpty ? post.excerpt : post.content,
                style: TextStyle(color: AppTheme.textSecondaryFor(context)),
              ),
              if (post.link != null) ...[
                const SizedBox(height: 18),
                AppButton.primary(
                  label: 'Abrir noticia completa',
                  icon: Icons.open_in_new_rounded,
                  onPressed: () => launchUrl(
                    post.link!,
                    mode: LaunchMode.externalApplication,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _NewsVisual extends StatelessWidget {
  const _NewsVisual({required this.post});

  final _WordPressPost post;

  @override
  Widget build(BuildContext context) {
    if (post.imageUrl != null) {
      return Image.network(
        post.imageUrl.toString(),
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => const _NewsFallback(),
      );
    }
    return const _NewsFallback();
  }
}

class _NewsFallback extends StatelessWidget {
  const _NewsFallback();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(gradient: AppTheme.primaryGradient),
      child: Center(
        child: Container(
          width: 68,
          height: 68,
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.15),
            shape: BoxShape.circle,
          ),
          child: SvgPicture.asset(
            'assets/branding/cic_mark.svg',
            colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn),
          ),
        ),
      ),
    );
  }
}

class _WordPressPost {
  const _WordPressPost({
    required this.title,
    required this.excerpt,
    required this.content,
    required this.link,
    required this.imageUrl,
    required this.dateLabel,
  });

  final String title;
  final String excerpt;
  final String content;
  final Uri? link;
  final Uri? imageUrl;
  final String dateLabel;

  static const mock = _WordPressPost(
    title: 'Nueva intranet móvil del CIC',
    excerpt:
        'Consulta tus documentos, reservas, formación y comunicaciones desde la aplicación.',
    content:
        'La nueva intranet móvil reúne en un solo lugar la información y las gestiones disponibles para cada usuario.',
    link: null,
    imageUrl: null,
    dateLabel: '11 ago 2026',
  );

  factory _WordPressPost.fromJson(Map<String, dynamic> json) {
    return _WordPressPost(
      title: _cleanHtml((json['title'] as Map?)?['rendered']?.toString() ?? ''),
      excerpt: _cleanHtml(
        (json['excerpt'] as Map?)?['rendered']?.toString() ?? '',
      ),
      content: _cleanHtml(
        (json['content'] as Map?)?['rendered']?.toString() ?? '',
      ),
      link: Uri.tryParse((json['link'] ?? '').toString()),
      imageUrl: _featuredImageUrl(json),
      dateLabel: _formatDate(json['date']?.toString()),
    );
  }

  static String _formatDate(String? raw) {
    final date = DateTime.tryParse(raw ?? '');
    if (date == null) return 'CIC Salamanca';
    const months = [
      'ene',
      'feb',
      'mar',
      'abr',
      'may',
      'jun',
      'jul',
      'ago',
      'sep',
      'oct',
      'nov',
      'dic',
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  static Uri? _featuredImageUrl(Map<String, dynamic> json) {
    final embedded = json['_embedded'];
    if (embedded is! Map) return null;
    final media = embedded['wp:featuredmedia'];
    if (media is! List || media.isEmpty || media.first is! Map) return null;
    return Uri.tryParse((media.first as Map)['source_url']?.toString() ?? '');
  }

  static String _cleanHtml(String value) {
    return value
        .replaceAll(RegExp(r'<[^>]+>'), ' ')
        .replaceAll('&nbsp;', ' ')
        .replaceAll('&amp;', '&')
        .replaceAll('&quot;', '"')
        .replaceAll('&#8217;', "'")
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }
}

class _ActivityList extends StatelessWidget {
  const _ActivityList({required this.items, required this.auth});

  final List<AppNotification> items;
  final AuthProvider auth;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const AppEmptyState(
        title: 'Sin actividad reciente',
        subtitle: 'Cuando haya novedades aparecerán aquí.',
        icon: Icons.notifications_none_rounded,
      );
    }

    final top = items.take(4).toList();
    return Column(
      children: top.map((n) {
        final color = n.level == 'high'
            ? AppTheme.error
            : n.level == 'medium'
            ? AppTheme.warning
            : AppTheme.primary;
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: AppListTile(
            onTap: () => ModuleNavigation.openModule(
              context,
              auth: auth,
              moduleKey: n.moduleKey,
            ),
            leading: Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            title: n.title,
            subtitle: '${n.subtitle} · ${n.createdAtLabel}',
          ),
        );
      }).toList(),
    );
  }
}

class _AccessScopeBanner extends StatelessWidget {
  const _AccessScopeBanner();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: AppCard(
        child: Row(
          children: [
            Icon(Icons.info_outline_rounded, size: 18, color: AppTheme.info),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Algunas métricas globales no están disponibles para este perfil. La app seguirá mostrando solo la información permitida dentro de sus permisos actuales.',
                style: TextStyle(
                  color: AppTheme.textSecondaryFor(context),
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
