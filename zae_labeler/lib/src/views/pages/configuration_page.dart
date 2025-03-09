import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../view_models/configuration_view_model.dart';
import '../../view_models/project_list_view_model.dart';
import '../widgets/labeling_mode_selector.dart';

/// ✅ **ConfigureProjectPage**
/// - 프로젝트 생성 페이지 (StatelessWidget)
/// - `ConfigurationViewModel`을 사용하여 설정 관리
class ConfigureProjectPage extends StatelessWidget {
  const ConfigureProjectPage({Key? key}) : super(key: key);

  void _addClass(BuildContext context) {
    final classController = TextEditingController();
    final configVM = Provider.of<ConfigurationViewModel>(context, listen: false); // ✅ 다이얼로그 내부에서 찾지 않도록 미리 가져오기

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

  void _confirmProject(BuildContext context) {
    final configVM = Provider.of<ConfigurationViewModel>(context, listen: false);
    final projectListVM = Provider.of<ProjectListViewModel>(context, listen: false);

    final isNewProject = configVM.projectName.isEmpty; // ✅ 기존 프로젝트인지 새 프로젝트인지 확인
    final newProject = configVM.createProject();

    if (isNewProject) {
      projectListVM.saveProject(configVM.createProject());
    } else {
      projectListVM.updateProject(context, newProject); // ✅ 기존 프로젝트 수정 메서드 추가
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${newProject.name} project has been ${isNewProject ? "created" : "updated"}.')),
    );

    configVM.reset();
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ConfigurationViewModel>(
      builder: (context, configVM, child) {
        return Scaffold(
          appBar: AppBar(title: const Text('Create Project')),
          body: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Form(
              child: ListView(
                children: [
                  /// ✅ 프로젝트 이름 입력
                  TextFormField(
                    decoration: const InputDecoration(labelText: 'Project Name'),
                    onChanged: (value) => configVM.setProjectName(value),
                    validator: (value) => (value == null || value.isEmpty) ? "Please enter a project name" : null,
                  ),
                  const SizedBox(height: 16),

                  /// ✅ 라벨링 모드 선택
                  LabelingModeSelector.dropdown(
                    selectedMode: configVM.selectedMode,
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
                  ...configVM.classes.asMap().entries.map((entry) {
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

                  /// ✅ 프로젝트 생성 버튼
                  ElevatedButton(
                    onPressed: () => _confirmProject(context),
                    child: const Text('Create Project'),
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


// class ConfigureProjectPage extends StatefulWidget {
//   final Project? project;

//   const ConfigureProjectPage({Key? key, this.project}) : super(key: key);

//   @override
//   ConfigureProjectPageState createState() => ConfigureProjectPageState();
// }

// class ConfigureProjectPageState extends State<ConfigureProjectPage> {
//   final _formKey = GlobalKey<FormState>();
//   final _nameController = TextEditingController();

//   @override
//   void initState() {
//     super.initState();
//     final projectVM = Provider.of<ProjectViewModel>(context, listen: false);

//     if (widget.project != null) {
//       _nameController.text = projectVM.project.name;
//     }
//   }

//   @override
//   void dispose() {
//     _nameController.dispose();
//     super.dispose();
//   }

//   void _addClass() {
//     showDialog(
//       context: context,
//       builder: (context) {
//         final classController = TextEditingController();

//         return AlertDialog(
//           title: const Text('Add Class'),
//           content: TextField(controller: classController, decoration: const InputDecoration(labelText: 'Class Name')),
//           actions: [
//             TextButton(
//               onPressed: () {
//                 if (classController.text.isNotEmpty) {
//                   setState(() => Provider.of<ProjectViewModel>(context, listen: false).addClass(classController.text));
//                   Navigator.pop(context);
//                 }
//               },
//               child: const Text('Add'),
//             ),
//           ],
//         );
//       },
//     );
//   }

//   void _removeClass(int index) {
//     setState(() => Provider.of<ProjectViewModel>(context, listen: false).removeClass(index));
//   }

//   Future<void> _pickData() async {
//     final projectVM = Provider.of<ProjectViewModel>(context, listen: false);

//     if (kIsWeb) {
//       FilePickerResult? result = await FilePicker.platform.pickFiles(allowMultiple: true, withData: true);

//       if (result != null) {
//         setState(() {
//           for (var file in result.files) {
//             projectVM.addDataPath(DataPath(fileName: file.name, base64Content: base64Encode(file.bytes ?? [])));
//           }
//         });
//       }
//     } else {
//       String? selectedDirectory = await FilePicker.platform.getDirectoryPath();
//       if (selectedDirectory != null) {
//         setState(() {
//           final directory = Directory(selectedDirectory);
//           final files = directory.listSync().whereType<File>();
//           for (var file in files) {
//             projectVM.addDataPath(DataPath(fileName: file.uri.pathSegments.last, filePath: file.path));
//           }
//         });
//       }
//     }
//   }

//   Future<void> _confirmProject() async {
//     if (_formKey.currentState!.validate()) {
//       final projectVM = Provider.of<ProjectViewModel>(context, listen: false);
//       final projectListVM = Provider.of<ProjectListViewModel>(context, listen: false);

//       bool isNewProject = widget.project == null;
//       if (!isNewProject && projectVM.isLabelingModeChanged()) {
//         bool confirmChange = await _showLabelingModeChangeDialog(context);
//         if (!confirmChange) return;
//       }

//       await projectVM.saveProject(isNewProject);
//       projectListVM.loadProjects(); // 프로젝트 목록 업데이트

//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('${projectVM.project.name} project has been ${isNewProject ? 'created' : 'updated'}.')),
//       );

//       if (!mounted) return;
//       Navigator.pop(context);
//     }
//   }

//   Future<bool> _showLabelingModeChangeDialog(BuildContext context) async {
//     return await showDialog<bool>(
//           context: context,
//           builder: (BuildContext context) {
//             return AlertDialog(
//               title: const Text('Labeling Mode 변경 경고'),
//               content: const Text('Labeling Mode를 변경하면 기존 작업 내용이 삭제될 수 있습니다. 변경하시겠습니까?'),
//               actions: [
//                 TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('취소')),
//                 TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('확인')),
//               ],
//             );
//           },
//         ) ??
//         false;
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Consumer<ProjectViewModel>(
//       builder: (context, projectVM, child) {
//         return Scaffold(
//           appBar: AppBar(title: Text(widget.project == null ? 'Create Project' : 'Edit Project')),
//           body: Padding(
//             padding: const EdgeInsets.all(16.0),
//             child: Form(
//               key: _formKey,
//               child: ListView(
//                 children: [
//                   TextFormField(
//                     controller: _nameController,
//                     decoration: const InputDecoration(labelText: 'Project Name'),
//                     onChanged: (value) => projectVM.setName(value),
//                     validator: (value) => (value == null || value.isEmpty) ? "Please enter a project name" : null,
//                   ),
//                   const SizedBox(height: 16),
//                   LabelingModeSelector.dropdown(
//                     selectedMode: projectVM.project.mode,
//                     onModeChanged: (newMode) => projectVM.setLabelingMode(newMode),
//                   ),
//                   const SizedBox(height: 16),
//                   Row(
//                     mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                     children: [
//                       const Text('Classes', style: TextStyle(fontSize: 16)),
//                       IconButton(icon: const Icon(Icons.add), onPressed: _addClass, tooltip: 'Add Class'),
//                     ],
//                   ),
//                   ...projectVM.project.classes.asMap().entries.map((entry) {
//                     int index = entry.key;
//                     String className = entry.value;
//                     return ListTile(
//                       title: Text(className),
//                       trailing: IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () => _removeClass(index), tooltip: 'Remove Class'),
//                     );
//                   }).toList(),
//                   const SizedBox(height: 16),
//                   ElevatedButton(onPressed: _confirmProject, child: Text(widget.project == null ? 'Create Project' : 'Save Changes')),
//                 ],
//               ),
//             ),
//           ),
//         );
//       },
//     );
//   }
// }
