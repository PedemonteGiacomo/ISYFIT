import 'package:flutter/material.dart';

class PTDashboard extends StatelessWidget {
  const PTDashboard({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('PT Dashboard'),
        centerTitle: true,
      ),
      body: Center(
        child: Text(
          'Welcome to the PT Dashboard!',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
