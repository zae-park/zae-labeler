import 'package:flutter/material.dart';
import '../../models/project_model.dart';

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
    return ListTile(
      title: Text(project.name),
      subtitle: Text('Mode: ${project.mode.toString().split('.').last}'),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(icon: const Icon(Icons.edit), onPressed: onEdit, tooltip: 'Edit Project'),
          IconButton(icon: const Icon(Icons.download), onPressed: onDownload, tooltip: 'Download Configuration'),
          IconButton(icon: const Icon(Icons.share), onPressed: onShare, tooltip: 'Share Project'),
          IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: onDelete, tooltip: 'Delete Project'),
        ],
      ),
      onTap: onTap,
    );
  }
}
