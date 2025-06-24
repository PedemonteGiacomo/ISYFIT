import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'home_screen.dart';
import 'isy_training/isy_training_main_screen.dart';
import 'isy_lab/isy_lab_main_screen.dart';
import 'isy_check/isy_check_main_screen.dart';
import 'account/account_screen.dart';
import 'isy_diary/isy_diary_main_screen.dart';
import '../widgets/radial_menu.dart';
import '../widgets/navigation_bar.dart' as nav;

class BaseScreen extends StatefulWidget {
  const BaseScreen({Key? key}) : super(key: key);
  @override
  _BaseScreenState createState() => _BaseScreenState();
}

class _BaseScreenState extends State<BaseScreen> {
  int _currentIndex = 0;
  late List<Widget> _screens;
  bool _menuOpen = false;

  @override
  void initState() {
    super.initState();
    _screens = const [
      HomeScreen(),
      IsyTrainingMainScreen(),
      IsyLabMainScreen(),
      IsyCheckMainScreen(),
      IsyDiaryMainScreen(),
      AccountScreen(),
    ];
  }

  void _onTabChanged(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    const hubSize = 56.0;
    const menuRadius = 80.0;
    const barHeight = 64.0;

    return Scaffold(
      extendBody: true,
      body: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          _screens[_currentIndex],
          Positioned(
            bottom: barHeight / 2 - menuRadius,
            child: RadialMenu(
              radius: menuRadius,
              startAngle: math.pi,
              sweepAngle: math.pi,
              spin: false,
              open: _menuOpen,
              items: const [
                RadialMenuItem(Icons.fitness_center, 'IsyTraining'),
                RadialMenuItem(Icons.science, 'IsyLab'),
                RadialMenuItem(Icons.check_circle, 'IsyCheck'),
                RadialMenuItem(Icons.apple, 'IsyDiary'),
              ],
              onItemTap: (i) {
                setState(() {
                  _menuOpen = false;
                  _currentIndex = i + 1;
                });
              },
            ),
          ),
        ],
      ),
      bottomNavigationBar: nav.NavigationBar(
        currentIndex: _currentIndex,
        onIndexChanged: _onTabChanged,
        onLogoTap: () => setState(() => _menuOpen = !_menuOpen),
        hubSize: hubSize,
      ),
    );
  }
}
