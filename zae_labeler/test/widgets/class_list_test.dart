import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:zae_labeler/src/views/widgets/class_list.dart';

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

    await tester.pumpAndSettle(); // ✅ UI가 완전히 렌더링될 때까지 기다림

    expect(find.text('Math'), findsOneWidget);
    expect(find.text('Science'), findsOneWidget);

    // ✅ Add a new class (find FloatingActionButton or IconButton)
    Finder addButton = find.byIcon(Icons.add);
    if (addButton.evaluate().isEmpty) {
      addButton = find.widgetWithIcon(FloatingActionButton, Icons.add);
    }

    expect(addButton, findsOneWidget); // ✅ 아이콘이 존재하는지 확인
    await tester.tap(addButton);
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'History');
    await tester.tap(find.text('추가'));
    await tester.pumpAndSettle();

    expect(find.text('History'), findsOneWidget);

    // ✅ Remove a class (find delete button)
    Finder deleteButton = find.byIcon(Icons.delete);
    if (deleteButton.evaluate().isEmpty) {
      deleteButton = find.widgetWithIcon(IconButton, Icons.delete);
    }

    expect(deleteButton, findsWidgets); // ✅ 삭제 버튼이 존재하는지 확인
    await tester.tap(deleteButton.first);
    await tester.pumpAndSettle();

    expect(find.text('Math'), findsNothing); // ✅ "Math"가 삭제되었는지 확인
  });
}
