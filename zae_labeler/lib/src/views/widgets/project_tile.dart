import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/project_model.dart';
import '../../utils/share_helper.dart';
import '../../view_models/project_view_model.dart';

class ProjectTile extends StatelessWidget {
  final Project project;
  final VoidCallback onEdit;
  final VoidCallback onDownload;
  final VoidCallback onShare;
  final VoidCallback onDelete;
  final VoidCallback onTap;

  const ProjectTile({
    Key? key,
    required this.project,
    required this.onEdit,
    required this.onDownload,
    required this.onShare,
    required this.onDelete,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ProjectViewModel(storageHelper: Provider.of(context, listen: false), shareHelper: getShareHelper(), project: project),
      child: Consumer<ProjectViewModel>(
        builder: (context, vm, _) {
          final actionMap = <String, VoidCallback>{'edit': onEdit, 'download': onDownload, 'share': onShare, 'delete': onDelete};

          return Card(
            child: ListTile(
              title: Text(project.name),
              subtitle: Text(project.mode.displayName),
              onTap: onTap,
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
