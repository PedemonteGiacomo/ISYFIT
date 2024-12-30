import 'package:flutter/material.dart';
import 'screens/home_screen.dart';
import 'screens/medical_history_screen.dart';
import 'screens/training_records_screen.dart';
import 'widgets/navigation_bar.dart' as navbar;

void main() {
  runApp(IsyFitApp());
}

class IsyFitApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'IsyFit',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: MainLayout(),
    );
  }
}

class MainLayout extends StatefulWidget {
  @override
  _MainLayoutState createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    HomeScreen(),
    MedicalHistoryScreen(),
    TrainingRecordsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("IsyFit"),
      ),
      body: _screens[_currentIndex],
      bottomNavigationBar: navbar.NavigationBar(
        currentIndex: _currentIndex,
        onIndexChanged: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
      ),
    );
  }
}
