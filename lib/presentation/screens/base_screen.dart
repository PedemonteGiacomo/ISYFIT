import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'home_screen.dart';
import 'isy_training/isy_training_main_screen.dart';
import 'isy_lab/isy_lab_main_screen.dart';
import 'isy_check/isy_check_main_screen.dart';
import 'account/account_screen.dart';
import 'notifications/client_notifications_screen.dart';
import '../widgets/navigation_bar.dart' as NavigationBar;

class BaseScreen extends StatefulWidget {
  const BaseScreen({Key? key}) : super(key: key);
  @override
  _BaseScreenState createState() => _BaseScreenState();
}

class _BaseScreenState extends State<BaseScreen> {
  int _currentIndex = 0;
  final String clientid = FirebaseAuth.instance.currentUser!.uid;
  late List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _screens = [
      const HomeScreen(),
      ClientNotificationsScreen(clientId: clientid),
      const IsyTrainingMainScreen(),
      const IsyLabMainScreen(),
      const IsyCheckMainScreen(),
      const AccountScreen(),
      //TODO: Add NutritionScreen if needed
      // NutritionScreen(),
    ];
  }

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
