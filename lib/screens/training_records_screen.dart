import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:isyfit/screens/login_screen.dart';

// Example of a TrainingRecordsScreen that can handle both
//  - the current user (clientUid == null)
//  - or a specific client (clientUid != null) if a PT opens it.

class TrainingRecordsScreen extends StatefulWidget {
  final String? clientUid; 
  // If null, uses the logged-in user's data.
  // If not null, the PT is viewing that user's training data.

  const TrainingRecordsScreen({Key? key, this.clientUid}) : super(key: key);

  @override
  State<TrainingRecordsScreen> createState() => _TrainingRecordsScreenState();
}

class _TrainingRecordsScreenState extends State<TrainingRecordsScreen> {
  // If this is false, we won't show "Add plan," etc.
  // You can decide if the PT can add plans for their clients or not.
  bool get isOwnAccount {
    final currentUser = FirebaseAuth.instance.currentUser;
    final uid = currentUser?.uid;
    // If clientUid is null or equals the current user's UID => own account
    if (widget.clientUid == null || widget.clientUid == uid) {
      return true;
    }
    return false;
  }

  /// Returns either [widget.clientUid] if not null, or the current user's uid otherwise.
  String? get targetUid {
    final user = FirebaseAuth.instance.currentUser;
    return widget.clientUid ?? user?.uid;
  }

  // For PT viewing a client's data, we fetch name + email
  bool get isPTView => widget.clientUid != null;

  // We'll store the future that fetches client doc
  late Future<Map<String, dynamic>?>? _clientProfileFuture;

  @override
  void initState() {
    super.initState();
    if (isPTView) {
      _clientProfileFuture = _fetchClientProfile();
    } else {
      _clientProfileFuture = null;
    }
  }

  /// If PT is viewing a client, fetch that client's name and email
  Future<Map<String, dynamic>?> _fetchClientProfile() async {
    if (targetUid == null) return null;
    final docSnap = await FirebaseFirestore.instance
        .collection('users')
        .doc(targetUid)
        .get();
    return docSnap.data();
  }

  @override
  Widget build(BuildContext context) {
    // If there's no user & no clientUid, we cannot load anything
    if (targetUid == null) {
      return const LoginScreen();
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Training Records'),
        centerTitle: true,
      ),
      body: isPTView
          ? // If PT is viewing, show a profile future + the main content
          FutureBuilder<Map<String, dynamic>?>(
            future: _clientProfileFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              final clientData = snapshot.data;
              return _buildMainContent(context, clientData: clientData);
            },
          )
          : // If it's the user's own account, just build main content with no profile header
          _buildMainContent(context, clientData: null),
    );
  }

  /// Builds the **entire** screen content, optionally showing a client header
  Widget _buildMainContent(BuildContext context, {Map<String, dynamic>? clientData}) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (clientData != null) _buildClientHeader(context, clientData),
            // Overview Section
            _buildSectionTitle('Overview'),
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Manage and track training progress effectively.',
                      style: TextStyle(fontSize: 16),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      isOwnAccount
                          ? 'This section provides insights into your training plans, progress updates, and session history.'
                          : 'This section provides insights into your client’s training plans, progress updates, and session history.',
                      style: const TextStyle(fontSize: 14, color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Recent Training Sessions Section
            _buildSectionTitle('Recent Training Sessions'),
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    _buildListTile(
                      title: 'John Doe - Session: Dec 29, 2024',
                      subtitle: 'Focus: Strength Training',
                      icon: Icons.person,
                      onTap: () {
                        // For example, open a detail screen
                        Navigator.pushNamed(context, '/client-training-detail');
                      },
                    ),
                    _buildListTile(
                      title: 'Jane Smith - Session: Dec 28, 2024',
                      subtitle: 'Focus: Cardio',
                      icon: Icons.person,
                      onTap: () {
                        Navigator.pushNamed(context, '/client-training-detail');
                      },
                    ),
                    _buildListTile(
                      title: 'Tom Brown - Session: Dec 27, 2024',
                      subtitle: 'Focus: Flexibility',
                      icon: Icons.person,
                      onTap: () {
                        Navigator.pushNamed(context, '/client-training-detail');
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Actions Section
            _buildSectionTitle('Actions'),
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    // "Create New Training Plan"
                    if (isOwnAccount) ...[
                      _buildActionButton(
                        label: 'Create New Training Plan',
                        icon: Icons.add_circle_outline,
                        onPressed: () {
                          Navigator.pushNamed(context, '/create-training-plan');
                        },
                      ),
                      const SizedBox(height: 12),
                    ],
                    _buildActionButton(
                      label: 'View All Training Records',
                      icon: Icons.search,
                      onPressed: () {
                        Navigator.pushNamed(context, '/all-training-records');
                      },
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// If PT is viewing a client, show a small header with name + email
  Widget _buildClientHeader(BuildContext context, Map<String, dynamic> clientData) {
    final clientName = clientData['name'] ?? 'Unknown Name';
    final clientEmail = clientData['email'] ?? 'Unknown Email';

    return Container(
      margin: const EdgeInsets.only(bottom: 16.0),
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.deepPurple.shade50,
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(
          color: Colors.deepPurple.shade100,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: Colors.deepPurple.shade100,
            child: const Icon(Icons.person, color: Colors.white),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  clientName,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.deepPurple.shade700,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  clientEmail,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.deepPurple.shade400,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildListTile({
    required String title,
    required String subtitle,
    required IconData icon,
    VoidCallback? onTap,
  }) {
    return ListTile(
      leading: Icon(icon, size: 32),
      title: Text(title, style: const TextStyle(fontSize: 16)),
      subtitle: Text(subtitle, style: const TextStyle(color: Colors.grey)),
      trailing: const Icon(Icons.arrow_forward),
      onTap: onTap,
    );
  }

  Widget _buildActionButton({
    required String label,
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    return ElevatedButton.icon(
      icon: Icon(icon, size: 20),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      onPressed: onPressed,
    );
  }
}
