import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

// Your other local screens
import 'package:isyfit/screens/isy_lab/isy_lab_main_screen.dart';
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

  /// When tapping a client from the "Recent" list, let the PT choose which
  /// area to go to: isy-training, isy-lab, etc.
  void _showClientOptions(
    BuildContext context, {
    required String clientUid,
    required String clientName,
    required String clientSurname,
  }) {
    showDialog(
      context: context,
      builder: (context) {
        final theme = Theme.of(context);
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.0),
          ),
          surfaceTintColor: theme.colorScheme.surface,
          title: Text(
            "$clientName $clientSurname",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.primary,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: Icon(Icons.fitness_center,
                    color: theme.colorScheme.primary),
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
                leading: Icon(Icons.straighten,
                    color: theme.colorScheme.secondary),
                title: const Text('isy-lab'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => IsyLabMainScreen(clientUid: clientUid),
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
                leading: Icon(Icons.info, color: theme.colorScheme.tertiary),
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

  /// Builds the list of up to 3 recent clients
  Widget _buildClientList(BuildContext context) {
    final theme = Theme.of(context);

    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _fetchClients(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
            child: CircularProgressIndicator(color: theme.colorScheme.primary),
          );
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
            for (final client in clients) ...[
              _buildClientRow(context, client),
            ],
          ],
        );
      },
    );
  }

  /// Renders a single row for a client, with avatar + pay status
  Widget _buildClientRow(BuildContext context, Map<String, dynamic> client) {
    final theme = Theme.of(context);
    final String clientName = client['name'] ?? ' ';
    final String clientSurname = client['surname'] ?? ' ';
    final bool isPaying = client['isPaying'] ?? false;

    return InkWell(
      onTap: () {
        _showClientOptions(
          context,
          clientUid: client['uid'],
          clientName: clientName,
          clientSurname: clientSurname,
        );
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: theme.colorScheme.primary.withOpacity(0.05),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            // Avatar with initials
            CircleAvatar(
              radius: 22,
              backgroundColor: theme.colorScheme.primary.withOpacity(0.75),
              child: Text(
                _buildClientInitials(clientName, clientSurname),
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(width: 16),
            // Client name
            Expanded(
              child: Text(
                "$clientName $clientSurname",
                style: theme.textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            // Payment status
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    color: isPaying ? Colors.green : theme.colorScheme.error,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  isPaying ? 'Paying' : 'Not Paying',
                  style: TextStyle(
                    fontSize: 12,
                    color: isPaying ? Colors.green : theme.colorScheme.error,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Build 2-letter initials from name + surname
  String _buildClientInitials(String name, String surname) {
    if (name.isNotEmpty && surname.isNotEmpty) {
      return name[0].toUpperCase() + surname[0].toUpperCase();
    }
    return 'U';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const LoginScreen();
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'PT Dashboard',
          style: TextStyle(color: colorScheme.onPrimary),
        ),
        centerTitle: true,
        backgroundColor: colorScheme.primary,
        iconTheme: IconThemeData(color: colorScheme.onPrimary),
      ),
      body: FutureBuilder<String>(
        future: _fetchUserName(),
        builder: (context, snapshot) {
          final userName =
              snapshot.connectionState == ConnectionState.done &&
                      snapshot.hasData
                  ? snapshot.data!
                  : "User";

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                /// 1) "Welcome" Card
                Card(
                  // This uses the M3 card shape from your theme or you can override:
                  margin: EdgeInsets.zero,
                  shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  ),
                  child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                      Theme.of(context).colorScheme.primary,
                      Theme.of(context).colorScheme.primary.withOpacity(0.6),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    ),
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                    children: [
                      CircleAvatar(
                      radius: 28,
                      backgroundColor:
                        Theme.of(context).colorScheme.onPrimary,
                      child: Icon(
                        Icons.person,
                        size: 30,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                      child: Text(
                        "Welcome, $userName",
                        style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.onPrimary,
                        ),
                      ),
                      ),
                    ],
                    ),
                  ),
                  ),
                ),

                const SizedBox(height: 24),

                /// 2) Recent Clients + "View All" Button
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Recent Clients",
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    // We'll use a FilledButton (Material 3)
                    FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: colorScheme.primary,
                        foregroundColor: colorScheme.onPrimary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const ManageClientsScreen(),
                          ),
                        );
                      },
                      child: const Text("View All"),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                /// 3) Card containing the clients list
                Card(
                  margin: EdgeInsets.zero,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: _buildClientList(context),
                  ),
                ),

                const SizedBox(height: 32),

                /// 4) Weekly Checks placeholder
                Row(
                  children: [
                    Icon(Icons.check_circle_outline,
                        color: colorScheme.primary),
                    const SizedBox(width: 8),
                    Text(
                      "All Weekly Checks",
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: colorScheme.primary.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    "This is a placeholder for weekly checks data.",
                    style: theme.textTheme.bodyMedium,
                  ),
                ),

                const SizedBox(height: 32),
              ],
            ),
          );
        },
      ),

      // /// 5) FAB (optional) to add new clients or handle other actions
      // floatingActionButton: FloatingActionButton.extended(
      //   onPressed: () {
      //     // Example: jump to client creation or ManageClientsScreen
      //     Navigator.push(
      //       context,
      //       MaterialPageRoute(builder: (_) => const ManageClientsScreen()),
      //     );
      //   },
      //   icon: const Icon(Icons.group_add),
      //   label: const Text("Add Client"),
      //   backgroundColor: colorScheme.primary,
      //   foregroundColor: colorScheme.onPrimary,
      // ),
    );
  }
}
