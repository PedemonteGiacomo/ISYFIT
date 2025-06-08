import 'package:flutter/material.dart';
import '../theme/app_gradients.dart';

/// A reusable 3‑tab bar for "BIA / USArmy / Plicometro"
/// 
/// To use it:
/// 1) In your State, create: late TabController _tabController;
///    inside `initState`, do: _tabController = TabController(length: 3, vsync: this);
/// 2) Then place this widget in build:
///    MeasurementTypeTabBarWidget(tabController: _tabController)
/// 3) In your TabBarView, pass the same controller: TabBarView(controller: _tabController, ...)
///
class MeasurementTypeTabBarWidget extends StatelessWidget {
  final TabController tabController;

  const MeasurementTypeTabBarWidget({Key? key, required this.tabController})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      // We omit extra margin so it can attach directly to whatever is above it.
      decoration: BoxDecoration(
        gradient: AppGradients.primary(Theme.of(context)),
      ),
      child: TabBar(
        controller: tabController,
        indicatorColor: Colors.white,
        indicatorWeight: 3,
        labelColor: Colors.white,
        unselectedLabelColor: Colors.white70,
        tabs: const [
          Tab(text: 'BIA'),
          Tab(text: 'USArmy'),
          Tab(text: 'Plicometro'),
        ],
      ),
    );
  }
}
