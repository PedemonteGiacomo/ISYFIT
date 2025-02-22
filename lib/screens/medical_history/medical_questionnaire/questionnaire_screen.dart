import 'package:flutter/material.dart';
import 'personal_information_screen.dart';

class QuestionnaireScreen extends StatelessWidget {
  final String? clientUid;  // <-- Add this
  const QuestionnaireScreen({Key? key, this.clientUid}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Card(
            elevation: 8,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16.0),
            ),
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.medical_services, size: 64, color: Colors.blue),
                  const SizedBox(height: 16),
                  const Text(
                    'Welcome to the Medical History Questionnaire!',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'This questionnaire will help us understand background, lifestyle, and goals. '
                    'Please take a few minutes to complete it.',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () {
                      // Navigate to PersonalInformationScreen, passing clientUid
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => PersonalInformationScreen(
                            clientUid: clientUid,
                          ),
                        ),
                      );
                    },
                    child: const Text('Start'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
