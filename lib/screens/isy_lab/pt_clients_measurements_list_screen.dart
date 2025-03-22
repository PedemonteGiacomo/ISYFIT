import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

// Import the screen that shows the tabbed 3-tab layout for isy-lab
import 'package:isyfit/screens/isy_lab/isy_lab_main_screen.dart';
// Or if you want to go to a direct measurements screen, import that:
// import 'package:isyfit/screens/measurements/measurements_home_screen.dart';

// Import your gradient app bar and gradient button
import 'package:isyfit/widgets/gradient_app_bar.dart';
import 'package:isyfit/widgets/gradient_button.dart';

/// This screen shows the PT’s clients for isy-lab.
///  - By default, shows only clients who DO have measurement data
///  - We have a toggle to “Show clients WITHOUT measurement data”
///  - A Search bar to filter by name/email
///  - Tapping a client with data → goes to IsyLabMainScreen
///  - Tapping a client without data → also goes to IsyLabMainScreen (or a new measurement creation)
class PTClientsIsyLabListScreen extends StatefulWidget {
  const PTClientsIsyLabListScreen({Key? key}) : super(key: key);

  @override
  State<PTClientsIsyLabListScreen> createState() =>
      _PTClientsIsyLabListScreenState();
}

class _PTClientsIsyLabListScreenState extends State<PTClientsIsyLabListScreen> {
  bool showClientsWithoutMeasurements = false;

  // We’ll store the entire fetched list once loaded, so we can filter
  List<Map<String, dynamic>> _allClients = [];

  final TextEditingController _searchController = TextEditingController();
  String _searchTerm = '';

  late Future<List<Map<String, dynamic>>> _futureClients;

  @override
  void initState() {
    super.initState();
    // Kick off fetching the PT’s clients + their measurement data presence
    _futureClients = _fetchPTClientsMeasurementData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  /// We define "hasMeasurementData" as “the user has at least 1 doc in `measurements/{clientUid}/user_measurements/…`”
  Future<List<Map<String, dynamic>>> _fetchPTClientsMeasurementData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return [];

    // Load the PT’s doc
    final ptDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();
    final ptData = ptDoc.data();
    if (ptData == null) return [];

    final clients = ptData['clients'] as List<dynamic>? ?? [];

    // For each clientUid, check if “measurements/{clientUid}/(some subcollection)” has any docs
    final tasks = clients.map((clientUid) async {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(clientUid)
          .get();
      final userData = userDoc.data() ?? {};

      // Check if there’s at least 1 measurement doc
      // For example, "measurements/{clientUid}/records"
      final measurementQuery = await FirebaseFirestore.instance
          .collection('measurements')
          .doc(clientUid)
          .collection('records')
          .limit(1)
          .get();

      final hasData = measurementQuery.docs.isNotEmpty;

      return {
        'uid': clientUid.toString(),
        'hasMeasurementData': hasData,
        'name': (userData['name'] ?? '') + ' ' + (userData['surname'] ?? ''),
        'email': userData['email'] ?? '',
      };
    });

    return Future.wait(tasks);
  }

  /// Filter the loaded clients by:
  ///   1) Data presence toggle
  ///   2) Search text
  List<Map<String, dynamic>> _buildFilteredClients() {
    // First filter by data presence
    final filteredByData = _allClients.where((c) {
      final hasData = c['hasMeasurementData'] == true;
      // If we are showing clients WITHOUT measurements, we want !hasData
      // If not, we want hasData
      return showClientsWithoutMeasurements ? !hasData : hasData;
    }).toList();

    // Next filter by searchTerm
    final searchLower = _searchTerm.toLowerCase();
    if (searchLower.isEmpty) return filteredByData;

    return filteredByData.where((c) {
      final nameLower = (c['name'] as String).toLowerCase();
      final emailLower = (c['email'] as String).toLowerCase();
      return nameLower.contains(searchLower) || emailLower.contains(searchLower);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: GradientAppBar(
        title: 'My Clients - isy-lab',
      ),
      body: Column(
        children: [
          const SizedBox(height: 16),

          // Search field
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: TextField(
              controller: _searchController,
              onChanged: (val) {
                setState(() {
                  _searchTerm = val;
                });
              },
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search),
                hintText: 'Search client by name or email...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),

          const SizedBox(height: 12),

          // Toggle button
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: GradientButton(
              label: showClientsWithoutMeasurements
                  ? 'Show Clients WITH Measurements'
                  : 'Show Clients WITHOUT Measurements',
              icon: Icons.swap_horiz,
              onPressed: () {
                setState(() {
                  showClientsWithoutMeasurements =
                      !showClientsWithoutMeasurements;
                });
              },
            ),
          ),

          const SizedBox(height: 16),

          // FutureBuilder to load the clients
          Expanded(
            child: FutureBuilder<List<Map<String, dynamic>>>(
              future: _futureClients,
              builder: (ctx, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData) {
                  return const Center(child: Text('No clients found.'));
                }
                // Store the result in _allClients so we can do local filtering
                _allClients = snapshot.data!;

                final displayedClients = _buildFilteredClients();
                if (displayedClients.isEmpty) {
                  return Center(
                    child: Text(
                      showClientsWithoutMeasurements
                          ? 'No clients are missing measurement data.'
                          : 'No matching clients have measurement data.',
                      style: theme.textTheme.titleMedium,
                    ),
                  );
                }

                return ListView.builder(
                  itemCount: displayedClients.length,
                  itemBuilder: (ctx, index) {
                    final c = displayedClients[index];
                    final hasData = (c['hasMeasurementData'] == true);
                    final name = (c['name'] as String).trim();
                    final email = (c['email'] as String).trim();

                    return Card(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 3,
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: hasData
                              ? Colors.green.shade100
                              : Colors.red.shade100,
                          child: Icon(
                            hasData ? Icons.check : Icons.close,
                            color: hasData ? Colors.green : Colors.red,
                          ),
                        ),
                        title: Text(
                          name.isNotEmpty ? name : 'Unnamed Client',
                          style: theme.textTheme.bodyLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        subtitle: Text(email),
                        trailing: hasData
                            ? Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.green.shade100,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  'Has Data',
                                  style: TextStyle(color: Colors.green[800]),
                                ),
                              )
                            : Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.red.shade100,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  'No Data',
                                  style: TextStyle(color: Colors.red[800]),
                                ),
                              ),
                        onTap: () {
                          // If data => show IsyLabMainScreen with clientUid
                          // Otherwise => maybe show the same or a “Create measurement” flow
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => IsyLabMainScreen(
                                clientUid: c['uid'] as String,
                              ),
                            ),
                          );
                        },
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
