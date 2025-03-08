import 'package:flutter/material.dart';
import 'measurements_insert_screen.dart';
import 'measurements_view_screen.dart';
import 'measurements_complete_view_screen.dart';

class MeasurementsHomeScreen extends StatelessWidget {
  final String clientUid;
  const MeasurementsHomeScreen({Key? key, required this.clientUid})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3, // Now 3 tabs
      child: Scaffold(
        appBar: AppBar(
          title: Text("Measurements",
              style: TextStyle(color: Theme.of(context).colorScheme.onPrimary)),
          bottom: const TabBar(
            tabs: [
              Tab(icon: Icon(Icons.add), text: "Insert"),
              Tab(icon: Icon(Icons.view_agenda), text: "Simple View"),
              Tab(icon: Icon(Icons.auto_graph), text: "Complete View"),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            MeasurementsInsertScreen(clientUid: clientUid),
            MeasurementsViewScreen(clientUid: clientUid),
            MeasurementsCompleteViewScreen(clientUid: clientUid),
          ],
        ),
      ),
    );
  }
}
