import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:zae_labeler/common/common_widgets.dart';

import '../../models/project_model.dart';
import '../../utils/share_helper.dart';
import '../../view_models/project_list_view_model.dart';
import '../../view_models/project_view_model.dart';
import '../../view_models/configuration_view_model.dart';
import '../../views/pages/configuration_page.dart';
import '../pages/labeling_page.dart';
import '../../repositories/project_repository.dart';

class ProjectTile extends StatelessWidget {
  final Project project;

  const ProjectTile({Key? key, required this.project}) : super(key: key);

  void _openLabelingPage(BuildContext context, Project p) async {
    if (!context.mounted) return;
    Navigator.push(context, MaterialPageRoute(builder: (_) => LabelingPage(project: p)));
  }

  void _openEditPage(BuildContext context, Project p) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChangeNotifierProvider(
          create: (_) => ConfigurationViewModel.fromProject(p),
          child: const ConfigureProjectPage(),
        ),
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, Project project, ProjectViewModel vm) async {
    bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Project'),
        content: Text('Are you sure you want to delete the project "${project.name}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete', style: TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (confirmed == true) {
      final projectListVM = Provider.of<ProjectListViewModel>(context, listen: false);
      await vm.deleteProject();
      await projectListVM.removeProject(project.id);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Deleted project: ${project.name}')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ProjectViewModel(
        repository: Provider.of<ProjectRepository>(context, listen: false),
        shareHelper: getShareHelper(),
        project: project,
      ),
      child: Consumer<ProjectViewModel>(
        builder: (context, vm, _) {
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
                      ElevatedButton.icon(
                          onPressed: () => _openLabelingPage(context, vm.project), icon: const Icon(Icons.play_arrow), label: const Text("Label")),
                      OutlinedButton.icon(onPressed: () => _openEditPage(context, vm.project), icon: const Icon(Icons.edit), label: const Text("Edit")),
                      OutlinedButton.icon(onPressed: () => vm.downloadProjectConfig(), icon: const Icon(Icons.download), label: const Text("Download")),
                      OutlinedButton.icon(onPressed: () => vm.shareProject(context), icon: const Icon(Icons.share), label: const Text("Share")),
                      TextButton.icon(
                          onPressed: () => _confirmDelete(context, vm.project, vm),
                          icon: const Icon(Icons.delete, color: Colors.red),
                          label: const Text("Delete", style: TextStyle(color: Colors.red)))
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
