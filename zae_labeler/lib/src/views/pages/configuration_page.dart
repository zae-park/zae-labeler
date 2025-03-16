import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../view_models/configuration_view_model.dart';
import '../../view_models/project_list_view_model.dart';
import '../widgets/labeling_mode_selector.dart';

/// ✅ **ConfigureProjectPage**
/// - 새 프로젝트 생성 및 기존 프로젝트 편집을 담당하는 페이지.
/// - `ConfigurationViewModel`을 사용하여 프로젝트 정보를 관리.
/// - 기존 프로젝트를 편집하는 경우 "Create Project"가 아닌 "Update Project" 버튼을 표시.
class ConfigureProjectPage extends StatelessWidget {
  const ConfigureProjectPage({Key? key}) : super(key: key);

  /// ✅ 클래스 추가 다이얼로그
  void _addClass(BuildContext context) {
    final classController = TextEditingController();
    final configVM = Provider.of<ConfigurationViewModel>(context, listen: false);

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Add Class'),
          content: TextField(controller: classController, decoration: const InputDecoration(labelText: 'Class Name')),
          actions: [
            TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Cancel')),
            TextButton(
              onPressed: () {
                final className = classController.text.trim();
                if (className.isNotEmpty) {
                  configVM.addClass(className);
                  Navigator.pop(dialogContext);
                }
              },
              child: const Text('Add'),
            ),
          ],
        );
      },
    );
  }

  /// ✅ 프로젝트 생성/수정 버튼 핸들러
  void _confirmProject(BuildContext context) {
    final configVM = Provider.of<ConfigurationViewModel>(context, listen: false);
    final projectListVM = Provider.of<ProjectListViewModel>(context, listen: false);

    final updatedProject = configVM.project;
    final isNewProject = !configVM.isEditing;

    if (isNewProject) {
      projectListVM.saveProject(updatedProject);
    } else {
      projectListVM.updateProject(context, updatedProject);
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${updatedProject.name} project has been ${isNewProject ? "created" : "updated"}.')),
    );

    configVM.reset();
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ConfigurationViewModel>(
      builder: (context, configVM, child) {
        return Scaffold(
          appBar: AppBar(title: Text(configVM.isEditing ? 'Edit Project' : 'Create Project')),
          body: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Form(
              child: ListView(
                children: [
                  /// ✅ 프로젝트 이름 입력 (기존 프로젝트 수정 시, 기존 값 유지)
                  TextFormField(
                    initialValue: configVM.project.name, // ✅ 기존 프로젝트 이름 유지
                    decoration: const InputDecoration(labelText: 'Project Name'),
                    onChanged: (value) => configVM.setProjectName(value),
                    validator: (value) => (value == null || value.isEmpty) ? "Please enter a project name" : null,
                  ),
                  const SizedBox(height: 16),

                  /// ✅ 라벨링 모드 선택
                  LabelingModeSelector.dropdown(
                    selectedMode: configVM.project.mode,
                    onModeChanged: (newMode) => configVM.setLabelingMode(newMode),
                  ),
                  const SizedBox(height: 16),

                  /// ✅ 클래스 관리 (추가 / 삭제)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Classes', style: TextStyle(fontSize: 16)),
                      IconButton(icon: const Icon(Icons.add), onPressed: () => _addClass(context), tooltip: 'Add Class'),
                    ],
                  ),
                  ...configVM.project.classes.asMap().entries.map((entry) {
                    int index = entry.key;
                    String className = entry.value;
                    return ListTile(
                      title: Text(className),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => configVM.removeClass(index),
                        tooltip: 'Remove Class',
                      ),
                    );
                  }).toList(),

                  const SizedBox(height: 16),

                  /// ✅ 데이터 경로 선택
                  ElevatedButton.icon(
                    icon: const Icon(Icons.folder_open),
                    label: const Text('Select Data Directory'),
                    onPressed: () => configVM.addDataPath(),
                  ),
                  const SizedBox(height: 32),

                  /// ✅ 프로젝트 생성/수정 버튼
                  ElevatedButton(
                    onPressed: () => _confirmProject(context),
                    child: Text(configVM.isEditing ? 'Update Project' : 'Create Project'),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
