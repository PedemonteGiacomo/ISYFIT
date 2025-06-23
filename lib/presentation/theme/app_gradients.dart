import 'package:flutter/material.dart';

class AppGradients {
  static List<Color> primaryColors(ThemeData theme) => [
        theme.colorScheme.primary,
        theme.colorScheme.primary.withOpacity(0.64),
      ];

  static LinearGradient primary(ThemeData theme) => LinearGradient(
        colors: primaryColors(theme),
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      );

  /// Continues the primary gradient by starting from its final color and
  /// fading to white. Useful for widgets directly below the app bar so the
  /// gradient feels seamless.
  static LinearGradient primaryToWhite(ThemeData theme) => LinearGradient(
        colors: [
          theme.colorScheme.primary.withOpacity(0.665),
          theme.colorScheme.primary.withOpacity(0.8),
        ],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      );
}
