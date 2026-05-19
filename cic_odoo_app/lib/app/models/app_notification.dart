class AppNotification {
  const AppNotification({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.level,
    required this.createdAtLabel,
    required this.moduleKey,
    this.unread = true,
  });

  final int id;
  final String title;
  final String subtitle;
  final String level;
  final String createdAtLabel;
  final String moduleKey;
  final bool unread;
}
