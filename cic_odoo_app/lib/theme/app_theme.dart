import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  AppTheme._();

  static const Color primary = Color(0xFF0A84FF);
  static const Color primaryDark = Color(0xFF0067D6);
  static const Color accent = Color(0xFF34C3B3);

  static const Color success = Color(0xFF21B573);
  static const Color warning = Color(0xFFFFA938);
  static const Color danger = Color(0xFFFF5A5F);
  static const Color error = danger;
  static const Color info = Color(0xFF0A84FF);
  static const Color primaryLight = Color(0xFFD9ECFF);

  static const Color surface = Color(0xFFF4F7FB);
  static const Color surfaceLight = Colors.white;
  static const Color surfaceCard = Colors.white;
  static const Color surfaceElevated = Color(0xFFECF2F9);
  static const Color textPrimary = Color(0xFF152033);
  static const Color textSecondary = Color(0xFF5F6F86);
  static const Color textMuted = Color(0xFF90A0B7);
  static const Color divider = Color(0xFFDCE5F0);

  static const LinearGradient cardGradient = LinearGradient(
    colors: [Color(0xFFFFFFFF), Color(0xFFF8FBFF)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  static const LinearGradient heroGradient = LinearGradient(
    colors: [Color(0xFFE8F3FF), Color(0xFFF8FBFF), Color(0xFFF0FBF8)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  static List<BoxShadow> get softShadow => const [
        BoxShadow(
          color: Color(0x120D1B2A),
          blurRadius: 28,
          offset: Offset(0, 14),
        ),
      ];
  static List<BoxShadow> get glowShadow => const [
        BoxShadow(
          color: Color(0x160A84FF),
          blurRadius: 30,
          offset: Offset(0, 12),
        ),
      ];

  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF0A84FF), Color(0xFF34C3B3)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static final BorderRadius radiusSm = BorderRadius.circular(14);
  static final BorderRadius radiusMd = BorderRadius.circular(20);
  static final BorderRadius radiusLg = BorderRadius.circular(28);
  static final BorderRadius radiusXl = BorderRadius.circular(9999);

  static ThemeData get lightTheme => _buildTheme(Brightness.light);
  static ThemeData get darkTheme => _buildTheme(Brightness.dark);

  static bool isDark(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark;

  static Color surfaceFor(BuildContext context) =>
      isDark(context) ? const Color(0xFF0B1623) : surface;

  static Color cardFor(BuildContext context) =>
      isDark(context) ? const Color(0xFF102033) : surfaceCard;

  static Color elevatedFor(BuildContext context) =>
      isDark(context) ? const Color(0xFF16304A) : surfaceElevated;

  static Color dividerFor(BuildContext context) =>
      isDark(context) ? const Color(0xFF27415D) : divider;

  static Color textPrimaryFor(BuildContext context) =>
      isDark(context) ? const Color(0xFFF5F9FF) : textPrimary;

  static Color textSecondaryFor(BuildContext context) =>
      isDark(context) ? const Color(0xFFBFD0E3) : textSecondary;

  static Color textMutedFor(BuildContext context) =>
      isDark(context) ? const Color(0xFF7E91A8) : textMuted;

  static LinearGradient cardGradientFor(BuildContext context) {
    if (!isDark(context)) return cardGradient;
    return const LinearGradient(
      colors: [Color(0xFF13263A), Color(0xFF0F1D2C)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );
  }

  static LinearGradient heroGradientFor(BuildContext context) {
    if (!isDark(context)) return heroGradient;
    return const LinearGradient(
      colors: [Color(0xFF07111D), Color(0xFF0B1623), Color(0xFF102033)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );
  }

  static ThemeData _buildTheme(Brightness brightness) {
    final isDark = brightness == Brightness.dark;

    final bg = isDark ? const Color(0xFF0B1623) : surface;
    final card = isDark ? const Color(0xFF102033) : surfaceCard;
    final elevated = isDark ? const Color(0xFF16304A) : surfaceElevated;
    final border = isDark ? const Color(0xFF27415D) : divider;
    final text = isDark ? const Color(0xFFF5F9FF) : textPrimary;
    final textSub = isDark ? const Color(0xFFBFD0E3) : textSecondary;

    final base = ThemeData(useMaterial3: true, brightness: brightness);
    final txt = GoogleFonts.plusJakartaSansTextTheme(base.textTheme);

    return base.copyWith(
      scaffoldBackgroundColor: bg,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primary,
        brightness: brightness,
        primary: primary,
        secondary: accent,
        surface: card,
      ),
      textTheme: txt.copyWith(
        headlineMedium: GoogleFonts.plusJakartaSans(
          fontSize: 30,
          fontWeight: FontWeight.w700,
          color: text,
        ),
        titleLarge: GoogleFonts.plusJakartaSans(
          fontSize: 22,
          fontWeight: FontWeight.w600,
          color: text,
        ),
        titleMedium: GoogleFonts.plusJakartaSans(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: text,
        ),
        bodyMedium: GoogleFonts.plusJakartaSans(
          fontSize: 14,
          fontWeight: FontWeight.w400,
          color: textSub,
        ),
        bodySmall: GoogleFonts.plusJakartaSans(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: textSub,
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: bg,
        foregroundColor: text,
        elevation: 0,
        centerTitle: false,
        toolbarHeight: 60,
        scrolledUnderElevation: 0,
        titleTextStyle: GoogleFonts.plusJakartaSans(
          color: text,
          fontSize: 26,
          fontWeight: FontWeight.w700,
        ),
      ),
      cardTheme: CardThemeData(
        color: card,
        shape: RoundedRectangleBorder(
          borderRadius: radiusMd,
          side: BorderSide(color: border),
        ),
        elevation: 0,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isDark ? elevated : const Color(0xFFFAFCFF),
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: radiusMd,
          borderSide: BorderSide(color: border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: radiusMd,
          borderSide: BorderSide(color: border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: radiusMd,
          borderSide: const BorderSide(color: primary, width: 1.5),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: card,
        indicatorColor: primary.withValues(alpha: 0.12),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return GoogleFonts.plusJakartaSans(
            fontSize: 12,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
            color: selected ? primary : textSub,
          );
        }),
      ),
      tabBarTheme: TabBarThemeData(
        labelStyle: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600),
        unselectedLabelStyle: GoogleFonts.plusJakartaSans(
          fontWeight: FontWeight.w500,
        ),
        labelColor: primary,
        unselectedLabelColor: textSub,
        indicatorColor: primary,
      ),
      chipTheme: base.chipTheme.copyWith(
        backgroundColor: elevated,
        selectedColor: primary.withValues(alpha: 0.12),
        side: BorderSide(color: border),
        shape: RoundedRectangleBorder(borderRadius: radiusXl),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          minimumSize: const Size(double.infinity, 52),
          backgroundColor: primaryDark,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: radiusSm),
          textStyle: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600),
          elevation: 0,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          shape: RoundedRectangleBorder(borderRadius: radiusSm),
          side: BorderSide(color: border),
          foregroundColor: text,
          minimumSize: const Size(double.infinity, 52),
        ),
      ),
      dividerColor: border,
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: isDark ? const Color(0xFF111827) : const Color(0xFF111827),
        shape: RoundedRectangleBorder(borderRadius: radiusSm),
      ),
    );
  }
}
