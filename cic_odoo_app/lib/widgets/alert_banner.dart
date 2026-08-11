import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Banner de alerta con icono, color de tono y acción.
class AlertBanner extends StatelessWidget {
  final String title;
  final int value;
  final String tone; // 'danger', 'warning', 'info'
  final VoidCallback? onTap;

  const AlertBanner({
    super.key,
    required this.title,
    required this.value,
    this.tone = 'warning',
    this.onTap,
  });

  Color get _color {
    switch (tone) {
      case 'danger':
        return AppTheme.danger;
      case 'warning':
        return AppTheme.warning;
      default:
        return AppTheme.info;
    }
  }

  IconData get _icon {
    switch (tone) {
      case 'danger':
        return Icons.error_outline_rounded;
      case 'warning':
        return Icons.warning_amber_rounded;
      default:
        return Icons.info_outline_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: _color.withValues(alpha: 0.1),
          borderRadius: AppTheme.radiusSm,
          border: Border.all(color: _color.withValues(alpha: 0.3)),
          boxShadow: AppTheme.subtleShadowFor(context),
        ),
        child: Row(
          children: [
            Icon(_icon, color: _color, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  color: _color,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: _color.withValues(alpha: 0.2),
                borderRadius: AppTheme.radiusXl,
              ),
              child: Text(
                value.toString(),
                style: TextStyle(
                  color: _color,
                  fontWeight: FontWeight.w800,
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
