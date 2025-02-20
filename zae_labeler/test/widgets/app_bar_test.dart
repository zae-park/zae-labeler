import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:zae_labeler/src/views/widgets/app_bar.dart';

void main() {
  testWidgets('AppBar renders with settings button', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(appBar: buildAppBar(context)), // ✅ Builder 사용
        ),
      ),
    );

    await tester.pumpAndSettle(); // ✅ 이미지 로딩 대기
    expect(find.byIcon(Icons.settings), findsOneWidget); // ✅ 설정 버튼이 렌더링되는지 확인
  });
}
