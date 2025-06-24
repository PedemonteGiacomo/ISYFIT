import 'package:flutter/material.dart';

class NavigationBar extends StatelessWidget {
  const NavigationBar({
    Key? key,
    required this.currentIndex,
    required this.onIndexChanged,
    required this.onLogoTap,
    this.hubSize = 56.0,
  }) : super(key: key);

  final int currentIndex;
  final ValueChanged<int> onIndexChanged;
  final VoidCallback onLogoTap;
  final double hubSize;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      height: 64,
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            offset: const Offset(0, -1),
            blurRadius: 5,
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildIcon(
                icon: Icons.home,
                selected: currentIndex == 0,
                onTap: () => onIndexChanged(0),
                theme: theme,
              ),
              SizedBox(width: hubSize),
              _buildIcon(
                icon: Icons.person,
                selected: currentIndex == 5,
                onTap: () => onIndexChanged(5),
                theme: theme,
              ),
            ],
          ),
          GestureDetector(
            onTap: onLogoTap,
            child: Container(
              width: hubSize,
              height: hubSize,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(.15),
                    offset: const Offset(0, 2),
                    blurRadius: 4,
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Image.asset(
                  'assets/images/ISYFIT_LOGO_new-removebg-resized.png',
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIcon({
    required IconData icon,
    required bool selected,
    required VoidCallback onTap,
    required ThemeData theme,
  }) {
    return IconButton(
      icon: Icon(
        icon,
        color: selected
            ? theme.colorScheme.primary
            : theme.colorScheme.onSurface.withOpacity(.6),
      ),
      onPressed: onTap,
    );
  }
}
