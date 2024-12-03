import 'package:flutter/material.dart';

class AppButton extends StatelessWidget {
  final IconData? icon;
  final String? label;
  final VoidCallback onPressed;

  const AppButton({super.key, this.icon, this.label, required this.onPressed});

  /// Factory for a home icon button
  factory AppButton.home({required VoidCallback onPressed}) {
    return AppButton(icon: Icons.home, onPressed: onPressed);
  }

  /// Factory for a settings icon button
  factory AppButton.settings({required VoidCallback onPressed}) {
    return AppButton(icon: Icons.settings, onPressed: onPressed);
  }

  /// Factory for a save icon button
  factory AppButton.save({required VoidCallback onPressed}) {
    return AppButton(icon: Icons.save, onPressed: onPressed);
  }

  /// Factory for a cancel icon button
  factory AppButton.cancel({required VoidCallback onPressed}) {
    return AppButton(icon: Icons.cancel, onPressed: onPressed);
  }

  @override
  Widget build(BuildContext context) {
    return IconButton(icon: Icon(icon), tooltip: label, onPressed: onPressed);
  }
}
