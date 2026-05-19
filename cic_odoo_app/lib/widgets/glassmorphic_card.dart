import 'dart:ui';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Tarjeta con efecto glassmorphism premium.
class GlassmorphicCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double blur;
  final double opacity;
  final VoidCallback? onTap;
  final Color? borderColor;

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

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: margin ?? const EdgeInsets.only(bottom: 12),
        child: ClipRRect(
          borderRadius: AppTheme.radiusMd,
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
            child: Container(
              padding: padding ??
                  const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: opacity),
                borderRadius: AppTheme.radiusMd,
                border: Border.all(
                  color: borderColor ??
                      Colors.white.withValues(alpha: 0.12),
                  width: 1,
                ),
              ),
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}
