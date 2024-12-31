import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:your_project/src/views/widgets/class_list.dart';

void main() {
  testWidgets('ClassListWidget displays classes and allows addition and removal', (WidgetTester tester) async {
    final List<String> classes = ['Math', 'Science'];
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: ClassListWidget(
          classes: classes,
          onAddClass: (newClass) => classes.add(newClass),
          onRemoveClass: (index) => classes.removeAt(index),
        ),
      ),
    ));

    expect(find.text('Math'), findsOneWidget);
    expect(find.text('Science'), findsOneWidget);

    // Add a new class
    await tester.tap(find.byIcon(Icons.add));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'History');
    await tester.tap(find.text('추가'));
    await tester.pumpAndSettle();

    expect(find.text('History'), findsOneWidget);

    // Remove a class
    await tester.tap(find.byIcon(Icons.delete).first);
    await tester.pumpAndSettle();

    expect(find.text('Math'), findsNothing);
  });
}
