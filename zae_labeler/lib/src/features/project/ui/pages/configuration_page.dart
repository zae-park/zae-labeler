import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../../common/common_widgets.dart';
import '../../view_models/configuration_view_model.dart';
import '../../view_models/project_list_view_model.dart';
import '../../../../views/widgets/labeling_mode_selector.dart';

class ConfigureProjectPage extends StatelessWidget {
  const ConfigureProjectPage({Key? key}) : super(key: key);

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

  void _confirmProject(BuildContext context) {
    final configVM = Provider.of<ConfigurationViewModel>(context, listen: false);
    final projectListVM = Provider.of<ProjectListViewModel>(context, listen: false);

    final updatedProject = configVM.project;
    final isNewProject = !configVM.isEditing;

    debugPrint("[confirmProject] mode: ${configVM.project.mode} is new? : $isNewProject");
    debugPrint("[confirmProject] dataInfos 수: ${updatedProject.dataInfos.length}");
    for (final dp in updatedProject.dataInfos) {
      debugPrint("📂 dataInfo: dataId=${dp.id}, path=${dp.filePath}, name=${dp.fileName}");
    }
    projectListVM.upsertProject(updatedProject);
    GlobalAlertManager.show(context, '${updatedProject.name} project has been ${isNewProject ? "created" : "updated"}.', type: AlertType.success);

    configVM.reset();
    Navigator.pop(context, updatedProject);
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
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          initialValue: configVM.project.name,
                          decoration: const InputDecoration(labelText: 'Project Name'),
                          onChanged: (value) => configVM.setProjectName(value),
                          validator: (value) => (value == null || value.isEmpty) ? "Please enter a project name" : null,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: LabelingModeSelector.dropdown(
                          selectedMode: configVM.project.mode,
                          onModeChanged: (newMode) => configVM.setLabelingMode(newMode),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 64),

                  /// ✅ Class List와 Data List를 한 Row에 배치
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      /// ✅ 클래스 리스트 (좌측)
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('Classes :', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                                IconButton(icon: const Icon(Icons.add), onPressed: () => _addClass(context), tooltip: 'Add Class'),
                              ],
                            ),
                            Container(
                              height: 150,
                              decoration: BoxDecoration(border: Border.all(color: Colors.grey), borderRadius: BorderRadius.circular(8)),
                              child: Scrollbar(
                                child: ListView.builder(
                                  itemCount: configVM.project.classes.length,
                                  itemBuilder: (context, index) {
                                    return ListTile(
                                      title: Text(configVM.project.classes[index]),
                                      trailing: IconButton(
                                        icon: const Icon(Icons.delete, color: Colors.red),
                                        onPressed: () => configVM.removeClass(index),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),

                      /// ✅ 데이터 리스트 (우측)
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('Selected Data:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                                const SizedBox(height: 8),
                                ElevatedButton.icon(
                                  icon: const Icon(Icons.folder_open),
                                  label: const Text(kIsWeb ? 'Select Files' : 'Select Data Directory'),
                                  onPressed: () => configVM.addDataInfo(),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            if (configVM.project.dataInfos.isNotEmpty) ...[
                              const SizedBox(height: 8),
                              Container(
                                height: 150,
                                decoration: BoxDecoration(border: Border.all(color: Colors.grey), borderRadius: BorderRadius.circular(8)),
                                child: Scrollbar(
                                  child: ListView.builder(
                                    itemCount: configVM.project.dataInfos.length,
                                    itemBuilder: (context, index) {
                                      return ListTile(
                                        title: Text(configVM.project.dataInfos[index].fileName),
                                        trailing: IconButton(
                                          icon: const Icon(Icons.delete, color: Colors.red),
                                          onPressed: () => configVM.removeDataInfo(index),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 32),
                  ElevatedButton(onPressed: () => _confirmProject(context), child: Text(configVM.isEditing ? 'Update Project' : 'Create Project')),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
