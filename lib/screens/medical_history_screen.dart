import 'package:flutter/material.dart';

class MedicalHistoryScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Medical History'),
      ),
      body: Center(
        child: Text(
          'Medical History Screen',
          style: TextStyle(fontSize: 18),
        ),
      ),
    );
  }
}
