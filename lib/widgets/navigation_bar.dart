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
    final theme = Theme.of(context);
    return BottomNavigationBar(
      currentIndex: currentIndex,
      onTap: onIndexChanged,
      backgroundColor: theme.colorScheme.surface,
      selectedItemColor: theme.colorScheme.primary,
      unselectedItemColor: theme.colorScheme.onSurface.withOpacity(0.7),
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.home),
          label: "Home",
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.fitness_center),
          label: "IsyTraining",
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.science_outlined),
          label: "IsyLab",
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.check_circle_outline),
          label: "IsyCheck",
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.person),
          label: "Account",
        ),
      ],
    );
  }
}
