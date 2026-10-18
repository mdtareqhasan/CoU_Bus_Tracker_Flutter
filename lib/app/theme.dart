import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

/// AppTheme — single source of truth for tokens, gradients, motion, themes.
///
/// Visual direction: polished glass + blue (indigo → vivid blue → cyan aurora)
/// applied across light + dark themes. Every screen reads from here; no
/// screen hardcodes a color, radius, or motion duration.
class AppTheme {
  AppTheme._();

  // ─── Brand aurora ────────────────────────────────────────────────────────
  static const Color indigoDeep = Color(0xFF20146B);
  static const Color blueVivid = Color(0xFF1D64C2);
  static const Color cyanBright = Color(0xFF19D0D8);
  static const Color bluePrimary = Color(0xFF2F7CE6);

  // Surfaces (light)
  static const Color bgLight = Color(0xFFF4F7FD);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceMuted = Color(0xFFF1F5FB);

  // Surfaces (dark)
  static const Color bgDark = Color(0xFF0B1220);
  static const Color surfaceDark = Color(0xFF111B2E);
  static const Color surfaceDarkElevated = Color(0xFF1A2540);

  // Text
  static const Color textPrimary = Color(0xFF0F172A);
  static const Color textSecondary = Color(0xFF475569);
  static const Color textHint = Color(0xFF94A3B8);
  static const Color textOnAurora = Colors.white;
  static const Color textOnAuroraMuted = Color(0xCCFFFFFF);

  // Semantic
  static const Color success = Color(0xFF10B981);
  static const Color successGreen = success;
  static const Color warning = Color(0xFFF59E0B);
  static const Color warningAmber = warning;
  static const Color error = Color(0xFFEF4444);
  static const Color errorRed = error;
  static const Color info = Color(0xFF3B82F6);

  // Category palette — aligned to bus_category enums (BLUE / RED / TEACHER / OFFICER / STAFF)
  static const Color catBlue = Color(0xFF2F7CE6);
  static const Color catRed = Color(0xFFEF4444);
  static const Color catTeacher = Color(0xFF7C3AED);
  static const Color catOfficer = Color(0xFF0D9488);
  static const Color catStaff = Color(0xFFF59E0B);

  /// Map a stored bus category to its token color.
  static Color colorForCategory(String? category) {
    switch (category?.toUpperCase()) {
      case 'RED':
        return catRed;
      case 'TEACHER':
        return catTeacher;
      case 'OFFICER':
        return catOfficer;
      case 'STAFF':
        return catStaff;
      case 'BLUE':
      default:
        return catBlue;
    }
  }

