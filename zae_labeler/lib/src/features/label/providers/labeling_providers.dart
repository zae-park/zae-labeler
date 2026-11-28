// lib/src/features/label/providers/labeling_providers.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:zae_labeler/src/core/di/providers.dart';
import 'package:zae_labeler/src/core/models/project/project_model.dart';

import '../modes/labeling_mode_registry.dart';
import '../view_models/labeling_view_model.dart';

/// 프로젝트별 라벨링 VM.
///
/// - 생성: 모드 레지스트리([labelingModeSpecFor])가 결정
/// - 초기화: provider 안에서 `initialize()`까지 끝낸 뒤 노출 (로딩/에러는 AsyncValue로 표현)
/// - 해제: 페이지가 사라져 구독이 없어지면 autoDispose → `vm.dispose()` (단일 소유자)
/// - 실패 시 자동 재시도하지 않고 에러를 그대로 보여줍니다(사용자가 다시 시도).
final labelingViewModelProvider = FutureProvider.autoDispose.family<LabelingViewModel, Project>((ref, project) async {
  final deps = LabelingDeps(project: project, storageHelper: ref.watch(storageHelperProvider), labelUseCases: ref.watch(labelUseCasesProvider));
  final vm = labelingModeSpecFor(project.mode).createViewModel(deps);
  ref.onDispose(vm.dispose);
  await vm.initialize();
  return vm;
}, retry: (_, __) => null);
