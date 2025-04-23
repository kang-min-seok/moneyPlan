import 'package:flutter/material.dart';

class ThemeCustom {
  static ThemeData lightTheme = ThemeData(
    // fontFamily: "SB_agro",
    useMaterial3: true,
    dividerColor: const Color(0xFFD9D9D9),
    primaryColor: const Color.fromARGB(255, 38, 38, 38),
    primaryColorDark: const Color.fromARGB(255, 118, 156, 220),
    primaryColorLight: const Color.fromARGB(255, 217, 235, 255),
    shadowColor: const Color.fromARGB(255, 87, 87, 87).withOpacity(0.3),
    canvasColor: const Color.fromARGB(255, 255, 255, 255),
    textTheme: const TextTheme(
        displayLarge: TextStyle(
          color: Color.fromARGB(255, 0, 0, 0),
          fontSize: 27,
        ),
        displayMedium: TextStyle(
          color: Color.fromARGB(255, 0, 0, 0),
        ),
        displaySmall: TextStyle(
          color: Color.fromARGB(255, 0, 0, 0),
        )
    ),
    colorScheme: const ColorScheme(
      background: Color.fromARGB(255, 255, 255, 255),
      brightness: Brightness.light,
      primary: Color.fromARGB(255, 49, 130, 247),
      onPrimary: Color.fromARGB(255, 255, 255, 255),
      secondary: Color.fromARGB(255, 118, 156, 220),
      onSecondary: Color.fromARGB(255, 217, 235, 255),
      error: Colors.red,
      onError: Colors.white,
      onBackground: Color.fromARGB(255, 0, 0, 0),
      surface: Color.fromARGB(255, 255, 255, 255),
      onSurface: Color.fromARGB(255, 0, 0, 0),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        foregroundColor: Colors.white,
        backgroundColor: const Color.fromARGB(255, 49, 130, 247),
      ),
    ),
    expansionTileTheme: const ExpansionTileThemeData(
      iconColor: Colors.black,
    ),
    inputDecorationTheme: const InputDecorationTheme(
      hintStyle: TextStyle(
        color: Color(0xFF636363), // 원하는 hint 색상으로 설정
      ),
    ),
  );
  static ThemeData darkTheme = ThemeData(
    // fontFamily: "SB_agro",
    useMaterial3: true,
    dividerColor: const Color.fromARGB(255, 50, 50, 50),
    primaryColor: Colors.white,
    primaryColorDark: const Color.fromARGB(255, 118, 156, 220),
    primaryColorLight: const Color.fromARGB(255, 145, 157, 170),
    shadowColor: const Color.fromARGB(255, 173, 173, 173).withOpacity(0.3),
    canvasColor: const Color.fromARGB(255, 38, 38, 38),
    textTheme: const TextTheme(
        displayLarge: TextStyle(
          color: Color.fromARGB(255, 255, 255, 255),
          fontSize: 27,
        ),
        displayMedium: TextStyle(
          color: Color.fromARGB(255, 195, 195, 195),
        ),
        displaySmall: TextStyle(
          color: Color.fromARGB(255, 195, 195, 195),
        )
    ),
    colorScheme: ColorScheme(
      background: const Color.fromARGB(255, 26, 26, 26),
      brightness: Brightness.dark,
      primary: const Color.fromARGB(255, 49, 130, 247),
      onPrimary: const Color.fromARGB(255, 38, 38, 38),
      secondary: Colors.white,
      onSecondary: const Color.fromARGB(255, 49, 130, 247),
      error: Colors.red[700]!,
      onError: Colors.black,
      onBackground: const Color.fromARGB(255, 195, 195, 195),
      surface: const Color.fromARGB(255, 26, 26, 26),
      onSurface: Colors.white,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        foregroundColor: Colors.white,
        backgroundColor: const Color.fromARGB(255, 49, 130, 247),
      ),
    ),
    expansionTileTheme: const ExpansionTileThemeData(
      iconColor: Colors.white,
    ),
    inputDecorationTheme: const InputDecorationTheme(
      hintStyle: TextStyle(
        color: Color(0xFFD9D9D9), // 원하는 hint 색상으로 설정
      ),
    ),
  );
}
