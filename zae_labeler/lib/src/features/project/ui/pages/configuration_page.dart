import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zae_labeler/common/i18n.dart';
import '../../../../../common/common_widgets.dart';
import '../../../../core/models/project/project_model.dart';
import '../../../../views/widgets/labeling_mode_selector.dart';
import '../../providers/project_providers.dart';

/// 프로젝트 생성/편집 페이지.
/// - [project]가 null이면 새 프로젝트를 만들고, 아니면 해당 프로젝트를 편집합니다.
/// - 편집 상태는 [projectEditorProvider]가 보유하며 페이지를 벗어나면 정리됩니다.
class ConfigureProjectPage extends ConsumerWidget {
  final Project? project;

  const ConfigureProjectPage({super.key, required this.project});

  void _addClass(BuildContext context, ProjectEditorNotifier editor) {
    final classController = TextEditingController();

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
                  editor.addClass(className);
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

  Future<void> _confirmProject(BuildContext context, ProjectEditorState state, ProjectEditorNotifier editor) async {
    final isNewProject = !state.isEditing;
    debugPrint("[confirmProject] mode: ${state.project.mode} is new? : $isNewProject, dataInfos: ${state.project.dataInfos.length}");

    final saved = await editor.confirm();
    if (!context.mounted) return;
    GlobalAlertManager.show(context, '${saved.name} project has been ${isNewProject ? "created" : "updated"}.', type: AlertType.success);
    Navigator.pop(context, saved);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final provider = projectEditorProvider(project);
    final state = ref.watch(provider);
    final editor = ref.read(provider.notifier);

    return Scaffold(
      appBar: AppBar(title: Text(state.isEditing ? context.l10n.configPage_title_edit : context.l10n.configPage_title_create)),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          child: ListView(
            children: [
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      initialValue: state.project.name,
                      decoration: InputDecoration(labelText: context.l10n.project_name),
                      onChanged: (value) => editor.setName(value),
                      validator: (value) => (value == null || value.isEmpty) ? "Please enter a project name" : null,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: LabelingModeSelector.dropdown(selectedMode: state.project.mode, onModeChanged: (newMode) => editor.setLabelingMode(newMode)),
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
                            IconButton(icon: const Icon(Icons.add), onPressed: () => _addClass(context, editor), tooltip: 'Add Class'),
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
                              itemCount: state.project.classes.length,
                              itemBuilder: (context, index) {
                                return ListTile(
                                  title: Text(state.project.classes[index]),
                                  trailing: IconButton(
                                    icon: const Icon(Icons.delete, color: Colors.red),
                                    onPressed: () => editor.removeClass(index),
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
                              onPressed: () async => await editor.pickAndAddDataInfos(),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        if (state.project.dataInfos.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Container(
                            height: 150,
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Scrollbar(
                              child: ListView.builder(
                                itemCount: state.project.dataInfos.length,
                                itemBuilder: (context, index) {
                                  return ListTile(
                                    title: Text(state.project.dataInfos[index].fileName),
                                    trailing: IconButton(
                                      icon: const Icon(Icons.delete, color: Colors.red),
                                      onPressed: () => editor.removeDataInfoAt(index),
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
                onPressed: state.isBusy ? null : () => _confirmProject(context, state, editor),
                child: Text(state.isBusy ? 'Data 업데이트 중...' : context.l10n.configPage_confirm),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
