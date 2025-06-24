import 'package:flutter/material.dart';
import 'home_screen.dart';
import 'isy_training/isy_training_main_screen.dart';
import 'isy_lab/isy_lab_main_screen.dart';
import 'isy_check/isy_check_main_screen.dart';
import 'account/account_screen.dart';
import 'isy_diary/isy_diary_main_screen.dart';
import '../widgets/fancy_bottom_bar.dart';

class BaseScreen extends StatefulWidget {
  const BaseScreen({Key? key}) : super(key: key);
  @override
  _BaseScreenState createState() => _BaseScreenState();
}

class _BaseScreenState extends State<BaseScreen> {
  int _currentIndex = 0;
  late List<Widget> _screens;

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
    return Scaffold(
      body: _screens[_currentIndex],
      extendBody: true,
      bottomNavigationBar: FancyBottomBar(
        currentIndex: _currentIndex,
        onTap: _onTabChanged,
      ),
      floatingActionButton: GestureDetector(
        onTap: () => setState(() => _currentIndex = 0),
        child: Container(
          width: 72,
          height: 72,
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
                'assets/images/ISYFIT_LOGO_new-removebg-resized.png'),
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }
}
