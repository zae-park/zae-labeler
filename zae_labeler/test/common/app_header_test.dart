import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zae_labeler/common/widgets/app_header.dart';

void main() {
  group('AppHeader Widget', () {
    testWidgets('renders title correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            appBar: AppHeader(title: 'Test Title'),
          ),
        ),
      );

      expect(find.text('Test Title'), findsOneWidget);
    });

    testWidgets('renders leading widget', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(appBar: AppHeader(title: 'Leading Test', leading: Icon(Icons.menu)))),
      );

      expect(find.byIcon(Icons.menu), findsOneWidget);
    });

    testWidgets('renders action widgets', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            appBar: AppHeader(
              title: 'Actions Test',
              actions: [IconButton(icon: const Icon(Icons.search), onPressed: () {})],
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.search), findsOneWidget);
    });

    test('has correct preferred size', () {
      const header = AppHeader(title: 'Size Test');
      expect(header.preferredSize.height, equals(kToolbarHeight));
    });
  });
}
