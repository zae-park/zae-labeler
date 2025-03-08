import 'dart:convert';
import 'dart:io' as io;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import '../../view_models/project_list_view_model.dart';
import '../../view_models/project_view_model.dart';
import '../../view_models/locale_view_model.dart';
import '../../models/project_model.dart';
import '../pages/configuration_page.dart';
import '../../utils/storage_helper.dart';
import '../widgets/project_tile.dart';

class ProjectListPage extends StatefulWidget {
  const ProjectListPage({Key? key}) : super(key: key);

  @override
  State<ProjectListPage> createState() => _ProjectListPageState();
}

class _ProjectListPageState extends State<ProjectListPage> {
  /// ✅ 프로젝트 가져오기 (Import)
  Future<void> _importProject(BuildContext context) async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );

      if (result != null) {
        final file = result.files.single;
        final content = file.bytes != null ? utf8.decode(file.bytes!) : await io.File(file.path!).readAsString();
        final jsonData = jsonDecode(content);
        final project = Project.fromJson(jsonData);

        if (!mounted) return;
        final projectListVM = Provider.of<ProjectListViewModel>(context, listen: false);
        await projectListVM.saveProject(project);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Imported project: ${project.name}')));
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to import project: $e')));
      }
    }
  }

  /// ✅ 프로젝트 삭제 확인 다이얼로그
  Future<void> _confirmDelete(BuildContext context, ProjectViewModel projectVM, ProjectListViewModel projectListVM) async {
    bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Project'),
        content: Text('Are you sure you want to delete the project "${projectVM.project.name}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete', style: TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (confirmed == true) {
      await projectVM.deleteProject(); // ✅ `ProjectViewModel`을 사용하여 삭제
      await projectListVM.removeProject(projectVM.project.id);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Deleted project: ${projectVM.project.name}')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<ProjectListViewModel, LocaleViewModel>(
      builder: (context, projectListVM, localeVM, child) {
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
          body: projectListVM.projects.isEmpty
              ? Center(
                  child: Text(
                    localeVM.currentLocale.languageCode == 'ko' ? '등록된 프로젝트가 없습니다.' : 'No projects available.',
                  ),
                )
              : ListView.builder(
                  itemCount: projectListVM.projects.length,
                  itemBuilder: (context, index) {
                    final project = projectListVM.projects[index];

                    return ChangeNotifierProvider(
                      create: (context) => ProjectViewModel(storageHelper: StorageHelper.instance, project: project),
                      child: Consumer<ProjectViewModel>(
                        builder: (context, projectVM, _) {
                          return ProjectTile(
                            project: project,
                            onEdit: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (_) => ChangeNotifierProvider(
                                        create: (_) => ConfigurationViewModel(),
                                        child: const ConfigureProjectPage(),
                                    ),
                                ),
                            ),
                            onDownload: () => projectVM.downloadProjectConfig(),
                            onShare: () => projectVM.shareProject(context),
                            onDelete: () => _confirmDelete(context, projectVM, projectListVM),
                            onTap: () => Navigator.pushNamed(context, '/labeling', arguments: project),
                          );
                        },
                      ),
                    );
                  },
                ),
        );
      },
    );
  }
}
