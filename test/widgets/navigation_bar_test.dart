import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:isyfit/presentation/widgets/fancy_bottom_bar.dart';

void main() {
  testWidgets('FancyBottomBar notifies taps', (tester) async {
    int tapped = -1;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          bottomNavigationBar: FancyBottomBar(
            currentIndex: 0,
            onTap: (i) => tapped = i,
          ),
        ),
      ),
    );

    await tester.tap(find.byIcon(Icons.science));
    await tester.pumpAndSettle();

    expect(tapped, 2);
  });
}
