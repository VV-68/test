import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Brand Colors
  static const Color primaryCoral = Color(0xFFFF6B4A);
  static const Color secondaryPink = Color(0xFFFF4B72);
  static Color bgObsidian = const Color(0xFF121214);
  static Color cardObsidian = const Color(0xFF1E1E22);
  static Color cardObsidianLight = const Color(0xFF28282E);
  static Color textWhite = const Color(0xFFFFFFFF);
  static Color textGray = const Color(0xFF8D8D99);
  static Color borderGray = const Color(0xFF2E2E34);

  // Status Colors
  static const Color likeGreen = Color(0xFF2EE59D);
  static const Color nopeRed = Color(0xFFFF4949);
  static const Color starBlue = Color(0xFF4FA7FF);

  // Gradient definitions
  static const LinearGradient brandGradient = LinearGradient(
    colors: [primaryCoral, secondaryPink],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient cardGlowGradient = LinearGradient(
    colors: [Color(0x33FF6B4A), Color(0x33FF4B72)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static void setThemeMode(bool isDark) {
    if (isDark) {
      bgObsidian = const Color(0xFF121214);
      cardObsidian = const Color(0xFF1E1E22);
      cardObsidianLight = const Color(0xFF28282E);
      textWhite = const Color(0xFFFFFFFF);
      textGray = const Color(0xFF8D8D99);
      borderGray = const Color(0xFF2E2E34);
    } else {
      bgObsidian = const Color(0xFFF5F5F7);
      cardObsidian = const Color(0xFFFFFFFF);
      cardObsidianLight = const Color(0xFFEBEBEF);
      textWhite = const Color(0xFF1C1C1E);
      textGray = const Color(0xFF7C7C8A);
      borderGray = const Color(0xFFE2E2E6);
    }
  }

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: const Color(0xFFF5F5F7),
      colorScheme: const ColorScheme.light(
        primary: primaryCoral,
        secondary: secondaryPink,
        background: Color(0xFFF5F5F7),
        surface: Colors.white,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onBackground: Color(0xFF1C1C1E),
        onSurface: Color(0xFF1C1C1E),
      ),
      textTheme: GoogleFonts.outfitTextTheme(
        ThemeData.light().textTheme.copyWith(
              headlineLarge: const TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.w800,
                color: Color(0xFF1C1C1E),
                letterSpacing: -0.5,
              ),
              headlineMedium: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1C1C1E),
                letterSpacing: -0.5,
              ),
              titleLarge: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1C1C1E),
              ),
              bodyLarge: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.normal,
                color: Color(0xFF1C1C1E),
              ),
              bodyMedium: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.normal,
                color: Color(0xFF7C7C8A),
              ),
            ),
      ),
      sliderTheme: const SliderThemeData(
        activeTrackColor: primaryCoral,
        inactiveTrackColor: Color(0xFFE2E2E6),
        thumbColor: primaryCoral,
        overlayColor: Color(0x33FF6B4A),
        valueIndicatorColor: Color(0xFFEBEBEF),
        valueIndicatorTextStyle: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        showValueIndicator: ShowValueIndicator.always,
      ),
      cardTheme: CardThemeData(
        color: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: Color(0xFFE2E2E6), width: 1),
        ),
        elevation: 2,
        shadowColor: Colors.black.withOpacity(0.05),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        hintStyle: const TextStyle(color: Color(0xFF7C7C8A), fontSize: 15),
        labelStyle: const TextStyle(color: primaryCoral),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFFE2E2E6), width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: primaryCoral, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: nopeRed, width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: nopeRed, width: 2.0),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          foregroundColor: Colors.white,
          backgroundColor: primaryCoral,
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: const Color(0xFF121214),
      colorScheme: ColorScheme.dark(
        primary: primaryCoral,
        secondary: secondaryPink,
        background: const Color(0xFF121214),
        surface: cardObsidian,
        onPrimary: textWhite,
        onSecondary: textWhite,
        onBackground: textWhite,
        onSurface: textWhite,
      ),
      textTheme: GoogleFonts.outfitTextTheme(
        ThemeData.dark().textTheme.copyWith(
              headlineLarge: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.w800,
                color: textWhite,
                letterSpacing: -0.5,
              ),
              headlineMedium: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: textWhite,
                letterSpacing: -0.5,
              ),
              titleLarge: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: textWhite,
              ),
              bodyLarge: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.normal,
                color: textWhite,
              ),
              bodyMedium: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.normal,
                color: textGray,
              ),
            ),
      ),
      sliderTheme: SliderThemeData(
        activeTrackColor: primaryCoral,
        inactiveTrackColor: borderGray,
        thumbColor: textWhite,
        overlayColor: primaryCoral.withOpacity(0.2),
        valueIndicatorColor: cardObsidianLight,
        valueIndicatorTextStyle: TextStyle(color: textWhite, fontWeight: FontWeight.bold),
        showValueIndicator: ShowValueIndicator.always,
      ),
      cardTheme: CardThemeData(
        color: cardObsidian,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: borderGray, width: 1),
        ),
        elevation: 0,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: cardObsidian,
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        hintStyle: TextStyle(color: textGray, fontSize: 15),
        labelStyle: const TextStyle(color: primaryCoral),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: borderGray, width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: primaryCoral, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: nopeRed, width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: nopeRed, width: 2.0),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          foregroundColor: textWhite,
          backgroundColor: primaryCoral,
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }
}
