import 'package:flutter/material.dart';

// Example sub-screens for isy-training
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
        appBar: AppBar(
          title: Text("isy-training", style: TextStyle(color: Theme.of(context).colorScheme.onPrimary)),
          centerTitle: true,
          backgroundColor: Theme.of(context).colorScheme.primary,
          iconTheme: IconThemeData(
            color: Theme.of(context).colorScheme.onPrimary,
          ),
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
        body: const TabBarView(
          children: [
            LogbookScreen(), //TODO: pass the clientUid here to separate the PT view of the client's logbook
            LibraryScreen(), //TODO: pass the clientUid here to separate the PT view of the client's library
          ],
        ),
      ),
    );
  }
}
