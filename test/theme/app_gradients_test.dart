import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:isyfit/theme/app_gradients.dart';

void main() {
  test('primaryColors returns two colors', () {
    final theme = ThemeData.light();
    final colors = AppGradients.primaryColors(theme);
    expect(colors.length, 2);
    expect(colors.first, theme.colorScheme.primary);
  });
}
