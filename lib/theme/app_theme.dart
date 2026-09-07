// THEME LOCK: light — source: domain signal (factory floor, outdoor contrast)
// Scaffold.backgroundColor = AppTheme.backgroundLight — ALL screens
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Primary palette
  static const Color primary = Color(0xFF1A237E);
  static const Color primaryLight = Color(0xFF3949AB);
  static const Color primaryContainer = Color(0xFFE8EAF6);
  static const Color secondary = Color(0xFFFF8F00);
  static const Color secondaryContainer = Color(0xFFFFF8E1);

  // Semantic colors
  static const Color success = Color(0xFF2E7D32);
  static const Color successContainer = Color(0xFFE8F5E9);
  static const Color warning = Color(0xFFFF8F00);
  static const Color warningContainer = Color(0xFFFFF8E1);
  static const Color error = Color(0xFFC62828);
  static const Color errorContainer = Color(0xFFFFEBEE);
  static const Color info = Color(0xFF1565C0);

  // Light surfaces
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color surfaceVariantLight = Color(0xFFF5F6FA);
  static const Color backgroundLight = Color(0xFFEEF0F8);
  static const Color outlineLight = Color(0xFFBDBDBD);
  static const Color outlineVariantLight = Color(0xFFE0E0E0);
  static const Color mutedText = Color(0xFF757575);
  static const Color onSurfaceLight = Color(0xFF1A1A2E);

  // Dark surfaces (required even for light-primary app)
  static const Color surfaceDark = Color(0xFF1E1E2E);
  static const Color backgroundDark = Color(0xFF12121E);

  static ThemeData get lightTheme => ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.light(
      primary: primary,
      onPrimary: Colors.white,
      primaryContainer: primaryContainer,
      onPrimaryContainer: Color(0xFF1A237E),
      secondary: secondary,
      onSecondary: Colors.white,
      secondaryContainer: secondaryContainer,
      onSecondaryContainer: Color(0xFF6D4C00),
      surface: surfaceLight,
      onSurface: onSurfaceLight,
      surfaceContainerHighest: surfaceVariantLight,
      onSurfaceVariant: Color(0xFF424242),
      error: error,
      onError: Colors.white,
      errorContainer: errorContainer,
      outline: outlineLight,
      outlineVariant: outlineVariantLight,
    ),
    scaffoldBackgroundColor: backgroundLight,
    textTheme: GoogleFonts.ibmPlexSansTextTheme(
      TextTheme(
        displayLarge: TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.5,
        ),
        displayMedium: TextStyle(fontSize: 28, fontWeight: FontWeight.w600),
        displaySmall: TextStyle(fontSize: 24, fontWeight: FontWeight.w600),
        headlineLarge: TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
        headlineMedium: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
        headlineSmall: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        titleLarge: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        titleMedium: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
        titleSmall: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
        bodyLarge: TextStyle(fontSize: 14, fontWeight: FontWeight.w400),
        bodyMedium: TextStyle(fontSize: 13, fontWeight: FontWeight.w400),
        bodySmall: TextStyle(fontSize: 12, fontWeight: FontWeight.w400),
        labelLarge: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.2,
        ),
        labelMedium: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.2,
        ),
        labelSmall: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.3,
        ),
      ),
    ),
    appBarTheme: AppBarThemeData(
      backgroundColor: surfaceLight,
      foregroundColor: onSurfaceLight,
      elevation: 0,
      scrolledUnderElevation: 2,
      shadowColor: Colors.black.withAlpha(20),
      titleTextStyle: GoogleFonts.ibmPlexSans(
        fontSize: 18,
        fontWeight: FontWeight.w700,
        color: onSurfaceLight,
      ),
    ),
    cardTheme: CardThemeData(
      color: surfaceLight,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: EdgeInsets.zero,
    ),
    chipTheme: ChipThemeData(
      backgroundColor: surfaceVariantLight,
      selectedColor: primaryContainer,
      labelStyle: GoogleFonts.ibmPlexSans(
        fontSize: 12,
        fontWeight: FontWeight.w500,
      ),
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    ),
    inputDecorationTheme: InputDecorationThemeData(
      filled: true,
      fillColor: surfaceVariantLight,
      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: outlineVariantLight, width: 1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: primary, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: error, width: 1),
      ),
      labelStyle: GoogleFonts.ibmPlexSans(fontSize: 13, color: mutedText),
      hintStyle: GoogleFonts.ibmPlexSans(fontSize: 13, color: mutedText),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primary,
        foregroundColor: Colors.white,
        minimumSize: Size(double.infinity, 52),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: GoogleFonts.ibmPlexSans(
          fontSize: 15,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: primary,
      foregroundColor: Colors.white,
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: surfaceLight,
      indicatorColor: primaryContainer,
      labelTextStyle: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return GoogleFonts.ibmPlexSans(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: primary,
          );
        }
        return GoogleFonts.ibmPlexSans(
          fontSize: 11,
          fontWeight: FontWeight.w400,
          color: mutedText,
        );
      }),
      iconTheme: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return IconThemeData(color: primary, size: 22);
        }
        return IconThemeData(color: mutedText, size: 22);
      }),
      height: 64,
      elevation: 4,
      shadowColor: Colors.black.withAlpha(26),
    ),
    dividerTheme: DividerThemeData(
      color: outlineVariantLight,
      thickness: 1,
      space: 0,
    ),
    progressIndicatorTheme: ProgressIndicatorThemeData(
      color: primary,
      linearTrackColor: primaryContainer,
    ),
  );

  static ThemeData get darkTheme => ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.dark(
      primary: Color(0xFF7986CB),
      onPrimary: Colors.white,
      primaryContainer: Color(0xFF1A237E),
      onPrimaryContainer: Color(0xFFE8EAF6),
      secondary: Color(0xFFFFB74D),
      onSecondary: Color(0xFF3E2000),
      surface: surfaceDark,
      onSurface: Color(0xFFE6E6F0),
      surfaceContainerHighest: Color(0xFF2A2A3E),
      onSurfaceVariant: Color(0xFFB0B0C8),
      error: Color(0xFFEF9A9A),
      onError: Color(0xFF4A0000),
      outline: Color(0xFF4A4A6A),
      outlineVariant: Color(0xFF2E2E4E),
    ),
    scaffoldBackgroundColor: backgroundDark,
    textTheme: GoogleFonts.ibmPlexSansTextTheme(
      TextTheme(
        bodyLarge: TextStyle(color: Color(0xFFE6E6F0)),
        bodyMedium: TextStyle(color: Color(0xFFE6E6F0)),
      ),
    ),
  );
}
