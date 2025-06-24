import 'dart:math' as math;

import 'package:flutter/material.dart';

class _NavBackgroundPainter extends CustomPainter {
  final Color color;
  final double radius;

  _NavBackgroundPainter(this.color, this.radius);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width / 2 - radius, 0)
      ..arcTo(
        Rect.fromCircle(center: Offset(size.width / 2, 0), radius: radius),
        math.pi,
        -math.pi,
        false,
      )
      ..lineTo(size.width, 0)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();

    canvas.drawShadow(path, Colors.black, 4, false);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _NavBackgroundPainter old) =>
      old.color != color || old.radius != radius;
}

class FancyBottomBar extends StatelessWidget {
  const FancyBottomBar({
    Key? key,
    required this.currentIndex,
    required this.onTap,
  }) : super(key: key);

  final int currentIndex;
  final ValueChanged<int> onTap;

  static const _items = [
    (Icons.home, 'Home'),
    (Icons.fitness_center, 'IsyTraining'),
    (Icons.science, 'IsyLab'),
    (Icons.check_circle, 'IsyCheck'),
    (Icons.apple, 'IsyDiary'),
    (Icons.person, 'Account'),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    const fabRadius = 36.0;
    const notchPadding = 16.0;
    const barHeight = 64.0;
    final gap = (fabRadius + notchPadding) * 2;

    return SizedBox(
      height: barHeight,
      child: CustomPaint(
        painter: _NavBackgroundPainter(Colors.white, fabRadius + notchPadding),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: List.generate(_items.length, (i) {
            if (i == 3) return SizedBox(width: gap);
            final pair = _items[i];
            final icon = pair.$1;
            final label = pair.$2;
            final selected = i == currentIndex;
            return Expanded(
              child: InkWell(
                onTap: () => onTap(i),
                child: Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        icon,
                        size: 26,
                        color: selected
                            ? theme.colorScheme.primary
                            : theme.colorScheme.onSurface.withOpacity(.7),
                      ),
                      const SizedBox(height: 4),
                      _buildLabel(context, label, selected),
                    ],
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }

  Widget _buildLabel(BuildContext context, String text, bool selected) {
    final show = MediaQuery.of(context).size.width > 420 || selected;
    return AnimatedOpacity(
      opacity: show ? 1 : 0,
      duration: const Duration(milliseconds: 200),
      child: Text(
        text,
        overflow: TextOverflow.ellipsis,
        style: Theme.of(context).textTheme.labelSmall!.copyWith(
              color: selected
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).colorScheme.onSurface.withOpacity(.7),
            ),
      ),
    );
  }
}
