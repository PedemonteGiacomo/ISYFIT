import 'package:flutter/material.dart';
import '../medical_history/anamnesis_screen.dart';

class IsyCheckMainScreen extends StatelessWidget {
  final String? clientUid;
  const IsyCheckMainScreen({Key? key, this.clientUid}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MedicalHistoryScreen(clientUid: clientUid);
  }
}
