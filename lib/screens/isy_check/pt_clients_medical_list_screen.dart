import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

// Import your MedicalHistoryScreen & QuestionnaireScreen
import 'package:isyfit/screens/medical_history/anamnesis_screen.dart';
import 'package:isyfit/screens/medical_history/medical_questionnaire/questionnaire_screen.dart';

// Import your gradient widgets / custom UI
import 'package:isyfit/widgets/gradient_app_bar.dart';
import 'package:isyfit/widgets/gradient_button.dart';

/// If the user is a PT and no clientUid is given, we display
/// a list of PT’s clients, toggling "with data" vs. "without data",
/// plus a search bar to filter by name/email.
class PTClientsMedicalListScreen extends StatefulWidget {
  const PTClientsMedicalListScreen({Key? key}) : super(key: key);

  @override
  State<PTClientsMedicalListScreen> createState() => _PTClientsMedicalListScreenState();
}

class _PTClientsMedicalListScreenState extends State<PTClientsMedicalListScreen> {
  bool showClientsWithoutData = false;

  // We'll store the entire list once loaded, so we can filter
  List<Map<String, dynamic>> _allClients = [];

  // For searching
  final TextEditingController _searchController = TextEditingController();
  String _searchTerm = '';

  late Future<List<Map<String, dynamic>>> _futureClients;

  @override
  void initState() {
    super.initState();
    _futureClients = _fetchPTClientsMedicalData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<List<Map<String, dynamic>>> _fetchPTClientsMedicalData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return [];

    final ptDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();
    final ptData = ptDoc.data();
    if (ptData == null) return [];

    final clients = ptData['clients'] as List<dynamic>? ?? [];

    final tasks = clients.map((clientUid) async {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(clientUid)
          .get();
      final userData = userDoc.data() ?? {};

      final mhDoc = await FirebaseFirestore.instance
          .collection('medical_history')
          .doc(clientUid)
          .get();
      final hasData = mhDoc.exists;

      return {
        'uid': clientUid.toString(),
        'hasMedicalData': hasData,
        'name': (userData['name'] ?? '') + ' ' + (userData['surname'] ?? ''),
        'email': userData['email'] ?? '',
      };
    });

    return Future.wait(tasks);
  }

  /// Apply toggles (with or without data) + search
  List<Map<String, dynamic>> _buildFilteredClients() {
    // First filter by showClientsWithoutData
    final filteredByData = _allClients.where((c) {
      final hasData = c['hasMedicalData'] == true;
      return showClientsWithoutData ? !hasData : hasData;
    }).toList();

    final searchLower = _searchTerm.toLowerCase();
    // Then filter by search
    final finalFiltered = filteredByData.where((c) {
      if (searchLower.isEmpty) return true;
      final nameLower = (c['name'] as String).toLowerCase();
      final emailLower = (c['email'] as String).toLowerCase();
      return nameLower.contains(searchLower) || emailLower.contains(searchLower);
    }).toList();

    return finalFiltered;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: GradientAppBar(
        title: 'isy-check- My Clients',
      ),
      body: Column(
        children: [
          const SizedBox(height: 16),

          // Search Bar
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
                hintText: 'Search by name or email...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Toggle Button
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: GradientButton(
              label: showClientsWithoutData
                  ? 'Show Clients WITH Medical Data'
                  : 'Show Clients WITHOUT Medical Data',
              icon: Icons.swap_horiz,
              onPressed: () {
                setState(() {
                  showClientsWithoutData = !showClientsWithoutData;
                });
              },
            ),
          ),

          const SizedBox(height: 16),

          // FutureBuilder to load all clients once
          Expanded(
            child: FutureBuilder<List<Map<String, dynamic>>>(
              future: _futureClients,
              builder: (ctx, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData) {
                  return const Center(
                    child: Text('No clients found.'),
                  );
                }
                // Once data is loaded, store it
                _allClients = snapshot.data!;
                final displayedClients = _buildFilteredClients();

                if (displayedClients.isEmpty) {
                  return Center(
                    child: Text(
                      showClientsWithoutData
                          ? 'No clients are missing medical data.'
                          : 'No matching clients have medical data.',
                      style: theme.textTheme.titleMedium,
                    ),
                  );
                }

                return ListView.builder(
                  itemCount: displayedClients.length,
                  itemBuilder: (ctx, index) {
                    final c = displayedClients[index];
                    final name = (c['name'] as String).trim();
                    final email = c['email'] as String;
                    final hasData = c['hasMedicalData'] == true;

                    // More "engaging" style: leading circle + trailing badge
                    return Card(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 8,
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
                          if (hasData) {
                            // If they have data => go to MedicalHistoryScreen
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => MedicalHistoryScreen(
                                  clientUid: c['uid'] as String,
                                ),
                              ),
                            );
                          } else {
                            // No data => start questionnaire for them
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => QuestionnaireScreen(
                                  clientUid: c['uid'] as String,
                                ),
                              ),
                            );
                          }
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
