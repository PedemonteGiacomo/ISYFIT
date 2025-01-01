import 'package:flutter/material.dart';

class NavigationBar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onIndexChanged;

  const NavigationBar({
    required this.currentIndex,
    required this.onIndexChanged,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: currentIndex,
      onTap: onIndexChanged,
      backgroundColor: Theme.of(context).primaryColorLight,
      selectedItemColor: Theme.of(context).primaryColorDark,
      unselectedItemColor: Theme.of(context).colorScheme.secondary,
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.home),
          label: 'Home',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.medical_services),
          label: 'Medical History',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.fitness_center),
          label: 'Training',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.account_circle_rounded),
          label: 'Account',
        ),
      ],
    );
  }
}
