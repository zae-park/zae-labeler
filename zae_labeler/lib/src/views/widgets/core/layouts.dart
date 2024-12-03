import 'package:flutter/material.dart';

class RRow extends StatelessWidget {
  final MainAxisAlignment mainAxisAlignment;
  final List<Widget> children;

  const RRow({super.key, required this.mainAxisAlignment, required this.children});

  factory RRow.spaceBetween({required children}) => RRow(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: children);

  @override
  Widget build(BuildContext context) => const Placeholder();
}

class CColumn extends StatelessWidget {
  final MainAxisAlignment mainAxisAlignment;
  final List<Widget> children;

  const CColumn({super.key, required this.mainAxisAlignment, required this.children});

  factory CColumn.spaceBetween({required children}) => CColumn(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: children);

  @override
  Widget build(BuildContext context) => const Placeholder();
}
