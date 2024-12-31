import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:zae_labeler/src/views/widgets/app_bar.dart';

void main() {
  testWidgets('AppBar renders with settings button', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(appBar: buildAppBar(tester.element(find.byType(MaterialApp)))),
      ),
    );

    expect(find.byIcon(Icons.settings), findsOneWidget);
  });
}
