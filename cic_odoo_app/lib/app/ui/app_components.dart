import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../theme/app_theme.dart';

class AppScaffold extends StatelessWidget {
  const AppScaffold({
    super.key,
    required this.title,
    required this.child,
    this.actions,
    this.floatingActionButton,
    this.showAppBar = true,
    this.padding = const EdgeInsets.fromLTRB(20, 10, 20, 20),
  });

  final String title;
  final Widget child;
  final List<Widget>? actions;
  final Widget? floatingActionButton;
  final bool showAppBar;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surfaceFor(context),
      appBar: showAppBar ? AppBar(title: Text(title), actions: actions) : null,
      floatingActionButton: floatingActionButton,
      body: Container(
        decoration: BoxDecoration(gradient: AppTheme.heroGradientFor(context)),
        child: SafeArea(
          child: Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1120),
              child: Padding(padding: padding, child: child),
            ),
          ),
        ),
      ),
    );
  }
}

/// Superficie base del sistema neumórfico. Mantiene contraste mediante borde
/// además del relieve para que funcione también en modo oscuro.
class NeumorphicSurface extends StatelessWidget {
  const NeumorphicSurface({
    super.key,
    required this.child,
    this.padding = EdgeInsets.zero,
    this.margin = EdgeInsets.zero,
    this.borderRadius,
    this.color,
    this.onTap,
    this.subtle = false,
    this.showBorder = true,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry margin;
  final BorderRadius? borderRadius;
  final Color? color;
  final VoidCallback? onTap;
  final bool subtle;
  final bool showBorder;

  @override
  Widget build(BuildContext context) {
    final radius = borderRadius ?? AppTheme.radiusMd;
    final content = AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      margin: margin,
      padding: padding,
      decoration: AppTheme.neumorphicDecoration(
        context,
        borderRadius: radius,
        color: color,
        subtle: subtle,
        showBorder: showBorder,
      ),
      child: child,
    );
    if (onTap == null) return content;
    return Semantics(
      button: true,
      child: InkWell(borderRadius: radius, onTap: onTap, child: content),
    );
  }
}

class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.onTap,
  });

  final Widget child;
  final EdgeInsets padding;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return NeumorphicSurface(
      padding: padding,
      onTap: onTap,
      child: child,
    );
  }
}

class AppButton extends StatelessWidget {
  const AppButton.primary({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
    this.loading = false,
  }) : outlined = false;

  const AppButton.outline({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
    this.loading = false,
  }) : outlined = true;

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool loading;
  final bool outlined;

  @override
  Widget build(BuildContext context) {
    final content = Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (loading)
          const AppLoadingIndicator(size: 18)
        else if (icon != null)
          Icon(icon, size: 18),
        if (loading || icon != null) const SizedBox(width: 8),
        Text(label),
      ],
    );

    if (outlined) {
      return OutlinedButton(
        onPressed: loading ? null : onPressed,
        child: content,
      );
    }
    return FilledButton(onPressed: loading ? null : onPressed, child: content);
  }
}

class AppInput extends StatelessWidget {
  const AppInput({
    super.key,
    required this.controller,
    this.hintText,
    this.labelText,
    this.prefixIcon,
    this.keyboardType,
    this.onChanged,
    this.onSubmitted,
    this.obscureText = false,
    this.suffixIcon,
  });

  final TextEditingController controller;
  final String? hintText;
  final String? labelText;
  final IconData? prefixIcon;
  final TextInputType? keyboardType;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final bool obscureText;
  final Widget? suffixIcon;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscureText,
      onChanged: onChanged,
      onSubmitted: onSubmitted,
      decoration: InputDecoration(
        hintText: hintText,
        labelText: labelText,
        prefixIcon: prefixIcon == null ? null : Icon(prefixIcon),
        suffixIcon: suffixIcon,
      ),
    );
  }
}

class AppSearchBar extends StatelessWidget {
  const AppSearchBar({
    super.key,
    required this.controller,
    required this.hintText,
    this.onChanged,
    this.onSubmitted,
  });

  final TextEditingController controller;
  final String hintText;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;

  @override
  Widget build(BuildContext context) {
    return AppInput(
      controller: controller,
      hintText: hintText,
      prefixIcon: Icons.search_rounded,
      onChanged: onChanged,
      onSubmitted: onSubmitted,
      suffixIcon: controller.text.isEmpty
          ? null
          : IconButton(
              icon: const Icon(Icons.close_rounded, size: 18),
              onPressed: () {
                controller.clear();
                if (onChanged != null) onChanged!('');
              },
            ),
    );
  }
}

