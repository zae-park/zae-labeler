import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

import '../../models/project_model.dart';
import '../../models/data_model.dart';
import '../../view_models/project_list_view_model.dart';
import '../../view_models/project_view_model.dart';
import '../widgets/labeling_mode_selector.dart';

class ConfigureProjectPage extends StatefulWidget {
  final Project? project;

  const ConfigureProjectPage({Key? key, this.project}) : super(key: key);

  @override
  ConfigureProjectPageState createState() => ConfigureProjectPageState();
}

class ConfigureProjectPageState extends State<ConfigureProjectPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final projectVM = Provider.of<ProjectViewModel>(context, listen: false);

    if (widget.project != null) {
      _nameController.text = projectVM.project.name;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _addClass() {
    showDialog(
      context: context,
      builder: (context) {
        final classController = TextEditingController();

        return AlertDialog(
          title: const Text('Add Class'),
          content: TextField(controller: classController, decoration: const InputDecoration(labelText: 'Class Name')),
          actions: [
            TextButton(
              onPressed: () {
                if (classController.text.isNotEmpty) {
                  setState(() => Provider.of<ProjectViewModel>(context, listen: false).addClass(classController.text));
                  Navigator.pop(context);
                }
              },
              child: const Text('Add'),
            ),
          ],
        );
      },
    );
  }

  void _removeClass(int index) {
    setState(() => Provider.of<ProjectViewModel>(context, listen: false).removeClass(index));
  }

  Future<void> _pickData() async {
    final projectVM = Provider.of<ProjectViewModel>(context, listen: false);

    if (kIsWeb) {
      FilePickerResult? result = await FilePicker.platform.pickFiles(allowMultiple: true, withData: true);

      if (result != null) {
        setState(() {
          for (var file in result.files) {
            projectVM.addDataPath(DataPath(fileName: file.name, base64Content: base64Encode(file.bytes ?? [])));
          }
        });
      }
    } else {
      String? selectedDirectory = await FilePicker.platform.getDirectoryPath();
      if (selectedDirectory != null) {
        setState(() {
          final directory = Directory(selectedDirectory);
          final files = directory.listSync().whereType<File>();
          for (var file in files) {
            projectVM.addDataPath(DataPath(fileName: file.uri.pathSegments.last, filePath: file.path));
          }
        });
      }
    }
  }

  Future<void> _confirmProject() async {
    if (_formKey.currentState!.validate()) {
      final projectVM = Provider.of<ProjectViewModel>(context, listen: false);
      final projectListVM = Provider.of<ProjectListViewModel>(context, listen: false);

      bool isNewProject = widget.project == null;
      if (!isNewProject && projectVM.isLabelingModeChanged()) {
        bool confirmChange = await _showLabelingModeChangeDialog(context);
        if (!confirmChange) return;
      }

      await projectVM.saveProject(isNewProject);
      projectListVM.loadProjects(); // 프로젝트 목록 업데이트

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${projectVM.project.name} project has been ${isNewProject ? 'created' : 'updated'}.')),
      );

      if (!mounted) return;
      Navigator.pop(context);
    }
  }

  Future<bool> _showLabelingModeChangeDialog(BuildContext context) async {
    return await showDialog<bool>(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('Labeling Mode 변경 경고'),
              content: const Text('Labeling Mode를 변경하면 기존 작업 내용이 삭제될 수 있습니다. 변경하시겠습니까?'),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('취소')),
                TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('확인')),
              ],
            );
          },
        ) ??
        false;
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ProjectViewModel>(
      builder: (context, projectVM, child) {
        return Scaffold(
          appBar: AppBar(title: Text(widget.project == null ? 'Create Project' : 'Edit Project')),
          body: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Form(
              key: _formKey,
              child: ListView(
                children: [
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(labelText: 'Project Name'),
                    onChanged: (value) => projectVM.setName(value),
                    validator: (value) => (value == null || value.isEmpty) ? "Please enter a project name" : null,
                  ),
                  const SizedBox(height: 16),
                  LabelingModeSelector.dropdown(
                    selectedMode: projectVM.project.mode,
                    onModeChanged: (newMode) => projectVM.setLabelingMode(newMode),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Classes', style: TextStyle(fontSize: 16)),
                      IconButton(icon: const Icon(Icons.add), onPressed: _addClass, tooltip: 'Add Class'),
                    ],
                  ),
                  ...projectVM.project.classes.asMap().entries.map((entry) {
                    int index = entry.key;
                    String className = entry.value;
                    return ListTile(
                      title: Text(className),
                      trailing: IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () => _removeClass(index), tooltip: 'Remove Class'),
                    );
                  }).toList(),
                  const SizedBox(height: 16),
                  ElevatedButton(onPressed: _confirmProject, child: Text(widget.project == null ? 'Create Project' : 'Save Changes')),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
