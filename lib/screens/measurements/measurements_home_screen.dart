import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'measurements_complete_view_screen.dart';
import 'measurements_insert_screen.dart';
import 'measurements_view_screen.dart';

class MeasurementsHomeScreen extends StatefulWidget {
  final String clientUid; // Non-null => possibly a PT viewing a client

  const MeasurementsHomeScreen({Key? key, required this.clientUid})
      : super(key: key);

  @override
  State<MeasurementsHomeScreen> createState() => _MeasurementsHomeScreenState();
}

class _MeasurementsHomeScreenState extends State<MeasurementsHomeScreen> {
  late Future<Map<String, dynamic>?> _clientProfileFuture;

  /// If currentUser.uid != widget.clientUid => PT is viewing someone else
  bool get isPTView {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return false;
    return currentUser.uid != widget.clientUid;
  }

  @override
  void initState() {
    super.initState();
    // Only fetch the client’s info if it’s a PT viewing a different user
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
      length: 3, // Insert, Simple View, Complete View
      child: Scaffold(
        // No appBar here, so we don't override the parent's "isy-lab" app bar
        body: Column(
          children: [
            // 1) A Material widget for the TabBar for a more “Material” look:
            Container(
              decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                Theme.of(context).colorScheme.primary,
                Theme.of(context).colorScheme.primary.withOpacity(0.6),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              // boxShadow: [
              //   BoxShadow(
              //   color: Colors.black.withOpacity(0.2),
              //   blurRadius: 4,
              //   offset: const Offset(0, 2),
              //   ),
              // ],
              ),
              child: TabBar(
              tabs: const [
                Tab(icon: Icon(Icons.add), text: "Insert"),
                Tab(icon: Icon(Icons.watch_later_outlined), text: "Last Data"),
                Tab(icon: Icon(Icons.auto_graph), text: "All Data"),
              ],
              labelColor: Theme.of(context).colorScheme.onPrimary,
              unselectedLabelColor:
                Theme.of(context).colorScheme.onPrimary.withOpacity(0.7),
              indicatorColor: Theme.of(context).colorScheme.onPrimary,
              indicatorWeight: 3,
              ),
            ),

            // 1) Optional label for PT or "Your measurements"
            if (isPTView)
              FutureBuilder<Map<String, dynamic>?>(
                future: _clientProfileFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const SizedBox(height: 0);
                  }
                  final data = snapshot.data;
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
              )
            else
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

            // 3) TabBarView with your 3 screens
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
