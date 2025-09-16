import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:zae_labeler/common/i18n.dart';
import 'package:zae_labeler/common/common_widgets.dart';
import 'package:zae_labeler/src/features/project/ui/widgets/progress_indicator.dart';
import '../../../../core/models/project/project_model.dart';
import '../../view_models/project_view_model.dart';
import '../../../label/ui/pages/labeling_page.dart';
import '../pages/configuration_page.dart';
import '../../view_models/project_list_view_model.dart';

class ProjectTile extends StatelessWidget {
  final ProjectViewModel vm;

  const ProjectTile({super.key, required this.vm});

  // 라벨링 페이지 이동 및 복귀 후 summary 강제 갱신
  Future<void> _openLabelingPage(BuildContext context) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        settings: const RouteSettings(name: '/labeling'),
        builder: (_) => LabelingPage(project: vm.project),
      ),
    );

    if (result == true && context.mounted) {
      final listVM = context.read<ProjectListViewModel>();
      await listVM.fetchSummary(vm.project.id, force: true);
    }
  }

  // 설정 페이지 이동 (기존 VM 그대로 전달)
  Future<void> _openEditPage(BuildContext context) async {
    final updated = await Navigator.push<Project?>(
      context,
      MaterialPageRoute(
        settings: const RouteSettings(name: '/configuration'),
        builder: (_) => ChangeNotifierProvider<ProjectViewModel>.value(value: vm, child: const ConfigureProjectPage()),
      ),
    );

    if (updated != null) {
      vm.updateFrom(updated);
      vm.onChanged?.call(updated);
      // 편집 후에도 진행률 요약은 변동 가능 → 갱신
      if (context.mounted) await context.read<ProjectListViewModel>().fetchSummary(vm.project.id, force: true);
    }
  }

  // 삭제 확인
  Future<void> _confirmDelete(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.l10n.projectTile_delete),
        content: Text('${context.l10n.projectTile_deleteEnsure} "${vm.project.name}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text(context.l10n.common_cancel)),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(context.l10n.projectTile_delete, style: const TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final projectListVM = context.read<ProjectListViewModel>();
      await projectListVM.removeProject(vm.project.id);

      if (context.mounted) {
        GlobalAlertManager.show(context, '${context.l10n.projectTile_deleteMessage}: ${vm.project.name}', type: AlertType.success);
      }
    }
  }

  // 타일 개별 오버플로 메뉴 (재계산/삭제)
  Widget _overflowMenu(BuildContext context) {
    return PopupMenuButton<String>(
      onSelected: (value) async {
        switch (value) {
          case 'recalc':
            await context.read<ProjectListViewModel>().fetchSummary(vm.project.id, force: true);
            break;
          case 'delete':
            await _confirmDelete(context);
            break;
        }
      },
      itemBuilder: (ctx) => [const PopupMenuItem(value: 'recalc', child: Text('진행률 재계산')), const PopupMenuItem(value: 'delete', child: Text('삭제'))],
    );
  }

  @override
  Widget build(BuildContext context) {
    final projectId = vm.project.id;
    final listVM = context.watch<ProjectListViewModel>();
    final summary = listVM.summaries[projectId];

    // 요약이 아직 없고, 현재 전역 프리로드 중이 아니면 지연 로드 1회
    if (summary == null && !listVM.isPreloadingSummaries) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) context.read<ProjectListViewModel>().fetchSummary(projectId);
      });
    }

    final modeText = vm.project.mode.name;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // 🔹 좌측 정보 + 오버플로 메뉴
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Text(
                          vm.project.name,
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ),
                      _overflowMenu(context), // ⋮
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text('Mode: $modeText'),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 12,
                    runSpacing: 8,
                    children: [
                      ElevatedButton.icon(
                        onPressed: () => _openLabelingPage(context),
                        icon: const Icon(Icons.play_arrow),
                        label: Text(context.l10n.projectTile_label),
                      ),
                      OutlinedButton.icon(onPressed: () => _openEditPage(context), icon: const Icon(Icons.edit), label: Text(context.l10n.projectTile_edit)),
                      OutlinedButton.icon(
                        onPressed: () => vm.downloadProjectConfig(),
                        icon: const Icon(Icons.download),
                        label: Text(context.l10n.projectTile_download),
                      ),
                      OutlinedButton.icon(
                        onPressed: () => vm.shareProject(context),
                        icon: const Icon(Icons.share),
                        label: Text(context.l10n.projectTile_share),
                      ),
                      TextButton.icon(
                        onPressed: () => _confirmDelete(context),
                        icon: const Icon(Icons.delete, color: Colors.red),
                        label: Text(context.l10n.projectTile_delete, style: const TextStyle(color: Colors.red)),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(width: 12),

            // 🔸 우측 인디케이터 (항상 고정 크기)
            SizedBox(
              width: 110,
              height: 110,
              child: summary != null
                  ? LabelingCircularProgressButton(summary: summary, onPressed: () => _openLabelingPage(context))
                  : const Center(child: SizedBox(width: 64, height: 64, child: CircularProgressIndicator(strokeWidth: 3))),
            ),
          ],
        ),
      ),
    );
  }
}
