import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:zae_labeler/common/common_widgets.dart';
import 'package:zae_labeler/common/i18n.dart';

import '../../../../core/models/project/project_model.dart';
import '../../../label/ui/pages/labeling_page.dart';
import '../../providers/project_providers.dart';
import '../pages/configuration_page.dart';
import 'progress_indicator.dart';

class ProjectTile extends ConsumerWidget {
  final Project project;

  const ProjectTile({super.key, required this.project});

  Future<void> _openLabelingPage(BuildContext context, WidgetRef ref) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        settings: const RouteSettings(name: '/labeling'),
        builder: (_) => LabelingPage(project: project),
      ),
    );
    // 라벨링 후 진행률 요약 갱신
    if (result == true) ref.invalidate(projectSummaryProvider(project.id));
  }

  void _openEditPage(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        settings: const RouteSettings(name: '/configuration'),
        builder: (_) => ConfigureProjectPage(project: project),
      ),
    );
  }

  Future<void> _download(BuildContext context, WidgetRef ref) async {
    try {
      await ref.read(projectListProvider.notifier).exportConfig(project);
    } catch (e) {
      debugPrint('❌ Failed to download config: $e');
      if (context.mounted) GlobalAlertManager.show(context, '⚠️ 다운로드에 실패했습니다: $e', type: AlertType.error);
    }
  }

  Future<void> _share(BuildContext context, WidgetRef ref) async {
    try {
      await ref.read(projectListProvider.notifier).share(project);
      if (context.mounted) GlobalAlertManager.show(context, '✅ 프로젝트 공유 준비가 완료되었습니다.', type: AlertType.success);
    } catch (e) {
      if (context.mounted) GlobalAlertManager.show(context, '⚠️ 프로젝트 공유에 실패했습니다: $e', type: AlertType.error);
    }
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.l10n.projectTile_delete),
        content: Text('${context.l10n.projectTile_deleteEnsure} "${project.name}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text(context.l10n.common_cancel)),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(context.l10n.projectTile_delete, style: const TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    await ref.read(projectListProvider.notifier).remove(project.id);
    if (context.mounted) {
      GlobalAlertManager.show(context, '${context.l10n.projectTile_deleteMessage}: ${project.name}', type: AlertType.success);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summary = ref.watch(projectSummaryProvider(project.id)).value;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // 🔹 좌측 정보
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(project.name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text('Mode: ${project.mode.name}'),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 12,
                    runSpacing: 8,
                    children: [
                      ElevatedButton.icon(
                        onPressed: () => _openLabelingPage(context, ref),
                        icon: const Icon(Icons.play_arrow),
                        label: Text(context.l10n.projectTile_label),
                      ),
                      OutlinedButton.icon(onPressed: () => _openEditPage(context), icon: const Icon(Icons.edit), label: Text(context.l10n.projectTile_edit)),
                      OutlinedButton.icon(
                        onPressed: () => _download(context, ref),
                        icon: const Icon(Icons.download),
                        label: Text(context.l10n.projectTile_download),
                      ),
                      OutlinedButton.icon(onPressed: () => _share(context, ref), icon: const Icon(Icons.share), label: Text(context.l10n.projectTile_share)),
                      TextButton.icon(
                        onPressed: () => _confirmDelete(context, ref),
                        icon: const Icon(Icons.delete, color: Colors.red),
                        label: Text(context.l10n.projectTile_delete, style: const TextStyle(color: Colors.red)),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(width: 12),

            // 🔸 우측 인디케이터
            summary != null
                ? SizedBox(
                    width: 110,
                    height: 110,
                    child: LabelingCircularProgressButton(summary: summary, onPressed: () => _openLabelingPage(context, ref)),
                  )
                : const SizedBox(width: 64, height: 64, child: Center(child: CircularProgressIndicator(strokeWidth: 3))),
          ],
        ),
      ),
    );
  }
}
