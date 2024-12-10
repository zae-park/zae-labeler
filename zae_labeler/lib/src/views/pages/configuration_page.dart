// This file implements the page for configuring a new project or editing an existing one.
// Users can specify the project name, labeling mode, classes, and data directory or file uploads.

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart'; // For generating unique project IDs
import 'package:file_picker/file_picker.dart'; // For picking directories or files
import 'package:flutter/foundation.dart' show kIsWeb; // To determine the platform (web or native)

import '../../models/project_model.dart';
import '../../view_models/project_view_model.dart';

class ConfigureProjectPage extends StatefulWidget {
  // Project to be edited, or null for creating a new one
  final Project? project;

  const ConfigureProjectPage({Key? key, this.project}) : super(key: key);

  @override
  _ConfigureProjectPageState createState() => _ConfigureProjectPageState();
}

class _ConfigureProjectPageState extends State<ConfigureProjectPage> {
  // Form key for validating input fields
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController(); // project name controller

  // Default lableing mode : Single Classification with 3 class
  LabelingMode _selectedMode = LabelingMode.singleClassification;
  final List<String> _classes = ['1', '2', '3']; // List to hold class names

  // Data Hub
  String? _dataDirectory = ''; // Data directory path (native)
  List<String>? _dataPaths = []; // Data file paths (web)

  @override
  void initState() {
    super.initState();

    // If editing an existing project, initialize fields with its data
    if (widget.project != null) {
      _nameController.text = widget.project!.name;
      _selectedMode = widget.project!.mode;
      _classes.addAll(widget.project!.classes);
      _dataDirectory = widget.project!.dataDirectory;
      _dataPaths = widget.project!.dataPaths;
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
  Future<void> _pickDataDirectory() async {
    if (kIsWeb) {
      // Web: Use file picker for file uploads
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        allowMultiple: true,
        withData: true, // Ensure file data is loaded
      );

      if (result != null) {
        setState(() {
          _dataPaths = result.files.map((file) {
            // Store both name and data for later use
            return '${file.name}:${base64Encode(file.bytes ?? [])}';
          }).toList();
        });
      } else {
        print('No files selected');
      }
    } else {
      // Native: Use directory picker
      String? selectedDirectory = await FilePicker.platform.getDirectoryPath();
      (selectedDirectory != null) ? setState(() => _dataDirectory = selectedDirectory) : null;
    }
  }

  // Save the project to the ProjectViewModel
  void _confirmProject() {
    if (_formKey.currentState!.validate()) {
      final project = Project(
        id: widget.project?.id ?? const Uuid().v4(), // If new, generate new ID
        name: _nameController.text,
        mode: _selectedMode,
        classes: _classes,
        dataDirectory: _dataDirectory,
        dataPaths: _dataPaths,
      );
      final projectVM = Provider.of<ProjectViewModel>(context, listen: false);

      if (widget.project == null) {
        // If there is no project in parent widget (Project List Page).
        projectVM.saveProject(project);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${project.name} project has been created.')));
      } else {
        projectVM.updateProject(project);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${project.name} project has been updated.')));
      }
      Navigator.pop(context); // Navigate back after saving
    }
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
              DropdownButtonFormField<LabelingMode>(
                value: _selectedMode,
                decoration: const InputDecoration(labelText: 'Labeling Mode'),
                items: LabelingMode.values.map((mode) {
                  final displayText = {
                        LabelingMode.singleClassification: 'Single Classification',
                        LabelingMode.multiClassification: 'Multi Classification',
                        LabelingMode.segmentation: 'Segmentation',
                      }[mode] ??
                      mode.toString();
                  return DropdownMenuItem<LabelingMode>(value: mode, child: Text(displayText));
                }).toList(),
                onChanged: (newMode) => newMode != null ? setState(() => _selectedMode = newMode) : null,
              ),
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
                      controller: TextEditingController(text: kIsWeb ? _dataPaths?.join(', ') : _dataDirectory),
                      validator: (value) => (value == null || value.isEmpty) ? (kIsWeb ? 'Please upload files' : 'Please select a directory') : null,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(kIsWeb ? Icons.upload_file : Icons.folder_open),
                    onPressed: _pickDataDirectory, // Trigger directory or file picker
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
