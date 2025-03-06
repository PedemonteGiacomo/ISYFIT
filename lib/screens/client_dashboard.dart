import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:isyfit/screens/login_screen.dart';

class ClientDashboard extends StatelessWidget {
  const ClientDashboard({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final User? user = FirebaseAuth.instance.currentUser;

    // If no user is signed in, immediately return LoginScreen
    if (user == null) {
      return const LoginScreen();
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Client Dashboard'),
        centerTitle: true,
        backgroundColor: theme.colorScheme.primary,
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

          final userData = snapshot.data!.data() as Map<String, dynamic>;

          if (userData['isSolo'] == true) {
            return Center(
              child: Text(
                'You are in SOLO mode.',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            );
          } else {
            final ptId = userData['supervisorPT'];
            return FutureBuilder<DocumentSnapshot>(
              future:
                  FirebaseFirestore.instance.collection('users').doc(ptId).get(),
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

                final ptData = ptSnapshot.data!.data() as Map<String, dynamic>;
                final String? ptImageUrl = ptData['profileImageUrl'];

                return Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        'Your PT:',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      CircleAvatar(
                        radius: 50,
                        backgroundColor:
                            theme.colorScheme.primary.withOpacity(0.2),
                        backgroundImage: (ptImageUrl != null &&
                                ptImageUrl.isNotEmpty)
                            ? NetworkImage(ptImageUrl)
                            : null,
                        child: (ptImageUrl == null || ptImageUrl.isEmpty)
                            ? const Icon(Icons.person, size: 50)
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
                        style: theme.textTheme.bodyMedium,
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                );
              },
            );
          }
        },
      ),
    );
  }
}
