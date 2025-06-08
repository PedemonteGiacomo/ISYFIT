import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:isyfit/screens/login_screen.dart';
import 'pt_dashboard.dart';
import 'client_dashboard.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final User? user = FirebaseAuth.instance.currentUser;

    // If user is not logged in, return to LoginScreen
    if (user == null) {
      return LoginScreen();
    }

    return FutureBuilder<DocumentSnapshot>(
      future:
          FirebaseFirestore.instance.collection('users').doc(user.uid).get(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError ||
            !snapshot.hasData ||
            !snapshot.data!.exists) {
          return Center(
            child: Text(
              'Error loading user data.',
              style: theme.textTheme.bodyLarge,
            ),
          );
        } else {
          final role = snapshot.data!.get('role');
          if (role == 'PT') {
            return const PTDashboard(); // to PT Dashboard
          } else if (role == 'Client') {
            return const ClientDashboard(); // to Client Dashboard
          } else {
            return Center(
              child: Text(
                'Invalid role.',
                style: theme.textTheme.bodyLarge,
              ),
            );
          }
        }
      },
    );
  }
}
