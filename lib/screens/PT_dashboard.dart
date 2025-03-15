import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:isyfit/screens/login_screen.dart';
import 'package:isyfit/screens/measurements/measurements_home_screen.dart';
import 'manage_clients_screen.dart';
import 'package:isyfit/screens/medical_history/medical_history_screen.dart';
import 'package:isyfit/screens/account/account_screen.dart';
import 'package:isyfit/screens/isy_training/isy_training_main_screen.dart';
import 'package:isyfit/screens/isy_check/isy_check_main_screen.dart';


class PTDashboard extends StatelessWidget {
  const PTDashboard({Key? key}) : super(key: key);

  /// Fetch logged-in user's name
  Future<String> _fetchUserName() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return "User";
    }
    final userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();
    return userDoc.data()?['name'] ?? "User";
  }

  /// Fetch the last 3 clients
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

    final clientIds = (ptData['clients'] as List<dynamic>).take(3).toList();
    List<Map<String, dynamic>> clients = [];

    for (String clientId in clientIds) {
      final clientDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(clientId)
          .get();

      if (clientDoc.exists) {
        final clientData = clientDoc.data() as Map<String, dynamic>;
        clientData['uid'] = clientId;
        clients.add(clientData);
      }
    }
    return clients;
  }

  /// Show popup with 4 options
  void _showClientOptions(
    BuildContext context, {
    required String clientUid,
    required String clientName,
    required String clientSurname,
  }) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.0),
          ),
          title: Text(
            clientName + " " + clientSurname,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.fitness_center, color: Colors.orange),
                title: const Text('isy-training'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          IsyTrainingMainScreen(clientUid: clientUid),
                    ),
                  );
                },
              ),       
              ListTile(
                leading: const Icon(Icons.straighten, color: Colors.green),
                title: const Text('isy-lab'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          MeasurementsHomeScreen(clientUid: clientUid),
                    ),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.medical_services, color: Colors.red),
                title: const Text('isi-check'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          IsyCheckMainScreen(clientUid: clientUid),
                    ),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.info, color: Colors.blue),
                title: const Text('account'),
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
            ],
          ),
        );
      },
    );
  }

  Widget _buildClientList(BuildContext context) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _fetchClients(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(
            child: Text(
              "No clients available",
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
          );
        }

        final clients = snapshot.data!;
        return Column(
          children: [
            ...clients.map((client) {
              final clientName = client['name'] ?? ' ';
              final clientSurname = client['surname'] ?? ' ';
              final isPaying = client['isPaying'] ?? false;

              return InkWell(
                onTap: () {
                  _showClientOptions(
                    context,
                    clientUid: client['uid'],
                    clientName: clientName,
                    clientSurname: clientSurname,
                  );
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 20,
                        child: Text(
                          clientName.isNotEmpty
                              ? clientName[0].toUpperCase() +
                                  clientSurname[0].toUpperCase()
                              : 'U',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        backgroundColor: Colors.blue.shade400,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          clientName + " " + clientSurname,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Column(
                        children: [
                          Container(
                            width: 16,
                            height: 16,
                            decoration: BoxDecoration(
                              color: isPaying ? Colors.green : Colors.red,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            isPaying ? 'Paying' : 'Not Paying',
                            style: TextStyle(
                              fontSize: 12,
                              color: isPaying ? Colors.green : Colors.red,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
            const SizedBox(height: 12),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      appBar: AppBar(
        title: Text('PT Dashboard',
            style: TextStyle(color: Theme.of(context).colorScheme.onPrimary)),
        centerTitle: true,
        backgroundColor: Theme.of(context).colorScheme.primary,
        iconTheme: IconThemeData(
          color: Theme.of(context).colorScheme.onPrimary,
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: FutureBuilder<String>(
            future: _fetchUserName(),
            builder: (context, snapshot) {
              final userName =
                  snapshot.connectionState == ConnectionState.done &&
                          snapshot.hasData
                      ? snapshot.data!
                      : "User";

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 30,
                        backgroundColor: Colors.grey.shade300,
                        child: const Icon(
                          Icons.person,
                          size: 30,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Text(
                        "Welcome $userName",
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Search and actions
                  // Row(
                  //   children: [
                  //     Expanded(
                  //       child: TextField(
                  //         decoration: InputDecoration(
                  //           hintText: "Search...",
                  //           prefixIcon: const Icon(Icons.search),
                  //           border: OutlineInputBorder(
                  //             borderRadius: BorderRadius.circular(12.0),
                  //           ),
                  //         ),
                  //       ),
                  //     ),
                  //     const SizedBox(width: 8),
                  //     ElevatedButton.icon(
                  //       onPressed: () {},
                  //       icon: const Icon(Icons.add),
                  //       label: const Text("Add New"),
                  //     ),
                  //     const SizedBox(width: 8),
                  //     ElevatedButton(
                  //       onPressed: () {},
                  //       child: const Text("Filter"),
                  //     ),
                  //   ],
                  // ),
                  // const SizedBox(height: 16),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Recent Clients",
                        style:
                            Theme.of(context).textTheme.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                      ),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const ManageClientsScreen(),
                            ),
                          );
                        },
                        child: Text("View All", style: TextStyle(color: Theme.of(context).colorScheme.onPrimary)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ConstrainedBox(
                    constraints: BoxConstraints(
                      maxHeight: screenHeight * 0.4,
                    ),
                    child: SingleChildScrollView(
                      child: _buildClientList(context),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Weekly Checks Placeholder
                  // const Divider(thickness: 1.5),
                  const SizedBox(height: 16),
                  const Text(
                    "All Weekly Checks",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
