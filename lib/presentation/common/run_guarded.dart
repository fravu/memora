import 'package:flutter/material.dart';

/// Fuehrt [action] aus und zeigt einen Fehler als SnackBar an, statt die
/// Exception bis zum Flutter-Error-Overlay durchschlagen zu lassen.
Future<void> runGuarded(
  BuildContext context,
  Future<void> Function() action,
) async {
  try {
    await action();
  } catch (error) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Fehler: $error')),
    );
  }
}
