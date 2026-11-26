// lib/src/features/label/ui/pages/labeling_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/models/project/project_model.dart';
import '../../modes/labeling_mode_registry.dart';
import '../../providers/labeling_providers.dart';

/// 라벨링 진입 페이지.
/// VM 생성·초기화·dispose는 [labelingViewModelProvider]가 담당하고,
/// 이 페이지는 상태(로딩/에러/데이터)에 따라 모드별 페이지를 보여주기만 합니다.
class LabelingPage extends ConsumerWidget {
  final Project project;

  const LabelingPage({super.key, required this.project});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final provider = labelingViewModelProvider(project);
    final state = ref.watch(provider);

    return state.when(
      data: (vm) => labelingModeSpecFor(project.mode).buildPage(vm),
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (error, stack) {
        debugPrint('❌ Labeling init error: $error\n$stack');
        return Scaffold(
          appBar: AppBar(title: Text(project.name)),
          body: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('초기화 실패'),
                const SizedBox(height: 8),
                Text(
                  '$error',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.red, fontSize: 12),
                ),
                const SizedBox(height: 16),
                ElevatedButton(onPressed: () => ref.invalidate(provider), child: const Text('다시 시도')),
              ],
            ),
          ),
        );
      },
    );
  }
}
