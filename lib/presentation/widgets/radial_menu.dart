import 'dart:math' as math;

import 'package:flutter/material.dart';

class RadialMenu extends StatefulWidget {
  const RadialMenu({
    Key? key,
    required this.open,
    required this.onSelected,
  }) : super(key: key);

  final bool open;
  final ValueChanged<int> onSelected;

  static const _items = [
    (Icons.fitness_center, 'IsyTraining'),
    (Icons.science, 'IsyLab'),
    (Icons.check_circle, 'IsyCheck'),
    (Icons.apple, 'IsyDiary'),
  ];

  @override
  State<RadialMenu> createState() => _RadialMenuState();
}

class _RadialMenuState extends State<RadialMenu>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    if (widget.open) _controller.value = 1;
  }

  @override
  void didUpdateWidget(covariant RadialMenu oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.open != oldWidget.open) {
      if (widget.open) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const radius = 90.0;
    return SizedBox(
      width: radius * 2 + 72,
      height: radius * 2 + 72,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (_, __) {
          final progress = Curves.easeOut.transform(_controller.value);
          return Stack(
            alignment: Alignment.center,
            children: [
              for (var i = 0; i < RadialMenu._items.length; i++)
                _buildItem(i, progress, radius),
            ],
          );
        },
      ),
    );
  }

  Widget _buildItem(int index, double progress, double radius) {
    final angleStart = math.pi;
    final angleStep = -math.pi / (RadialMenu._items.length - 1);
    final angle = angleStart + angleStep * index;
    final offset = Offset(
      radius * progress * math.cos(angle),
      -radius * progress * math.sin(angle),
    );
    final pair = RadialMenu._items[index];
    final icon = pair.$1;
    final label = pair.$2;
    return Transform.translate(
      offset: offset,
      child: Opacity(
        opacity: progress,
        child: GestureDetector(
          onTap: progress > 0.9 ? () => widget.onSelected(index) : null,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Material(
                elevation: 4,
                shape: const CircleBorder(),
                color: Colors.white,
                shadowColor: Colors.black.withOpacity(0.3),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Icon(icon, size: 28),
                ),
              ),
              const SizedBox(height: 4),
              Builder(
                builder: (context) {
                  final bg = Theme.of(context).scaffoldBackgroundColor;
                  final brightness = ThemeData.estimateBrightnessForColor(bg);
                  final labelColor = brightness == Brightness.dark
                      ? Colors.white
                      : Colors.black;
                  return Text(
                    label,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: labelColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
