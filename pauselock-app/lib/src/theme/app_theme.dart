import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static const Color primaryColor = Color(0xFFFF9900); // Tracklock orange
  static const Color secondaryColor = Color(0xFF7B2FFF);
  static const Color accentColor = Color(0xFF00D4FF);
  static const Color backgroundColor = Color(0xFF0E1018);
  static const Color surfaceColor = Color(0xFF161822);
  static const Color surfaceColorLight = Color(0xFF1C1F2E);
  static const Color surfaceColorMedium = Color(0xFF222638);
  static const Color cardColor = Color(0xFF1A1D2E);
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFF8B90A5);
  static const Color textMuted = Color(0xFF5C6078);
  static const Color successColor = Color(0xFF00FF88);
  static const Color warningColor = Color(0xFFFFB300);
  static const Color errorColor = Color(0xFFFF4455);
  static const Color borderColor = Color(0xFF2A2E3F);

  static LinearGradient get primaryGradient => const LinearGradient(
    colors: [primaryColor, secondaryColor],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static LinearGradient get backgroundGradient => const LinearGradient(
    colors: [Color(0xFF0E1018), Color(0xFF12141E)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static BoxDecoration get glassDecoration => const BoxDecoration(
    color: cardColor,
    borderRadius: BorderRadius.all(Radius.circular(10)),
  );

  static BoxDecoration get glassDecorationSmall => const BoxDecoration(
    color: surfaceColorMedium,
    borderRadius: BorderRadius.all(Radius.circular(8)),
  );

  static ThemeData get darkTheme => ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: backgroundColor,
    colorScheme: const ColorScheme.dark(
      primary: primaryColor,
      secondary: secondaryColor,
      surface: surfaceColor,
      error: errorColor,
    ),
    textTheme: GoogleFonts.interTextTheme(
      const TextTheme(
        displayLarge: TextStyle(color: textPrimary, fontWeight: FontWeight.bold),
        displayMedium: TextStyle(color: textPrimary, fontWeight: FontWeight.bold),
        displaySmall: TextStyle(color: textPrimary, fontWeight: FontWeight.bold),
        headlineLarge: TextStyle(color: textPrimary, fontWeight: FontWeight.w700),
        headlineMedium: TextStyle(color: textPrimary, fontWeight: FontWeight.w600),
        headlineSmall: TextStyle(color: textPrimary, fontWeight: FontWeight.w600),
        titleLarge: TextStyle(color: textPrimary, fontWeight: FontWeight.w600, fontSize: 18),
        titleMedium: TextStyle(color: textPrimary, fontWeight: FontWeight.w500, fontSize: 15),
        titleSmall: TextStyle(color: textSecondary, fontWeight: FontWeight.w500, fontSize: 13),
        bodyLarge: TextStyle(color: textPrimary, fontSize: 15),
        bodyMedium: TextStyle(color: textSecondary, fontSize: 13),
        bodySmall: TextStyle(color: textSecondary, fontSize: 11),
        labelLarge: TextStyle(color: textPrimary, fontWeight: FontWeight.w600, fontSize: 13),
        labelMedium: TextStyle(color: textSecondary, fontSize: 12),
        labelSmall: TextStyle(color: textMuted, fontSize: 10),
      ),
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      titleTextStyle: GoogleFonts.inter(
        color: textPrimary,
        fontSize: 18,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.5,
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        textStyle: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 13),
      ),
    ),
    cardTheme: CardThemeData(
      color: cardColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      elevation: 0,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: surfaceColorLight,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: borderColor, width: 1),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: borderColor, width: 1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: primaryColor, width: 1),
      ),
      hintStyle: const TextStyle(color: textMuted),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
    ),
    dividerTheme: const DividerThemeData(
      color: borderColor,
      thickness: 1,
      space: 1,
    ),
  );
}
