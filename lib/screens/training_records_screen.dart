import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:isyfit/screens/login_screen.dart';

class TrainingRecordsScreen extends StatefulWidget {
  /// If `clientUid` is null, it uses the currently logged-in user.
  /// If not null, it means a PT is viewing a specific client's records.
  final String? clientUid;

  const TrainingRecordsScreen({Key? key, this.clientUid}) : super(key: key);

  @override
  State<TrainingRecordsScreen> createState() => _TrainingRecordsScreenState();
}

class _TrainingRecordsScreenState extends State<TrainingRecordsScreen> {
  /// Check if the user is looking at their own data
  bool get isOwnAccount {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return false;
    // If clientUid is null or matches current user => own account
    return widget.clientUid == null || widget.clientUid == currentUser.uid;
  }

  /// Return `widget.clientUid` if not null, else the current user's UID.
  String? get targetUid {
    final user = FirebaseAuth.instance.currentUser;
    return widget.clientUid ?? user?.uid;
  }

  /// If `clientUid` is non-null, we assume a PT is viewing a client's records.
  bool get isPTView => widget.clientUid != null;

  /// Store a Future that fetches the client's profile if a PT is viewing it.
  late final Future<Map<String, dynamic>?>? _clientProfileFuture;

  @override
  void initState() {
    super.initState();
    if (isPTView) {
      _clientProfileFuture = _fetchClientProfile();
    } else {
      _clientProfileFuture = null;
    }
  }

  /// Fetch client profile data if PT is viewing
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
    // If we have no user and no clientUid, we must prompt for login
    if (targetUid == null) {
      return const LoginScreen();
    }

    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('Training Records',
            style: TextStyle(color: Theme.of(context).colorScheme.onPrimary)),
        centerTitle: true,
        backgroundColor: theme.colorScheme.primary,
        iconTheme: IconThemeData(
          color: Theme.of(context).colorScheme.onPrimary,
        ),
      ),
      body: isPTView
          ? FutureBuilder<Map<String, dynamic>?>(
              future: _clientProfileFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                final clientData = snapshot.data;
                return _buildMainContent(context, clientData: clientData);
              },
            )
          : _buildMainContent(context, clientData: null),
    );
  }

  /// Builds the entire screen content
  Widget _buildMainContent(
    BuildContext context, {
    Map<String, dynamic>? clientData,
  }) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (clientData != null) _buildClientHeader(context, clientData),

            // Overview
            _buildSectionTitle(context, 'Overview'),
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: _buildOverviewInfo(context),
              ),
            ),
            const SizedBox(height: 20),

            // Recent Training Sessions
            _buildSectionTitle(context, 'Recent Training Sessions'),
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
                        // Example: open a detail screen
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

            // Actions
            _buildSectionTitle(context, 'Actions'),
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: _buildActions(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Header for PT viewing a client
  Widget _buildClientHeader(
      BuildContext context, Map<String, dynamic> clientData) {
    final theme = Theme.of(context);
    final clientName = clientData['name'] ?? 'Unknown Name';
    final clientEmail = clientData['email'] ?? 'Unknown Email';
    final profilePicUrl = clientData['profileImageUrl'] as String?;

    return Container(
      margin: const EdgeInsets.only(bottom: 16.0),
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(
          color: theme.colorScheme.primary.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: theme.colorScheme.primary.withOpacity(0.2),
            backgroundImage:
                profilePicUrl != null ? NetworkImage(profilePicUrl) : null,
            child: profilePicUrl == null
                ? const Icon(Icons.person, color: Colors.white)
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  clientName,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  clientEmail,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.primary.withOpacity(0.7),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Builds an overview text, depending on if it's the user's own account
  Widget _buildOverviewInfo(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Manage and track training progress effectively.',
          style: theme.textTheme.bodyLarge,
        ),
        const SizedBox(height: 8),
        Text(
          isOwnAccount
              ? 'This section provides insights into your training plans, progress updates, and session history.'
              : 'This section provides insights into your client’s training plans, progress updates, and session history.',
          style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey),
        ),
      ],
    );
  }

  Widget _buildListTile({
    required String title,
    required String subtitle,
    required IconData icon,
    VoidCallback? onTap,
  }) {
    final theme = Theme.of(context);
    return ListTile(
      leading: Icon(icon, size: 32, color: theme.colorScheme.primary),
      title: Text(title, style: theme.textTheme.bodyLarge),
      subtitle: Text(
        subtitle,
        style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey),
      ),
      trailing: const Icon(Icons.arrow_forward),
      onTap: onTap,
    );
  }

  Widget _buildActions(BuildContext context) {
    final widgets = <Widget>[];

    // If it's your own account, show "Create New Training Plan"
    if (isOwnAccount) {
      widgets.addAll([
        _buildActionButton(
          label: 'Create New Training Plan',
          icon: Icons.add_circle_outline,
          onPressed: () {
            Navigator.pushNamed(context, '/create-training-plan');
          },
        ),
        const SizedBox(height: 12),
      ]);
    }

    // Everyone sees "View All Training Records"
    widgets.add(
      _buildActionButton(
        label: 'View All Training Records',
        icon: Icons.search,
        onPressed: () {
          Navigator.pushNamed(context, '/all-training-records');
        },
      ),
    );

    return Column(children: widgets);
  }

  Widget _buildActionButton({
    required String label,
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    final theme = Theme.of(context);
    return ElevatedButton.icon(
      icon: Icon(icon, color: theme.colorScheme.onPrimary, size: 20),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: theme.colorScheme.primary,
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      onPressed: onPressed,
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(
        title,
        style:
            theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
      ),
    );
  }
}