class AppSectionHeader extends StatelessWidget {
  const AppSectionHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.action,
  });

  final String title;
  final String? subtitle;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Theme.of(context).textTheme.titleLarge),
                if (subtitle != null) ...[
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      subtitle!,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                ],
              ],
            ),
          ),
          // ignore: use_null_aware_elements
          if (action case final action?) action,
        ],
      ),
    );
  }
}

class AppAvatar extends StatelessWidget {
  const AppAvatar({super.key, required this.name, this.size = 42});

  final String name;
  final double size;

  @override
  Widget build(BuildContext context) {
    final clean = name.trim();
    final parts = clean
        .split(RegExp(r'\s+'))
        .where((e) => e.isNotEmpty)
        .toList();
    final initials = parts.isEmpty
        ? 'U'
        : parts.length == 1
        ? parts.first[0].toUpperCase()
        : '${parts[0][0]}${parts[1][0]}'.toUpperCase();

    return Container(
      width: size,
      height: size,
      decoration: AppTheme.neumorphicDecoration(
        context,
        borderRadius: BorderRadius.circular(size / 2),
        subtle: true,
      ),
      child: Center(
        child: Text(
          initials,
          style: TextStyle(
            color: AppTheme.primary,
            fontWeight: FontWeight.w800,
            fontSize: size * 0.34,
          ),
        ),
      ),
    );
  }
}

class AppListTile extends StatelessWidget {
  const AppListTile({
    super.key,
    required this.title,
    this.subtitle,
    this.leading,
    this.trailing,
    this.onTap,
  });

  final String title;
  final String? subtitle;
  final Widget? leading;
  final Widget? trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          if (leading != null) ...[leading!, const SizedBox(width: 10)],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimaryFor(context),
                  ),
                ),
                if (subtitle != null) ...[
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      subtitle!,
                      style: TextStyle(
                        fontSize: 12,
                        color: AppTheme.textSecondaryFor(context),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          // ignore: use_null_aware_elements
          if (trailing case final trailing?) trailing,
        ],
      ),
    );
  }
}

class AppEmptyState extends StatelessWidget {
  const AppEmptyState({
    super.key,
    required this.title,
    required this.subtitle,
    this.icon = Icons.inbox_rounded,
    this.action,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: AppTheme.neumorphicDecoration(
                context,
                color: AppTheme.elevatedFor(context),
                borderRadius: BorderRadius.circular(18),
                subtle: true,
              ),
              child: Icon(
                icon,
                size: 26,
                color: AppTheme.textMutedFor(context),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: AppTheme.textPrimaryFor(context),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              subtitle,
              style: TextStyle(color: AppTheme.textSecondaryFor(context)),
              textAlign: TextAlign.center,
            ),
            if (action != null) ...[const SizedBox(height: 14), action!],
          ],
        ),
      ),
    );
  }
}

class AppLoadingView extends StatelessWidget {
  const AppLoadingView({super.key, this.label = 'Cargando'});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Center(child: AppLoadingIndicator(semanticLabel: label));
  }
}

/// Indicador de carga de la app: únicamente el símbolo de marca rebotando.
class AppLoadingIndicator extends StatefulWidget {
  const AppLoadingIndicator({
    super.key,
    this.size = 56,
    this.semanticLabel = 'Cargando',
  });

  final double size;
  final String semanticLabel;

  @override
  State<AppLoadingIndicator> createState() => _AppLoadingIndicatorState();
}

