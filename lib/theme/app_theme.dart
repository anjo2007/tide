import 'package:flutter/material.dart';

class AppTheme {
  // Theme Colors
  static const Color creamBg = Color(0xFFF9F7F4);        // Soft warm cream background
  static const Color creamCard = Color(0xFFFFFFFF);      // Pure white card background
  static const Color textDark = Color(0xFF2C3437);       // Deep slate/charcoal for main text
  static const Color textMuted = Color(0xFF7A868A);      // Muted slate grey for secondary text
  
  // Accents
  static const Color goldAccent = Color(0xFFC5A059);     // Premium warm gold
  static const Color goldLight = Color(0xFFF4EDE2);      // Very light gold/beige highlights
  static const Color bronze = Color(0xFFA67C52);         // Deeper accent gold
  
  // Statuses
  static const Color successSage = Color(0xFF8E9F8E);    // Soft muted green for completed tasks
  static const Color dangerRose = Color(0xFFD69E9E);     // Soft red for high priority / overdue
  static const Color infoBlue = Color(0xFF8E9DB0);       // Soft muted blue for info/links
  
  // Shadow
  static List<BoxShadow> get premiumShadow => [
    BoxShadow(
      color: Colors.black.withOpacity(0.04),
      blurRadius: 24,
      offset: const Offset(0, 8),
    ),
    BoxShadow(
      color: const Color(0xFFC5A059).withOpacity(0.02),
      blurRadius: 12,
      offset: const Offset(0, 4),
    ),
  ];

  static List<BoxShadow> get buttonShadow => [
    BoxShadow(
      color: const Color(0xFFC5A059).withOpacity(0.15),
      blurRadius: 16,
      offset: const Offset(0, 6),
    ),
  ];

  // Material Light Theme
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      primaryColor: goldAccent,
      scaffoldBackgroundColor: creamBg,
      colorScheme: const ColorScheme.light(
        primary: goldAccent,
        secondary: bronze,
        surface: creamCard,
        error: dangerRose,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: textDark,
      ),
      cardTheme: CardThemeData(
        color: creamCard,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(
            color: const Color(0xFFEFECE6),
            width: 1.5,
          ),
        ),
      ),
      
      // Input Decoration Theme
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFFFBF9F6),
        labelStyle: const TextStyle(color: textMuted, fontSize: 14),
        hintStyle: const TextStyle(color: textMuted, fontSize: 14),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFFEBE6DD), width: 1.5),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFFEBE6DD), width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: goldAccent, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: dangerRose, width: 1.5),
        ),
      ),
      
      // Button Themes
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: goldAccent,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
      ),
      
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: textDark,
          side: const BorderSide(color: Color(0xFFDCD5CA), width: 1.5),
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      
      // Floating Action Button Theme
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: goldAccent,
        foregroundColor: Colors.white,
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
        ),
      ),
      
      // Text Theme
      textTheme: const TextTheme(
        displayLarge: TextStyle(color: textDark, fontSize: 32, fontWeight: FontWeight.w800, letterSpacing: -0.5),
        displayMedium: TextStyle(color: textDark, fontSize: 28, fontWeight: FontWeight.w700, letterSpacing: -0.5),
        titleLarge: TextStyle(color: textDark, fontSize: 20, fontWeight: FontWeight.w600, letterSpacing: -0.2),
        titleMedium: TextStyle(color: textDark, fontSize: 16, fontWeight: FontWeight.w600),
        bodyLarge: TextStyle(color: textDark, fontSize: 16, height: 1.5),
        bodyMedium: TextStyle(color: textMuted, fontSize: 14, height: 1.5),
        labelLarge: TextStyle(color: textDark, fontSize: 14, fontWeight: FontWeight.w600),
      ),
      
      // App Bar Theme
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: textDark),
        titleTextStyle: TextStyle(
          color: textDark,
          fontSize: 20,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.5,
        ),
      ),
      
      // Date Picker Theme
      datePickerTheme: DatePickerThemeData(
        backgroundColor: creamBg,
        headerBackgroundColor: goldAccent,
        headerForegroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      ),
    );
  }
}
