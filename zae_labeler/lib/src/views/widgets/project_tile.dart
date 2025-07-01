import 'package:flutter/material.dart';
import 'package:zae_labeler/common/common_widgets.dart';
import '../../core/use_cases/app_use_cases.dart';
import '../../core/models/project_model.dart';
import '../../view_models/project_view_model.dart';
import '../../view_models/configuration_view_model.dart';
import '../pages/labeling_page.dart';
import '../../views/pages/configuration_page.dart';
import 'package:provider/provider.dart';
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
            create: (_) => ConfigurationViewModel.fromProject(vm.project, appUseCases: appUseCases), child: const ConfigureProjectPage()),
      ),
    );

    if (updated != null) {
      vm.updateFrom(updated); // ✅ ViewModel 내부 상태 갱신
      vm.onChanged?.call(updated); // ✅ 외부 콜백도 호출 (필요한 경우)
    }
  }

  Future<void> _confirmDelete(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Project'),
        content: Text('Are you sure you want to delete the project "${vm.project.name}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete', style: TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (confirmed == true) {
      final projectListVM = Provider.of<ProjectListViewModel>(context, listen: false);
      await projectListVM.removeProject(vm.project.id);

      if (context.mounted) {
        GlobalAlertManager.show(context, 'Deleted project: ${vm.project.name}', type: AlertType.error);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: AutoSeparatedColumn(
          separator: const SizedBox(height: 4),
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(vm.project.name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            Text("Mode: ${vm.project.mode.displayName}"),
            const SizedBox(height: 4),
            Wrap(
              spacing: 12,
              children: [
                ElevatedButton.icon(onPressed: () => _openLabelingPage(context), icon: const Icon(Icons.play_arrow), label: const Text("Label")),
                OutlinedButton.icon(onPressed: () => _openEditPage(context), icon: const Icon(Icons.edit), label: const Text("Edit")),
                OutlinedButton.icon(onPressed: () => vm.downloadProjectConfig(), icon: const Icon(Icons.download), label: const Text("Download")),
                OutlinedButton.icon(onPressed: () => vm.shareProject(context), icon: const Icon(Icons.share), label: const Text("Share")),
                TextButton.icon(
                  onPressed: () => _confirmDelete(context),
                  icon: const Icon(Icons.delete, color: Colors.red),
                  label: const Text("Delete", style: TextStyle(color: Colors.red)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
