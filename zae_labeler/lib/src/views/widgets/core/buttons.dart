import 'package:flutter/material.dart';

class AppButton extends StatelessWidget {
  final IconData? icon;
  final String? label;
  final VoidCallback onPressed;

  const AppButton({super.key, this.icon, this.label, required this.onPressed});

  /// Factorys
  factory AppButton.home({required VoidCallback onPressed}) => AppButton(icon: Icons.home, onPressed: onPressed);
  factory AppButton.settings({required VoidCallback onPressed}) => AppButton(icon: Icons.settings, onPressed: onPressed);
  factory AppButton.save({required VoidCallback onPressed}) => AppButton(icon: Icons.save, onPressed: onPressed);
  factory AppButton.cancel({required VoidCallback onPressed}) => AppButton(icon: Icons.cancel, onPressed: onPressed);

  @override
  Widget build(BuildContext context) => IconButton(icon: Icon(icon), tooltip: label, onPressed: onPressed);
}
