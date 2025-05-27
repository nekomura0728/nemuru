import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Color palette - Improved contrast ratios for accessibility
  static const Color primaryColor = Color(0xFF6B8CA7); // Darker blue for better contrast
  static const Color accentColor = Color(0xFFE8A892);  // Darker peach for better contrast  
  static const Color backgroundColor = Color(0xFFF8F5F2); // Warm white
  static const Color textColor = Color(0xFF2D2D2D); // Darker text for better contrast (4.5:1)
  static const Color secondaryTextColor = Color(0xFF5A5A5A); // Darker medium gray (3:1)
  static const Color cardColor = Color(0xFFFFFFFF); // White
  static const Color errorColor = Color(0xFFD32F2F); // Darker red for better contrast
  
  // Dark theme colors - Improved contrast ratios
  static const Color darkPrimaryColor = Color(0xFF7B9DB8); // Lighter blue for dark theme
  static const Color darkAccentColor = Color(0xFFE8B19E); // Lighter peach for dark theme
  static const Color darkBackgroundColor = Color(0xFF1A1A1A); // Darker background
  static const Color darkTextColor = Color(0xFFEEEEEE); // Lighter text for better contrast
  static const Color darkSecondaryTextColor = Color(0xFFCCCCCC); // Lighter medium gray
  static const Color darkCardColor = Color(0xFF2D2D2D); // Lighter card color

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

  // Light theme with font scaling support
  static ThemeData lightThemeWithScale({double fontScale = 1.0}) {
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
        displayLarge: _baseTextStyle.copyWith(fontSize: 26 * fontScale, fontWeight: FontWeight.bold),
        displayMedium: _baseTextStyle.copyWith(fontSize: 22 * fontScale, fontWeight: FontWeight.bold),
        displaySmall: _baseTextStyle.copyWith(fontSize: 18 * fontScale, fontWeight: FontWeight.bold),
        headlineMedium: _baseTextStyle.copyWith(fontSize: 16 * fontScale, fontWeight: FontWeight.bold),
        titleLarge: _baseTextStyle.copyWith(fontSize: 16 * fontScale, fontWeight: FontWeight.w600),
        bodyLarge: _baseTextStyle.copyWith(fontSize: 16 * fontScale),
        bodyMedium: _baseTextStyle.copyWith(fontSize: 14 * fontScale),
        labelLarge: _baseTextStyle.copyWith(fontSize: 14 * fontScale, fontWeight: FontWeight.bold),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: backgroundColor,
        elevation: 0,
        iconTheme: IconThemeData(color: textColor),
        titleTextStyle: _baseTextStyle.copyWith(
          fontSize: 20 * fontScale, 
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

  // Dark theme with font scaling support
  static ThemeData darkThemeWithScale({double fontScale = 1.0}) {
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
        displayLarge: _baseDarkTextStyle.copyWith(fontSize: 26 * fontScale, fontWeight: FontWeight.bold),
        displayMedium: _baseDarkTextStyle.copyWith(fontSize: 22 * fontScale, fontWeight: FontWeight.bold),
        displaySmall: _baseDarkTextStyle.copyWith(fontSize: 18 * fontScale, fontWeight: FontWeight.bold),
        headlineMedium: _baseDarkTextStyle.copyWith(fontSize: 16 * fontScale, fontWeight: FontWeight.bold),
        titleLarge: _baseDarkTextStyle.copyWith(fontSize: 16 * fontScale, fontWeight: FontWeight.w600),
        bodyLarge: _baseDarkTextStyle.copyWith(fontSize: 16 * fontScale),
        bodyMedium: _baseDarkTextStyle.copyWith(fontSize: 14 * fontScale),
        labelLarge: _baseDarkTextStyle.copyWith(fontSize: 14 * fontScale, fontWeight: FontWeight.bold),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: darkBackgroundColor,
        elevation: 0,
        iconTheme: IconThemeData(color: darkTextColor),
        titleTextStyle: _baseDarkTextStyle.copyWith(
          fontSize: 20 * fontScale, 
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

  // Convenience getters for backward compatibility
  static ThemeData get lightTheme => lightThemeWithScale();
  static ThemeData get darkTheme => darkThemeWithScale();
}
