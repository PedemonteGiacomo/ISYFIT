import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../theme/app_gradients.dart';

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
  late Future<bool> _isPTFuture;

  /// If the currentUser.uid != clientUid => it means a PT is viewing a client
  bool get isPTView {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return false;
    return currentUser.uid != widget.clientUid;
  }

  @override
  void initState() {
    super.initState();

    // We'll fetch the profile of the client if a PT is viewing them
    _clientProfileFuture = isPTView ? _fetchClientProfile() : Future.value(null);

    // Also, we check whether the *current user* is PT
    _isPTFuture = _fetchIsPT();
  }

  Future<Map<String, dynamic>?> _fetchClientProfile() async {
    final docSnap = await FirebaseFirestore.instance
        .collection('users')
        .doc(widget.clientUid)
        .get();
    return docSnap.data();
  }

  /// Checks Firestore: does the current logged in user have role == "PT" ?
  Future<bool> _fetchIsPT() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return false;
    final docSnap = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();
    final data = docSnap.data() ?? {};
    return data['role'] == 'PT';
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: _isPTFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        final isCurrentUserPT = snapshot.data ?? false;

        // Decide whether to show the Insert tab
        // Example #1: Show "Insert" if the user is PT, or if the user is the client themselves
        // Example #2: If you want to hide Insert from the client, just show it for PT
        // You can adapt whichever condition you prefer:
        final showInsert = isCurrentUserPT;
        // If you want to also allow the client to insert for themselves:
        // final showInsert = (isCurrentUserPT || !isPTView);

        // Then the total tab count changes
        final tabCount = showInsert ? 3 : 2;

        return DefaultTabController(
          length: tabCount,
          child: Scaffold(
            //backgroundColor: Colors.blueGrey.shade50,
            body: Column(
              children: [
                // Gradient container for the TabBar
                Container(
                  decoration: BoxDecoration(
                    gradient: AppGradients.primary(Theme.of(context)),
                  ),
                  // Build the TabBar depending on how many tabs
                  child: TabBar(
                    indicatorColor: Colors.white,
                    indicatorWeight: 3,
                    tabs: _buildTabs(showInsert),
                  ),
                ),

                // Show the PT's "client info" if relevant
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
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
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
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                      );
                    },
                  )
                else
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Text(
                      'Your Measurements',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ),

                // The TabBarView: if we have 2 tabs, we skip the Insert screen
                Expanded(
                  child: TabBarView(
                    children: _buildTabViews(showInsert),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Builds the list of Tab widgets depending on whether the Insert tab is shown.
  List<Widget> _buildTabs(bool showInsert) {
    final onPrimary = Theme.of(context).colorScheme.onPrimary;
    if (showInsert) {
      // 3 tabs: Insert, Last Data, All Data
      return [
        Tab(
          icon: Icon(Icons.add, color: onPrimary),
          child: Text("Insert", style: TextStyle(color: onPrimary)),
        ),
        Tab(
          icon: Icon(Icons.watch_later_outlined, color: onPrimary),
          child: Text("Last Data", style: TextStyle(color: onPrimary)),
        ),
        Tab(
          icon: Icon(Icons.auto_graph, color: onPrimary),
          child: Text("All Data", style: TextStyle(color: onPrimary)),
        ),
      ];
    } else {
      // 2 tabs: Last Data, All Data
      return [
        Tab(
          icon: Icon(Icons.watch_later_outlined, color: onPrimary),
          child: Text("Last Data", style: TextStyle(color: onPrimary)),
        ),
        Tab(
          icon: Icon(Icons.auto_graph, color: onPrimary),
          child: Text("All Data", style: TextStyle(color: onPrimary)),
        ),
      ];
    }
  }

  /// Builds the list of tab views depending on whether we want the Insert tab or not.
  List<Widget> _buildTabViews(bool showInsert) {
    if (showInsert) {
      // When Insert is shown
      return [
        MeasurementsInsertScreen(clientUid: widget.clientUid),
        MeasurementsViewScreen(clientUid: widget.clientUid),
        MeasurementsCompleteViewScreen(clientUid: widget.clientUid),
      ];
    } else {
      // Only 2 tabs: skip the Insert screen
      return [
        MeasurementsViewScreen(clientUid: widget.clientUid),
        MeasurementsCompleteViewScreen(clientUid: widget.clientUid),
      ];
    }
  }
}
