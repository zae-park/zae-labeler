// test/features/label/labeling_providers_test.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:zae_labeler/l10n/app_localizations.dart';
import 'package:zae_labeler/src/core/di/providers.dart';
import 'package:zae_labeler/src/core/models/data/data_info.dart';
import 'package:zae_labeler/src/core/models/label/label_model.dart';
import 'package:zae_labeler/src/core/models/project/project_model.dart';
import 'package:zae_labeler/src/features/label/modes/labeling_mode_registry.dart';
import 'package:zae_labeler/src/features/label/providers/labeling_providers.dart';
import 'package:zae_labeler/src/features/label/repository/label_repository.dart';
import 'package:zae_labeler/src/features/label/use_cases/label_use_cases.dart';
import 'package:zae_labeler/src/features/label/ui/pages/labeling_page.dart';
import 'package:zae_labeler/src/features/label/ui/pages/sub_pages/classification_labeling_page.dart';
import 'package:zae_labeler/src/features/label/ui/pages/sub_pages/cross_classification_labeling_page.dart';
import 'package:zae_labeler/src/features/label/ui/pages/sub_pages/segmentation_labeling_page.dart';
import 'package:zae_labeler/src/features/label/view_models/classification_labeling_view_model.dart';
import 'package:zae_labeler/src/features/label/view_models/labeling_view_model.dart';
import 'package:zae_labeler/src/features/label/view_models/segmentation_labeling_view_model.dart';
import 'package:zae_labeler/src/features/project/repository/project_repository.dart';

import '../../support/in_memory_storage_helper.dart';

Project _project(LabelingMode mode) => Project(
  id: 'p-${mode.name}',
  name: 'Proj',
  mode: mode,
  classes: const ['A', 'B'],
  dataInfos: const [DataInfo(id: 'd1', fileName: 'missing.png')],
);

void main() {
  late InMemoryStorageHelper storage;

  setUp(() => storage = InMemoryStorageHelper());

  group('labelingModeSpecFor', () {
    LabelingDeps deps(LabelingMode m) {
      final s = InMemoryStorageHelper();
      return LabelingDeps(
        project: _project(m),
        storageHelper: s,
        labelUseCases: LabelUseCases.from(LabelRepository(storageHelper: s), ProjectRepository(storageHelper: s)),
      );
    }

    test('모든 모드가 알맞은 VM 타입을 만든다', () {
      expect(
        labelingModeSpecFor(LabelingMode.singleClassification).createViewModel(deps(LabelingMode.singleClassification)),
        isA<ClassificationLabelingViewModel>(),
      );
      expect(
        labelingModeSpecFor(LabelingMode.multiClassification).createViewModel(deps(LabelingMode.multiClassification)),
        isA<ClassificationLabelingViewModel>(),
      );
      expect(
        labelingModeSpecFor(LabelingMode.crossClassification).createViewModel(deps(LabelingMode.crossClassification)),
        isA<CrossClassificationLabelingViewModel>(),
      );
      expect(
        labelingModeSpecFor(LabelingMode.singleClassSegmentation).createViewModel(deps(LabelingMode.singleClassSegmentation)),
        isA<SegmentationLabelingViewModel>(),
      );
      expect(
        labelingModeSpecFor(LabelingMode.multiClassSegmentation).createViewModel(deps(LabelingMode.multiClassSegmentation)),
        isA<SegmentationLabelingViewModel>(),
      );
    });

    test('buildPage는 VM 타입에 맞는 페이지를 만든다', () {
      for (final (mode, pageType) in [
        (LabelingMode.singleClassification, ClassificationLabelingPage),
        (LabelingMode.crossClassification, CrossClassificationLabelingPage),
        (LabelingMode.multiClassSegmentation, SegmentationLabelingPage),
      ]) {
        final spec = labelingModeSpecFor(mode);
        expect(spec.buildPage(spec.createViewModel(deps(mode))).runtimeType, pageType);
      }
    });
  });

  group('labelingViewModelProvider', () {
    test('초기화된 VM을 노출하고, 구독이 끊기면 정확히 한 번 dispose한다', () async {
      final container = ProviderContainer(overrides: [storageHelperProvider.overrideWithValue(storage)]);
      addTearDown(container.dispose);

      final provider = labelingViewModelProvider(_project(LabelingMode.singleClassification));
      final sub = container.listen(provider, (_, __) {});

      final vm = await container.read(provider.future);
      expect(vm, isA<ClassificationLabelingViewModel>());
      expect(vm.isInitialized, isTrue);
      expect(storage.loadAllCalls, 1);

      sub.close();
      await container.pump();
      expect(vm.isDisposed, isTrue);
    });
  });

  testWidgets('LabelingPage: 로딩 후 모드별 페이지를 그리고, 화면을 벗어나면 VM을 해제한다', (tester) async {
    final container = ProviderContainer(overrides: [storageHelperProvider.overrideWithValue(storage)]);
    addTearDown(container.dispose);
    final project = _project(LabelingMode.singleClassification);

    Widget app(Widget home) => UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        localizationsDelegates: const [AppLocalizations.delegate, GlobalMaterialLocalizations.delegate, GlobalWidgetsLocalizations.delegate],
        supportedLocales: const [Locale('en'), Locale('ko')],
        home: home,
      ),
    );

    await tester.pumpWidget(app(LabelingPage(project: project)));
    expect(find.byType(CircularProgressIndicator), findsWidgets);

    await tester.pumpAndSettle();
    expect(find.byType(ClassificationLabelingPage), findsOneWidget);
    expect(find.text('라벨링할 데이터가 없습니다.'), findsNothing);
    expect(find.text('A'), findsOneWidget);

    final LabelingViewModel vm = container.read(labelingViewModelProvider(project)).requireValue;

    // 숫자 키 1 → 첫 번째 클래스 선택 (1회 저장)
    await tester.sendKeyEvent(LogicalKeyboardKey.digit1);
    await tester.pumpAndSettle();
    expect((vm as ClassificationLabelingViewModel).isLabelSelected('A'), isTrue);
    expect(storage.saveLabelCalls, 1);

    // 화면을 벗어나면 provider가 VM을 해제 (이중 dispose 없이)
    await tester.pumpWidget(app(const SizedBox()));
    await tester.pumpAndSettle();
    expect(vm.isDisposed, isTrue);
  });
}
