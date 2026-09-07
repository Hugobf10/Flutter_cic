import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_motion.dart';
import 'accessibility_media.dart';

class AppTheme {
  AppTheme._();

  static Color statusColorFor(BuildContext context, Color color) {
    if (MediaQuery.highContrastOf(context)) return textPrimaryFor(context);
    if (!AccessibilityPalette.enabled(context)) return color;
    final dark = isDark(context);
    if (color == success || color == info || color == accent) {
      return dark ? const Color(0xFF8CCBFF) : const Color(0xFF005A91);
    }
    if (color == danger || color == warning) {
      return dark ? const Color(0xFFFFBE85) : const Color(0xFF8B3A00);
    }
    return color;
  }

  // Identidad CIC.
  static const Color primary = Color(0xFF0191B9);
  static const Color primaryDark = Color(0xFF07005E);
  static const Color accent = Color(0xFF3C6FE6);

  static const Color success = Color(0xFF21B573);
  static const Color warning = Color(0xFFFFA938);
  static const Color danger = Color(0xFFFF5A5F);
  static const Color error = danger;
  static const Color info = primary;
  static const Color primaryLight = Color(0xFFD8F1F7);

  // Tokens claros. Las superficies comparten tono para crear el relieve suave.
  static const Color surface = Color(0xFFEEF2F6);
  static const Color surfaceLight = Color(0xFFF6F8FB);
  static const Color surfaceCard = Color(0xFFEEF2F6);
  static const Color surfaceElevated = Color(0xFFE5EBF2);
  static const Color textPrimary = Color(0xFF111A33);
  static const Color textSecondary = Color(0xFF536078);
  static const Color textMuted = Color(0xFF7F8A9E);
  static const Color divider = Color(0xFFD4DCE6);

  // Tokens oscuros con contraste reforzado; no se depende solo de las sombras.
  static const Color _darkSurface = Color(0xFF171B24);
  static const Color _darkCard = Color(0xFF202633);
  static const Color _darkElevated = Color(0xFF272E3C);
  static const Color _darkDivider = Color(0xFF374151);
  static const Color _darkText = Color(0xFFF4F7FB);
  static const Color _darkTextSecondary = Color(0xFFB9C3D2);
  static const Color _darkTextMuted = Color(0xFF8A95A7);

