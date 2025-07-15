import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:zae_labeler/common/i18n.dart';
import 'package:zae_labeler/common/common_widgets.dart';
import 'package:zae_labeler/src/features/project/ui/widgets/progress_indicator.dart';
import '../../../../core/use_cases/app_use_cases.dart';
import '../../models/project_model.dart';
import '../../view_models/project_view_model.dart';
import '../../view_models/configuration_view_model.dart';
import '../../../label/ui/pages/labeling_page.dart';
import '../pages/configuration_page.dart';
import '../../view_models/project_list_view_model.dart';

class ProjectTile extends StatelessWidget {
  final ProjectViewModel vm;

  const ProjectTile({Key? key, required this.vm}) : super(key: key);

  void _openLabelingPage(BuildContext context) {
    Navigator.push(context, MaterialPageRoute(settings: const RouteSettings(name: '/labeling'), builder: (_) => LabelingPage(project: vm.project)));
  }

  void _openEditPage(BuildContext context) async {
    final appUseCases = Provider.of<AppUseCases>(context, listen: false);
    final updated = await Navigator.push<Project?>(
      context,
      MaterialPageRoute(
        settings: const RouteSettings(name: '/configuration'),
        builder: (_) => ChangeNotifierProvider(
          create: (_) => ConfigurationViewModel.fromProject(vm.project, appUseCases: appUseCases),
          child: const ConfigureProjectPage(),
        ),
      ),
    );

    if (updated != null) {
      vm.updateFrom(updated);
      vm.onChanged?.call(updated);
    }
  }

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
      final projectListVM = Provider.of<ProjectListViewModel>(context, listen: false);
      await projectListVM.removeProject(vm.project.id);

      if (context.mounted) {
        GlobalAlertManager.show(context, '${context.l10n.projectTile_deleteMessage}: ${vm.project.name}', type: AlertType.success);
      }
    }
  }

  Widget _buildSummaryIndicator(BuildContext context) {
    final projectId = vm.project.id;
    final projectListVM = context.watch<ProjectListViewModel>();
    final summary = projectListVM.summaries[projectId];

    // fetch summary if not loaded yet
    if (summary == null) {
      Future.microtask(() {
        final appUseCases = context.read<AppUseCases>();
        projectListVM.fetchSummary(projectId, appUseCases);
      });

      return const SizedBox(
        width: 64,
        height: 64,
        child: Center(child: CircularProgressIndicator(strokeWidth: 3)),
      );
    }

    return LabelingCircularProgressButton(summary: summary, onPressed: () => _openLabelingPage(context));
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ──────────────────────
            // 🔹 상단 요약 + 인디케이터
            // ──────────────────────
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: AutoSeparatedColumn(
                    separator: const SizedBox(height: 4),
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(vm.project.name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      Text("Mode: ${vm.project.mode.displayName}"),
                    ],
                  ),
                ),
                _buildSummaryIndicator(context),
              ],
            ),

            const SizedBox(height: 12),

            // ──────────────────────
            // 🔸 하단 버튼 그룹
            // ──────────────────────
            Wrap(
              spacing: 12,
              runSpacing: 8,
              children: [
                OutlinedButton.icon(
                  onPressed: () => _openEditPage(context),
                  icon: const Icon(Icons.edit),
                  label: Text(context.l10n.projectTile_edit),
                ),
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
    );
  }
}
