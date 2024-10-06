// lib/src/pages/project_list_page.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../view_models/project_manager.dart';
import '../models/project_model.dart';

class ProjectListPage extends StatelessWidget {
  const ProjectListPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ProjectManager(),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('프로젝트 목록'),
        ),
        body: Consumer<ProjectManager>(
          builder: (context, projectManager, child) {
            return ListView.builder(
              itemCount: projectManager.projects.length,
              itemBuilder: (context, index) {
                final project = projectManager.projects[index];
                return ListTile(
                  title: Text(project.name),
                  onTap: () {
                    // 프로젝트 선택 시 라벨링 페이지로 이동
                    Navigator.pushNamed(
                      context,
                      '/labeling',
                      arguments: project,
                    );
                  },
                );
              },
            );
          },
        ),
        floatingActionButton: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            FloatingActionButton(
              heroTag: 'createProject',
              onPressed: () {
                // 새 프로젝트 생성 페이지로 이동
                Navigator.pushNamed(context, '/configuration');
              },
              tooltip: '새 프로젝트 생성',
              child: const Icon(Icons.add),
            ),
            const SizedBox(height: 10),
            FloatingActionButton(
              heroTag: 'loadProject',
              onPressed: () {
                // 프로젝트 목록은 이미 메인 페이지에 표시됨
                // 추가적인 로드 로직이 필요하다면 구현
              },
              tooltip: '프로젝트 불러오기',
              child: const Icon(Icons.folder_open),
            ),
          ],
        ),
      ),
    );
  }
}
