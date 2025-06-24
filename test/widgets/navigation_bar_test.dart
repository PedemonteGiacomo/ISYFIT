import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:isyfit/presentation/widgets/navigation_bar.dart' as nav;

void main() {
  testWidgets('NavigationBar notifies index changes', (tester) async {
    int selected = -1;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          bottomNavigationBar: nav.NavigationBar(
            currentIndex: 0,
            onIndexChanged: (i) => selected = i,
          ),
        ),
      ),
    );

    await tester.tap(find.byIcon(Icons.fitness_center));
    await tester.pumpAndSettle();

    expect(selected, 1);
  });
}
