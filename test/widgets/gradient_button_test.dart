import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:isyfit/widgets/gradient_button.dart';

void main() {
  testWidgets('GradientButton renders label and triggers callback', (tester) async {
    bool tapped = false;
    await tester.pumpWidget(
      MaterialApp(
        home: GradientButton(
          label: 'Save',
          icon: Icons.save,
          onPressed: () => tapped = true,
        ),
      ),
    );

    expect(find.text('Save'), findsOneWidget);
    expect(find.byIcon(Icons.save), findsOneWidget);

    await tester.tap(find.byType(GradientButton));
    expect(tapped, isTrue);
  });
}
