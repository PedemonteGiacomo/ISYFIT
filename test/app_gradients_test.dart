import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:isyfit/presentation/theme/app_gradients.dart';

void main() {
  test('primaryColors uses theme colors', () {
    const primaryColor = Color(0xFF123456);
    final theme = ThemeData(
      colorScheme: const ColorScheme.light().copyWith(primary: primaryColor),
    );
    final colors = AppGradients.primaryColors(theme);
    expect(colors.first, primaryColor);
    expect(colors.last, primaryColor.withOpacity(0.6));
  });
}
