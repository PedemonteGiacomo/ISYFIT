import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:isyfit/widgets/gradient_button.dart';

void main() {
  testWidgets('GradientButton triggers callback', (tester) async {
    var tapped = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: GradientButton(
            label: 'Tap',
            onPressed: () => tapped = true,
          ),
        ),
      ),
    );

    await tester.tap(find.text('Tap'));
    await tester.pumpAndSettle();
    expect(tapped, isTrue);
  });
}
