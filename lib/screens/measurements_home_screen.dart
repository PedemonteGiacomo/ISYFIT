import 'package:flutter/material.dart';
import 'measurements_insert_screen.dart';
import 'measurements_view_screen.dart';

class MeasurementsHomeScreen extends StatelessWidget {
  final String clientUid;
  const MeasurementsHomeScreen({Key? key, required this.clientUid}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text("Measurements"),
          bottom: const TabBar(
            tabs: [
              Tab(icon: Icon(Icons.add), text: "Insert"),
              Tab(icon: Icon(Icons.list), text: "View/Compare"),
            ],
          ),
        ),
        body: const TabBarView(
          // NB: Each tab uses a separate widget
          children: [
            // We pass the clientUid to each screen as needed
            MeasurementsInsertScreen(),
            MeasurementsViewScreen(),
          ],
        ),
      ),
    );
  }
}
