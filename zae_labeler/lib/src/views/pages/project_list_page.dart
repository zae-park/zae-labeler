// lib/src/pages/project_list_page.dart
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../view_models/project_view_model.dart';
import '../../models/project_model.dart';
import '../pages/configuration_page.dart'; // 프로젝트 설정 수정 페이지
import '../../utils/storage_helper.dart';
import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart'; // 파일 선택을 위한 패키지 추가

class ProjectListPage extends StatelessWidget {
  const ProjectListPage({Key? key}) : super(key: key);

  // 프로젝트 공유 기능
  Future<void> _shareProject(BuildContext context, Project project) async {
    try {
      final projectJson = project.toJson();
      final jsonString = jsonEncode(projectJson);
      final directory = await getTemporaryDirectory();
      final file = File('${directory.path}/${project.name}_config.json');
      await file.writeAsString(jsonString);

      await Share.shareFiles([file.path], text: '${project.name} 프로젝트 설정 공유');
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('프로젝트 공유 실패: $e')),
      );
    }
  }

  // 프로젝트 설정 파일 다운로드 기능
  Future<void> _downloadProjectConfig(
      BuildContext context, Project project) async {
    try {
      String filePath = await StorageHelper.downloadProjectConfig(project);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('프로젝트 설정 파일이 다운로드되었습니다: $filePath')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('프로젝트 설정 파일 다운로드 실패: $e')),
      );
    }
  }

  // 프로젝트 가져오기 기능 (파일 선택 다이얼로그 사용)
  Future<void> _importProject(BuildContext context) async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );

      if (result != null && result.files.single.path != null) {
        String filePath = result.files.single.path!;
        final file = File(filePath);
        if (await file.exists()) {
          final content = await file.readAsString();
          final jsonData = jsonDecode(content);
          final project = Project.fromJson(jsonData);

          final projectVM =
              Provider.of<ProjectViewModel>(context, listen: false);
          await projectVM.saveProject(project);

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('${project.name} 프로젝트가 가져와졌습니다.')),
          );
        } else {
          throw Exception('선택한 파일이 존재하지 않습니다.');
        }
      } else {
        // 사용자가 파일 선택을 취소한 경우
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('파일 선택이 취소되었습니다.')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('프로젝트 가져오기 실패: $e')),
      );
    }
  }

  // 프로젝트 삭제 시 확인 다이얼로그
  Future<void> _confirmDelete(
      BuildContext context, ProjectViewModel projectVM, Project project) async {
    bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('프로젝트 삭제'),
        content: Text('${project.name} 프로젝트를 정말 삭제하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('삭제', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await projectVM.removeProject(project.id);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${project.name} 프로젝트가 삭제되었습니다.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ProjectViewModel>(
      builder: (context, projectVM, child) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('프로젝트 목록'),
            actions: [
              IconButton(
                icon: const Icon(Icons.add),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const ConfigureProjectPage()),
                  );
                },
                tooltip: '프로젝트 생성',
              ),
              IconButton(
                icon: const Icon(Icons.file_upload),
                onPressed: () {
                  _importProject(context);
                },
                tooltip: '프로젝트 가져오기',
              ),
            ],
          ),
          body: ListView.builder(
            itemCount: projectVM.projects.length,
            itemBuilder: (context, index) {
              final project = projectVM.projects[index];
              return ListTile(
                title: Text(project.name),
                subtitle:
                    Text('모드: ${project.mode.toString().split('.').last}'),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                ConfigureProjectPage(project: project),
                          ),
                        );
                      },
                      tooltip: '프로젝트 수정',
                    ),
                    IconButton(
                      icon: const Icon(Icons.download),
                      onPressed: () => _downloadProjectConfig(context, project),
                      tooltip: '프로젝트 설정 다운로드',
                    ),
                    IconButton(
                      icon: const Icon(Icons.share),
                      onPressed: () => _shareProject(context, project),
                      tooltip: '프로젝트 공유',
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () =>
                          _confirmDelete(context, projectVM, project),
                      tooltip: '프로젝트 삭제',
                    ),
                  ],
                ),
                onTap: () {
                  // 프로젝트 선택 시 라벨링 페이지로 이동
                  Navigator.pushNamed(context, '/labeling', arguments: project);
                },
              );
            },
          ),
        );
      },
    );
  }
}
