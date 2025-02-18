import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:zae_labeler/src/views/widgets/labeling_mode.dart';
import 'package:zae_labeler/src/models/project_model.dart';

void main() {
  testWidgets('LabelingModeDropdown changes mode', (WidgetTester tester) async {
    LabelingMode selectedMode = LabelingMode.singleClassification;

    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: LabelingModeSelector.dropdown(
          selectedMode: selectedMode,
          onModeChanged: (newMode) {
            selectedMode = newMode;
          },
        ),
      ),
    ));

    await tester.pumpAndSettle(); // ✅ UI가 완전히 로드될 때까지 기다림

    // ✅ DropdownButtonFormField가 없을 경우, DropdownButton을 찾음
    Finder dropdownFinder = find.byType(DropdownButtonFormField<LabelingMode>);
    if (dropdownFinder.evaluate().isEmpty) {
      dropdownFinder = find.byType(DropdownButton<LabelingMode>);
    }

    expect(dropdownFinder, findsOneWidget); // ✅ 드롭다운이 존재하는지 확인

    await tester.tap(dropdownFinder);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Multi Classification').last);
    await tester.pumpAndSettle();

    expect(selectedMode, LabelingMode.multiClassification); // ✅ 선택된 값이 변경되었는지 확인
  });
}
