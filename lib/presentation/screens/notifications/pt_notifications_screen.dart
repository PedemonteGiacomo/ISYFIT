import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import 'package:isyfit/presentation/widgets/gradient_app_bar.dart';

class PTNotificationsScreen extends StatelessWidget {
  final String ptId;
  const PTNotificationsScreen({Key? key, required this.ptId}) : super(key: key);

  Future<void> _accept(Map<String, dynamic> notif) async {
    final clientId = notif['clientId'] as String;
    final notifsRef = FirebaseFirestore.instance.collection('users').doc(ptId);
    final doc = await notifsRef.get();
    final data = doc.data() as Map<String, dynamic>? ?? {};
    final notifs = List<Map<String, dynamic>>.from(data['notifications'] ?? []);
    final idx = notifs.indexWhere((n) => n['id'] == notif['id']);
    if (idx >= 0) {
      notifs[idx]['status'] = 'accepted';
      notifs[idx]['read'] = true;
    }
    await notifsRef.update({
      'notifications': notifs,
      'clients': FieldValue.arrayUnion([clientId]),
    });
    await FirebaseFirestore.instance.collection('users').doc(clientId).update({
      'isSolo': false,
      'supervisorPT': ptId,
      'requestStatus': 'accepted',
    });
  }

  Future<void> _reject(Map<String, dynamic> notif) async {
    final clientId = notif['clientId'] as String;
    final notifsRef = FirebaseFirestore.instance.collection('users').doc(ptId);
    final doc = await notifsRef.get();
    final data = doc.data() as Map<String, dynamic>? ?? {};
    final notifs = List<Map<String, dynamic>>.from(data['notifications'] ?? []);
    final idx = notifs.indexWhere((n) => n['id'] == notif['id']);
    if (idx >= 0) {
      notifs[idx]['status'] = 'rejected';
      notifs[idx]['read'] = true;
    }
    await notifsRef.update({'notifications': notifs});
    await FirebaseFirestore.instance.collection('users').doc(clientId).update({
      'requestStatus': 'rejected',
    });
  }

  Future<void> _delete(Map<String, dynamic> notif) async {
    final notifsRef = FirebaseFirestore.instance.collection('users').doc(ptId);
    final doc = await notifsRef.get();
    final data = doc.data() as Map<String, dynamic>? ?? {};
    final notifs = List<Map<String, dynamic>>.from(data['notifications'] ?? []);
    notifs.removeWhere((n) => n['id'] == notif['id']);
    await notifsRef.update({'notifications': notifs});
  }

  Widget _buildTile(BuildContext context, Map<String, dynamic> n) {
    final status = n['status'] ?? 'pending';
    return Card(
      child: ListTile(
        title: Text('${n['clientName']} ${n['clientSurname']}'),
        subtitle: Text('Status: $status'),
        trailing: status == 'pending'
            ? Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.check, color: Colors.green),
                    onPressed: () => _accept(n),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.red),
                    onPressed: () => _reject(n),
                  ),
                ],
              )
            : IconButton(
                icon: const Icon(Icons.delete),
                onPressed: () => _delete(n),
              ),
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
            .doc(ptId)
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
            children: [for (final n in notifs) _buildTile(context, n)],
          );
        },
      ),
    );
  }
}