  // ─── Gradients (only three are allowed) ──────────────────────────────────
  static const LinearGradient auroraGradient = LinearGradient(
    colors: [indigoDeep, blueVivid, cyanBright],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient auroraHeaderGradient = LinearGradient(
    colors: [Color(0xFF1B1A6B), Color(0xFF1F5BC0), Color(0xFF19D0D8)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient glassOverlay = LinearGradient(
    colors: [Color(0x14FFFFFF), Color(0x08FFFFFF)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  /// Backwards-compatible alias — earlier code referenced `primaryGradient`.
  /// Re-routes to the canonical aurora header gradient so the visual language
  /// stays consistent across the codebase.
  static const LinearGradient primaryGradient = auroraHeaderGradient;

  static LinearGradient frostedGlass(Brightness brightness) {
    return LinearGradient(
      colors: brightness == Brightness.light
          ? [
              Colors.white.withValues(alpha: 0.92),
              Colors.white.withValues(alpha: 0.74),
            ]
          : [
              surfaceDarkElevated.withValues(alpha: 0.95),
              surfaceDark.withValues(alpha: 0.85),
            ],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );
  }

  // ─── Spacing (8-pt grid) ─────────────────────────────────────────────────
  static const double space2 = 2.0;
  static const double space4 = 4.0;
  static const double space8 = 8.0;
  static const double space12 = 12.0;
  static const double space16 = 16.0;
  static const double space20 = 20.0;
  static const double space24 = 24.0;
  static const double space32 = 32.0;
  static const double space40 = 40.0;
  static const double space48 = 48.0;
  static const double space64 = 64.0;

  // ─── Radii ───────────────────────────────────────────────────────────────
  static const double radiusXS = 4.0;
  static const double radiusSM = 8.0;
  static const double radiusMD = 12.0;
  static const double radiusLG = 16.0;
  static const double radiusXL = 24.0;
  static const double radius2XL = 32.0;
  static const double radiusPill = 999.0;

  // ─── Elevation ───────────────────────────────────────────────────────────
  static const List<BoxShadow> shadowXS = [
    BoxShadow(
      color: Color(0x10000000),
      blurRadius: 6,
      offset: Offset(0, 2),
    ),
  ];
  static const List<BoxShadow> shadowSM = [
    BoxShadow(
      color: Color(0x0F0F172A),
      blurRadius: 12,
      offset: Offset(0, 4),
    ),
  ];
  static const List<BoxShadow> shadowMD = [
    BoxShadow(
      color: Color(0x140F172A),
      blurRadius: 18,
      offset: Offset(0, 8),
    ),
  ];
  static const List<BoxShadow> shadowLG = [
    BoxShadow(
      color: Color(0x1A0F172A),
      blurRadius: 24,
      offset: Offset(0, 12),
    ),
  ];
  static const List<BoxShadow> auroraGlow = [
    BoxShadow(
      color: Color(0x4D1D64C2),
      blurRadius: 32,
      offset: Offset(0, 16),
    ),
  ];

  // Backwards-compatible alias.
  static const List<BoxShadow> softShadow = shadowXS;

  // ─── Light theme ─────────────────────────────────────────────────────────
  static ThemeData get lightTheme {
    final base = ThemeData.light(useMaterial3: true);
    final textTheme = _buildTextTheme(base.textTheme, textPrimary);

    return base.copyWith(
      brightness: Brightness.light,
      primaryColor: bluePrimary,
      scaffoldBackgroundColor: bgLight,
      colorScheme: const ColorScheme.light(
        primary: bluePrimary,
        secondary: cyanBright,
        surface: surface,
        onSurface: textPrimary,
        error: error,
        onPrimary: Colors.white,
      ),
      textTheme: textTheme,
      cardTheme: CardThemeData(
        color: surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusLG),
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        systemOverlayStyle: SystemUiOverlayStyle.light,
        titleTextStyle: TextStyle(
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.2,
        ),
        iconTheme: IconThemeData(color: Colors.white),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: surface,
        selectedItemColor: bluePrimary,
        unselectedItemColor: textHint,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),
      chipTheme: ChipThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusPill),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        side: BorderSide.none,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: bluePrimary,
          foregroundColor: Colors.white,
          elevation: 0,
          minimumSize: const Size(double.infinity, 56),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusMD),
          ),
          textStyle: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.2,
          ),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: Color(0x140F172A),
        thickness: 0.5,
        space: 1,
      ),
    );
  }

  // ─── Dark theme ──────────────────────────────────────────────────────────
  static ThemeData get darkTheme {
    final base = ThemeData.dark(useMaterial3: true);
    final textTheme = _buildTextTheme(base.textTheme, Colors.white);

    return base.copyWith(
      brightness: Brightness.dark,
      primaryColor: bluePrimary,
      scaffoldBackgroundColor: bgDark,
      colorScheme: const ColorScheme.dark(
        primary: bluePrimary,
        secondary: cyanBright,
        surface: surfaceDark,
        onSurface: Colors.white,
        error: error,
        onPrimary: Colors.white,
      ),
      textTheme: textTheme,
      cardTheme: CardThemeData(
        color: surfaceDark,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusLG),
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        systemOverlayStyle: SystemUiOverlayStyle.light,
        titleTextStyle: TextStyle(
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.2,
        ),
        iconTheme: IconThemeData(color: Colors.white),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: surfaceDark,
        selectedItemColor: cyanBright,
        unselectedItemColor: Colors.white38,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),
      chipTheme: ChipThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusPill),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        side: BorderSide.none,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: bluePrimary,
          foregroundColor: Colors.white,
          elevation: 0,
          minimumSize: const Size(double.infinity, 56),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusMD),
          ),
          textStyle: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.2,
          ),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: Color(0x1FFFFFFF),
        thickness: 0.5,
        space: 1,
      ),
    );
  }

  static TextTheme _buildTextTheme(TextTheme base, Color textColor) {
    return GoogleFonts.interTextTheme(base).copyWith(
      displayLarge: GoogleFonts.plusJakartaSans(
        fontSize: 34,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.6,
        color: textColor,
      ),
      displayMedium: GoogleFonts.plusJakartaSans(
        fontSize: 28,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.5,
        color: textColor,
      ),
      displaySmall: GoogleFonts.plusJakartaSans(
        fontSize: 24,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.4,
        color: textColor,
      ),
      headlineLarge: GoogleFonts.plusJakartaSans(
        fontSize: 24,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.4,
        color: textColor,
      ),
      headlineMedium: GoogleFonts.plusJakartaSans(
        fontSize: 20,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.3,
        color: textColor,
      ),
      headlineSmall: GoogleFonts.plusJakartaSans(
        fontSize: 18,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.2,
        color: textColor,
      ),
      titleLarge: GoogleFonts.plusJakartaSans(
        fontSize: 18,
        fontWeight: FontWeight.w700,
        color: textColor,
      ),
      titleMedium: GoogleFonts.plusJakartaSans(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: textColor,
      ),
      titleSmall: GoogleFonts.plusJakartaSans(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: textColor,
      ),
      bodyLarge: GoogleFonts.inter(
        fontSize: 15,
        fontWeight: FontWeight.w400,
        height: 1.5,
        color: textColor,
      ),
      bodyMedium: GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        height: 1.5,
        color: textColor.withValues(alpha: 0.85),
      ),
      bodySmall: GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        height: 1.4,
        color: textColor.withValues(alpha: 0.65),
      ),
      labelLarge: GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.1,
        color: textColor,
      ),
      labelMedium: GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.4,
        color: textColor,
      ),
      labelSmall: GoogleFonts.inter(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.6,
        color: textColor,
      ),
    );
  }
}

/// Motion tokens — referenced by every animation in the app.
class Motion {
  Motion._();

  static const Duration durFast = Duration(milliseconds: 180);
  static const Duration durMed = Duration(milliseconds: 320);
  static const Duration durSlow = Duration(milliseconds: 600);
  static const Duration durExtra = Duration(milliseconds: 900);
  static const int staggerStep = 60; // ms between siblings
  static const double cardPress = 0.97; // scale on tap
  static const double navPress = 0.94; // bottom-nav icon scale on tap

  // Curves
  static const Curve enter = Curves.easeOutCubic;
  static const Curve exit = Curves.easeInCubic;
  static const Curve press = Curves.easeInOut;
  static const Curve bounce = Curves.easeOutBack;
}
