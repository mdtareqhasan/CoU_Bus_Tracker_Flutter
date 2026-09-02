import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Colors - Slightly Darkened Light Blue with richer gradient
  static const Color primaryBlue = Color(0xFF3886D8);
  static const Color secondaryBlue = Color(0xFF5BA4FB);
  static const Color primaryDark = Color(0xFF2C6BB1);
  static const Color accentBlue = Color(0xFFE1EBFD);

  static const Color backgroundLight = Color(0xFFF6F9FE);
  static const Color backgroundDark = Color(0xFF0F172A);

  static const Color surfaceLight = Colors.white;
  static const Color surfaceDark = Color(0xFF1E293B);

  static const Color textPrimary = Color(0xFF1E293B);
  static const Color textSecondary = Color(0xFF64748B);
  static const Color textHint = Color(0xFF94A3B8);

  static const Color success = Color(0xFF10B981);
  static const Color successGreen = success;
  static const Color warning = Color(0xFFF59E0B);
  static const Color warningAmber = warning;
  static const Color error = Color(0xFFEF4444);
  static const Color errorRed = error;

  // Spacing Scale
  static const double space4 = 4.0;
  static const double space8 = 8.0;
  static const double space12 = 12.0;
  static const double space16 = 16.0;
  static const double space24 = 24.0;
  static const double space32 = 32.0;
  static const double space40 = 40.0;
  static const double space48 = 48.0;
  static const double space64 = 64.0;

  // Border Radius
  static const double radiusSmall = 8.0;
  static const double radiusMedium = 12.0;
  static const double radiusLarge = 16.0;
  static const double radiusExtraLarge = 32.0;

  // Gradients - Enhanced for more depth (Inspired by requested style)
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [
      Color(0xFF20146B), // Deep Indigo
      Color(0xFF1D64C2), // Vibrant Blue
      Color(0xFF19D0D8), // Bright Cyan
    ],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static LinearGradient glassGradient(Brightness brightness) {
    return LinearGradient(
      colors: brightness == Brightness.light
          ? [Colors.white.withOpacity(0.8), Colors.white.withOpacity(0.4)]
          : [surfaceDark.withOpacity(0.8), surfaceDark.withOpacity(0.4)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );
  }

  // Shadow - Soft
  static List<BoxShadow> softShadow = [
    BoxShadow(
      color: Colors.black.withOpacity(0.06),
      blurRadius: 10,
      offset: const Offset(0, 4),
    ),
  ];

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      primaryColor: primaryBlue,
      scaffoldBackgroundColor: backgroundLight,
      colorScheme: const ColorScheme.light(
        primary: primaryBlue,
        secondary: secondaryBlue,
        surface: surfaceLight,
        onSurface: textPrimary,
        error: error,
      ),
      textTheme: GoogleFonts.interTextTheme().copyWith(
        headlineLarge: GoogleFonts.plusJakartaSans(
          fontSize: 28,
          fontWeight: FontWeight.bold,
          letterSpacing: -0.5,
          color: textPrimary,
        ),
        headlineMedium: GoogleFonts.plusJakartaSans(
          fontSize: 22,
          fontWeight: FontWeight.bold,
          letterSpacing: -0.5,
          color: textPrimary,
        ),
        titleLarge: GoogleFonts.plusJakartaSans(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: textPrimary,
        ),
        titleMedium: GoogleFonts.plusJakartaSans(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: textPrimary,
        ),
        bodyLarge: GoogleFonts.inter(fontSize: 15, color: textPrimary),
        bodyMedium: GoogleFonts.inter(fontSize: 13, color: textSecondary),
        bodySmall: GoogleFonts.inter(fontSize: 11, color: textHint),
      ),
      cardTheme: CardThemeData(
        color: surfaceLight,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusLarge),
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
          fontWeight: FontWeight.bold,
        ),
        iconTheme: IconThemeData(color: Colors.white),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Colors.white,
        selectedItemColor: primaryBlue,
        unselectedItemColor: textHint,
        type: BottomNavigationBarType.fixed,
        elevation: 15,
      ),
      chipTheme: ChipThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusMedium),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryBlue,
          foregroundColor: Colors.white,
          elevation: 0,
          minimumSize: const Size(double.infinity, 56),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusMedium),
          ),
          textStyle: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      primaryColor: primaryBlue,
      scaffoldBackgroundColor: backgroundDark,
      colorScheme: const ColorScheme.dark(
        primary: primaryBlue,
        secondary: secondaryBlue,
        surface: surfaceDark,
        onSurface: Colors.white,
        error: error,
      ),
      textTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme)
          .copyWith(
            headlineLarge: GoogleFonts.plusJakartaSans(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            headlineMedium: GoogleFonts.plusJakartaSans(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            titleLarge: GoogleFonts.plusJakartaSans(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
            titleMedium: GoogleFonts.plusJakartaSans(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
            bodyLarge: GoogleFonts.inter(
              fontSize: 15,
              color: Colors.white.withOpacity(0.9),
            ),
            bodyMedium: GoogleFonts.inter(
              fontSize: 13,
              color: Colors.white.withOpacity(0.7),
            ),
            bodySmall: GoogleFonts.inter(
              fontSize: 11,
              color: Colors.white.withOpacity(0.5),
            ),
          ),
      cardTheme: CardThemeData(
        color: surfaceDark,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusLarge),
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: surfaceDark,
        elevation: 0,
        centerTitle: true,
        systemOverlayStyle: SystemUiOverlayStyle.light,
        titleTextStyle: TextStyle(
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
        iconTheme: IconThemeData(color: Colors.white),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: surfaceDark,
        selectedItemColor: primaryBlue,
        unselectedItemColor: Colors.white24,
        type: BottomNavigationBarType.fixed,
        elevation: 15,
      ),
    );
  }
}
