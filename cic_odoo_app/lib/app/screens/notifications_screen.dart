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
    final highCount = appState.notifications.where((e) => e.level == 'high').length;

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
                _buildFilterChip('all', 'Todas'),
                const SizedBox(width: 8),
                _buildFilterChip('unread', 'No leídas'),
                const SizedBox(width: 8),
                _buildFilterChip('high', 'Importantes'),
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

  Widget _buildFilterChip(String key, String label) {
    return ChoiceChip(
      selected: _filter == key,
      label: Text(label),
      onSelected: (_) => setState(() => _filter = key),
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
          const Text(
            'Centro de actividad',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Aquí ves lo más reciente, lo importante y lo pendiente de revisar.',
            style: TextStyle(color: AppTheme.textSecondary),
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
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: AppTheme.textSecondary,
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
      leading: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(Icons.notifications_rounded, size: 18, color: color),
      ),
      title: item.title,
      subtitle: '${item.subtitle} · ${item.createdAtLabel}',
      trailing: item.unread
          ? const Icon(Icons.circle, size: 10, color: AppTheme.primary)
          : null,
    );
  }
}
