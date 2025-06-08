import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:isyfit/widgets/gradient_app_bar.dart';

void main() {
  testWidgets('GradientAppBar displays title', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(appBar: GradientAppBar(title: 'Hello')),
      ),
    );

    expect(find.text('Hello'), findsOneWidget);
    expect(find.byType(AppBar), findsOneWidget);
  });
}
