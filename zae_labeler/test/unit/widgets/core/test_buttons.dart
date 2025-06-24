import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:zae_labeler/src/views/widgets/core/buttons.dart';

void main() {
  testWidgets('AppButton triggers onPressed', (WidgetTester tester) async {
    bool pressed = false;

    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: AppButton.settings(onPressed: () => pressed = true),
      ),
    ));

    await tester.tap(find.byType(IconButton));
    expect(pressed, isTrue);
  });
}
