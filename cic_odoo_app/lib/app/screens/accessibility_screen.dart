import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../l10n/strings.dart';
import '../../theme/app_motion.dart';
import '../../theme/app_theme.dart';
import '../providers/app_state_provider.dart';
import '../ui/app_components.dart';

class AccessibilityScreen extends StatefulWidget {
  const AccessibilityScreen({super.key});
  @override
  State<AccessibilityScreen> createState() => _AccessibilityScreenState();
}

class _AccessibilityScreenState extends State<AccessibilityScreen> {
  final _scroll = ScrollController();
  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<AppStateProvider>();
    final t = context.l10n;
    final percentage = (settings.textScaleFactor * 100).round();
    return AppScaffold(
      title: t.accessibility,
      child: ListView(
        controller: _scroll,
        children: [
          AppSectionHeader(
            title: t.readingVision,
            subtitle: t.readingVisionHint,
          ),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  t.textSize,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                Text('$percentage % · ${t.textSizeHint}'),
                Semantics(
                  label: t.textSize,
                  child: Slider(
                    value: settings.textScaleFactor,
                    min: 1,
                    max: 1.4,
                    divisions: 4,
                    label: '$percentage %',
                    onChanged: settings.setTextScaleFactor,
                  ),
                ),
                const Divider(),
                SwitchListTile.adaptive(
                  contentPadding: EdgeInsets.zero,
                  title: Text(t.boldText),
                  subtitle: Text(t.boldTextHint),
                  value: settings.boldText,
                  onChanged: settings.setBoldText,
                ),
                const Divider(),
                SwitchListTile.adaptive(
                  contentPadding: EdgeInsets.zero,
                  title: Text(t.highContrast),
                  subtitle: Text(t.highContrastHint),
                  value: settings.highContrast,
                  onChanged: settings.setHighContrast,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          AppSectionHeader(title: t.colorSupport, subtitle: t.colorSupportHint),
          AppCard(
            child: SwitchListTile.adaptive(
              contentPadding: EdgeInsets.zero,
              title: Text(t.alternativeColors),
              value: settings.alternativeColors,
              onChanged: settings.setAlternativeColors,
            ),
          ),
          const SizedBox(height: 16),
          AppSectionHeader(title: t.movement, subtitle: t.movementHint),
          AppCard(
            child: SwitchListTile.adaptive(
              contentPadding: EdgeInsets.zero,
              title: Text(t.reduceMotion),
              subtitle: Text(t.reduceMotionHint),
              value: settings.reduceMotion,
              onChanged: settings.setReduceMotion,
            ),
          ),
          const SizedBox(height: 16),
          AppSectionHeader(title: t.screenReader),
          AppCard(child: Text(t.screenReaderHint)),
          const SizedBox(height: 16),
          AppSectionHeader(title: t.preview),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(t.previewText),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    AppStatusChip(
                      label: t.previewSuccess,
                      color: AppTheme.success,
                    ),
                    AppStatusChip(
                      label: t.previewWarning,
                      color: AppTheme.warning,
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: settings.resetAccessibilityPreferences,
            icon: const Icon(Icons.restart_alt_rounded),
            label: Text(t.resetAccessibility),
          ),
          const SizedBox(height: 8),
          TextButton.icon(
            onPressed: () {
              if (!_scroll.hasClients) return;
              if (AppMotion.reduceMotion(context)) {
                _scroll.jumpTo(0);
              } else {
                _scroll.animateTo(
                  0,
                  duration: AppMotion.standard,
                  curve: AppMotion.enterCurve,
                );
              }
            },
            icon: const Icon(Icons.arrow_upward_rounded),
            label: Text(t.backToTop),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
