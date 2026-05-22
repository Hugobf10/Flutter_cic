import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/app_notification.dart';
import '../providers/app_state_provider.dart';
import '../ui/app_components.dart';
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
    final list = _applyFilter(appState.notifications);

    return AppScaffold(
      title: 'Actividad',
      child: Column(
        children: [
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
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (_, i) => _NotificationCard(item: list[i]),
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

class _NotificationCard extends StatelessWidget {
  const _NotificationCard({required this.item});

  final AppNotification item;

  @override
  Widget build(BuildContext context) {
    final color = switch (item.level) {
      'high' => AppTheme.error,
      'medium' => AppTheme.warning,
      _ => AppTheme.primary,
    };

    return AppListTile(
      leading: Container(
        width: 30,
        height: 30,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(Icons.notifications_rounded, size: 16, color: color),
      ),
      title: item.title,
      subtitle: '${item.subtitle} · ${item.createdAtLabel}',
      trailing: item.unread ? const Icon(Icons.circle, size: 10, color: AppTheme.primary) : null,
    );
  }
}
