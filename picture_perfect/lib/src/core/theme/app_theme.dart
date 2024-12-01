import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AppTheme {
  // Gradient colors
  static const gradientStart = Colors.blueAccent; // Yellow-ish
  static const gradientEnd = Color(0xFF657FFA); // Blue

  // Create gradient
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [gradientStart, gradientEnd],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  static ThemeData darkTheme = ThemeData(
    brightness: Brightness.dark,
    scaffoldBackgroundColor: Colors.black,

    // Color Scheme
    colorScheme: ColorScheme.dark(
      surface: Colors.black,
      primary: gradientStart,
      secondary: gradientEnd,
      onPrimary: Colors.black,
      onSecondary: Colors.black,
      onSurface: Colors.white.withOpacity(0.7),
    ),

    // Text Theme
    textTheme: TextTheme(
      displayLarge: TextStyle(
        fontSize: 64,
        fontWeight: FontWeight.bold,
        color: Colors.white,
        height: 1.2,
      ),
      displayMedium: TextStyle(
        fontSize: 24,
        color: Colors.white.withOpacity(0.7),
        height: 1.5,
      ),
      titleLarge: const TextStyle(
        fontSize: 28,
        fontWeight: FontWeight.w600,
      ),
      bodyLarge: TextStyle(
        fontSize: 16,
        color: Colors.white.withOpacity(0.7),
        fontWeight: FontWeight.w500,
      ),
      bodyMedium: TextStyle(
        fontSize: 14,
        color: Colors.white.withOpacity(0.5),
      ),
    ),

    // AppBar Theme
    appBarTheme: AppBarTheme(
      systemOverlayStyle: SystemUiOverlayStyle.light,
      backgroundColor: Colors.black12,
      elevation: 0,
      titleTextStyle: const TextStyle(
        fontSize: 28,
        fontWeight: FontWeight.w600,
      ),
      iconTheme: IconThemeData(
        color: Colors.white.withOpacity(0.7),
      ),
    ),

    // Button Theme
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        padding: const EdgeInsets.symmetric(
          horizontal: 32,
          vertical: 16,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        textStyle: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w500,
        ),
      ),
    ),

    // Text Button Theme
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: Colors.white.withOpacity(0.7),
        textStyle: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
      ),
    ),

    // Input Decoration Theme
    inputDecorationTheme: InputDecorationTheme(
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(
          color: Colors.white.withOpacity(0.1),
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(
          color: Colors.white.withOpacity(0.1),
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(
          color: gradientEnd,
          width: 2,
        ),
      ),
      filled: true,
      fillColor: Colors.white.withOpacity(0.05),
      labelStyle: TextStyle(
        color: Colors.white.withOpacity(0.7),
      ),
    ),
  );

  static ThemeData lightTheme = ThemeData(
    brightness: Brightness.light,
    scaffoldBackgroundColor: Colors.white,

    // Color Scheme
    colorScheme: ColorScheme.light(
      surface: Colors.white,
      primary: gradientStart,
      secondary: gradientEnd,
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onSurface: Colors.black.withOpacity(0.7),
    ),

    // Text Theme
    textTheme: TextTheme(
      displayLarge: TextStyle(
        fontSize: 64,
        fontWeight: FontWeight.bold,
        color: Colors.black,
        height: 1.2,
      ),
      displayMedium: TextStyle(
        fontSize: 24,
        color: Colors.black.withOpacity(0.7),
        height: 1.5,
      ),
      titleLarge: const TextStyle(
        fontSize: 28,
        fontWeight: FontWeight.w600,
      ),
      bodyLarge: TextStyle(
        fontSize: 16,
        color: Colors.black.withOpacity(0.7),
        fontWeight: FontWeight.w500,
      ),
      bodyMedium: TextStyle(
        fontSize: 14,
        color: Colors.black.withOpacity(0.5),
      ),
    ),

    // AppBar Theme
    appBarTheme: AppBarTheme(
      systemOverlayStyle: SystemUiOverlayStyle.dark,
      backgroundColor: Colors.transparent,
      elevation: 0,
      titleTextStyle: const TextStyle(
          fontSize: 28, fontWeight: FontWeight.w600, color: Colors.black),
      iconTheme: IconThemeData(
        color: Colors.black.withOpacity(0.7),
      ),
    ),

    // Button Theme
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(
          horizontal: 32,
          vertical: 16,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        textStyle: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w500,
        ),
      ),
    ),

    // Text Button Theme
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: Colors.black.withOpacity(0.7),
        textStyle: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
      ),
    ),

    // Input Decoration Theme
    inputDecorationTheme: InputDecorationTheme(
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(
          color: Colors.black.withOpacity(0.1),
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(
          color: Colors.black.withOpacity(0.1),
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(
          color: gradientEnd,
          width: 2,
        ),
      ),
      filled: true,
      fillColor: Colors.black.withOpacity(0.05),
      labelStyle: TextStyle(
        color: Colors.black.withOpacity(0.7),
      ),
    ),
  );
}

// Utility functions for common styling patterns
class AppStyles {
  // Gradient Text Painter
  static TextPainter gradientTextPainter({
    required String text,
    required TextStyle style,
    required Gradient gradient,
    required double width,
  }) {
    final TextPainter textPainter = TextPainter(
      text: TextSpan(
        text: text,
        style: style,
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout(maxWidth: width);
    return textPainter;
  }

  // Gradient Border Decoration
  static BoxDecoration gradientBorderDecoration({
    double borderRadius = 8,
    double borderWidth = 1,
  }) {
    return BoxDecoration(
      borderRadius: BorderRadius.circular(borderRadius),
      gradient: AppTheme.primaryGradient,
      border: Border.all(
        color: Colors.transparent,
        width: borderWidth,
      ),
    );
  }

  // Glassmorphic Container Decoration
  static BoxDecoration glassDecoration({
    double borderRadius = 8,
    double opacity = 0.1,
  }) {
    return BoxDecoration(
      color: Colors.white.withOpacity(opacity),
      borderRadius: BorderRadius.circular(borderRadius),
      border: Border.all(
        color: Colors.white.withOpacity(0.1),
      ),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.1),
          blurRadius: 10,
          spreadRadius: 0,
        ),
      ],
    );
  }

  // Gradient Background Widget
  static Widget gradientBackground({required Widget child}) {
    return Stack(
      children: [
        Positioned.fill(
          child: Container(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                colors: [
                  AppTheme.gradientEnd.withOpacity(0.1),
                  AppTheme.gradientStart.withOpacity(0.05),
                ],
                center: Alignment.topRight,
                radius: 1.5,
              ),
            ),
          ),
        ),
        child,
      ],
    );
  }
}

// Extension for easy gradient text
extension GradientText on Text {
  Widget gradient({double? width}) {
    return ShaderMask(
      shaderCallback: (bounds) => AppTheme.primaryGradient.createShader(bounds),
      child: this,
    );
  }
}
