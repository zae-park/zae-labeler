import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/project_model.dart';
import '../../utils/share_helper.dart';
import '../../view_models/project_list_view_model.dart';
import '../../view_models/project_view_model.dart';
import '../../view_models/configuration_view_model.dart';
import '../../views/pages/configuration_page.dart';

class ProjectTile extends StatelessWidget {
  final Project project;

  const ProjectTile({Key? key, required this.project}) : super(key: key);

  void _openLabelingPage(BuildContext context, Project p) {
    Navigator.pushNamed(context, '/labeling', arguments: p);
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
      create: (_) => ProjectViewModel(storageHelper: Provider.of(context, listen: false), shareHelper: getShareHelper(), project: project),
      child: Consumer<ProjectViewModel>(
        builder: (context, vm, _) {
          final actionMap = <String, VoidCallback>{
            'edit': () => _openEditPage(context, vm.project),
            'download': () => vm.downloadProjectConfig(),
            'share': () => vm.shareProject(context),
            'delete': () => _confirmDelete(context, vm.project, vm),
          };

          return Card(
            child: ListTile(
              title: Text(project.name),
              subtitle: Text(project.mode.displayName),
              onTap: () => _openLabelingPage(context, vm.project),
              trailing: PopupMenuButton<String>(
                onSelected: (value) => actionMap[value]?.call(),
                itemBuilder: (context) => [
                  const PopupMenuItem(value: 'edit', child: Text('Edit')),
                  const PopupMenuItem(value: 'download', child: Text('Download')),
                  const PopupMenuItem(value: 'share', child: Text('Share')),
                  const PopupMenuItem(value: 'delete', child: Text('Delete')),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
