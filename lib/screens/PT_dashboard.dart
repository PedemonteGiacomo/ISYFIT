import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:isyfit/screens/login_screen.dart';
import 'package:isyfit/screens/measurements_screen.dart';
import 'manage_clients_screen.dart';
// Import the screens that accept clientUid:
import 'package:isyfit/screens/medical_history/medical_history_screen.dart';
import 'package:isyfit/screens/training_records_screen.dart';
import 'package:isyfit/screens/account_screen.dart';

class PTDashboard extends StatelessWidget {
  const PTDashboard({Key? key}) : super(key: key);

  /// Fetch up to 3 "top clients" from Firestore
  Future<List<Map<String, dynamic>>> _fetchClients() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      return [];
    }

    final ptDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(currentUser.uid)
        .get();

    final ptData = ptDoc.data();
    if (ptData == null || !ptData.containsKey('clients')) {
      return [];
    }

    // Take the first 3 from the array
    final clientIds = (ptData['clients'] as List<dynamic>).take(3).toList();
    final List<Map<String, dynamic>> clients = [];

    for (String clientId in clientIds) {
      final clientDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(clientId)
          .get();

      if (clientDoc.exists) {
        final clientData = clientDoc.data() as Map<String, dynamic>;
        // Add doc ID if needed
        clientData['uid'] = clientId;
        clients.add(clientData);
      }
    }
    return clients;
  }

  /// Show a popup dialog with “Medical”, “Training”, and “Info” for the chosen client
void _showClientOptions(
  BuildContext context, {
  required String clientUid,
  required String clientEmail,
}) {
  showDialog(
    context: context,
    builder: (context) {
      return AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.0),
        ),
        title: Row(
          children: [
            const Icon(Icons.person, color: Colors.blue),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                clientEmail,
                style: const TextStyle(fontWeight: FontWeight.bold),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 1) Medical
              ListTile(
                leading: const Icon(Icons.medical_services, color: Colors.red),
                title: const Text('Medical'),
                subtitle: const Text('View medical history & documents'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => MedicalHistoryScreen(clientUid: clientUid),
                    ),
                  );
                },
              ),
              const Divider(),
              // 2) Training
              ListTile(
                leading: const Icon(Icons.fitness_center, color: Colors.orange),
                title: const Text('Training'),
                subtitle: const Text('View training records'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => TrainingRecordsScreen(clientUid: clientUid),
                    ),
                  );
                },
              ),
              const Divider(),
              // 3) Info
              ListTile(
                leading: const Icon(Icons.info, color: Colors.blue),
                title: const Text('Information'),
                subtitle: const Text('View personal data & profile'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => AccountScreen(clientUid: clientUid),
                    ),
                  );
                },
              ),
              const Divider(),
              // 4) Measurements (NEW)
              ListTile(
                leading: const Icon(Icons.straighten, color: Colors.green),
                title: const Text('Measurements'),
                subtitle: const Text('Manage body measurements'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => MeasurementsScreen(clientUid: clientUid),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      );
    },
  );
}

  /// Compute card width based on number of clients
  double _computeCardWidth(int numClients, double screenWidth) {
    if (numClients == 1) {
      return screenWidth * 0.4;
    } else if (numClients == 2) {
      return screenWidth * 0.3;
    } else {
      return screenWidth * 0.22;
    }
  }

  /// Build a single "client" card with a gradient
  Widget _buildClientCard({
    required BuildContext context,
    required Map<String, dynamic> clientData,
    required double cardWidth,
    required double cardHeight,
  }) {
    final clientName = clientData['name'] ?? '';
    final clientEmail = clientData['email'] ?? '';
    final profileImageUrl =
        clientData['profileImageUrl'] ?? 'https://via.placeholder.com/150';

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 16.0),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20.0),
      ),
      elevation: 4,
      child: Container(
        width: cardWidth,
        height: cardHeight,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20.0),
          gradient: LinearGradient(
            colors: [Colors.blue.shade100, Colors.blue.shade300],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircleAvatar(
                backgroundImage: NetworkImage(profileImageUrl),
                radius: 30,
                onBackgroundImageError: (_, __) => const Icon(Icons.person),
              ),
              const SizedBox(height: 8),
              Text(
                clientName,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: Colors.white,
                ),
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                clientEmail,
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.white70,
                ),
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: () {
                  final clientUid = clientData['uid'] as String? ?? '';
                  _showClientOptions(
                    context,
                    clientUid: clientUid,
                    clientEmail: clientEmail,
                  );
                },
                icon: const Icon(Icons.manage_accounts, size: 16),
                label: const Text(
                  'Manage',
                  style: TextStyle(fontSize: 13),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.blue.shade800,
                  padding: const EdgeInsets.symmetric(
                    vertical: 6,
                    horizontal: 10,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// "Manage All Clients" card
  Widget _buildManageAllCard(BuildContext context, double cardWidth, double cardHeight) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 16.0),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20.0),
      ),
      elevation: 4,
      child: Container(
        width: cardWidth,
        height: cardHeight,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20.0),
          gradient: LinearGradient(
            colors: [Colors.green.shade100, Colors.green.shade300],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(20.0),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const ManageClientsScreen(),
              ),
            );
          },
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              Icon(
                Icons.group,
                size: 40,
                color: Colors.white,
              ),
              SizedBox(height: 10),
              Text(
                'Manage All Clients',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 8),
              Icon(
                Icons.arrow_forward,
                size: 24,
                color: Colors.white,
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // If the user is null, return the LoginScreen
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const LoginScreen();
    }

    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      appBar: AppBar(
        title: const Text('PT Dashboard'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Title row
            Row(
              children: [
                Text(
                  'Your Top Clients',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            FutureBuilder<List<Map<String, dynamic>>>(
              future: _fetchClients(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Center(
                    child: Column(
                      children: [
                        const SizedBox(height: 32),
                        const Text(
                          "You don't have clients",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey,
                          ),
                        ),
                        const SizedBox(height: 20),
                        ElevatedButton.icon(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const ManageClientsScreen(),
                              ),
                            );
                          },
                          icon: const Icon(Icons.add),
                          label: const Text('Add Clients'),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              vertical: 12,
                              horizontal: 24,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12.0),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }

                final clients = snapshot.data!;
                final cardWidth = _computeCardWidth(clients.length, screenWidth);
                const cardHeight = 220.0;

                return Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Show up to 3 client cards
                    ...clients.map((client) {
                      return GestureDetector(
                        onTap: () {
                          final clientUid = client['uid'] as String? ?? '';
                          final clientEmail = client['email'] ?? 'No Email';
                          _showClientOptions(
                            context,
                            clientUid: clientUid,
                            clientEmail: clientEmail,
                          );
                        },
                        child: _buildClientCard(
                          context: context,
                          clientData: client,
                          cardWidth: cardWidth,
                          cardHeight: cardHeight,
                        ),
                      );
                    }).toList(),

                    // "Manage All Clients" card
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const ManageClientsScreen(),
                          ),
                        );
                      },
                      child: _buildManageAllCard(context, cardWidth, cardHeight),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
