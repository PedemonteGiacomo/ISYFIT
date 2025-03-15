import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:isyfit/screens/base_screen.dart';
import 'package:isyfit/screens/measurements/measurements_home_screen.dart';
import 'package:isyfit/widgets/gradient_app_bar.dart';

class IsyLabMainScreen extends StatefulWidget {
  final String? clientUid;
  const IsyLabMainScreen({Key? key, this.clientUid}) : super(key: key);

  @override
  State<IsyLabMainScreen> createState() => _IsyLabMainScreenState();
}

class _IsyLabMainScreenState extends State<IsyLabMainScreen> {
  @override
  Widget build(BuildContext context) {
    // Retrieve current user uid to pass to MeasurementsHomeScreen.
    final String contextUserUid =
        widget.clientUid ?? FirebaseAuth.instance.currentUser?.uid ?? "";
    return DefaultTabController(
      length: 3,
      initialIndex: 1, // This makes the "Measurements" tab the default
      child: Scaffold(
        bottomNavigationBar: const TabBar(
          tabs: [
            Tab(icon: Icon(Icons.photo_camera), text: "Photo"),
            Tab(
                icon: Icon(Icons.monitor_weight_outlined),
                text: "Measurements"),
            Tab(icon: Icon(Icons.insights_outlined), text: "Bodyfat"),
          ],
          labelColor: Colors.blue,
          unselectedLabelColor: Colors.grey,
        ),
        appBar: GradientAppBar(
          title: 'isy-lab',
          actions: [
            IconButton(
              icon: Icon(Icons.home),
              onPressed: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const BaseScreen()),
                );
              },
            ),
          ],
        ),
        body: TabBarView(
          children: [
            Center(child: Text("Photo Screen")),
            MeasurementsHomeScreen(clientUid: contextUserUid),
            Center(child: Text("Bodyfat Comparison Screen")),
          ],
        ),
      ),
    );
  }
}
