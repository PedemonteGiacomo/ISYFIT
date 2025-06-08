import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:isyfit/widgets/data_card.dart';

void main() {
  testWidgets('DataCard displays provided information', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: DataCard(
            title: 'Weight',
            value: '70kg',
            icon: Icons.scale,
            color: Colors.blue,
          ),
        ),
      ),
    );

    expect(find.text('Weight'), findsOneWidget);
    expect(find.text('70kg'), findsOneWidget);
    expect(find.byIcon(Icons.scale), findsOneWidget);
  });
}
