import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:isyfit/presentation/screens/login_screen.dart';
import 'package:isyfit/presentation/widgets/gradient_app_bar.dart';

class ClientDashboard extends StatelessWidget {
  const ClientDashboard({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final User? user = FirebaseAuth.instance.currentUser;

    // If no user is signed in, immediately return LoginScreen
    if (user == null) {
      return LoginScreen();
    }

    return Scaffold(
      appBar: GradientAppBar(
        title: 'Client Dashboard',
      ),
      body: FutureBuilder<DocumentSnapshot>(
        future:
            FirebaseFirestore.instance.collection('users').doc(user.uid).get(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data == null) {
            return Center(
              child: Text(
                'No data found.',
                style: theme.textTheme.bodyLarge,
              ),
            );
          }

          final userData = snapshot.data!.data() as Map<String, dynamic>?;

          if (userData == null) {
            return Center(
              child: Text(
                'No data found.',
                style: theme.textTheme.bodyLarge,
              ),
            );
          }

          final bool isSolo = userData['isSolo'] == true;
          if (isSolo) {
            return _buildSoloCard(context);
          } else {
            final ptId = userData['supervisorPT'];
            return FutureBuilder<DocumentSnapshot>(
              future: FirebaseFirestore.instance
                  .collection('users')
                  .doc(ptId)
                  .get(),
              builder: (context, ptSnapshot) {
                if (ptSnapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!ptSnapshot.hasData || ptSnapshot.data == null) {
                  return Center(
                    child: Text(
                      'PT information not available.',
                      style: theme.textTheme.bodyLarge,
                    ),
                  );
                }

                final ptData = ptSnapshot.data!.data() as Map<String, dynamic>?;
                if (ptData == null) {
                  return Center(
                    child: Text(
                      'PT information not available.',
                      style: theme.textTheme.bodyLarge,
                    ),
                  );
                }
                return _buildPtCard(context, ptData);
              },
            );
          }
        },
      ),
    );
  }

  /// Shows a Card indicating the user is in SOLO mode
  Widget _buildSoloCard(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Card(
          elevation: 3,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Container(
            width: 300,
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.person_outline,
                    size: 60, color: theme.colorScheme.primary),
                const SizedBox(height: 16),
                Text(
                  'SOLO Mode',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'You are currently training on your own. Explore the app’s features to manage your fitness journey independently.',
                  style: theme.textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Builds a card displaying the assigned PT’s details
  Widget _buildPtCard(BuildContext context, Map<String, dynamic> ptData) {
    final theme = Theme.of(context);
    final String? ptImageUrl = ptData['profileImageUrl'];

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Card(
          elevation: 4,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Container(
            width: 340,
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Your Personal Trainer',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                CircleAvatar(
                  radius: 50,
                  backgroundColor: theme.colorScheme.primary.withOpacity(0.2),
                  backgroundImage: (ptImageUrl != null && ptImageUrl.isNotEmpty)
                      ? NetworkImage(ptImageUrl)
                      : null,
                  child: (ptImageUrl == null || ptImageUrl.isEmpty)
                      ? Icon(
                          Icons.person,
                          size: 50,
                          color: theme.colorScheme.primary,
                        )
                      : null,
                ),
                const SizedBox(height: 16),
                Text(
                  '${ptData['name']} ${ptData['surname']}',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  ptData['email'] ?? '',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),

                // Example: a button for contacting the PT, if you want
                // FilledButton.icon(
                //   onPressed: () {
                //     // Could open a chat or email
                //   },
                //   icon: const Icon(Icons.email_outlined),
                //   label: const Text('Contact PT'),
                //   style: FilledButton.styleFrom(
                //     backgroundColor: theme.colorScheme.primary,
                //     foregroundColor: theme.colorScheme.onPrimary,
                //     shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                //   ),
                // ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
