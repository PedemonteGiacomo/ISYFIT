import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:isyfit/screens/measurements_home_screen.dart';
import 'package:isyfit/screens/medical_history/medical_history_screen.dart';
import 'package:isyfit/screens/training_records_screen.dart';
import 'package:isyfit/screens/account_screen.dart';
import 'package:intl/intl.dart';

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
  bool _showPayments = false;
  final Map<String, Map<String, dynamic>> _paymentData = {};

  Future<void> _addClient() async {
    if (_emailController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid email address.')),
      );
      return;
    }

    setState(() => _isAddingClient = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('User not authenticated.');

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

      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .update({'clients': FieldValue.arrayUnion([clientId])});

      await FirebaseFirestore.instance
          .collection('users')
          .doc(clientId)
          .update({'isSolo': false, 'supervisorPT': user.uid});

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
      setState(() => _isAddingClient = false);
    }
  }

  Future<void> _removeClient(String clientId) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('User not authenticated.');

      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .update({'clients': FieldValue.arrayRemove([clientId])});

      await FirebaseFirestore.instance
          .collection('users')
          .doc(clientId)
          .update({'isSolo': true, 'supervisorPT': FieldValue.delete()});

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
        final theme = Theme.of(context);
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(25.0),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: _emailController,
                  decoration: const InputDecoration(
                    labelText: 'Client Email',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                  ),
                  onPressed: () {
                    Navigator.pop(context);
                    _addClient();
                  },
                  child: const Text("Add Client"),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Show popup options for a client
  void _showClientOptions(
    BuildContext context,
    String clientUid,
    String clientName,
    String clientSurname,
  ) {
    final theme = Theme.of(context);
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(
            '$clientName $clientSurname',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: Icon(
                  Icons.medical_services,
                  color: theme.colorScheme.error, // was red
                ),
                title: const Text('Medical'),
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
              ListTile(
                leading: Icon(
                  Icons.fitness_center,
                  color: theme.colorScheme.primary, // was orange
                ),
                title: const Text('Training'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          TrainingRecordsScreen(clientUid: clientUid),
                    ),
                  );
                },
              ),
              ListTile(
                leading: Icon(
                  Icons.info,
                  color: theme.colorScheme.primary, // was blue
                ),
                title: const Text('Info'),
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
                leading: Icon(
                  Icons.straighten,
                  color: theme.colorScheme.primary, // was green
                ),
                title: const Text('Measurements'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => MeasurementsHomeScreen(clientUid: clientUid),
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

  Widget _buildClientList(List<dynamic> clientIds) {
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
            if (clientSnapshot.connectionState == ConnectionState.waiting) {
              return const ListTile(title: LinearProgressIndicator());
            }
            if (!clientSnapshot.hasData || clientSnapshot.data == null) {
              return const SizedBox.shrink();
            }
            final clientData =
                clientSnapshot.data!.data() as Map<String, dynamic>;
            final clientName = clientData['name'] ?? 'Unknown';
            final clientSurname = clientData['surname'] ?? 'Unknown';
            final query = '$clientName $clientSurname'.toLowerCase();
            if (!query.contains(_searchQuery)) {
              return const SizedBox.shrink();
            }
            return _buildClientTile(clientData, clientSnapshot.data!.id);
          },
        );
      },
    );
  }

  Widget _buildClientTile(Map<String, dynamic> clientData, String clientUid) {
    final theme = Theme.of(context);
    return Card(
      color: theme.colorScheme.surface,
      margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
      child: ListTile(
        leading: CircleAvatar(
          backgroundImage: NetworkImage(
            clientData['profileImageUrl'] ?? 'https://via.placeholder.com/150',
          ),
          onBackgroundImageError: (_, __) => const Icon(Icons.person),
        ),
        title: Text(
          '${clientData['name'] ?? ''} ${clientData['surname'] ?? ''}',
          style: theme.textTheme.bodyLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(clientData['email'] ?? 'No Email'),
        onTap: () => _showClientOptions(
          context,
          clientUid,
          clientData['name'] ?? 'Unknown',
          clientData['surname'] ?? 'Unknown',
        ),
        trailing: IconButton(
          icon: Icon(Icons.remove_circle, color: theme.colorScheme.error),
          onPressed: () => _removeClient(clientUid),
        ),
      ),
    );
  }

  Widget _buildPaymentsTable(List<dynamic> clientIds) {
    return FutureBuilder<Map<String, Map<String, dynamic>>>(
      future: _fetchPaymentData(clientIds),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }
        final paymentDataMap = snapshot.data!;
        return _buildEditableDataTable(paymentDataMap, clientIds);
      },
    );
  }

  Future<Map<String, Map<String, dynamic>>> _fetchPaymentData(
      List<dynamic> clientIds) async {
    final Map<String, Map<String, dynamic>> paymentDataMap = {};
    for (final clientId in clientIds) {
      final paymentQuery = await FirebaseFirestore.instance
          .collection('payments')
          .where('clientUid', isEqualTo: clientId)
          .get();
      if (paymentQuery.docs.isNotEmpty) {
        paymentDataMap[clientId] = paymentQuery.docs.first.data();
      }
    }
    return paymentDataMap;
  }

  Widget _buildEditableDataTable(
    Map<String, Map<String, dynamic>> paymentDataMap,
    List<dynamic> clientIds,
  ) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SingleChildScrollView(
        scrollDirection: Axis.vertical,
        child: DataTable(
          columns: const [
            DataColumn(label: Text('Client')),
            DataColumn(label: Text('Amount')),
            DataColumn(label: Text('Date')),
            DataColumn(label: Text('Method')),
            DataColumn(label: Text('Object')),
            DataColumn(label: Text('Edit')),
          ],
          rows: clientIds.map((clientId) {
            final paymentData = paymentDataMap[clientId] ?? {};
            final clientNameFuture = _getClientNameFromUid(clientId);
            return DataRow(cells: [
              DataCell(
                FutureBuilder<String>(
                  future: clientNameFuture,
                  builder: (context, nameSnapshot) {
                    return Text(nameSnapshot.data ?? 'Loading...');
                  },
                ),
              ),
              DataCell(
                  _buildEditableField(clientId, 'amount', paymentData['amount'])),
              DataCell(_buildEditableDateField(clientId, 'date', paymentData['date'])),
              DataCell(_buildEditableField(clientId, 'method', paymentData['method'])),
              DataCell(_buildEditableField(clientId, 'object', paymentData['object'])),
              DataCell(
                IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: () => _editPayment(clientId),
                ),
              ),
            ]);
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildEditableField(String documentId, String field, dynamic value) {
    return TextFormField(
      initialValue: value?.toString() ?? '',
      decoration: const InputDecoration(border: InputBorder.none),
      onChanged: (newValue) => _updatePaymentField(documentId, field, newValue),
    );
  }

  Widget _buildEditableDateField(String documentId, String field, Timestamp? value) {
    final formattedDate =
        value != null ? DateFormat('yyyy-MM-dd').format(value.toDate()) : '';
    return TextFormField(
      initialValue: formattedDate,
      decoration: const InputDecoration(border: InputBorder.none),
      onChanged: (newValue) {
        try {
          final newDate = DateFormat('yyyy-MM-dd').parse(newValue);
          _updatePaymentField(documentId, field, Timestamp.fromDate(newDate));
        } catch (_) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Invalid date format. Use yyyy-MM-dd'),
            ),
          );
        }
      },
    );
  }

  void _updatePaymentField(String paymentId, String field, dynamic newValue) {
    if (_paymentData.containsKey(paymentId)) {
      setState(() => _paymentData[paymentId]![field] = newValue);
    }
    FirebaseFirestore.instance
        .collection('payments')
        .doc(paymentId)
        .set({field: newValue}, SetOptions(merge: true));
  }

  Future<String> _getClientNameFromUid(String clientUid) async {
    final userSnapshot =
        await FirebaseFirestore.instance.collection('users').doc(clientUid).get();
    if (userSnapshot.exists) {
      final userData = userSnapshot.data() as Map<String, dynamic>;
      return '${userData['name'] ?? ''} ${userData['surname'] ?? ''}';
    }
    return 'Unknown Client';
  }

  void _editPayment(String clientId) {
    // Implement your edit logic here
  }

  @override
  void dispose() {
    _emailController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final currentUser = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Clients'),
        centerTitle: true,
        backgroundColor: theme.colorScheme.primary,
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
          Text(
            'Add New Client',
            style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.bold),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              onChanged: (value) => setState(() => _searchQuery = value.trim().toLowerCase()),
              decoration: InputDecoration(
                labelText: 'Search Clients',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.0),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  _showPayments ? 'Payments' : 'Manage Clients',
                  style: theme.textTheme.titleSmall,
                ),
              ],
            ),
          ),
          const Divider(),
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

                final ptData = snapshot.data!.data() as Map<String, dynamic>;
                final clientIds = ptData['clients'] as List<dynamic>? ?? [];

                if (clientIds.isEmpty && !_showPayments) {
                  return const Center(child: Text('No clients to manage.'));
                } else if (clientIds.isEmpty && _showPayments) {
                  return const Center(child: Text('No payment data available.'));
                }

                return _showPayments
                    ? _buildPaymentsTable(clientIds)
                    : _buildClientList(clientIds);
              },
            ),
          ),
        ],
      ),
    );
  }
}
