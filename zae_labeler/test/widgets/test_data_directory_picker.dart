import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:zae_labeler/src/views/widgets/data_directory_picker.dart';

void main() {
  testWidgets('DataDirectoryPicker updates directory path', (WidgetTester tester) async {
    String? dataDirectory;

    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: DataDirectoryPicker(
          dataDirectory: dataDirectory,
          onDataDirectoryChanged: (path) => dataDirectory = path,
        ),
      ),
    ));

    expect(find.text('데이터 디렉토리 경로'), findsOneWidget);
    await tester.tap(find.byIcon(Icons.folder_open));
    await tester.pumpAndSettle();

    // Simulate directory selection
    expect(dataDirectory, isNotNull);
  });
}
