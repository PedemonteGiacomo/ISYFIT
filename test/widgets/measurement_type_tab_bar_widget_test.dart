import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:isyfit/widgets/measurement_type_tab_bar_widget.dart';

void main() {
  testWidgets('MeasurementTypeTabBarWidget shows three tabs', (tester) async {
    final controller = TabController(length: 3, vsync: const TestVSync());
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: MeasurementTypeTabBarWidget(tabController: controller),
        ),
      ),
    );

    expect(find.text('BIA'), findsOneWidget);
    expect(find.text('USArmy'), findsOneWidget);
    expect(find.text('Plicometro'), findsOneWidget);
  });
}

class TestVSync implements TickerProvider {
  const TestVSync();
  @override
  Ticker createTicker(TickerCallback onTick) => Ticker(onTick);
}
