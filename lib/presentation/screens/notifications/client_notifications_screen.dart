import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import 'package:isyfit/presentation/widgets/gradient_app_bar.dart';
import 'package:isyfit/presentation/constants/layout_constants.dart';

class ClientNotificationsScreen extends StatefulWidget {
  final String clientId;
  const ClientNotificationsScreen({Key? key, required this.clientId})
      : super(key: key);

  @override
  State<ClientNotificationsScreen> createState() =>
      _ClientNotificationsScreenState();
}

class _ClientNotificationsScreenState extends State<ClientNotificationsScreen> {
  Future<void> _markAllAsRead() async {
    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(widget.clientId)
        .get();
    final data = doc.data() as Map<String, dynamic>? ?? {};
    final notifs = List<Map<String, dynamic>>.from(data['notifications'] ?? []);
    bool changed = false;
    for (final n in notifs) {
      if (!(n['read'] as bool? ?? false)) {
        n['read'] = true;
        changed = true;
      }
    }
    if (changed) {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.clientId)
          .update({'notifications': notifs});
    }
  }

  @override
  void initState() {
    super.initState();
    _markAllAsRead();
  }

  Widget _buildTile(Map<String, dynamic> n) {
    return Card(
      child: ListTile(
        title: Text(n['title'] ?? ''),
        subtitle: Text(n['body'] ?? ''),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const GradientAppBar(title: 'Notifications'),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(widget.clientId)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final data = snapshot.data?.data() as Map<String, dynamic>? ?? {};
          final notifs =
              List<Map<String, dynamic>>.from(data['notifications'] ?? []);
          if (notifs.isEmpty) {
            return const Center(child: Text('No notifications'));
          }
          return ListView(
            padding: const EdgeInsets.all(12),
            children: [for (final n in notifs) _buildTile(n)],
          );
        },
      ),
    );
  }
}
