import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:isyfit/theme/app_theme.dart';

void main() {
  group('buildAppTheme', () {
    test('returns light theme by default', () {
      final theme = buildAppTheme();
      expect(theme.brightness, Brightness.light);
      expect(theme.primaryColor, kElectricBlue);
    });

    test('returns dark theme when specified', () {
      final theme = buildAppTheme(isDark: true);
      expect(theme.brightness, Brightness.dark);
      expect(theme.primaryColor, kElectricBlue);
    });
  });
}
