import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import 'package:isyfit/presentation/widgets/gradient_app_bar.dart';
import 'package:isyfit/presentation/constants/layout_constants.dart';

class PTNotificationsScreen extends StatefulWidget {
  final String ptId;
  const PTNotificationsScreen({Key? key, required this.ptId}) : super(key: key);

  @override
  State<PTNotificationsScreen> createState() => _PTNotificationsScreenState();
}

class _PTNotificationsScreenState extends State<PTNotificationsScreen> {
  /// Marks *every* notification as read the first time the screen is shown.
  Future<void> _markAllAsRead() async {
    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(widget.ptId)
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
          .doc(widget.ptId)
          .update({'notifications': notifs});
    }
  }

  @override
  void initState() {
    super.initState();
    // Fire-and-forget; errors bubble into Flutter error handler.
    _markAllAsRead();
  }

  Future<void> _accept(Map<String, dynamic> notif) async {
    final clientId = notif['clientId'] as String;
    final notifsRef =
        FirebaseFirestore.instance.collection('users').doc(widget.ptId);
    final doc = await notifsRef.get();
    final data = doc.data() as Map<String, dynamic>? ?? {};
    final notifs = List<Map<String, dynamic>>.from(data['notifications'] ?? []);
    final idx = notifs.indexWhere((n) => n['id'] == notif['id']);
    if (idx >= 0) {
      notifs[idx]['status'] = 'accepted';
      notifs[idx]['read'] =
          true; // Mark as read when accepted is no more needed since is readed when the notification is shown
    }
    await notifsRef.update({
      'notifications': notifs,
      'clients': FieldValue.arrayUnion([clientId]),
    });
    await FirebaseFirestore.instance.collection('users').doc(clientId).update({
      'isSolo': false,
      'supervisorPT': widget.ptId,
      'requestStatus': 'accepted',
      'notifications': FieldValue.arrayUnion([
        {
          'id': FirebaseFirestore.instance.collection('tmp').doc().id,
          'title': 'Richiesta accettata',
          'body': 'Il tuo PT ha accettato la tua richiesta',
          'read': false,
          'timestamp': Timestamp.now(),
        }
      ]),
    });
  }

  Future<void> _reject(Map<String, dynamic> notif) async {
    final clientId = notif['clientId'] as String;
    final notifsRef =
        FirebaseFirestore.instance.collection('users').doc(widget.ptId);
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
      'notifications': FieldValue.arrayUnion([
        {
          'id': FirebaseFirestore.instance.collection('tmp').doc().id,
          'title': 'Richiesta rifiutata',
          'body': 'Il tuo PT ha rifiutato la tua richiesta',
          'read': false,
          'timestamp': Timestamp.now(),
        }
      ]),
    });
  }

  Future<void> _delete(Map<String, dynamic> notif) async {
    final notifsRef =
        FirebaseFirestore.instance.collection('users').doc(widget.ptId);
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
            .doc(widget.ptId)
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
