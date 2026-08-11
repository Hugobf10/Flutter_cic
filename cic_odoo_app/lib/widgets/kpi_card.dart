import 'package:flutter/material.dart';

import '../app/ui/app_components.dart';
import '../theme/app_motion.dart';
import '../theme/app_theme.dart';

/// Tarjeta de KPI con indicador de estado y animación.
class KpiCard extends StatefulWidget {
  final String title;
  final String value;
  final String? badge;
  final String? helper;
  final IconData icon;
  final String tone; // 'info', 'success', 'warning', 'danger'
  final VoidCallback? onTap;

  const KpiCard({
    super.key,
    required this.title,
    required this.value,
    this.badge,
    this.helper,
    required this.icon,
    this.tone = 'info',
    this.onTap,
  });

  @override
  State<KpiCard> createState() => _KpiCardState();
}

class _KpiCardState extends State<KpiCard> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scaleAnimation;
  late final Animation<double> _fadeAnimation;
  bool _started = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: AppMotion.emphasized,
      vsync: this,
    );
    final curved = CurvedAnimation(
      parent: _controller,
      curve: AppMotion.enterCurve,
    );
    _scaleAnimation = Tween<double>(begin: 0.96, end: 1).animate(curved);
    _fadeAnimation = curved;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    if (AppMotion.reduceMotion(context)) {
      _controller.value = 1;
    } else {
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Color get _toneColor {
    switch (widget.tone) {
      case 'success':
        return AppTheme.success;
      case 'warning':
        return AppTheme.warning;
      case 'danger':
        return AppTheme.danger;
      default:
        return AppTheme.info;
    }
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: NeumorphicSurface(
          onTap: widget.onTap,
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: _toneColor.withValues(alpha: 0.15),
                      borderRadius: AppTheme.radiusSm,
                    ),
                    child: Icon(widget.icon, color: _toneColor, size: 18),
                  ),
                  const Spacer(),
                  if (widget.badge != null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: _toneColor.withValues(alpha: 0.15),
                        borderRadius: AppTheme.radiusXl,
                      ),
                      child: Text(
                        widget.badge!,
                        style: TextStyle(
                          color: _toneColor,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                widget.value,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.textPrimaryFor(context),
                  height: 1,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                widget.title,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: AppTheme.textSecondaryFor(context),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              if (widget.helper != null) ...[
                const SizedBox(height: 4),
                Text(
                  widget.helper!,
                  style: TextStyle(
                    fontSize: 10,
                    color: AppTheme.textMutedFor(context),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
