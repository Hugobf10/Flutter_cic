import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Alias histórico conservado para no romper pantallas antiguas.
/// La superficie ahora sigue el sistema neumórfico global.
class GlassmorphicCard extends StatelessWidget {
  const GlassmorphicCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.blur = 12,
    this.opacity = 0.08,
    this.onTap,
    this.borderColor,
  });

  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double blur;
  final double opacity;
  final VoidCallback? onTap;
  final Color? borderColor;

  @override
  Widget build(BuildContext context) {
    final radius = AppTheme.radiusMd;
    final content = Container(
      margin: margin ?? const EdgeInsets.only(bottom: 12),
      padding: padding ?? const EdgeInsets.all(20),
      decoration: AppTheme.neumorphicDecoration(context, borderRadius: radius)
          .copyWith(
            border: Border.all(
              color:
                  borderColor ??
                  AppTheme.dividerFor(context).withValues(alpha: 0.72),
            ),
          ),
      child: child,
    );
    if (onTap == null) return content;
    return InkWell(borderRadius: radius, onTap: onTap, child: content);
  }
}