class _AppLoadingIndicatorState extends State<AppLoadingIndicator>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  double _jump(double phase) {
    if (phase < 0.12) return 0;
    if (phase < 0.34) {
      return -Curves.easeOutCubic.transform((phase - 0.12) / 0.22);
    }
    if (phase < 0.58) {
      return -1 + Curves.easeOutBack.transform((phase - 0.34) / 0.24) * 1.12;
    }
    if (phase < 0.70) {
      return 0.12 * (1 - Curves.easeOutCubic.transform((phase - 0.58) / 0.12));
    }
    return 0;
  }

  double _tilt(double phase) {
    if (phase < 0.34 || phase > 0.70) return 0;
    final progress = (phase - 0.34) / 0.36;
    return math.sin(progress * math.pi * 2) * 0.07;
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: widget.semanticLabel,
      liveRegion: true,
      child: SizedBox(
        width: widget.size,
        height: widget.size,
        child: RepaintBoundary(
          child: AnimatedBuilder(
            animation: _controller,
            child: SvgPicture.asset(
              'assets/branding/cic_mark.svg',
              width: widget.size,
              height: widget.size * 0.76,
              fit: BoxFit.contain,
              excludeFromSemantics: true,
            ),
            builder: (context, child) {
              final jump = _jump(_controller.value);
              return Align(
                alignment: Alignment.bottomCenter,
                child: Transform.translate(
                  offset: Offset(0, jump * widget.size * 0.24),
                  child: Transform.rotate(
                    angle: _tilt(_controller.value),
                    child: Transform.scale(
                      scale: 1 + (-jump * 0.08),
                      alignment: Alignment.bottomCenter,
                      child: child,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class AppStatusChip extends StatelessWidget {
  const AppStatusChip({super.key, required this.label, required this.color});
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: AppTheme.radiusXl,
        border: Border.all(color: color.withValues(alpha: 0.26)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class AppPdfCard extends StatelessWidget {
  const AppPdfCard({
    super.key,
    required this.title,
    required this.subtitle,
    this.amount,
    required this.onDownload,
    this.onPreview,
  });

  final String title;
  final String subtitle;
  final String? amount;
  final VoidCallback onDownload;
  final VoidCallback? onPreview;

  @override
  Widget build(BuildContext context) {
    return AppListTile(
      title: title,
      subtitle: subtitle,
      leading: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: AppTheme.error.withValues(alpha: 0.1),
          borderRadius: AppTheme.radiusSm,
        ),
        child: const Icon(
          Icons.picture_as_pdf_rounded,
          color: AppTheme.error,
          size: 18,
        ),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (amount != null)
            Padding(
              padding: const EdgeInsets.only(right: 6),
              child: Text(
                amount!,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          if (onPreview != null)
            IconButton(
              onPressed: onPreview,
              icon: const Icon(Icons.visibility_outlined, size: 18),
              tooltip: 'Previsualizar',
            ),
          IconButton(
            onPressed: onDownload,
            icon: const Icon(Icons.download_rounded, size: 18),
            tooltip: 'Descargar',
          ),
        ],
      ),
    );
  }
}

class AppBottomNavigation extends StatelessWidget {
  const AppBottomNavigation({
    super.key,
    required this.currentIndex,
    required this.onTap,
    required this.items,
  });

  final int currentIndex;
  final ValueChanged<int> onTap;
  final List<({String label, IconData icon, Widget? badge})> items;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      minimum: const EdgeInsets.fromLTRB(12, 0, 12, 10),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: AppTheme.cardFor(context).withValues(alpha: 0.96),
          borderRadius: BorderRadius.circular(28),
          border: Border.all(
            color: AppTheme.dividerFor(context).withValues(alpha: 0.78),
          ),
          boxShadow: AppTheme.raisedShadowFor(context),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
          child: Row(
            children: List.generate(items.length, (i) {
              final selected = i == currentIndex;
              final item = items[i];
              return Expanded(
                child: InkWell(
                  borderRadius: BorderRadius.circular(14),
                  onTap: () => onTap(i),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 220),
                    padding: const EdgeInsets.symmetric(
                      vertical: 8,
                      horizontal: 6,
                    ),
                    decoration: BoxDecoration(
                      color: selected
                          ? AppTheme.primary.withValues(
                              alpha: AppTheme.isDark(context) ? 0.22 : 0.14,
                            )
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(18),
                      border: selected
                          ? Border.all(
                              color: AppTheme.primary.withValues(alpha: 0.24),
                            )
                          : null,
                      boxShadow: selected
                          ? AppTheme.subtleShadowFor(context)
                          : const [],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        item.badge ??
                            Icon(
                              item.icon,
                              size: 20,
                              color: selected
                                  ? AppTheme.primary
                                  : AppTheme.textSecondaryFor(context),
                            ),
                        const SizedBox(height: 4),
                        Text(
                          item.label,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: selected
                                ? FontWeight.w700
                                : FontWeight.w500,
                            color: selected
                                ? AppTheme.primary
                                : AppTheme.textSecondaryFor(context),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}
