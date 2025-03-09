import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'measurements_complete_view_screen.dart';
import 'measurements_insert_screen.dart';
import 'measurements_view_screen.dart';

class MeasurementsHomeScreen extends StatefulWidget {
  final String
      clientUid; // Non-null means we’re potentially a PT viewing a client.

  const MeasurementsHomeScreen({Key? key, required this.clientUid})
      : super(key: key);

  @override
  State<MeasurementsHomeScreen> createState() => _MeasurementsHomeScreenState();
}

class _MeasurementsHomeScreenState extends State<MeasurementsHomeScreen> {
  late Future<Map<String, dynamic>?> _clientProfileFuture;

  /// If the current user is the same as [widget.clientUid],
  /// we assume it’s the client themself. Otherwise, likely a PT is viewing the data.
  bool get isPTView {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return false;
    return currentUser.uid != widget.clientUid;
  }

  @override
  void initState() {
    super.initState();
    // Only fetch the client’s info if we’re a PT viewing a different user.
    // If you want to always show it (even for the user themselves),
    // you can remove the condition.
    _clientProfileFuture =
        isPTView ? _fetchClientProfile() : Future.value(null);
  }

  Future<Map<String, dynamic>?> _fetchClientProfile() async {
    final docSnap = await FirebaseFirestore.instance
        .collection('users')
        .doc(widget.clientUid)
        .get();
    return docSnap.data();
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            "Measurements",
            style: TextStyle(color: Theme.of(context).colorScheme.onPrimary),
          ),
          centerTitle: true,
          backgroundColor: Theme.of(context).colorScheme.primary,
          iconTheme: IconThemeData(
            color: Theme.of(context).colorScheme.onPrimary,
          ),
          bottom: TabBar(
            tabs: [
              Tab(
                icon: Icon(Icons.add,
                    color: Theme.of(context).colorScheme.onPrimary),
                text: "Insert",
              ),
              Tab(
                icon: Icon(Icons.view_agenda,
                    color: Theme.of(context).colorScheme.onPrimary),
                text: "Simple View",
              ),
              Tab(
                icon: Icon(Icons.auto_graph,
                    color: Theme.of(context).colorScheme.onPrimary),
                text: "Complete View",
              ),
            ],
            labelColor: Theme.of(context).colorScheme.onPrimary,
            unselectedLabelColor: Theme.of(context).colorScheme.onPrimary,
          ),
        ),
        body: Column(
          children: [
            // 1) Only show client’s name if we’re a PT viewing another user
            if (isPTView)
              FutureBuilder<Map<String, dynamic>?>(
                future: _clientProfileFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    // You could show a small linear progress or just an empty space:
                    return const SizedBox(height: 0);
                  }
                  final data = snapshot.data;
                  // If no data found, maybe show "Unknown client"
                  if (data == null) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: Text(
                        'Unknown Client',
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                    );
                  }
                  // Display "Name Surname (email)" or any format you like
                  final name = data['name'] ?? '';
                  final surname = data['surname'] ?? '';
                  final email = data['email'] ?? '';

                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Text(
                      '$name $surname ($email)',
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                  );
                },
              ),

            // else show "Your measurements"
            if (!isPTView)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Text(
                  'Your Measurements',
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
              ),
            // 2) The main TabBar content
            Expanded(
              child: TabBarView(
                children: [
                  MeasurementsInsertScreen(clientUid: widget.clientUid),
                  MeasurementsViewScreen(clientUid: widget.clientUid),
                  MeasurementsCompleteViewScreen(clientUid: widget.clientUid),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
