import 'package:flutter/material.dart';
import '../theme/app_gradients.dart';

class GradientAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget>? actions;
  final bool centerTitle;
  final PreferredSizeWidget? bottom;

  const GradientAppBar({
    Key? key,
    required this.title,
    this.actions,
    this.centerTitle = true,
    this.bottom,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        gradient: AppGradients.primary(theme),
      ),
      child: AppBar(
        title: Text(
          title,
          style: TextStyle(color: theme.colorScheme.onPrimary),
        ),
        centerTitle: centerTitle,
        actions: actions,
        backgroundColor: Colors.transparent,
        iconTheme: IconThemeData(
          color: theme.colorScheme.onPrimary,
        ),
        bottom: bottom,
      ),
    );
  }

  @override
  Size get preferredSize =>
      Size.fromHeight(bottom?.preferredSize.height ?? kToolbarHeight);
}
