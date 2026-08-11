import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../app/core/module_navigation.dart';
import '../../app/models/app_notification.dart';
import '../../app/providers/app_state_provider.dart';
import '../../app/screens/notifications_screen.dart';
import '../../app/ui/app_components.dart';
import '../../config/app_config.dart';
import '../../features/goals/goals_screen.dart';
import '../../features/payroll/payroll_screen.dart';
import '../../providers/auth_provider.dart';
import '../../providers/dashboard_provider.dart';
import '../documentos/documentos_screen.dart';
import '../reservas/reservas_screen.dart';
import '../../theme/app_theme.dart';

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
      title: 'CIC Salamanca',
      actions: [
        IconButton(onPressed: _onRefresh, icon: Icon(Icons.refresh_rounded)),
      ],
      child: RefreshIndicator(
        onRefresh: _onRefresh,
        child: ListView(
          children: [
            _HomeHero(auth: auth, unreadCount: appState.unreadNotifications),
            const SizedBox(height: 18),
            const AppSectionHeader(
              title: 'Accesos rápidos',
              subtitle: 'Tus secciones más usadas',
            ),
            const _QuickActions(),
            const SizedBox(height: 16),
            _NewsSection(newsFuture: _newsFuture),
            const SizedBox(height: 16),
            if (dashboard.permissionDenied) const _AccessScopeBanner(),
            if (dashboard.state == DashboardState.loading &&
                dashboard.dashboardData == null)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 40),
                child: AppLoadingView(label: 'Cargando inicio...'),
              )
            else if (dashboard.state == DashboardState.error)
              AppEmptyState(
                title: 'No se pudo cargar el inicio',
                subtitle: dashboard.errorMessage ?? 'Error desconocido',
                icon: Icons.cloud_off_rounded,
                action: SizedBox(
                  width: 170,
                  child: AppButton.primary(
                    label: 'Reintentar',
                    icon: Icons.refresh_rounded,
                    onPressed: _onRefresh,
                  ),
                ),
              )
            else ...[
              const AppSectionHeader(
                title: 'Tu día',
                subtitle: 'Lo más relevante ahora mismo',
              ),
              _PendingList(kpis: dashboard.kpis, auth: auth),
            ],
            const SizedBox(height: 14),
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
    final now = DateTime.now();
    final day = now.day.toString().padLeft(2, '0');
    final month = now.month.toString().padLeft(2, '0');
    final avatarBytes = _decodeAvatar(auth.profileImageBase64);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: AppTheme.primaryGradient,
        borderRadius: AppTheme.radiusLg,
        boxShadow: AppTheme.glowShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Center(
                  child: avatarBytes == null
                      ? AppAvatar(name: name, size: 42)
                      : CircleAvatar(
                          radius: 21,
                          backgroundImage: MemoryImage(avatarBytes),
                        ),
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.18),
                  borderRadius: AppTheme.radiusXl,
                ),
                child: Text(
                  '$day/$month',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Text(
            'Hola, $firstName',
            style: Theme.of(
              context,
            ).textTheme.headlineMedium?.copyWith(color: Colors.white),
          ),
          const SizedBox(height: 6),
          Text(
            'Todo tu espacio de trabajo en una sola app, limpio y directo.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.white.withValues(alpha: 0.88),
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: _HeroStat(label: 'Usuario', value: auth.userLogin),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _HeroStat(
                  label: 'Avisos',
                  value: unreadCount.toString(),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Uint8List? _decodeAvatar(String raw) {
    if (raw.trim().isEmpty) return null;
    try {
      return Uint8List.fromList(base64Decode(raw));
    } catch (_) {
      return null;
    }
  }
}

class _HeroStat extends StatelessWidget {
  const _HeroStat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(color: Colors.white70, fontSize: 12)),
          const SizedBox(height: 4),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
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
    final actions = <({String title, IconData icon, VoidCallback onTap})>[
      if (auth.canViewModule('documents'))
        (
          title: 'Documentos',
          icon: Icons.description_rounded,
          onTap: () {
            Navigator.of(
              context,
            ).push(MaterialPageRoute(builder: (_) => const DocumentosScreen()));
          },
        ),
      if (auth.canViewModule('reservas'))
        (
          title: 'Reservas',
          icon: Icons.calendar_month_rounded,
          onTap: () {
            Navigator.of(
              context,
            ).push(MaterialPageRoute(builder: (_) => const ReservasScreen()));
          },
        ),
      if (auth.canViewModule('goals'))
        (
          title: 'Objetivos',
          icon: Icons.track_changes_rounded,
          onTap: () {
            Navigator.of(
              context,
            ).push(MaterialPageRoute(builder: (_) => const GoalsScreen()));
          },
        ),
      if (auth.canViewModule('payroll'))
        (
          title: 'Nóminas',
          icon: Icons.receipt_long_rounded,
          onTap: () {
            Navigator.of(
              context,
            ).push(MaterialPageRoute(builder: (_) => const PayrollScreen()));
          },
        ),
    ];

    if (actions.isEmpty) {
      return const AppEmptyState(
        title: 'Sin accesos rápidos',
        subtitle: 'No hay módulos destacados disponibles para este usuario.',
        icon: Icons.apps_outlined,
      );
    }

    return LayoutBuilder(
      builder: (context, c) {
        final cols = c.maxWidth < 560 ? 2 : 4;
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: actions.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: cols,
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 1.1,
          ),
          itemBuilder: (_, i) {
            final a = actions[i];
            return AppCard(
              onTap: a.onTap,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: AppTheme.primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(a.icon, color: AppTheme.primary, size: 20),
                  ),
                  const Spacer(),
                  Text(
                    a.title,
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textPrimaryFor(context),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Abrir módulo',
                    style: TextStyle(
                      color: AppTheme.textMutedFor(context),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class _NewsSection extends StatelessWidget {
  const _NewsSection({required this.newsFuture});

  final Future<List<_WordPressPost>> newsFuture;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<_WordPressPost>>(
      future: newsFuture,
      builder: (context, snapshot) {
        final posts = snapshot.data ?? const <_WordPressPost>[];
        if (posts.isEmpty &&
            snapshot.connectionState != ConnectionState.waiting) {
          return const SizedBox.shrink();
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const AppSectionHeader(
              title: 'Noticias',
              subtitle: 'Últimas publicaciones del CIC',
            ),
            if (snapshot.connectionState == ConnectionState.waiting)
              const AppCard(
                child: SizedBox(
                  height: 72,
                  child: AppLoadingView(label: 'Cargando noticias...'),
                ),
              )
            else
              SizedBox(
                height: 184,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: posts.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 10),
                  itemBuilder: (context, index) {
                    final post = posts[index];
                    return SizedBox(
                      width: 260,
                      child: AppCard(
                        onTap: () => _openNews(context, post),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (post.imageUrl != null) ...[
                              ClipRRect(
                                borderRadius: AppTheme.radiusSm,
                                child: Image.network(
                                  post.imageUrl.toString(),
                                  height: 62,
                                  width: double.infinity,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, _, _) =>
                                      const SizedBox.shrink(),
                                ),
                              ),
                              const SizedBox(height: 8),
                            ],
                            Text(
                              post.title,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: AppTheme.textPrimaryFor(context),
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              post.excerpt,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: AppTheme.textSecondaryFor(context),
                                fontSize: 12,
                              ),
                            ),
                            const Spacer(),
                            Text(
                              'Leer más',
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.primary,
                                fontWeight: FontWeight.w700,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
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

class _WordPressPost {
  const _WordPressPost({
    required this.title,
    required this.excerpt,
    required this.content,
    required this.link,
    required this.imageUrl,
  });

  final String title;
  final String excerpt;
  final String content;
  final Uri? link;
  final Uri? imageUrl;

  static const mock = _WordPressPost(
    title: 'Nueva intranet móvil del CIC',
    excerpt:
        'Consulta tus documentos, reservas, formación y comunicaciones desde la aplicación.',
    content:
        'La nueva intranet móvil reúne en un solo lugar la información y las gestiones disponibles para cada usuario.',
    link: null,
    imageUrl: null,
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
    );
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

class _PendingList extends StatelessWidget {
  const _PendingList({required this.kpis, required this.auth});

  final List<dynamic> kpis;
  final AuthProvider auth;

  @override
  Widget build(BuildContext context) {
    if (kpis.isEmpty) {
      return const AppEmptyState(
        title: 'Sin pendientes',
        subtitle: 'No hay tareas críticas en este momento.',
        icon: Icons.task_alt_rounded,
      );
    }

    final top = kpis
        .take(4)
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();
    return Column(
      children: top.map((kpi) {
        final value = (kpi['value'] ?? 0).toString();
        final title = (kpi['title'] ?? 'Indicador').toString();
        final helper = (kpi['helper'] ?? '').toString();
        final moduleKey = ModuleNavigation.inferModuleKeyFromKpi(kpi);
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: AppListTile(
            onTap: moduleKey == null
                ? null
                : () => ModuleNavigation.openModule(
                    context,
                    auth: auth,
                    moduleKey: moduleKey,
                  ),
            title: title,
            subtitle: helper.isEmpty ? 'Pendiente' : helper,
            leading: Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: AppTheme.primaryLight,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                Icons.analytics_rounded,
                size: 18,
                color: AppTheme.primary,
              ),
            ),
            trailing: Text(
              value,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppTheme.textPrimaryFor(context),
              ),
            ),
          ),
        );
      }).toList(),
    );
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
