import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:isyfit/presentation/widgets/radial_menu.dart';

void main() {
  testWidgets('RadialMenu notifies item taps', (tester) async {
    int selected = -1;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 200,
              height: 200,
              child: RadialMenu(
                spin: false,
                radius: 40,
                items: const [
                  RadialMenuItem(Icons.fitness_center, 'Training'),
                  RadialMenuItem(Icons.science, 'Lab'),
                  RadialMenuItem(Icons.check_circle, 'Check'),
                  RadialMenuItem(Icons.apple, 'Diary'),
                ],
                onItemTap: (i) => selected = i,
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.byIcon(Icons.science));
    await tester.pumpAndSettle();

    expect(selected, 1);
  });
}
