import 'package:flutter/material.dart';
import 'package:isyfit/screens/base_screen.dart';
import 'package:isyfit/widgets/gradient_app_bar.dart';

// Example sub-screens for IsyTraining
import 'logbook_screen.dart';
import 'library_screen.dart';

class IsyTrainingMainScreen extends StatelessWidget {
  final String? clientUid;
  const IsyTrainingMainScreen({Key? key, this.clientUid}) : super(key: key);

  //TODO: implement the clientUid logic here to separate the PT view of the client's training logbook

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2, // We have 2 tabs: Logbook + Library
      child: Scaffold(
        appBar: GradientAppBar(
          title: 'IsyTraining',
          actions: [
            // Add a "Home" icon that takes the PT back to the main flow.
            IconButton(
              icon: Icon(Icons.home,
                  color: Theme.of(context).colorScheme.onPrimary),
              onPressed: () {
                // For example, pushReplacement to the main BaseScreen
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const BaseScreen()),
                );
              },
            ),
          ],
        ),
        // Put the TabBar in the bottomNavigationBar, just like your sample
        bottomNavigationBar: const TabBar(
          tabs: [
            Tab(icon: Icon(Icons.book_outlined), text: "Logbook"),
            Tab(icon: Icon(Icons.list_alt), text: "Library"),
          ],
          labelColor: Colors.blue,
          unselectedLabelColor: Colors.grey,
        ),
        // Each tab gets its own page in the TabBarView
        body: TabBarView(
          children: [
            LogbookScreen(clientUid: clientUid),
            LibraryScreen(clientUid: clientUid),
          ],
        ),
      ),
    );
  }
}
