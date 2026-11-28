// test/app_flow_test.dart
//
// 화면 간 흐름을 실제 provider 그래프로 검증하는 통합 위젯 테스트.
// 목록 → 라벨링 → 복귀 시 진행률 갱신 → 편집(이름 변경) → 삭제
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:zae_labeler/l10n/app_localizations.dart';
import 'package:zae_labeler/src/core/di/providers.dart';
import 'package:zae_labeler/src/core/models/data/data_info.dart';
import 'package:zae_labeler/src/core/models/label/label_model.dart';
import 'package:zae_labeler/src/core/models/project/project_model.dart';
import 'package:zae_labeler/src/features/label/ui/pages/sub_pages/classification_labeling_page.dart';
import 'package:zae_labeler/src/features/project/providers/project_providers.dart';
import 'package:zae_labeler/src/features/project/ui/pages/configuration_page.dart';
import 'package:zae_labeler/src/features/project/ui/pages/project_list_page.dart';

import 'support/in_memory_storage_helper.dart';

/// 유효한 1×1 PNG (웹 테스트는 실제로 이미지를 디코딩합니다)
const _png = 'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNkYAAAAAYAAjCB0C8AAAAASUVORK5CYII=';

void main() {
  testWidgets('목록 → 라벨링 → 진행률 갱신 → 편집 → 삭제', (tester) async {
    tester.view.physicalSize = const Size(1600, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    ProjectEditorNotifier.renameDebounce = Duration.zero;
    addTearDown(() => ProjectEditorNotifier.renameDebounce = const Duration(milliseconds: 400));

    SharedPreferences.setMockInitialValues({'has_seen_onboarding': true, 'user_locale': 'en'});
    final prefs = await SharedPreferences.getInstance();
    final storage = InMemoryStorageHelper()
      ..projects = [
        Project(
          id: 'p1',
          name: 'Cats',
          mode: LabelingMode.singleClassification,
          classes: const ['cat', 'dog'],
          dataInfos: const [
            DataInfo(id: 'd1', fileName: 'a.png', base64Content: _png),
            DataInfo(id: 'd2', fileName: 'b.png', base64Content: _png),
          ],
        ),
      ];

    await tester.pumpWidget(
      ProviderScope(
        overrides: [storageHelperProvider.overrideWithValue(storage), sharedPreferencesProvider.overrideWithValue(prefs)],
        child: const MaterialApp(
          localizationsDelegates: [AppLocalizations.delegate, GlobalMaterialLocalizations.delegate, GlobalWidgetsLocalizations.delegate],
          supportedLocales: [Locale('en'), Locale('ko')],
          home: ProjectListPage(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // 목록 + 진행률 요약(0/2)
    expect(find.text('Cats'), findsOneWidget);

    // 라벨링 진입 → 숫자 키로 첫 데이터 라벨 → 다음 → 두 번째 클래스
    await tester.tap(find.text('Labeling'));
    await tester.pumpAndSettle();
    expect(find.byType(ClassificationLabelingPage), findsOneWidget);
    expect(find.textContaining('a.png'), findsOneWidget);

    await tester.sendKeyEvent(LogicalKeyboardKey.digit1);
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.pumpAndSettle();
    expect(find.textContaining('b.png'), findsOneWidget);
    await tester.tap(find.widgetWithText(ElevatedButton, 'dog'));
    await tester.pumpAndSettle();

    expect(storage.stored('p1', 'd1')?.label, 'cat');
    expect(storage.stored('p1', 'd2')?.label, 'dog');

    // 뒤로 → 목록의 요약이 다시 계산되어 2/2 완료
    await tester.pageBack();
    await tester.pumpAndSettle();
    final container = ProviderScope.containerOf(tester.element(find.byType(ProjectListPage)));
    final summary = await container.read(projectSummaryProvider('p1').future);
    expect(summary.complete, 2);
    expect(summary.total, 2);

    // 편집 → 이름 변경 → 확정
    await tester.tap(find.text('Edit'));
    await tester.pumpAndSettle();
    expect(find.byType(ConfigureProjectPage), findsOneWidget);
    await tester.enterText(find.byType(TextFormField).first, 'Cats & Dogs');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Confirm'));
    await tester.pumpAndSettle();

    expect(find.text('Cats & Dogs'), findsOneWidget);
    expect(storage.projects.single.name, 'Cats & Dogs');
    expect(storage.stored('p1', 'd1')?.label, 'cat', reason: '이름 변경은 라벨을 건드리지 않음');

    // 삭제
    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();
    await tester.tap(find.descendant(of: find.byType(AlertDialog), matching: find.text('Delete')).last);
    await tester.pumpAndSettle();

    expect(find.text('No projects available. Please create a project.'), findsOneWidget);
    expect(storage.projects, isEmpty);
    expect(storage.stored('p1', 'd1'), isNull);

    // 남은 알림 타이머 정리
    await tester.pump(const Duration(seconds: 5));
  });
}
