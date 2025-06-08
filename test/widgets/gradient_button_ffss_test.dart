import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:isyfit/widgets/gradient_button_for_final_submit_screen.dart';

void main() {
  testWidgets('disabled GradientButtonFFSS shows label and icon',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: GradientButtonFFSS(
          label: 'Submit',
          icon: Icons.send,
          onPressed: null,
        ),
      ),
    );

    expect(find.text('Submit'), findsOneWidget);
    expect(find.byIcon(Icons.send), findsOneWidget);
  });
}
