import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:isyfit/widgets/navigation_bar.dart' as nav;

void main() {
  testWidgets('NavigationBar has five items', (tester) async {
    int index = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: nav.NavigationBar(
          currentIndex: index,
          onIndexChanged: (i) => index = i,
        ),
      ),
    );

    expect(find.byType(BottomNavigationBarItem), findsNWidgets(5));
    await tester.tap(find.text('Account'));
    expect(index, 4);
  });
}
