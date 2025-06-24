import 'package:flutter/material.dart';

class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      primaryColor: Colors.blueGrey[700], // Define primaryColor for consistency
      colorScheme: ColorScheme.fromSwatch(
        primarySwatch: Colors.blueGrey,
        accentColor: Colors.teal[400], // Example accent color
        brightness: Brightness.light,
      ).copyWith(
        secondary: Colors.teal[400], // For FloatingActionButtons, etc.
      ),
      scaffoldBackgroundColor: Colors.grey[100], // Light background
      appBarTheme: AppBarTheme(
        elevation: 0.5,
        backgroundColor: Colors.blueGrey[700], // A bit darker for contrast
        titleTextStyle: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w500),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blueGrey[700],
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8.0),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: Colors.blueGrey[700],
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
        )
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8.0),
          borderSide: BorderSide(color: Colors.grey[400]!),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8.0),
          borderSide: BorderSide(color: Colors.grey[400]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8.0),
          borderSide: BorderSide(color: Colors.blueGrey[700]!, width: 2.0),
        ),
        labelStyle: TextStyle(color: Colors.blueGrey[700]),
        floatingLabelStyle: TextStyle(color: Colors.blueGrey[700]),
        hintStyle: TextStyle(color: Colors.grey[500]),
      ),
      cardTheme: CardTheme(
        elevation: 1.0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8.0),
        ),
        margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
      ),
      // Define other theme properties as needed
    );
  }

  // Optional: Define a darkTheme similarly
  // static ThemeData get darkTheme { ... }
}
