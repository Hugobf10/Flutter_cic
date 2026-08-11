import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/module_navigation.dart';
import '../models/app_notification.dart';
import '../providers/app_state_provider.dart';
import '../ui/app_components.dart';
import '../../providers/auth_provider.dart';
import '../../theme/app_theme.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  String _filter = 'all';

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppStateProvider>();
    final auth = context.watch<AuthProvider>();
    final list = _applyFilter(appState.notifications);
    final unreadCount = appState.notifications.where((e) => e.unread).length;
    final highCount = appState.notifications
        .where((e) => e.level == 'high')
        .length;

    return AppScaffold(
      title: 'Actividad',
      child: Column(
        children: [
          _NotificationsHero(
            totalCount: appState.notifications.length,
            unreadCount: unreadCount,
            highCount: highCount,
          ),
          const SizedBox(height: 16),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildFilterChip('all', 'Todas', Icons.all_inbox_rounded),
                const SizedBox(width: 8),
                _buildFilterChip(
                  'unread',
                  'No leídas',
                  Icons.mark_email_unread_rounded,
                ),
                const SizedBox(width: 8),
                _buildFilterChip(
                  'high',
                  'Importantes',
                  Icons.priority_high_rounded,
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: appState.loadingNotifications
                ? const AppLoadingView(label: 'Cargando actividad...')
                : list.isEmpty
                ? const AppEmptyState(
                    title: 'Sin actividad',
                    subtitle: 'No hay notificaciones para este filtro.',
                    icon: Icons.notifications_none_rounded,
                  )
                : ListView.separated(
                    itemCount: list.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 8),
                    itemBuilder: (_, i) =>
                        _NotificationCard(item: list[i], auth: auth),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String key, String label, IconData icon) {
    return AppChoicePill(
      icon: icon,
      selected: _filter == key,
      label: label,
      onTap: () => setState(() => _filter = key),
    );
  }

  List<AppNotification> _applyFilter(List<AppNotification> all) {
    switch (_filter) {
      case 'unread':
        return all.where((e) => e.unread).toList();
      case 'high':
        return all.where((e) => e.level == 'high').toList();
      default:
        return all;
    }
  }
}

class _NotificationsHero extends StatelessWidget {
  const _NotificationsHero({
    required this.totalCount,
    required this.unreadCount,
    required this.highCount,
  });

  final int totalCount;
  final int unreadCount;
  final int highCount;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const AppIconSurface(
                icon: Icons.notifications_active_rounded,
                color: AppTheme.primary,
                size: 54,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Centro de actividad',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textPrimaryFor(context),
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      'Lo reciente, importante y pendiente de revisar.',
                      style: TextStyle(
                        color: AppTheme.textSecondaryFor(context),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _NotificationStat(
                  label: 'Total',
                  value: totalCount.toString(),
                  color: AppTheme.primary,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _NotificationStat(
                  label: 'No leídas',
                  value: unreadCount.toString(),
                  color: AppTheme.info,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _NotificationStat(
                  label: 'Importantes',
                  value: highCount.toString(),
                  color: AppTheme.warning,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _NotificationStat extends StatelessWidget {
  const _NotificationStat({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return NeumorphicSurface(
      padding: const EdgeInsets.all(12),
      color: Color.alphaBlend(
        color.withValues(alpha: AppTheme.isDark(context) ? 0.14 : 0.08),
        AppTheme.cardFor(context),
      ),
      borderRadius: BorderRadius.circular(16),
      subtle: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: AppTheme.textSecondaryFor(context),
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _NotificationCard extends StatelessWidget {
  const _NotificationCard({required this.item, required this.auth});

  final AppNotification item;
  final AuthProvider auth;

  @override
  Widget build(BuildContext context) {
    final color = switch (item.level) {
      'high' => AppTheme.error,
      'medium' => AppTheme.warning,
      _ => AppTheme.primary,
    };

    return AppListTile(
      onTap: () => ModuleNavigation.openModule(
        context,
        auth: auth,
        moduleKey: item.moduleKey,
      ),
      leading: AppIconSurface(
        icon: item.level == 'high'
            ? Icons.priority_high_rounded
            : Icons.notifications_rounded,
        color: color,
        size: 40,
        iconSize: 18,
      ),
      title: item.title,
      subtitle: '${item.subtitle} · ${item.createdAtLabel}',
      trailing: item.unread
          ? Icon(Icons.circle, size: 10, color: AppTheme.primary)
          : null,
    );
  }
}
