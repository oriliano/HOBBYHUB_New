// lib/theme.dart
import 'package:flutter/material.dart';

class MyTheme {
  static final ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    colorScheme: ColorScheme.fromSeed(
      seedColor: Colors.blue,
      brightness: Brightness.light,
    ),
    scaffoldBackgroundColor: Colors.grey[100],
    cardColor: Colors.white,
    textTheme: TextTheme(
      titleLarge: TextStyle(
        color: Colors.blueAccent,
        fontWeight: FontWeight.bold,
        fontSize: 18.0,
      ),
      bodyMedium: TextStyle(
        color: Colors.black87,
        fontSize: 16.0,
      ),
      titleMedium: TextStyle(
        color: Colors.grey[700],
        fontSize: 14.0,
      ),
    ),
    iconTheme: IconThemeData(
      color: Colors.blueAccent,
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: Colors.blueAccent,
      contentTextStyle: TextStyle(color: Colors.white),
    ),
  );

  static final ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: ColorScheme.fromSeed(
      seedColor: Colors.blue,
      brightness: Brightness.dark,
    ),
    scaffoldBackgroundColor: Colors.grey[900],
    cardColor: Colors.grey[800],
    textTheme: TextTheme(
      titleLarge: TextStyle(
        color: Colors.blueAccent,
        fontWeight: FontWeight.bold,
        fontSize: 18.0,
      ),
      bodyMedium: TextStyle(
        color: Colors.white70,
        fontSize: 16.0,
      ),
      titleMedium: TextStyle(
        color: Colors.grey[400],
        fontSize: 14.0,
      ),
    ),
    iconTheme: IconThemeData(
      color: Colors.blueAccent,
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: Colors.blueAccent,
      contentTextStyle: TextStyle(color: Colors.white),
    ),
  );
}
