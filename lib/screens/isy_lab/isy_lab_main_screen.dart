import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:isyfit/screens/measurements/measurements_home_screen.dart';

class IsyLabMainScreen extends StatefulWidget {
  const IsyLabMainScreen({Key? key}) : super(key: key);

  @override
  State<IsyLabMainScreen> createState() => _IsyLabMainScreenState();
}

class _IsyLabMainScreenState extends State<IsyLabMainScreen> {
  @override
  Widget build(BuildContext context) {
    // Retrieve current user uid to pass to MeasurementsHomeScreen.
    final String currentUserUid = FirebaseAuth.instance.currentUser?.uid ?? '';
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        bottomNavigationBar: const TabBar(
          tabs: [
            Tab(icon: Icon(Icons.photo_camera), text: "Photo"),
            Tab(icon: Icon(Icons.monitor_weight_outlined), text: "Measurements"),
            Tab(icon: Icon(Icons.insights_outlined), text: "Bodyfat"),
          ],
          labelColor: Colors.blue, // Adjust color as needed
          unselectedLabelColor: Colors.grey, // Adjust color as needed
        ),
        appBar: AppBar(
          title: Text("isy-lab", style: TextStyle(color: Theme.of(context).colorScheme.onPrimary)),
          centerTitle: true,
          backgroundColor: Theme.of(context).colorScheme.primary,
          iconTheme: IconThemeData(
            color: Theme.of(context).colorScheme.onPrimary,
          ),
        ),
        body: TabBarView(
          children: [
            // Photo Tab (for PT only; you can add PT-check logic if needed)
            Center(
              child: Text(
                "Photo Screen\n(For PT use only)",
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
            ),
            // Measurements Tab – reuse your existing MeasurementsHomeScreen.
            MeasurementsHomeScreen(clientUid: currentUserUid),
            // Bodyfat Tab – placeholder; implement as needed.
            Center(
              child: Text(
                "Bodyfat Comparison Screen",
                style: Theme.of(context).textTheme.headlineSmall,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
