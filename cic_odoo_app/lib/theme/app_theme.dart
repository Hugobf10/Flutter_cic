import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  AppTheme._();

  static const Color primary = Color(0xFF5B46F4);
  static const Color primaryDark = Color(0xFF4A37D4);
  static const Color accent = Color(0xFF00A3FF);

  static const Color success = Color(0xFF10B981);
  static const Color warning = Color(0xFFF59E0B);
  static const Color danger = Color(0xFFEF4444);
  static const Color info = Color(0xFF3B82F6);
  static const Color primaryLight = Color(0xFFB7AEFF);

  // Backward-compat aliases for existing screens/widgets
  static const Color surface = Color(0xFFF7F8FC);
  static const Color surfaceLight = Colors.white;
  static const Color surfaceCard = Colors.white;
  static const Color surfaceElevated = Color(0xFFF0F3FF);
  static const Color textPrimary = Color(0xFF111827);
  static const Color textSecondary = Color(0xFF5F6B85);
  static const Color textMuted = Color(0xFF8892AC);
  static const Color divider = Color(0xFFE2E8F5);
  static const LinearGradient cardGradient = LinearGradient(
    colors: [Colors.white, Color(0xFFF5F7FF)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  static const LinearGradient heroGradient = LinearGradient(
    colors: [Color(0xFF6D5EF9), Color(0xFF4A37D4), Color(0xFF00A3FF)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  static List<BoxShadow> get softShadow => const [
        BoxShadow(
          color: Color(0x140B1020),
          blurRadius: 16,
          offset: Offset(0, 6),
        ),
      ];
  static List<BoxShadow> get glowShadow => const [
        BoxShadow(
          color: Color(0x335B46F4),
          blurRadius: 24,
          offset: Offset(0, 8),
        ),
      ];

  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF6D5EF9), Color(0xFF4A37D4)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static final BorderRadius radiusSm = BorderRadius.circular(8);
  static final BorderRadius radiusMd = BorderRadius.circular(12);
  static final BorderRadius radiusLg = BorderRadius.circular(18);
  static final BorderRadius radiusXl = BorderRadius.circular(9999);

  static ThemeData get lightTheme => _buildTheme(Brightness.light);
  static ThemeData get darkTheme => _buildTheme(Brightness.dark);

  static ThemeData _buildTheme(Brightness brightness) {
    final isDark = brightness == Brightness.dark;

    final bg = isDark ? const Color(0xFF0B1020) : const Color(0xFFF7F8FC);
    final surface = isDark ? const Color(0xFF121933) : Colors.white;
    final elevated = isDark ? const Color(0xFF182241) : const Color(0xFFF0F3FF);
    final border = isDark ? const Color(0xFF2A355C) : const Color(0xFFE2E8F5);
    final textPrimary = isDark ? const Color(0xFFF5F7FF) : const Color(0xFF111827);
    final textSecondary = isDark ? const Color(0xFFA8B1D1) : const Color(0xFF5F6B85);

    final base = ThemeData(useMaterial3: true, brightness: brightness);
    final txt = GoogleFonts.interTextTheme(base.textTheme);

    return base.copyWith(
      scaffoldBackgroundColor: bg,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primary,
        brightness: brightness,
        primary: primary,
        secondary: accent,
        surface: surface,
      ),
      textTheme: txt.copyWith(
        headlineMedium: GoogleFonts.spaceGrotesk(
          fontSize: 30,
          fontWeight: FontWeight.w700,
          color: textPrimary,
        ),
        titleLarge: GoogleFonts.spaceGrotesk(
          fontSize: 22,
          fontWeight: FontWeight.w700,
          color: textPrimary,
        ),
        bodyMedium: GoogleFonts.inter(color: textSecondary, fontSize: 14),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: bg,
        foregroundColor: textPrimary,
        elevation: 0,
        centerTitle: false,
        toolbarHeight: 60,
        scrolledUnderElevation: 0,
        titleTextStyle: GoogleFonts.spaceGrotesk(
          color: textPrimary,
          fontSize: 24,
          fontWeight: FontWeight.w700,
        ),
      ),
      cardTheme: CardThemeData(
        color: surface,
        shape: RoundedRectangleBorder(
          borderRadius: radiusMd,
          side: BorderSide(color: border),
        ),
        elevation: 0,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surface,
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
          borderSide: const BorderSide(color: primary, width: 1.8),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: surface,
        indicatorColor: primary.withValues(alpha: 0.14),
      ),
      tabBarTheme: TabBarThemeData(
        labelStyle: GoogleFonts.inter(fontWeight: FontWeight.w700),
        unselectedLabelStyle: GoogleFonts.inter(fontWeight: FontWeight.w500),
        labelColor: primary,
        unselectedLabelColor: textSecondary,
        indicatorColor: primary,
      ),
      chipTheme: base.chipTheme.copyWith(
        backgroundColor: elevated,
        selectedColor: primary.withValues(alpha: 0.16),
        side: BorderSide(color: border),
        shape: RoundedRectangleBorder(borderRadius: radiusXl),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          minimumSize: const Size(double.infinity, 46),
          backgroundColor: primary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: radiusSm),
          textStyle: GoogleFonts.inter(fontWeight: FontWeight.w700),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          shape: RoundedRectangleBorder(borderRadius: radiusSm),
          side: BorderSide(color: border),
          foregroundColor: textPrimary,
        ),
      ),
      dividerColor: border,
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: isDark ? const Color(0xFF182241) : const Color(0xFF1F2937),
        shape: RoundedRectangleBorder(borderRadius: radiusSm),
      ),
    );
  }
}
