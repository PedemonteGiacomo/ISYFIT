import 'package:flutter/material.dart';

class AppGradients {
  static List<Color> primaryColors(ThemeData theme) => [
        theme.colorScheme.primary,
        theme.colorScheme.primary.withOpacity(0.6),
      ];

  static LinearGradient primary(ThemeData theme) => LinearGradient(
        colors: primaryColors(theme),
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );
}
