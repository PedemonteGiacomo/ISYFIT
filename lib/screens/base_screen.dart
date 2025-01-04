import 'package:flutter/material.dart';
import 'home_screen.dart';
import 'medical_history/medical_history_screen.dart';
import 'training_records_screen.dart';
import 'account_screen.dart';
import '../widgets/navigation_bar.dart' as NavigationBar;

class BaseScreen extends StatefulWidget {
  const BaseScreen({Key? key}) : super(key: key);

  @override
  _BaseScreenState createState() => _BaseScreenState();
}

class _BaseScreenState extends State<BaseScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const HomeScreen(),
    MedicalHistoryScreen(),
    TrainingRecordsScreen(),
    AccountScreen(),
  ];

  void _onTabChanged(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: NavigationBar.NavigationBar(
        currentIndex: _currentIndex,
        onIndexChanged: _onTabChanged,
      ),
    );
  }
}
