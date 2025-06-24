import 'dart:math' as math;

import 'package:flutter/material.dart';

class RadialMenu extends StatefulWidget {
  const RadialMenu({
    Key? key,
    required this.items,
    required this.radius,
    required this.onItemTap,
    this.spin = true,
  }) : super(key: key);

  final List<RadialMenuItem> items;
  final double radius;
  final ValueChanged<int> onItemTap;
  final bool spin;

  @override
  State<RadialMenu> createState() => _RadialMenuState();
}

class _RadialMenuState extends State<RadialMenu>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctl;

  @override
  void initState() {
    super.initState();
    _ctl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    );
    if (widget.spin) _ctl.repeat();
  }

  @override
  void dispose() {
    _ctl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctl,
      builder: (_, __) {
        final angleOffset = widget.spin ? _ctl.value * 2 * math.pi : 0.0;
        return Stack(
          clipBehavior: Clip.none,
          children: List.generate(widget.items.length, (i) {
            final theta = angleOffset +
                (2 * math.pi / widget.items.length) * i -
                math.pi / 2;
            final dx = widget.radius * math.cos(theta);
            final dy = widget.radius * math.sin(theta);
            return Positioned(
              left: dx,
              top: dy,
              child: _RadialIconButton(
                item: widget.items[i],
                onTap: () => widget.onItemTap(i),
              ),
            );
          }),
        );
      },
    );
  }
}

class RadialMenuItem {
  const RadialMenuItem(this.icon, this.tooltip);
  final IconData icon;
  final String tooltip;
}

class _RadialIconButton extends StatelessWidget {
  const _RadialIconButton({
    Key? key,
    required this.item,
    required this.onTap,
  }) : super(key: key);

  final RadialMenuItem item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      shape: const CircleBorder(),
      elevation: 4,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Icon(item.icon, size: 24),
        ),
      ),
    );
  }
}
