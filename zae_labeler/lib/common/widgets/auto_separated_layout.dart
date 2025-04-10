import 'package:flutter/widgets.dart';

class AutoSeparatedColumn extends StatelessWidget {
  final List<Widget> children;
  final Widget separator;
  final MainAxisAlignment mainAxisAlignment;
  final CrossAxisAlignment crossAxisAlignment;

  const AutoSeparatedColumn({
    super.key,
    required this.children,
    required this.separator,
    this.mainAxisAlignment = MainAxisAlignment.start,
    this.crossAxisAlignment = CrossAxisAlignment.center,
  });

  @override
  Widget build(BuildContext context) {
    final separated = <Widget>[];
    for (int i = 0; i < children.length; i++) {
      separated.add(children[i]);
      if (i != children.length - 1) {
        separated.add(separator);
      }
    }

    return Column(
      mainAxisAlignment: mainAxisAlignment,
      crossAxisAlignment: crossAxisAlignment,
      children: separated,
    );
  }
}

class AutoSeparatedRow extends StatelessWidget {
  final List<Widget> children;
  final Widget separator;
  final MainAxisAlignment mainAxisAlignment;
  final CrossAxisAlignment crossAxisAlignment;

  const AutoSeparatedRow({
    super.key,
    required this.children,
    required this.separator,
    this.mainAxisAlignment = MainAxisAlignment.start,
    this.crossAxisAlignment = CrossAxisAlignment.center,
  });

  @override
  Widget build(BuildContext context) {
    final separated = <Widget>[];
    for (int i = 0; i < children.length; i++) {
      separated.add(children[i]);
      if (i != children.length - 1) {
        separated.add(separator);
      }
    }

    return Row(
      mainAxisAlignment: mainAxisAlignment,
      crossAxisAlignment: crossAxisAlignment,
      children: separated,
    );
  }
}
