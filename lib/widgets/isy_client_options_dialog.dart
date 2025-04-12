import 'package:flutter/material.dart';
import 'package:isyfit/screens/isy_lab/isy_lab_main_screen.dart';
import 'package:isyfit/screens/isy_training/isy_training_main_screen.dart';
import 'package:isyfit/screens/measurements/measurements_home_screen.dart';
import 'package:isyfit/screens/isy_check/isy_check_main_screen.dart';
import 'package:isyfit/screens/account/account_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class IsyClientOptionsDialog extends StatelessWidget {
  final String clientUid;
  final String clientName;
  final String clientSurname;

  const IsyClientOptionsDialog({
    Key? key,
    required this.clientUid,
    required this.clientName,
    required this.clientSurname,
  }) : super(key: key);

  Future<void> _recordInteraction() async {
    final pt = FirebaseAuth.instance.currentUser;
    if (pt == null) return;
    await FirebaseFirestore.instance
        .collection('users')
        .doc(clientUid)
        .update({
      'lastInteractionTime': FieldValue.serverTimestamp(),
      'lastInteractionBy': pt.uid,
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16.0),
      ),
      title: Text(
        '$clientName $clientSurname',
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: Icon(Icons.fitness_center, color: theme.colorScheme.primary),
            title: const Text('IsyTraining'),
            onTap: () async {
              final nav = Navigator.of(context);
              nav.pop(); // close dialog
              await _recordInteraction();
              nav.push(
                MaterialPageRoute(
                  builder: (_) => IsyTrainingMainScreen(clientUid: clientUid),
                ),
              );
            },
          ),
          ListTile(
            leading: Icon(Icons.straighten, color: theme.colorScheme.primary),
            title: const Text('IsyLab'),
            onTap: () async {
              final nav = Navigator.of(context);
              nav.pop();

              // Push IsyLabMainScreen, not just MeasurementsHomeScreen
              nav.push(MaterialPageRoute(
                builder: (_) => IsyLabMainScreen(clientUid: clientUid),
              ));
            },
          ),

          ListTile(
            leading: const Icon(Icons.medical_services, color: Colors.red),
            title: const Text('IsyCheck'),
            onTap: () async {
              final nav = Navigator.of(context);
              nav.pop();
              await _recordInteraction();
              nav.push(
                MaterialPageRoute(
                  builder: (_) => IsyCheckMainScreen(clientUid: clientUid),
                ),
              );
            },
          ),
          ListTile(
            leading: Icon(Icons.info, color: theme.colorScheme.tertiary),
            title: const Text('IsyProfile'),
            onTap: () async {
              final nav = Navigator.of(context);
              nav.pop();
              await _recordInteraction();
              nav.push(
                MaterialPageRoute(
                  builder: (_) => AccountScreen(clientUid: clientUid),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
