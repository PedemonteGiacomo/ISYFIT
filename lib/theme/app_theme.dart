// lib/theme/app_theme.dart
import 'package:flutter/material.dart';

// If you want to embed a custom font (e.g. Roboto), 
// make sure you declared it in pubspec.yaml and placed the font file in assets.
// For now, let's assume "Roboto" is declared in pubspec.yaml. 

/// Example brand colors: Electric Blue, plus black/white
const Color kElectricBlue = Color(0xFF0062FF);
const Color kBlack = Colors.black;
const Color kWhite = Colors.white;

/// Optional swatch for controlling dynamic widget colors.
const MaterialColor kElectricBlueSwatch = MaterialColor(
  0xFF0062FF,
  <int, Color>{
    50:  Color(0xFFE6F0FF),
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
  
  return base.copyWith(
    //primarySwatch: kElectricBlueSwatch,
    primaryColor: kElectricBlue,
    scaffoldBackgroundColor: isDark ? kBlack : kWhite,
    
    // Text
    textTheme: base.textTheme.apply(
      fontFamily: 'Roboto', // or any other declared font
      bodyColor: isDark ? kWhite : kBlack,
      displayColor: isDark ? kWhite : kBlack,
    ),
    
    // ElevatedButton styling
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: kElectricBlue,
        foregroundColor: kWhite,
        textStyle: const TextStyle(fontFamily: 'Roboto'),
      ),
    ),

    // More flexible approach for color scheme
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
  );
}
