import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Color palette - Soft, natural colors
  static const Color primaryColor = Color(0xFF8EACC1); // Soft blue
  static const Color accentColor = Color(0xFFF2C4B3);  // Soft peach
  static const Color backgroundColor = Color(0xFFF8F5F2); // Warm white
  static const Color textColor = Color(0xFF4A4A4A); // Soft dark gray
  static const Color secondaryTextColor = Color(0xFF7D7D7D); // Medium gray
  static const Color cardColor = Color(0xFFFFFFFF); // White
  static const Color errorColor = Color(0xFFE57373); // Soft red
  
  // Dark theme colors
  static const Color darkPrimaryColor = Color(0xFF5D7D98); // Darker blue
  static const Color darkAccentColor = Color(0xFFD9A99E); // Darker peach
  static const Color darkBackgroundColor = Color(0xFF2D2D2D); // Dark gray
  static const Color darkTextColor = Color(0xFFE0E0E0); // Light gray
  static const Color darkSecondaryTextColor = Color(0xFFB0B0B0); // Medium light gray
  static const Color darkCardColor = Color(0xFF3D3D3D); // Medium dark gray

  // Mood colors
  static const Color joyColor = Color(0xFFFFC857); // Warm yellow
  static const Color angerColor = Color(0xFFE57373); // Soft red
  static const Color sadnessColor = Color(0xFF90CAF9); // Light blue
  static const Color pleasureColor = Color(0xFFAED581); // Soft green
  static const Color tiredColor = Color(0xFFCE93D8); // Soft purple
  static const Color anxietyColor = Color(0xFFFFD54F); // Amber

  // Text styles
  static TextStyle get _baseTextStyle => GoogleFonts.mPlus1p(
    color: textColor,
    fontWeight: FontWeight.normal,
  );

  static TextStyle get _baseDarkTextStyle => GoogleFonts.mPlus1p(
    color: darkTextColor,
    fontWeight: FontWeight.normal,
  );

  static TextStyle get handwrittenStyle => GoogleFonts.caveat(
    color: textColor,
    fontWeight: FontWeight.normal,
  );

  static TextStyle get darkHandwrittenStyle => GoogleFonts.caveat(
    color: darkTextColor,
    fontWeight: FontWeight.normal,
  );

  // Light theme
  static ThemeData get lightTheme {
    return ThemeData(
      primaryColor: primaryColor,
      colorScheme: ColorScheme.light(
        primary: primaryColor,
        secondary: accentColor,
        error: errorColor,
        background: backgroundColor,
      ),
      scaffoldBackgroundColor: backgroundColor,
      cardColor: cardColor,
      textTheme: TextTheme(
        displayLarge: _baseTextStyle.copyWith(fontSize: 26, fontWeight: FontWeight.bold),
        displayMedium: _baseTextStyle.copyWith(fontSize: 22, fontWeight: FontWeight.bold),
        displaySmall: _baseTextStyle.copyWith(fontSize: 18, fontWeight: FontWeight.bold),
        headlineMedium: _baseTextStyle.copyWith(fontSize: 16, fontWeight: FontWeight.bold),
        titleLarge: _baseTextStyle.copyWith(fontSize: 16, fontWeight: FontWeight.w600),
        bodyLarge: _baseTextStyle.copyWith(fontSize: 16),
        bodyMedium: _baseTextStyle.copyWith(fontSize: 14),
        labelLarge: _baseTextStyle.copyWith(fontSize: 14, fontWeight: FontWeight.bold),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: backgroundColor,
        elevation: 0,
        iconTheme: IconThemeData(color: textColor),
        titleTextStyle: _baseTextStyle.copyWith(
          fontSize: 20, 
          fontWeight: FontWeight.bold,
          color: textColor,
        ),
      ),
      buttonTheme: ButtonThemeData(
        buttonColor: primaryColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primaryColor,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: primaryColor.withOpacity(0.5)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: primaryColor.withOpacity(0.5)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: primaryColor),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
      cardTheme: CardThemeData(
        color: cardColor,
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }

  // Dark theme
  static ThemeData get darkTheme {
    return ThemeData(
      primaryColor: darkPrimaryColor,
      colorScheme: ColorScheme.dark(
        primary: darkPrimaryColor,
        secondary: darkAccentColor,
        error: errorColor,
        background: darkBackgroundColor,
      ),
      scaffoldBackgroundColor: darkBackgroundColor,
      cardColor: darkCardColor,
      textTheme: TextTheme(
        displayLarge: _baseDarkTextStyle.copyWith(fontSize: 26, fontWeight: FontWeight.bold),
        displayMedium: _baseDarkTextStyle.copyWith(fontSize: 22, fontWeight: FontWeight.bold),
        displaySmall: _baseDarkTextStyle.copyWith(fontSize: 18, fontWeight: FontWeight.bold),
        headlineMedium: _baseDarkTextStyle.copyWith(fontSize: 16, fontWeight: FontWeight.bold),
        titleLarge: _baseDarkTextStyle.copyWith(fontSize: 16, fontWeight: FontWeight.w600),
        bodyLarge: _baseDarkTextStyle.copyWith(fontSize: 16),
        bodyMedium: _baseDarkTextStyle.copyWith(fontSize: 14),
        labelLarge: _baseDarkTextStyle.copyWith(fontSize: 14, fontWeight: FontWeight.bold),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: darkBackgroundColor,
        elevation: 0,
        iconTheme: IconThemeData(color: darkTextColor),
        titleTextStyle: _baseDarkTextStyle.copyWith(
          fontSize: 20, 
          fontWeight: FontWeight.bold,
          color: darkTextColor,
        ),
      ),
      buttonTheme: ButtonThemeData(
        buttonColor: darkPrimaryColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: darkPrimaryColor,
          foregroundColor: Colors.white,
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: darkPrimaryColor,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: darkCardColor,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: darkPrimaryColor.withOpacity(0.5)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: darkPrimaryColor.withOpacity(0.5)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: darkPrimaryColor),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
      cardTheme: CardThemeData(
        color: darkCardColor,
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }
}
