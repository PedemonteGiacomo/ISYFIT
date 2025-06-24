import 'dart:math' as math;

import 'package:flutter/material.dart';

class RadialMenu extends StatefulWidget {
  const RadialMenu({
    Key? key,
    required this.items,
    required this.radius,
    required this.onItemTap,
    this.center,
    this.spin = false,
    this.startAngle = math.pi,
    this.sweepAngle = math.pi,
  }) : super(key: key);

  final List<RadialMenuItem> items;
  final double radius;
  final ValueChanged<int> onItemTap;
  final bool spin;
  final Widget? center;
  final double startAngle;
  final double sweepAngle;

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
  void didUpdateWidget(covariant RadialMenu oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.spin && !_ctl.isAnimating) {
      _ctl.repeat();
    } else if (!widget.spin && _ctl.isAnimating) {
      _ctl.stop();
    }
  }

  @override
  void dispose() {
    _ctl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.radius * 2,
      height: widget.radius * 2,
      child: AnimatedBuilder(
        animation: _ctl,
        builder: (_, __) {
          final angleOffset = widget.spin ? _ctl.value * 2 * math.pi : 0.0;
          final step = widget.items.length > 1
              ? widget.sweepAngle / (widget.items.length - 1)
              : 0.0;
          return Stack(
            alignment: Alignment.center,
            clipBehavior: Clip.none,
            children: [
              if (widget.center != null) widget.center!,
              for (var i = 0; i < widget.items.length; i++)
                _buildItem(angleOffset, step, i),
            ],
          );
        },
      ),
    );
  }

  Positioned _buildItem(double angleOffset, double step, int i) {
    final theta = widget.startAngle + angleOffset + step * i;
    final dx = widget.radius + widget.radius * math.cos(theta);
    final dy = widget.radius + widget.radius * math.sin(theta);
    return Positioned(
      left: dx,
      top: dy,
      child: _RadialIconButton(
        item: widget.items[i],
        onTap: () => widget.onItemTap(i),
      ),
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
