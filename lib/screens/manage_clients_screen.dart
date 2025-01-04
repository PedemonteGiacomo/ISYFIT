import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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

      // Add the client to the PT's list
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .update({
        'clients': FieldValue.arrayUnion([clientId])
      });

      // Update the client's supervisor field
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

  Future<void> _removeClient(String clientId) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('User not authenticated.');
      }

      // Remove the client from the PT's list
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .update({
        'clients': FieldValue.arrayRemove([clientId])
      });

      // Remove the PT reference from the client's document
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
            constraints: const BoxConstraints(
              maxWidth: 400, // Reduce the width of the dialog
            ),
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
                        color: Colors.indigo.withOpacity(0.8),
                        width: 2.0,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Action Buttons with Equal Width
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
                          Navigator.pop(context);
                          await _addClient();
                        },
                        icon: const Icon(Icons.person_add_alt,
                            color: Colors.white),
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

  @override
  Widget build(BuildContext context) {
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
          const SizedBox(height: 8), // Add spacing between button and text
          const Text(
            'Add New Client',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
          ),
        ],
      ),
      body: Column(
        children: [
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
          Expanded(
            child: FutureBuilder<DocumentSnapshot>(
              future: FirebaseFirestore.instance
                  .collection('users')
                  .doc(FirebaseAuth.instance.currentUser!.uid)
                  .get(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data == null) {
                  return const Center(
                    child: Text('No data found.'),
                  );
                }

                final ptData = snapshot.data!.data() as Map<String, dynamic>;
                final clientIds = ptData['clients'] as List<dynamic>? ?? [];

                if (clientIds.isEmpty) {
                  return const Center(
                    child: Text('No clients to manage.'),
                  );
                }

                return ListView.builder(
                  itemCount: clientIds.length,
                  itemBuilder: (context, index) {
                    return FutureBuilder<DocumentSnapshot>(
                      future: FirebaseFirestore.instance
                          .collection('users')
                          .doc(clientIds[index])
                          .get(),
                      builder: (context, clientSnapshot) {
                        if (!clientSnapshot.hasData) {
                          return const SizedBox.shrink();
                        }

                        final clientData =
                            clientSnapshot.data!.data() as Map<String, dynamic>;

                        // Apply search filter
                        final clientName =
                            '${clientData['name']} ${clientData['surname']}';
                        if (!clientName.toLowerCase().contains(_searchQuery)) {
                          return const SizedBox.shrink();
                        }

                        return Card(
                          margin: const EdgeInsets.symmetric(
                              horizontal: 8.0, vertical: 4.0),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundImage: NetworkImage(
                                clientData['profileImageUrl'] ??
                                    'https://via.placeholder.com/150',
                              ),
                              onBackgroundImageError: (_, __) =>
                                  const Icon(Icons.person),
                            ),
                            title: Text(
                              '${clientData['name']?.isNotEmpty == true ? clientData['name'] : ''} ${clientData['surname']?.isNotEmpty == true ? clientData['surname'] : ''}',
                            ),
                            subtitle: Text(clientData['email']),
                            trailing: IconButton(
                              icon: const Icon(Icons.remove_circle,
                                  color: Colors.red),
                              onPressed: () => _removeClient(clientIds[index]),
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
