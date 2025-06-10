import 'package:flutter/material.dart';
import '../theme/app_gradients.dart';

class GradientButton extends StatelessWidget {
  final String label;
  final IconData? icon;
  final VoidCallback onPressed;
  final double borderRadius;
  final EdgeInsetsGeometry padding;
  final List<Color>? gradientColors;

  const GradientButton({
    Key? key,
    required this.label,
    required this.onPressed,
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
    final defaultGradient = AppGradients.primaryColors(theme);

    return Material(
      // Material is needed so the InkWell can show a proper ripple effect
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(borderRadius),
      child: InkWell(
        borderRadius: BorderRadius.circular(borderRadius),
        onTap: onPressed,
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: gradientColors ?? defaultGradient,
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
                Icon(icon, color: theme.colorScheme.onPrimary),
                const SizedBox(width: 8),
              ],
              Text(
                label,
                style: TextStyle(
                  color: theme.colorScheme.onPrimary,
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
