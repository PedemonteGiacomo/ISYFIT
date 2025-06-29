import 'package:flutter/material.dart';
import 'package:top_snackbar_flutter/custom_snack_bar.dart';
import 'package:top_snackbar_flutter/top_snack_bar.dart';

/// Displays a snackbar at the top of the screen using [top_snackbar_flutter].
void showInfoSnackBar(BuildContext context, String message) {
  final overlay = Overlay.of(context);
  if (overlay == null) return;
  showTopSnackBar(
    overlay,
    CustomSnackBar.info(message: message),
    displayDuration: const Duration(seconds: 3),
  );
}

/// Displays a success snackbar at the top of the screen.
void showSuccessSnackBar(BuildContext context, String message) {
  final overlay = Overlay.of(context);
  if (overlay == null) return;
  showTopSnackBar(
    overlay,
    CustomSnackBar.success(message: message),
    displayDuration: const Duration(seconds: 3),
  );
}

/// Displays an error snackbar at the top of the screen.
void showErrorSnackBar(BuildContext context, String message) {
  final overlay = Overlay.of(context);
  if (overlay == null) return;
  showTopSnackBar(
    overlay,
    CustomSnackBar.error(message: message),
    displayDuration: const Duration(seconds: 3),
  );
}
