import 'package:flutter/material.dart';

// Your color definitions
const Color kElectricBlue = Color(0xFF0062FF);
const Color kBlack = Colors.black;
const Color kWhite = Colors.white;

const MaterialColor kElectricBlueSwatch = MaterialColor(
  0xFF0062FF,
  <int, Color>{
    50: Color(0xFFE6F0FF),
    100: Color(0xFFCCE0FF),
    200: Color(0xFF99C2FF),
    300: Color(0xFF66A3FF),
    400: Color(0xFF3385FF),
    500: Color(0xFF0062FF),
    600: Color(0xFF0058E6),
    700: Color(0xFF004BCC),
    800: Color(0xFF003FB3),
    900: Color(0xFF002680),
  },
);

ThemeData buildAppTheme({bool isDark = false}) {
  final base = isDark ? ThemeData.dark() : ThemeData.light();

  // We enable Material 3 while retaining our color definitions
  return base.copyWith(
    useMaterial3: true, // Activates many M3 styles (shapes, transitions, etc.)

    primaryColor: kElectricBlue,
    scaffoldBackgroundColor: isDark ? kBlack : kWhite,

    // Text
    textTheme: base.textTheme.apply(
      fontFamily: 'Roboto', // or your custom font
      bodyColor: isDark ? kWhite : kBlack,
      displayColor: isDark ? kWhite : kBlack,
    ),

    // We'll style ElevatedButtons + FilledButtons
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: kElectricBlue,
        foregroundColor: kWhite,
        textStyle: const TextStyle(fontFamily: 'Roboto'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    ),

    // New in Material 3: you can specify 'filled' or 'filled tonal' button styles
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: kElectricBlue,
        foregroundColor: kWhite,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    ),

    // Global color scheme
    colorScheme: base.colorScheme.copyWith(
      primary: kElectricBlue,
      secondary: kElectricBlue,
      background: isDark ? kBlack : kWhite,
      surface: isDark ? const Color(0xFF1E1E1E) : kWhite,
      onPrimary: kWhite,
      onSecondary: kWhite,
      onSurface: isDark ? kWhite : kBlack,
      onBackground: isDark ? kWhite : kBlack,
      brightness: isDark ? Brightness.dark : Brightness.light,
    ),

    // Let's style cards with M3 shapes
    cardTheme: CardThemeData(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      // M3-like surface tint is optional if you're going for a tinted surface
      color: isDark ? const Color(0xFF2C2C2C) : kWhite,
    ),
  );
}
