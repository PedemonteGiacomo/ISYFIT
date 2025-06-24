import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:isyfit/presentation/widgets/fancy_bottom_bar.dart' as nav;

void main() {
  testWidgets('FancyBottomBar notifies index changes', (tester) async {
    int selected = -1;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          bottomNavigationBar: nav.FancyBottomBar(
            currentIndex: 0,
            onTap: (i) => selected = i,
          ),
        ),
      ),
    );

    await tester.tap(find.byIcon(Icons.fitness_center));
    await tester.pumpAndSettle();

    expect(selected, 1);
  });
}
