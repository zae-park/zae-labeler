import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zae_labeler/common/i18n.dart';
import 'package:zae_labeler/src/features/project/view_models/project_view_model.dart';
import '../../../../../common/common_widgets.dart';
import 'package:zae_labeler/src/core/di/providers.dart';
import '../../../../views/widgets/labeling_mode_selector.dart';

/// 프로젝트 생성/편집 페이지.
/// - 편집 대상 [viewModel]은 호출 측(ProjectList/ProjectTile)이 소유하며 생성자로 전달합니다.
class ConfigureProjectPage extends ConsumerWidget {
  final ProjectViewModel viewModel;

  const ConfigureProjectPage({super.key, required this.viewModel});

  void _addClass(BuildContext context) {
    final classController = TextEditingController();
    final projectVM = viewModel;

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Add Class'),
          content: TextField(
            controller: classController,
            decoration: const InputDecoration(labelText: 'Class Name'),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Cancel')),
            TextButton(
              onPressed: () {
                final className = classController.text.trim();
                if (className.isNotEmpty) {
                  projectVM.addClass(className);
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

  void _confirmProject(BuildContext context, WidgetRef ref) {
    final projectVM = viewModel;
    final projectListVM = ref.read(projectListViewModelProvider);

    final updatedProject = projectVM.project;
    final isNewProject = !projectVM.isEditing;

    debugPrint("[confirmProject] mode: ${projectVM.project.mode} is new? : $isNewProject");
    debugPrint("[confirmProject] dataInfos 수: ${updatedProject.dataInfos.length}");
    for (final dp in updatedProject.dataInfos) {
      debugPrint("📂 dataInfo: dataId=${dp.id}, path=${dp.filePath}, name=${dp.fileName}");
    }
    projectListVM.upsertProject(updatedProject);
    GlobalAlertManager.show(context, '${updatedProject.name} project has been ${isNewProject ? "created" : "updated"}.', type: AlertType.success);

    projectVM.reset();
    Navigator.pop(context, updatedProject);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListenableBuilder(
      listenable: viewModel,
      builder: (context, _) {
        final projectVM = viewModel;
        return Scaffold(
          appBar: AppBar(title: Text(projectVM.isEditing ? context.l10n.configPage_title_edit : context.l10n.configPage_title_create)),
          body: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Form(
              child: ListView(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          initialValue: projectVM.project.name,
                          decoration: InputDecoration(labelText: context.l10n.project_name),
                          onChanged: (value) => projectVM.setName(value),
                          validator: (value) => (value == null || value.isEmpty) ? "Please enter a project name" : null,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: LabelingModeSelector.dropdown(
                          selectedMode: projectVM.project.mode,
                          onModeChanged: (newMode) => projectVM.setLabelingMode(newMode),
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
                                Text('${context.l10n.configPage_classes} :', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                                IconButton(icon: const Icon(Icons.add), onPressed: () => _addClass(context), tooltip: 'Add Class'),
                              ],
                            ),
                            Container(
                              height: 150,
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Scrollbar(
                                child: ListView.builder(
                                  itemCount: projectVM.project.classes.length,
                                  itemBuilder: (context, index) {
                                    return ListTile(
                                      title: Text(projectVM.project.classes[index]),
                                      trailing: IconButton(
                                        icon: const Icon(Icons.delete, color: Colors.red),
                                        onPressed: () => projectVM.removeClass(index),
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
                                Text('${context.l10n.configPage_dataList}:', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                                const SizedBox(height: 8),
                                ElevatedButton.icon(
                                  icon: const Icon(Icons.folder_open),
                                  label: const Text(kIsWeb ? 'Select Files' : 'Select Data Directory'),
                                  onPressed: () async => await projectVM.pickAndAddDataInfos(),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            if (projectVM.project.dataInfos.isNotEmpty) ...[
                              const SizedBox(height: 8),
                              Container(
                                height: 150,
                                decoration: BoxDecoration(
                                  border: Border.all(color: Colors.grey),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Scrollbar(
                                  child: ListView.builder(
                                    itemCount: projectVM.project.dataInfos.length,
                                    itemBuilder: (context, index) {
                                      return ListTile(
                                        title: Text(projectVM.project.dataInfos[index].fileName),
                                        trailing: IconButton(
                                          icon: const Icon(Icons.delete, color: Colors.red),
                                          onPressed: () => projectVM.removeDataInfoAt(index),
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
                  ElevatedButton(
                    onPressed: projectVM.isBusy ? null : () => _confirmProject(context, ref),
                    child: Text(projectVM.isBusy ? 'Data 업데이트 중...' : context.l10n.configPage_confirm),
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
