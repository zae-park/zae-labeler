import 'dart:html' as html;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../view_models/project_view_model.dart';
import '../../view_models/locale_view_model.dart';
import '../../models/project_model.dart';
import '../pages/configuration_page.dart';
import '../../utils/storage_helper.dart';
import 'dart:convert';
import 'dart:io' as io;
import 'package:file_picker/file_picker.dart';

class ProjectListPage extends StatelessWidget {
  const ProjectListPage({Key? key}) : super(key: key);

  Future<void> _shareProject(BuildContext context, Project project) async {
    try {
      final projectJson = project.toJson();
      final jsonString = jsonEncode(projectJson);
      final directory = await getTemporaryDirectory();
      final file = io.File('${directory.path}/${project.name}_config.json');
      await file.writeAsString(jsonString);

      await Share.shareFiles([file.path], text: '${project.name} project configuration');
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to share project: $e')));
    }
  }

  Future<void> _downloadProjectConfig(BuildContext context, Project project) async {
    try {
      final projectJson = project.toJson();
      final jsonString = jsonEncode(projectJson);

      if (kIsWeb) {
        // Web 환경: 파일을 Blob 형태로 제공
        final blob = html.Blob([jsonString]);
        final url = html.Url.createObjectUrlFromBlob(blob);
        html.AnchorElement(href: url)
          ..setAttribute('download', '${project.name}_config.json')
          ..click();
        html.Url.revokeObjectUrl(url); // URL 해제
      } else {
        // Native 환경: 파일 시스템에 저장
        String filePath = await StorageHelper.instance.downloadProjectConfig(project);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Project configuration downloaded: $filePath')));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to download project configuration: $e')));
    }
  }

  Future<void> _importProject(BuildContext context) async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
        withData: true, // Web에서 데이터 로드를 위한 옵션
      );

      if (result != null) {
        final file = result.files.single;

        // Web 환경: bytes에서 읽기
        final content = file.bytes != null ? utf8.decode(file.bytes!) : await io.File(file.path!).readAsString(); // Native 환경

        final jsonData = jsonDecode(content);
        final project = Project.fromJson(jsonData);

        final projectVM = Provider.of<ProjectViewModel>(context, listen: false);
        await projectVM.saveProject(project);

        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Imported project: ${project.name}')));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('File selection cancelled.')));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to import project: $e')));
    }
  }

  Future<void> _confirmDelete(BuildContext context, ProjectViewModel projectVM, Project project) async {
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
      await projectVM.removeProject(project.id);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Deleted project: ${project.name}')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<ProjectViewModel, LocaleViewModel>(
      builder: (context, projectVM, localeVM, child) {
        return Scaffold(
          appBar: AppBar(
            title: Text(localeVM.currentLocale.languageCode == 'ko' ? '프로젝트 목록' : 'Project List'),
            actions: [
              PopupMenuButton<String>(
                onSelected: (value) => localeVM.changeLocale(value),
                itemBuilder: (context) => [
                  const PopupMenuItem(value: 'en', child: Text('English')),
                  const PopupMenuItem(value: 'ko', child: Text('한국어')),
                ],
                icon: const Icon(Icons.language),
              ),
              IconButton(
                icon: const Icon(Icons.add),
                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ConfigureProjectPage())),
                tooltip: localeVM.currentLocale.languageCode == 'ko' ? '프로젝트 생성' : 'Create Project',
              ),
              IconButton(
                icon: const Icon(Icons.file_upload),
                onPressed: () => _importProject(context),
                tooltip: localeVM.currentLocale.languageCode == 'ko' ? '프로젝트 가져오기' : 'Import Project',
              ),
            ],
          ),
          body: projectVM.projects.isEmpty
              ? Center(
                  child: Text(
                    localeVM.currentLocale.languageCode == 'ko' ? '등록된 프로젝트가 없습니다.' : 'No projects available.',
                  ),
                )
              : ListView.builder(
                  itemCount: projectVM.projects.length,
                  itemBuilder: (context, index) {
                    final project = projectVM.projects[index];
                    return _ProjectTile(
                      project: project,
                      // isLoading: !project.isDataLoaded,
                      // onLoadData: () async {
                      //   await projectVM.loadProjectData(project);
                      //   if (project.isDataLoaded) {
                      //     ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Loaded data for: ${project.name}')));
                      //   }
                      // },
                      onEdit: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ConfigureProjectPage(project: project))),
                      onDownload: () => _downloadProjectConfig(context, project),
                      onShare: () => _shareProject(context, project),
                      onDelete: () => _confirmDelete(context, projectVM, project),
                      onTap: () => Navigator.pushNamed(context, '/labeling', arguments: project),
                    );
                  },
                ),
        );
      },
    );
  }
}

class _ProjectTile extends StatelessWidget {
  final Project project;
  // final bool isLoaded;
  // final VoidCallback onLoadData;
  final VoidCallback onEdit;
  final VoidCallback onDownload;
  final VoidCallback onShare;
  final VoidCallback onDelete;
  final VoidCallback onTap;

  const _ProjectTile({
    Key? key,
    required this.project,
    // required this.isLoaded,
    // required this.onLoadData,
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
      // trailing: isLoading
      //     ? ElevatedButton(onPressed: onLoadData, child: const Text('Load Data'))
      //     : Row(
      //         mainAxisSize: MainAxisSize.min,
      //         children: [
      //           IconButton(icon: const Icon(Icons.edit), onPressed: onEdit, tooltip: 'Edit Project'),
      //           IconButton(icon: const Icon(Icons.download), onPressed: onDownload, tooltip: 'Download Configuration'),
      //           IconButton(icon: const Icon(Icons.share), onPressed: onShare, tooltip: 'Share Project'),
      //           IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: onDelete, tooltip: 'Delete Project'),
      //         ],
      //       ),
      // onTap: isLoading ? null : onTap,
    );
  }
}
