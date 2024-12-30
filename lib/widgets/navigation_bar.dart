import 'package:flutter/material.dart';

class NavigationBar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onIndexChanged;

  NavigationBar({required this.currentIndex, required this.onIndexChanged});

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: currentIndex,
      onTap: onIndexChanged,
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
      ],
    );
  }
}
