import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/app_notification.dart';
import '../providers/app_state_provider.dart';

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

    return Scaffold(
      appBar: AppBar(title: const Text('Notificaciones')),
      body: Column(
        children: [
          const SizedBox(height: 8),
          SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16),
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
          const SizedBox(height: 8),
          Expanded(
            child: appState.loadingNotifications
                ? const Center(child: CircularProgressIndicator())
                : ListView.separated(
                    itemCount: list.length,
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                    separatorBuilder: (_, index) => const SizedBox(height: 8),
                    itemBuilder: (_, i) {
                      final n = list[i];
                      return _NotificationCard(item: n);
                    },
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
      'high' => const Color(0xFFEF4444),
      'medium' => const Color(0xFFF59E0B),
      _ => const Color(0xFF3B82F6),
    };

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Theme.of(context).dividerColor.withValues(alpha: 0.5)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 10,
            height: 10,
            margin: const EdgeInsets.only(top: 6),
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.title, style: const TextStyle(fontWeight: FontWeight.w700)),
                const SizedBox(height: 2),
                Text(item.subtitle, style: Theme.of(context).textTheme.bodySmall),
                const SizedBox(height: 6),
                Text(item.createdAtLabel, style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
          if (item.unread)
            Container(
              width: 8,
              height: 8,
              margin: const EdgeInsets.only(top: 6),
              decoration: const BoxDecoration(color: Color(0xFFEF4444), shape: BoxShape.circle),
            ),
        ],
      ),
    );
  }
}
