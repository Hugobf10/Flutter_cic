import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  AppTheme._();

  static const Color primary = Color(0xFF2563EB);
  static const Color primaryDark = Color(0xFF1D4ED8);
  static const Color accent = Color(0xFF7C3AED);

  static const Color success = Color(0xFF10B981);
  static const Color warning = Color(0xFFF59E0B);
  static const Color danger = Color(0xFFEF4444);
  static const Color error = danger;
  static const Color info = Color(0xFF2563EB);
  static const Color primaryLight = Color(0xFFDBEAFE);

  static const Color surface = Color(0xFFF7F8FA);
  static const Color surfaceLight = Colors.white;
  static const Color surfaceCard = Colors.white;
  static const Color surfaceElevated = Color(0xFFF1F5F9);
  static const Color textPrimary = Color(0xFF111827);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color textMuted = Color(0xFF9CA3AF);
  static const Color divider = Color(0xFFE5E7EB);

  static const LinearGradient cardGradient = LinearGradient(
    colors: [Colors.white, Colors.white],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  static const LinearGradient heroGradient = LinearGradient(
    colors: [Color(0xFFF8FAFF), Color(0xFFF8FAFF)],
  );
  static List<BoxShadow> get softShadow => const [];
  static List<BoxShadow> get glowShadow => const [];

  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF2563EB), Color(0xFF2563EB)],
  );

  static final BorderRadius radiusSm = BorderRadius.circular(10);
  static final BorderRadius radiusMd = BorderRadius.circular(14);
  static final BorderRadius radiusLg = BorderRadius.circular(18);
  static final BorderRadius radiusXl = BorderRadius.circular(9999);

  static ThemeData get lightTheme => _buildTheme(Brightness.light);
  static ThemeData get darkTheme => _buildTheme(Brightness.dark);

  static ThemeData _buildTheme(Brightness brightness) {
    final isDark = brightness == Brightness.dark;

    final bg = isDark ? const Color(0xFF0B1220) : surface;
    final card = isDark ? const Color(0xFF111827) : surfaceCard;
    final elevated = isDark ? const Color(0xFF1F2937) : surfaceElevated;
    final border = isDark ? const Color(0xFF334155) : divider;
    final text = isDark ? const Color(0xFFF9FAFB) : textPrimary;
    final textSub = isDark ? const Color(0xFFCBD5E1) : textSecondary;

    final base = ThemeData(useMaterial3: true, brightness: brightness);
    final txt = GoogleFonts.interTextTheme(base.textTheme);

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
        headlineMedium: GoogleFonts.inter(
          fontSize: 32,
          fontWeight: FontWeight.w800,
          color: text,
        ),
        titleLarge: GoogleFonts.inter(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: text,
        ),
        titleMedium: GoogleFonts.inter(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: text,
        ),
        bodyMedium: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w400,
          color: textSub,
        ),
        bodySmall: GoogleFonts.inter(
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
        toolbarHeight: 58,
        scrolledUnderElevation: 0,
        titleTextStyle: GoogleFonts.inter(
          color: text,
          fontSize: 28,
          fontWeight: FontWeight.w800,
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
        fillColor: card,
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
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
          return GoogleFonts.inter(
            fontSize: 12,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
            color: selected ? primary : textSub,
          );
        }),
      ),
      tabBarTheme: TabBarThemeData(
        labelStyle: GoogleFonts.inter(fontWeight: FontWeight.w600),
        unselectedLabelStyle: GoogleFonts.inter(fontWeight: FontWeight.w500),
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
          minimumSize: const Size(double.infinity, 48),
          backgroundColor: primary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: radiusSm),
          textStyle: GoogleFonts.inter(fontWeight: FontWeight.w600),
          elevation: 0,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          shape: RoundedRectangleBorder(borderRadius: radiusSm),
          side: BorderSide(color: border),
          foregroundColor: text,
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