  static const LinearGradient cardGradient = LinearGradient(
    colors: [Color(0xFFF4F7FA), Color(0xFFE8EDF3)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient heroGradient = LinearGradient(
    colors: [Color(0xFFF4F7FA), Color(0xFFEEF2F6), Color(0xFFE9EFF5)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // The product uses a flat, bordered visual language. Keeping these aliases
  // empty also removes shadows from legacy components without duplicating UI
  // changes across every screen.
  static List<BoxShadow> get softShadow => const [];
  static List<BoxShadow> get glowShadow => const [];

  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF07005E), Color(0xFF0191B9)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static final BorderRadius radiusSm = BorderRadius.circular(14);
  static final BorderRadius radiusMd = BorderRadius.circular(20);
  static final BorderRadius radiusLg = BorderRadius.circular(28);
  static final BorderRadius radiusXl = BorderRadius.circular(9999);

  static final Map<(Brightness, bool), ThemeData> _themes = {};
  static ThemeData _cachedTheme(Brightness brightness, bool contrast) =>
      _themes.putIfAbsent((
        brightness,
        contrast,
      ), () => _buildTheme(brightness, highContrast: contrast));

  static ThemeData get lightTheme => lightThemeFor();
  static ThemeData get darkTheme => darkThemeFor();

  static ThemeData lightThemeFor({bool highContrast = false}) =>
      _cachedTheme(Brightness.light, highContrast);

  static ThemeData darkThemeFor({bool highContrast = false}) =>
      _cachedTheme(Brightness.dark, highContrast);

  static bool isDark(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark;

  static Color surfaceFor(BuildContext context) =>
      Theme.of(context).scaffoldBackgroundColor;

  static Color cardFor(BuildContext context) =>
      Theme.of(context).cardTheme.color ??
      (isDark(context) ? _darkCard : surfaceCard);

  static Color elevatedFor(BuildContext context) =>
      Theme.of(context).inputDecorationTheme.fillColor ??
      (isDark(context) ? _darkElevated : surfaceElevated);

  static Color dividerFor(BuildContext context) =>
      Theme.of(context).dividerColor;

  static Color textPrimaryFor(BuildContext context) =>
      Theme.of(context).textTheme.titleLarge?.color ??
      (isDark(context) ? _darkText : textPrimary);

  static Color textSecondaryFor(BuildContext context) =>
      Theme.of(context).textTheme.bodyLarge?.color ??
      (isDark(context) ? _darkTextSecondary : textSecondary);

  static Color textMutedFor(BuildContext context) =>
      Theme.of(context).textTheme.bodySmall?.color ??
      (isDark(context) ? _darkTextMuted : textMuted);

  static List<BoxShadow> raisedShadowFor(BuildContext context) => const [];

  static List<BoxShadow> subtleShadowFor(BuildContext context) => const [];

  static BoxDecoration neumorphicDecoration(
    BuildContext context, {
    BorderRadius? borderRadius,
    Color? color,
    bool subtle = false,
    bool showBorder = true,
  }) {
    return BoxDecoration(
      color: color ?? cardFor(context),
      borderRadius: borderRadius ?? radiusMd,
      border: showBorder
          ? Border.all(color: dividerFor(context).withValues(alpha: 0.72))
          : null,
      boxShadow: const [],
    );
  }

  static LinearGradient cardGradientFor(BuildContext context) {
    if (MediaQuery.highContrastOf(context)) {
      return LinearGradient(colors: [cardFor(context), cardFor(context)]);
    }
    if (!isDark(context)) return cardGradient;
    return const LinearGradient(
      colors: [Color(0xFF252C39), Color(0xFF1C222D)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );
  }

  static LinearGradient heroGradientFor(BuildContext context) {
    if (MediaQuery.highContrastOf(context)) {
      return LinearGradient(colors: [surfaceFor(context), surfaceFor(context)]);
    }
    if (!isDark(context)) return heroGradient;
    return const LinearGradient(
      colors: [Color(0xFF1B202A), Color(0xFF171B24), Color(0xFF1D2330)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );
  }

  static ThemeData _buildTheme(
    Brightness brightness, {
    bool highContrast = false,
  }) {
    final isDark = brightness == Brightness.dark;
    final bg = highContrast
        ? (isDark ? Colors.black : Colors.white)
        : (isDark ? _darkSurface : surface);
    final card = highContrast
        ? (isDark ? const Color(0xFF090909) : Colors.white)
        : (isDark ? _darkCard : surfaceCard);
    final elevated = highContrast
        ? (isDark ? const Color(0xFF141414) : const Color(0xFFF2F2F2))
        : (isDark ? _darkElevated : surfaceElevated);
    final border = highContrast
        ? (isDark ? Colors.white : const Color(0xFF111111))
        : (isDark ? _darkDivider : divider);
    final text = highContrast
        ? (isDark ? Colors.white : Colors.black)
        : (isDark ? _darkText : textPrimary);
    final textSub = highContrast
        ? (isDark ? const Color(0xFFF0F0F0) : const Color(0xFF202020))
        : (isDark ? _darkTextSecondary : textSecondary);
    final muted = highContrast
        ? (isDark ? const Color(0xFFD8D8D8) : const Color(0xFF383838))
        : (isDark ? _darkTextMuted : textMuted);

    final base = ThemeData(useMaterial3: true, brightness: brightness);
    // Restore the product typeface. It is Plus Jakarta Sans, not Space Grotesk;
    // no font substitution is made by the accessibility settings.
    final txt = GoogleFonts.plusJakartaSansTextTheme(
      base.textTheme,
    ).apply(bodyColor: text, displayColor: text);
    final scheme = ColorScheme.fromSeed(
      seedColor: primary,
      brightness: brightness,
      primary: primary,
      secondary: accent,
      surface: card,
      error: danger,
    );

    final buttonShape = RoundedRectangleBorder(borderRadius: radiusSm);
    final controlOverlay = primary.withValues(alpha: isDark ? 0.16 : 0.10);

    return base.copyWith(
      scaffoldBackgroundColor: bg,
      canvasColor: bg,
      dividerColor: border,
      colorScheme: scheme,
      splashColor: controlOverlay,
      highlightColor: controlOverlay,
      textTheme: txt.copyWith(
        headlineLarge: TextStyle(
          fontSize: 34,
          height: 1.08,
          letterSpacing: -0.9,
          fontWeight: FontWeight.w800,
          color: text,
        ),
        headlineMedium: TextStyle(
          fontSize: 28,
          height: 1.12,
          letterSpacing: -0.55,
          fontWeight: FontWeight.w800,
          color: text,
        ),
        titleLarge: TextStyle(
          fontSize: 21,
          fontWeight: FontWeight.w700,
          color: text,
        ),
        titleMedium: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w700,
          color: text,
        ),
        bodyLarge: TextStyle(
          fontSize: 15,
          height: 1.45,
          fontWeight: FontWeight.w500,
          color: textSub,
        ),
        bodyMedium: TextStyle(
          fontSize: 14,
          height: 1.4,
          fontWeight: FontWeight.w500,
          color: textSub,
        ),
        bodySmall: TextStyle(
          fontSize: 12,
          height: 1.35,
          fontWeight: FontWeight.w500,
          color: muted,
        ),
        labelLarge: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: bg,
        foregroundColor: text,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        toolbarHeight: 68,
        scrolledUnderElevation: 0,
        systemOverlayStyle: isDark
            ? SystemUiOverlayStyle.light
            : SystemUiOverlayStyle.dark,
        iconTheme: IconThemeData(color: textSub),
        actionsIconTheme: IconThemeData(color: textSub),
        titleTextStyle: TextStyle(
          color: text,
          fontSize: 23,
          letterSpacing: -0.35,
          fontWeight: FontWeight.w800,
        ),
      ),
      cardTheme: CardThemeData(
        color: card,
        surfaceTintColor: Colors.transparent,
        shadowColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: radiusMd,
          side: BorderSide(color: border.withValues(alpha: 0.72)),
        ),
        elevation: 0,
        margin: EdgeInsets.zero,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: elevated,
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 17,
          vertical: 16,
        ),
        labelStyle: TextStyle(color: textSub, fontWeight: FontWeight.w600),
        hintStyle: TextStyle(color: muted),
        prefixIconColor: muted,
        suffixIconColor: muted,
        border: OutlineInputBorder(
          borderRadius: radiusMd,
          borderSide: BorderSide(color: border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: radiusMd,
          borderSide: BorderSide(color: border.withValues(alpha: 0.78)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: radiusMd,
          borderSide: const BorderSide(color: primary, width: 1.7),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: radiusMd,
          borderSide: const BorderSide(color: danger),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        height: 72,
        elevation: 0,
        backgroundColor: card,
        surfaceTintColor: Colors.transparent,
        indicatorColor: primary.withValues(alpha: isDark ? 0.22 : 0.14),
        indicatorShape: RoundedRectangleBorder(borderRadius: radiusSm),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          return IconThemeData(
            color: states.contains(WidgetState.selected) ? primary : muted,
            size: 23,
          );
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return TextStyle(
            fontSize: 11,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
            color: selected ? primary : muted,
          );
        }),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: card,
        selectedItemColor: primary,
        unselectedItemColor: muted,
        elevation: 0,
        type: BottomNavigationBarType.fixed,
      ),
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: card,
        indicatorColor: primary.withValues(alpha: isDark ? 0.22 : 0.14),
        selectedIconTheme: const IconThemeData(color: primary),
        unselectedIconTheme: IconThemeData(color: muted),
        selectedLabelTextStyle: TextStyle(
          color: primary,
          fontWeight: FontWeight.w700,
        ),
        unselectedLabelTextStyle: TextStyle(
          color: muted,
          fontWeight: FontWeight.w600,
        ),
      ),
      tabBarTheme: TabBarThemeData(
        dividerColor: Colors.transparent,
        labelStyle: TextStyle(fontWeight: FontWeight.w700),
        unselectedLabelStyle: TextStyle(fontWeight: FontWeight.w600),
        labelColor: primary,
        unselectedLabelColor: muted,
        indicator: BoxDecoration(
          color: primary.withValues(alpha: isDark ? 0.20 : 0.13),
          borderRadius: radiusSm,
          border: Border.all(color: primary.withValues(alpha: 0.28)),
        ),
        indicatorSize: TabBarIndicatorSize.tab,
      ),
      chipTheme: base.chipTheme.copyWith(
        backgroundColor: elevated,
        selectedColor: primary.withValues(alpha: isDark ? 0.22 : 0.13),
        disabledColor: elevated.withValues(alpha: 0.55),
        labelStyle: TextStyle(color: textSub, fontWeight: FontWeight.w700),
        side: BorderSide(color: border.withValues(alpha: 0.78)),
        shape: RoundedRectangleBorder(borderRadius: radiusXl),
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 7),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(48, 52),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          backgroundColor: primaryDark,
          foregroundColor: Colors.white,
          disabledBackgroundColor: elevated,
          disabledForegroundColor: muted,
          shape: buttonShape,
          textStyle: TextStyle(fontWeight: FontWeight.w700),
          elevation: 0,
          shadowColor: Colors.transparent,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          minimumSize: const Size(48, 52),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          backgroundColor: primaryDark,
          foregroundColor: Colors.white,
          disabledBackgroundColor: elevated,
          disabledForegroundColor: muted,
          shape: buttonShape,
          textStyle: TextStyle(fontWeight: FontWeight.w700),
          elevation: 0,
          shadowColor: Colors.transparent,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(48, 52),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          backgroundColor: card,
          foregroundColor: text,
          disabledForegroundColor: muted,
          side: BorderSide(color: border.withValues(alpha: 0.86)),
          shape: buttonShape,
          textStyle: TextStyle(fontWeight: FontWeight.w700),
          elevation: 0,
          shadowColor: Colors.transparent,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primary,
          shape: RoundedRectangleBorder(borderRadius: radiusSm),
          textStyle: TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          foregroundColor: textSub,
          backgroundColor: elevated.withValues(alpha: 0.86),
          disabledForegroundColor: muted,
          shape: RoundedRectangleBorder(borderRadius: radiusSm),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: primaryDark,
        foregroundColor: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: radiusMd),
      ),
      listTileTheme: ListTileThemeData(
        iconColor: primary,
        textColor: text,
        subtitleTextStyle: TextStyle(color: textSub, fontSize: 12),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
        shape: RoundedRectangleBorder(borderRadius: radiusMd),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: card,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shadowColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: radiusLg,
          side: BorderSide(color: border),
        ),
        titleTextStyle: TextStyle(
          color: text,
          fontSize: 20,
          fontWeight: FontWeight.w800,
        ),
        contentTextStyle: TextStyle(color: textSub, height: 1.45),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: card,
        modalBackgroundColor: card,
        surfaceTintColor: Colors.transparent,
        showDragHandle: true,
        dragHandleColor: muted,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
          side: BorderSide(color: border),
        ),
      ),
      drawerTheme: DrawerThemeData(
        backgroundColor: bg,
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.horizontal(right: Radius.circular(30)),
        ),
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: card,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: radiusMd,
          side: BorderSide(color: border),
        ),
        textStyle: TextStyle(color: text, fontWeight: FontWeight.w600),
      ),
      dividerTheme: DividerThemeData(
        color: border.withValues(alpha: 0.72),
        thickness: 1,
        space: 24,
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith(
          (states) =>
              states.contains(WidgetState.selected) ? primary : elevated,
        ),
        checkColor: const WidgetStatePropertyAll(Colors.white),
        side: BorderSide(color: border, width: 1.4),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
      ),
      radioTheme: RadioThemeData(
        fillColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected) ? primary : muted,
        ),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (states) =>
              states.contains(WidgetState.selected) ? Colors.white : muted,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (states) =>
              states.contains(WidgetState.selected) ? primary : elevated,
        ),
        trackOutlineColor: WidgetStatePropertyAll(border),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: primary,
        linearTrackColor: elevated,
        circularTrackColor: elevated,
      ),
      badgeTheme: BadgeThemeData(
        backgroundColor: danger,
        textColor: Colors.white,
        textStyle: TextStyle(fontSize: 10, fontWeight: FontWeight.w800),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: isDark ? _darkElevated : textPrimary,
        contentTextStyle: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w600,
        ),
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: radiusSm),
      ),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: AppPageTransitionsBuilder(),
          TargetPlatform.iOS: AppPageTransitionsBuilder(),
          TargetPlatform.macOS: AppPageTransitionsBuilder(),
          TargetPlatform.windows: AppPageTransitionsBuilder(),
          TargetPlatform.linux: AppPageTransitionsBuilder(),
          TargetPlatform.fuchsia: AppPageTransitionsBuilder(),
        },
      ),
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: isDark ? _darkElevated : textPrimary,
          borderRadius: radiusSm,
        ),
        textStyle: const TextStyle(color: Colors.white, fontSize: 12),
      ),
    );
  }
}
