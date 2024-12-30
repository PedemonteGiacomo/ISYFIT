import 'package:flutter/material.dart';
import 'medical_history_screen.dart';
import 'training_records_screen.dart';
import 'account_screen.dart';

class HomeScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => MedicalHistoryScreen()),
              );
            },
            child: Text('Go to Medical History'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => TrainingRecordsScreen()),
              );
            },
            child: Text('Go to Training Records'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => AccountScreen()),
              );
            },
            child: Text('Go to Account'),
          ),
        ],
      ),
    );
  }
}
