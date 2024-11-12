import 'package:flutter/material.dart';

class AppTheme {
  static ThemeData darkTheme = ThemeData(
    brightness: Brightness.dark,
    scaffoldBackgroundColor: Colors.grey[900],
    primaryColor: Colors.blueAccent,
    colorScheme: ColorScheme.fromSwatch(
      brightness: Brightness.dark,
      primarySwatch: Colors.blueGrey,
    ).copyWith(
      secondary: Colors.tealAccent,
    ),
    textTheme: const TextTheme(
      bodyLarge: TextStyle(
        fontSize: 16,
        color: Colors.white,
      ),
      bodyMedium: TextStyle(
        fontSize: 14,
        color: Colors.white,
      ),
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.grey[850],
      elevation: 0,
      iconTheme: const IconThemeData(color: Colors.white),
      titleTextStyle: const TextStyle(color: Colors.white, fontSize: 20),
    ),
  );
}

// Usage of gradient borders in container decoration
Widget gradientBorderContainer(Widget child) {
  return Container(
    decoration: BoxDecoration(
      gradient: const LinearGradient(
        colors: [Colors.blueAccent, Colors.purpleAccent],
      ),
      borderRadius: BorderRadius.circular(12),
    ),
    child: Container(
      margin: const EdgeInsets.all(2), // space between border and child
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(10),
      ),
      child: child,
    ),
  );
}
