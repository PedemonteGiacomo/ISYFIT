import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ClientDashboard extends StatelessWidget {
  const ClientDashboard({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Client Dashboard'),
        centerTitle: true,
      ),
      body: FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance
            .collection('users')
            .doc(FirebaseAuth.instance.currentUser!.uid)
            .get(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data == null) {
            return const Center(child: Text('No data found.'));
          }

          final userData = snapshot.data!.data() as Map<String, dynamic>;

          if (userData['isSolo'] == true) {
            return const Center(
              child: Text(
                'You are in SOLO mode.',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            );
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
                  return const Center(
                    child: Text('PT information not available.'),
                  );
                }

                final ptData = ptSnapshot.data!.data() as Map<String, dynamic>;
                return Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const Text(
                        'Your PT:',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      CircleAvatar(
                        radius: 50,
                        backgroundImage: NetworkImage(
                          ptData['profileImageUrl'] ?? '',
                        ),
                        onBackgroundImageError: (_, __) =>
                            const Icon(Icons.person, size: 50),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        '${ptData['name']} ${ptData['surname']}',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        ptData['email'] ?? '',
                        style: const TextStyle(fontSize: 16),
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
