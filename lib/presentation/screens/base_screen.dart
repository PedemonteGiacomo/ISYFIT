import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'home_screen.dart';
import 'isy_training/isy_training_main_screen.dart';
import 'isy_lab/isy_lab_main_screen.dart';
import 'isy_check/isy_check_main_screen.dart';
import 'account/account_screen.dart';
import 'isy_diary/isy_diary_main_screen.dart';
import '../widgets/radial_menu.dart';

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
    const menuContainer = menuRadius * 2 + 40;

    return Scaffold(
      body: _screens[_currentIndex],
      extendBody: true,
      bottomNavigationBar: BottomAppBar(
        shape: const CircularNotchedRectangle(),
        notchMargin: 8,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildMiniTab(
              icon: Icons.home,
              selected: _currentIndex == 0,
              onTap: () => _onTabChanged(0),
            ),
            const SizedBox(width: menuContainer / 2),
            _buildMiniTab(
              icon: Icons.person,
              selected: _currentIndex == 5,
              onTap: () => _onTabChanged(5),
            ),
          ],
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: SizedBox(
        width: menuContainer,
        height: menuContainer,
        child: Stack(
          alignment: Alignment.center,
          children: [
            RadialMenu(
              radius: menuRadius,
              startAngle: math.pi,
              sweepAngle: math.pi,
              spin: false,
              open: _menuOpen,
              center: GestureDetector(
                onTap: () {
                  setState(() => _menuOpen = !_menuOpen);
                },
                child: Material(
                  color: Colors.white,
                  shape: const CircleBorder(),
                  elevation: 0,
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Image.asset(
                        'assets/images/ISYFIT_LOGO_new-removebg-resized.png'),
                  ),
                ),
              ),
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
          ],
        ),
      ),
    );
  }

  Widget _buildMiniTab({
    required IconData icon,
    required bool selected,
    required VoidCallback onTap,
  }) =>
      IconButton(
        icon: Icon(
          icon,
          color: selected
              ? Theme.of(context).colorScheme.primary
              : Theme.of(context).colorScheme.onSurface.withOpacity(.6),
        ),
        onPressed: onTap,
      );
}
