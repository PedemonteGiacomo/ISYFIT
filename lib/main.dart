import 'package:flutter/material.dart';
import 'screens/home_screen.dart';
import 'screens/medical_history_screen.dart';
import 'screens/training_records_screen.dart';
import 'screens/account_screen.dart';
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
        primaryColor: Colors.blue,
        primaryColorDark: Colors.blue[700],
        primaryColorLight: Colors.blue[100],
        primarySwatch: Colors.blue,
        colorScheme: ColorScheme.fromSwatch().copyWith(
          secondary: Colors.blueGrey, // Set the secondary color
          onPrimary: Colors.white, // Color for text/icons on primary
        ),
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
    AccountScreen(),
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
