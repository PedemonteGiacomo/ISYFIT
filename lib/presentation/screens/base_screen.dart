import 'package:flutter/material.dart';
import 'home_screen.dart';
import 'isy_training/isy_training_main_screen.dart';
import 'isy_lab/isy_lab_main_screen.dart';
import 'isy_check/isy_check_main_screen.dart';
import 'account/account_screen.dart';
import 'isy_diary/isy_diary_main_screen.dart';
import '../widgets/fancy_bottom_bar.dart';
import '../widgets/radial_menu.dart';
import 'dart:math' as math;

class _CenterDockedNoMargin extends FloatingActionButtonLocation {
  const _CenterDockedNoMargin([this.dy = 0]);

  final double dy;

  @override
  Offset getOffset(ScaffoldPrelayoutGeometry geometry) {
    final double fabX = (geometry.scaffoldSize.width -
            geometry.floatingActionButtonSize.width) /
        2.0;
    
    // Calculate base Y position
    final double contentBottom = geometry.contentBottom;
    double fabY = contentBottom - geometry.floatingActionButtonSize.height / 2.0;
    
    // Apply the vertical offset
    fabY += dy;
    
    return Offset(fabX, fabY);
  }
}

class BaseScreen extends StatefulWidget {
  const BaseScreen({Key? key}) : super(key: key);
  @override
  _BaseScreenState createState() => _BaseScreenState();
}

class _BaseScreenState extends State<BaseScreen> {
  // Size of the central IsyFit logo in the bottom bar.
  static const double _fabSize = 72.0;
  static const double _arcGap = 30.0;
  
  int _currentIndex = 0;  bool _menuOpen = false;

  // List of screens to show based on bottom nav index
  final List<Widget> _screens = [
    const HomeScreen(),
    const IsyTrainingMainScreen(),
    const IsyLabMainScreen(),
    const IsyCheckMainScreen(),
    const IsyDiaryMainScreen(),
    const AccountScreen(),
  ];
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      bottomNavigationBar: FancyBottomBar(
        currentIndex: _currentIndex,
        onTap: (i) => setState(() => _currentIndex = i),
      ),
      floatingActionButtonLocation: const _CenterDockedNoMargin(-5),
      floatingActionButton: SizedBox(
        width: 252,
        height: 252,
        child: Stack(
          alignment: Alignment.center,
          clipBehavior: Clip.none,
          children: [
            if (_menuOpen) Transform.translate(
              offset: const Offset(0, -_arcGap),              child: RadialMenu(
                open: _menuOpen,                onSelected: (i) => setState(() {
                  // Map RadialMenu index to screen index
                  _currentIndex = i + 1; // +1 because first item is Home
                  _menuOpen = false;
                }),
              ),
            ),
            GestureDetector(
              onTap: () => setState(() => _menuOpen = !_menuOpen),
              child: Container(
                width: _fabSize,
                height: _fabSize,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      offset: const Offset(0, 4),
                      blurRadius: 8,
                      color: Colors.black.withOpacity(.15),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: Image.asset(
                    'assets/images/ISYFIT_LOGO_new-removebg-resized.png',
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      body: _screens[_currentIndex],
    );
  }
}
