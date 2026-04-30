import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // ─── Brand Colors (Restaurant Elegant Theme) ────────────────────────────────────────
  static const Color primary = Color(0xFF720D0D);      // Deep Burgundy
  static const Color primaryDark = Color(0xFF4A0808);  // Rich Noir Red
  static const Color primaryLight = Color(0xFF9E2A2A); // Velvet Red
  
  static const Color secondary = Color(0xFFC5A059);    // Antique Gold
  static const Color secondaryLight = Color(0xFFE5D1A0); // Champagne Gold
  static const Color secondaryDark = Color(0xFF9B7B3E); // Bronze Gold
  
  static const Color background = Color(0xFFFAF9F6);   // Off White / Linen
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceVariant = Color(0xFFF3F1EC); // Warm Gray
  
  static const Color textPrimary = Color(0xFF1A1A1A);  // Near Black
  static const Color textSecondary = Color(0xFF4A4A4A); // Graphite
  static const Color textLight = Color(0xFF8C8C8C);    // Silver Gray
  
  static const Color success = Color(0xFF3E5A3E);      // Forest Green
  static const Color error = Color(0xFF9B2C2C);        // Crimson
  
  static const Color divider = Color(0xFFE8E4DB);      // Pale Stone
  static const Color shadowColor = Color(0x0D000000);

  // ─── Shimmer Colors ─────────────────────────────────────────────────────────
  static const Color shimmerBase = Color(0xFFF0F0F0);
  static const Color shimmerHighlight = Color(0xFFF8F8F8);

  // ─── Gradients ───────────────────────────────────────────────────────────────
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primary, primaryDark],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient goldGradient = LinearGradient(
    colors: [secondaryLight, secondary, secondaryDark],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient surfaceGradient = LinearGradient(
    colors: [Colors.white, Color(0xFFFAFAFA)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  // ─── Theme Data ───────────────────────────────────────────────────────────────
  static ThemeData get theme => ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: primary,
          primary: primary,
          secondary: secondary,
          surface: surface,
          background: background,
          error: error,
          onPrimary: Colors.white,
          onSecondary: Colors.white,
          onSurface: textPrimary,
          onBackground: textPrimary,
        ),
        textTheme: GoogleFonts.loraTextTheme().copyWith(
          displayLarge: GoogleFonts.lora(
            fontSize: 32,
            fontWeight: FontWeight.w700,
            color: textPrimary,
            letterSpacing: -0.5,
          ),
          displayMedium: GoogleFonts.lora(
            fontSize: 28,
            fontWeight: FontWeight.w700,
            color: textPrimary,
          ),
          headlineLarge: GoogleFonts.lora(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: textPrimary,
          ),
          headlineMedium: GoogleFonts.lora(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: textPrimary,
          ),
          titleLarge: GoogleFonts.lora(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: textPrimary,
          ),
          titleMedium: GoogleFonts.lora(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: textPrimary,
          ),
          bodyLarge: GoogleFonts.lora(
            fontSize: 15,
            fontWeight: FontWeight.w400,
            color: textPrimary,
            height: 1.5,
          ),
          bodyMedium: GoogleFonts.lora(
            fontSize: 13,
            fontWeight: FontWeight.w400,
            color: textSecondary,
            height: 1.4,
          ),
          labelLarge: GoogleFonts.lora(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
        appBarTheme: AppBarTheme(
          backgroundColor: background,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          centerTitle: false,
          titleTextStyle: GoogleFonts.lora(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: textPrimary,
          ),
          iconTheme: const IconThemeData(color: textPrimary, size: 22),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: primary,
            foregroundColor: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            textStyle: GoogleFonts.lora(
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        cardTheme: CardThemeData(
          color: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          clipBehavior: Clip.antiAlias,
        ),
        scaffoldBackgroundColor: background,
        dividerTheme: const DividerThemeData(
          color: divider,
          thickness: 1,
          space: 24,
        ),
      );

  // ─── Shadow System ──────────────────────────────────────────────────────────
  static List<BoxShadow> get premiumShadow => [
        BoxShadow(
          color: Colors.black.withOpacity(0.04),
          blurRadius: 12,
          offset: const Offset(0, 4),
        ),
        BoxShadow(
          color: Colors.black.withOpacity(0.02),
          blurRadius: 2,
          offset: const Offset(0, 1),
        ),
      ];

  static List<BoxShadow> get floatingShadow => [
        BoxShadow(
          color: primary.withOpacity(0.15),
          blurRadius: 24,
          offset: const Offset(0, 8),
        ),
      ];

  static List<BoxShadow> get cardShadow => [
        BoxShadow(
          color: Colors.black.withOpacity(0.05),
          blurRadius: 15,
          offset: const Offset(0, 5),
        ),
      ];

  // ─── Animations ─────────────────────────────────────────────────────────────
  static Duration get fastAnim => const Duration(milliseconds: 200);
  static Duration get mediumAnim => const Duration(milliseconds: 400);
  static Curve get defaultCurve => Curves.easeInOutCubic;
}