import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:isyfit/screens/measurements_screen.dart';
import 'package:isyfit/screens/medical_history/medical_history_screen.dart';
import 'package:isyfit/screens/training_records_screen.dart';  
import 'package:isyfit/screens/account_screen.dart';

class ManageClientsScreen extends StatefulWidget {
  const ManageClientsScreen({Key? key}) : super(key: key);

  @override
  State<ManageClientsScreen> createState() => _ManageClientsScreenState();
}

class _ManageClientsScreenState extends State<ManageClientsScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();

  bool _isAddingClient = false;
  String _searchQuery = "";

  /// Add a new client by email (already existing in the system as a Client).
  Future<void> _addClient() async {
    if (_emailController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid email address.')),
      );
      return;
    }

    setState(() {
      _isAddingClient = true;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('User not authenticated.');
      }

      // Query Firestore for a Client with the given email
      final clientQuery = await FirebaseFirestore.instance
          .collection('users')
          .where('email', isEqualTo: _emailController.text.trim())
          .where('role', isEqualTo: 'Client')
          .get();

      if (clientQuery.docs.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No client found with this email.')),
        );
        return;
      }

      final clientDoc = clientQuery.docs.first;
      final clientId = clientDoc.id;

      // Add the client to the PT's 'clients' array
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .update({
        'clients': FieldValue.arrayUnion([clientId])
      });

      // Update the client’s doc so they’re not solo, point to this PT
      await FirebaseFirestore.instance
          .collection('users')
          .doc(clientId)
          .update({
        'isSolo': false,
        'supervisorPT': user.uid,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Client added successfully!')),
      );

      _emailController.clear();
      setState(() {});
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error adding client: $e')),
      );
    } finally {
      setState(() {
        _isAddingClient = false;
      });
    }
  }

  /// Remove the client from this PT's list, and reset the client's doc to solo
  Future<void> _removeClient(String clientId) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('User not authenticated.');
      }

      // Remove client from PT's array
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .update({
        'clients': FieldValue.arrayRemove([clientId])
      });

      // Reset the client doc
      await FirebaseFirestore.instance
          .collection('users')
          .doc(clientId)
          .update({
        'isSolo': true,
        'supervisorPT': FieldValue.delete(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Client removed successfully!')),
      );

      setState(() {});
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error removing client: $e')),
      );
    }
  }

  /// Show a dialog to enter the client's email
  void _showAddClientDialog() {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(25.0),
          ),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 400),
            padding: const EdgeInsets.all(20.0),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(25.0),
              gradient: LinearGradient(
                colors: [Colors.white, Colors.blueGrey.shade50],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header Icon
                Container(
                  decoration: BoxDecoration(
                    color: Colors.indigoAccent.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  padding: const EdgeInsets.all(12.0),
                  child: const Icon(
                    Icons.person_add_alt_1,
                    color: Colors.indigo,
                    size: 40,
                  ),
                ),
                const SizedBox(height: 16),

                // Dialog Title
                const Text(
                  'Add New Client',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.indigo,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                const Text(
                  'Enter the client’s email to assign them to your list.',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),

                // Email Input Field
                TextField(
                  controller: _emailController,
                  decoration: InputDecoration(
                    labelText: 'Client Email',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15.0),
                    ),
                    prefixIcon: const Icon(Icons.email_outlined),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(
                        color: Colors.indigoAccent,
                        width: 2.0,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Action Buttons
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                        },
                        icon: const Icon(Icons.cancel, color: Colors.white),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.redAccent,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12.0),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15.0),
                          ),
                        ),
                        label: const Text('Cancel'),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          Navigator.pop(context); // close the dialog
                          await _addClient();
                        },
                        icon: const Icon(Icons.person_add_alt, color: Colors.white),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.indigoAccent,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12.0),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15.0),
                          ),
                        ),
                        label: const Text('Add Client'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Show the popup with Medical, Fitness, Info for the chosen client
  void _showClientOptions(BuildContext context, String clientUid, String clientEmail) {
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
                    Navigator.pop(context); // close dialog
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => MedicalHistoryScreen(clientUid: clientUid),
                      ),
                    );
                  },
                ),
                const Divider(),
                // 2) Fitness
                ListTile(
                  leading: const Icon(Icons.fitness_center, color: Colors.orange),
                  title: const Text('Fitness'),
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

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Clients'),
        centerTitle: true,
      ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton(
            onPressed: _showAddClientDialog,
            child: const Icon(Icons.add),
          ),
          const SizedBox(height: 8),
          const Text(
            'Add New Client',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
          ),
        ],
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              onChanged: (value) {
                setState(() {
                  _searchQuery = value.trim().toLowerCase();
                });
              },
              decoration: const InputDecoration(
                labelText: 'Search Clients',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
            ),
          ),
          const Divider(),
          // Display the PT’s clients
          Expanded(
            child: FutureBuilder<DocumentSnapshot>(
              future: currentUser == null
                  ? null
                  : FirebaseFirestore.instance
                      .collection('users')
                      .doc(currentUser.uid)
                      .get(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data == null) {
                  return const Center(child: Text('No data found.'));
                }

                // The PT doc
                final ptData = snapshot.data!.data() as Map<String, dynamic>;
                final clientIds = ptData['clients'] as List<dynamic>? ?? [];

                if (clientIds.isEmpty) {
                  return const Center(child: Text('No clients to manage.'));
                }

                // Build a list of all clients
                return ListView.builder(
                  itemCount: clientIds.length,
                  itemBuilder: (context, index) {
                    final clientId = clientIds[index];
                    return FutureBuilder<DocumentSnapshot>(
                      future: FirebaseFirestore.instance
                          .collection('users')
                          .doc(clientId)
                          .get(),
                      builder: (context, clientSnapshot) {
                        if (!clientSnapshot.hasData) {
                          return const SizedBox.shrink();
                        }
                        final clientData =
                            clientSnapshot.data!.data() as Map<String, dynamic>;

                        // Filter by search query
                        final clientName =
                            '${clientData['name'] ?? ''} ${clientData['surname'] ?? ''}';
                        if (!clientName.toLowerCase().contains(_searchQuery)) {
                          return const SizedBox.shrink();
                        }

                        // Build the client tile
                        return Card(
                          margin: const EdgeInsets.symmetric(
                            horizontal: 8.0,
                            vertical: 4.0,
                          ),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundImage: NetworkImage(
                                clientData['profileImageUrl'] ??
                                    'https://via.placeholder.com/150',
                              ),
                              onBackgroundImageError: (_, __) =>
                                  const Icon(Icons.person),
                            ),
                            title: Text(clientName.trim()),
                            subtitle: Text(clientData['email'] ?? 'No Email'),
                            onTap: () {
                              // Show the popup with Medical, Fitness, Info
                              _showClientOptions(
                                context,
                                clientSnapshot.data!.id,
                                clientData['email'] ?? '',
                              );
                            },
                            trailing: IconButton(
                              icon:
                                  const Icon(Icons.remove_circle, color: Colors.red),
                              onPressed: () => _removeClient(clientId),
                            ),
                          ),
                        );
                      },
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
