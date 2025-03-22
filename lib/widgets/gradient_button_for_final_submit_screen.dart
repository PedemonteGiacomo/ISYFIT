import 'package:flutter/material.dart';

class GradientButtonFFSS extends StatelessWidget {
  final String label;
  final IconData? icon;
  final VoidCallback? onPressed; // <<-- Made nullable
  final double borderRadius;
  final EdgeInsetsGeometry padding;
  final List<Color>? gradientColors;

  const GradientButtonFFSS({
    Key? key,
    required this.label,
    // Notice we change to `VoidCallback?` 
    // and remove the "required" from onPressed
    this.onPressed,
    this.icon,
    this.borderRadius = 16.0,
    this.padding = const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
    this.gradientColors,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // If no custom gradient colors are provided,
    // we default to the same style as GradientAppBar.
    final defaultGradient = [
      theme.colorScheme.primary,
      theme.colorScheme.primary.withOpacity(0.6),
    ];

    // If onPressed is null, we’ll “disable” the InkWell 
    // by not providing a tap callback and dimming the gradient or text color if you like
    final isDisabled = onPressed == null;

    // Dim the gradient if disabled, or keep it if enabled
    final gradient = isDisabled
        ? [
            theme.disabledColor,
            theme.disabledColor.withOpacity(0.6),
          ]
        : (gradientColors ?? defaultGradient);

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(borderRadius),
      child: InkWell(
        borderRadius: BorderRadius.circular(borderRadius),
        // If onPressed is null, user can't tap
        onTap: isDisabled ? null : onPressed,
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: gradient,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(borderRadius),
          ),
          padding: padding,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(
                  icon, 
                  color: isDisabled
                      ? theme.colorScheme.onPrimary.withOpacity(0.4)
                      : theme.colorScheme.onPrimary,
                ),
                const SizedBox(width: 8),
              ],
              Text(
                label,
                style: TextStyle(
                  color: isDisabled
                      ? theme.colorScheme.onPrimary.withOpacity(0.6)
                      : theme.colorScheme.onPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
