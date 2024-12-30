import 'package:flutter/material.dart';

class TrainingRecordsScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Training Records'),
      ),
      body: Center(
        child: Text(
          'Training Records Screen',
          style: TextStyle(fontSize: 18),
        ),
      ),
    );
  }
}
