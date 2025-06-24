import 'dart:math' as math;

import 'package:flutter/material.dart';

class _NavBackgroundPainter extends CustomPainter {
  final Color color;
  final double fabRadius;

  _NavBackgroundPainter(this.color, this.fabRadius);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width / 2 - fabRadius - 8, 0)
      ..arcTo(
        Rect.fromCircle(
          center: Offset(size.width / 2, 0),
          radius: fabRadius + 8,
        ),
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
      old.color != color || old.fabRadius != fabRadius;
}

class FancyBottomBar extends StatelessWidget {
  const FancyBottomBar({
    required this.currentIndex,
    required this.onTap,
    Key? key,
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
    const barHeight = 64.0;

    return SizedBox(
      height: barHeight,
      child: CustomPaint(
        painter: _NavBackgroundPainter(Colors.white, fabRadius),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: List.generate(_items.length, (i) {
            if (i == 3) return const SizedBox(width: 72);

            final (icon, label) = _items[i];
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

  Widget _buildLabel(BuildContext ctx, String text, bool selected) {
    final show = MediaQuery.of(ctx).size.width > 420 || selected;
    return AnimatedOpacity(
      opacity: show ? 1 : 0,
      duration: const Duration(milliseconds: 200),
      child: Text(
        text,
        style: Theme.of(ctx).textTheme.labelSmall!.copyWith(
              color: selected
                  ? Theme.of(ctx).colorScheme.primary
                  : Theme.of(ctx).colorScheme.onSurface.withOpacity(.7),
            ),
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}
