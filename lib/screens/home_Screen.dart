import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'pt_dashboard.dart';
import 'client_dashboard.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final User? user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const Center(child: Text('No user found. Please log in.'));
    }

    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance.collection('users').doc(user.uid).get(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError || !snapshot.hasData || !snapshot.data!.exists) {
          return const Center(child: Text('Error loading user data.'));
        } else {
          final role = snapshot.data!.get('role');
          if (role == 'PT') {
            return const PTDashboard(); // Redirect to PT Dashboard
          } else if (role == 'Client') {
            return const ClientDashboard(); // Redirect to Client Dashboard
          } else {
            return const Center(child: Text('Invalid role.'));
          }
        }
      },
    );
  }
}
