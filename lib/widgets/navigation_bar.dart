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
      // or theme.colorScheme.onSurface if you prefer
      unselectedItemColor: theme.colorScheme.onSurface.withOpacity(0.7),
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.home),
          label: "Home",
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.fitness_center),
          label: "Training",
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.check_circle_outline),
          label: "Fit-Check",
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.straighten),
          label: "Measurements",
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.person),
          label: "Account",
        ),
      ],
    );
  }
}
