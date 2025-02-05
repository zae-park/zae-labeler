import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:zae_labeler/src/views/widgets/labeling_mode.dart';
import 'package:zae_labeler/src/models/project_model.dart';

void main() {
  testWidgets('LabelingModeDropdown changes mode', (WidgetTester tester) async {
    LabelingMode selectedMode = LabelingMode.singleClassification;

    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: LabelingModeSelector.dropdown(selectedMode: selectedMode, onModeChanged: (newMode) => selectedMode = newMode),
      ),
    ));

    await tester.tap(find.byType(DropdownButtonFormField));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Multi Classification').last);
    await tester.pumpAndSettle();

    expect(selectedMode, LabelingMode.multiClassification);
  });
}
