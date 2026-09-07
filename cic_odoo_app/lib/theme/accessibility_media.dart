import 'package:flutter/widgets.dart';

/// Changes semantic status colors only; never filters photos or documents.
class AccessibilityPalette extends InheritedWidget {
  const AccessibilityPalette({
    super.key,
    required this.alternativeColors,
    required super.child,
  });
  final bool alternativeColors;

  static bool enabled(BuildContext context) =>
      context
          .dependOnInheritedWidgetOfExactType<AccessibilityPalette>()
          ?.alternativeColors ??
      false;

  @override
  bool updateShouldNotify(AccessibilityPalette oldWidget) =>
      alternativeColors != oldWidget.alternativeColors;
}

/// Preserves Android's nonlinear scaling and the user's system magnification.
/// The app setting is an additional factor, never a cap on system accessibility.
class PreferenceTextScaler extends TextScaler {
  const PreferenceTextScaler(this.system, this.factor);
  final TextScaler system;
  final double factor;

  @override
  double scale(double fontSize) => system.scale(fontSize) * factor;

  @override
  double get textScaleFactor => scale(14) / 14;

  @override
  bool operator ==(Object other) =>
      other is PreferenceTextScaler &&
      other.system == system &&
      other.factor == factor;

  @override
  int get hashCode => Object.hash(system, factor);
}
