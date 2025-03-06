// This file implements the page for configuring a new project or editing an existing one.
// Users can specify the project name, labeling mode, classes, and data directory or file uploads.

import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart'; // For generating unique project IDs
import 'package:file_picker/file_picker.dart'; // For picking directories or files
import 'package:flutter/foundation.dart' show kIsWeb; // To determine the platform (web or native)

import '../../models/project_model.dart';
import '../../models/data_model.dart';
import '../../models/label_model.dart';
import '../../view_models/project_list_view_model.dart';
import '../widgets/labeling_mode_selector.dart';

class ConfigureProjectPage extends StatefulWidget {
  // Project to be edited, or null for creating a new one
  final Project? project;

  const ConfigureProjectPage({Key? key, this.project}) : super(key: key);

  @override
  ConfigureProjectPageState createState() => ConfigureProjectPageState();
}

class ConfigureProjectPageState extends State<ConfigureProjectPage> {
  // Form key for validating input fields
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController(); // project name controller

  // Default labeling mode : Single Classification with 3 classes
  LabelingMode _selectedMode = LabelingMode.singleClassification;
  List<String> _classes = ['1', '2', '3']; // List to hold class names
  List<DataPath> _dataPaths = [];

  get path => null;

  @override
  void initState() {
    super.initState();

    // If editing an existing project, initialize fields with its data
    if (widget.project != null) {
      _nameController.text = widget.project!.name;
      _selectedMode = widget.project!.mode;
      if (widget.project!.classes.isNotEmpty) {
        _classes = widget.project!.classes;
      }
      if (widget.project!.dataPaths.isNotEmpty) {
        _dataPaths = widget.project!.dataPaths;
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose(); // Dispose controller to free resources
    super.dispose();
  }

  // Add a new class to the project
  void _addClass() {
    showDialog(
      context: context,
      builder: (context) {
        // Controller for class name input
        final classController = TextEditingController();

        return AlertDialog(
          title: const Text('Add Class'),
          content: TextField(controller: classController, decoration: const InputDecoration(labelText: 'Class Name')),
          actions: [
            TextButton(
              onPressed: () {
                if (classController.text.isNotEmpty) {
                  // Add new class to the list
                  setState(() => _classes.add(classController.text));
                  Navigator.pop(context); // Close the dialog
                }
              },
              child: const Text('Add'),
            ),
          ],
        );
      },
    );
  }

  // Remove a class from the project
  void _removeClass(int index) => setState(() => _classes.removeAt(index));

  // Pick a data directory or files depending on the platform
  Future<void> _pickData() async {
    if (kIsWeb) {
      // Web: Use file picker for file uploads
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        allowMultiple: true,
        withData: true, // Ensure file data is loaded
      );

      if (result != null) {
        setState(() {
          for (var file in result.files) {
            _dataPaths.add(DataPath(fileName: file.name, base64Content: base64Encode(file.bytes ?? [])));
          }
        });
      }
    } else {
      // Native: Use directory picker
      String? selectedDirectory = await FilePicker.platform.getDirectoryPath();
      if (selectedDirectory != null) {
        setState(() {
          final directory = Directory(selectedDirectory);
          final files = directory.listSync().whereType<File>();
          for (var file in files) {
            _dataPaths.add(DataPath(fileName: path.basename(file.path), filePath: file.path));
          }
        });
      }
    }
  }

  void _confirmProject() async {
    if (_formKey.currentState!.validate()) {
      final projectVM = Provider.of<ProjectListViewModel>(context, listen: false);
      final isNewProject = widget.project == null;

      final updatedProject = Project(
        id: widget.project?.id ?? const Uuid().v4(),
        name: _nameController.text,
        mode: _selectedMode,
        classes: _classes,
        dataPaths: _dataPaths,
      );

      if (!isNewProject && widget.project!.mode != _selectedMode) {
        bool confirmChange = await _showLabelingModeChangeDialog(context);
        if (!confirmChange || !mounted) return;
      }

      if (isNewProject) {
        projectVM.saveProject(updatedProject);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${updatedProject.name} project has been created.')),
        );
      } else {
        debugPrint("📝 프로젝트 업데이트 시도: ${updatedProject.name}");
        await projectVM.updateProject(context, updatedProject);
        debugPrint("✅ 프로젝트 업데이트 완료");

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${updatedProject.name} project has been updated.')),
        );
      }

      if (!mounted) return;
      debugPrint("🔙 Navigator.pop 실행!");
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
    return Scaffold(
      appBar: AppBar(title: Text(widget.project == null ? 'Create Project' : 'Edit Project')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              // Project name input
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Project Name'),
                validator: (value) => (value == null || value.isEmpty) ? "Please enter a project name" : null,
              ),
              const SizedBox(height: 16),
              // Labeling mode dropdown
              LabelingModeSelector.dropdown(selectedMode: _selectedMode, onModeChanged: (newMode) => setState(() => _selectedMode = newMode)),
              const SizedBox(height: 16),
              // Class list section
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Classes', style: TextStyle(fontSize: 16)),
                  IconButton(icon: const Icon(Icons.add), onPressed: _addClass, tooltip: 'Add Class'),
                ],
              ),
              // Display list of classes
              ..._classes.asMap().entries.map((entry) {
                int index = entry.key;
                String className = entry.value;
                return ListTile(
                  title: Text(className),
                  trailing: IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () => _removeClass(index), tooltip: 'Remove Class'),
                );
              }).toList(),
              const SizedBox(height: 16),
              // Data directory or file selection
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      readOnly: true, // Make the field read-only
                      decoration: const InputDecoration(
                        labelText: kIsWeb ? 'Uploaded File Names' : 'Data Directory Path',
                        hintText: kIsWeb ? 'Upload files' : 'Select a directory',
                      ),
                      controller: TextEditingController(
                        text: _dataPaths.map((dp) => dp.fileName).join(', '),
                      ),
                      validator: (value) => (value == null || value.isEmpty) ? (kIsWeb ? 'Please upload files' : 'Please select a directory') : null,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(kIsWeb ? Icons.upload_file : Icons.folder_open),
                    onPressed: _pickData, // Trigger directory or file picker
                    tooltip: kIsWeb ? 'Upload Files' : 'Select Directory',
                  ),
                ],
              ),
              const SizedBox(height: 32),
              ElevatedButton(onPressed: _confirmProject, child: Text(widget.project == null ? 'Create Project' : 'Save Changes')),
            ],
          ),
        ),
      ),
    );
  }
}
