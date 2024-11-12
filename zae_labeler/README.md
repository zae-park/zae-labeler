# Flutter Labeling App

## Table of Contents
1. Project Overview
2. Installation, Execution, and Usage
   1. Prerequisites
   2. Installation
   3. Running the Application
   4. Building for Different Platforms
3. Features
   1. Project Management
      1. Creating a Project
      2. Modifying a Project
      3. Deleting a Project
      4. Sharing Project Configurations
      5. Downloading Project Configurations
   2. Labeling Modes
      1. Single Classification
      2. Multi Classification
      3. Segmentation
4. Code Structure
   1. lib Folder Overview
   2. Detailed Code Explanation
      1. Models
      2. View Models
      3. Pages
      4. Utilities
      5. Charts
5. Contributing
6. License

---

## Project Overview

The **Flutter Labeling App** is a versatile application designed for data labeling tasks. It allows users to create, manage, and configure labeling projects with ease. The app supports multiple labeling modes, including Single Classification, Multi Classification, and Segmentation, catering to various data annotation needs. Initially developed for Windows, the app also supports web deployment, ensuring accessibility across different platforms.

### Key Features
- **Project Management**: Create, modify, delete, share, and download project configurations.
- **Multiple Labeling Modes**: Supports Single Classification, Multi Classification, and Segmentation.
- **Cross-Platform Support**: Runs on Windows and can be deployed on the web.
- **User-Friendly Interface**: Intuitive UI for seamless data labeling and project management.

## Installation, Execution, and Usage
### Prerequisites
Before setting up the project, ensure you have the following installed on your system:
- **Flutter SDK**: Version 3.0.0 or higher.
- **Dart SDK**: Comes bundled with Flutter.
- **Visual Studio**: Required for Windows development (with C++ workload).
- **Git**: For version control and cloning the repository.

### Installation

1. **Clone the Repository**
```bash
git clone https://github.com/your-username/flutter-labeling-app.git
cd flutter-labeling-app
```

2. **Install Dependencies**

Navigate to the project directory and fetch the required packages:
```bash
flutter pub get
```

### Running the Application

**On Windows**

1. **Enable Windows Desktop Support**
   Ensure that Windows desktop support is enabled:
   
    ```bash
    flutter config --enable-windows-desktop
    flutter doctor
    ```
2. **Run the App**
    ```bash
    flutter run -d windows
    ```

**On Web**

1. **Enable Web Support**
   ```bash
   flutter config --enable-web
   flutter doctor
   ```
2. **Run the App**
   ```bash
   flutter run -d chrome
   ```

### Building for Different Platforms**

**Build for Windows**
To create a release build for Windows:

```bash
flutter build windows
```
The executable and required DLL files will be located in ```build/windows/runner/Release```.

**Build for Web**
To build the web version:

```bash
flutter build web
```
The build artifacts will be in the ```build/web``` directory, ready for deployment.

---

## Features
### Project Management
Managing projects is central to the app's functionality. Users can create, modify, delete, share, and download project configurations seamlessly.

**Creating a Project**
1. **Navigate to Project List**
   Launch the app and go to the "Project List" page.
2. **Add a New Project**
   Click the **Add** button (➕) in the top-right corner to open the "Configure Project" page.
3. **Configure Project Settings**
   - **Project Name**: Enter a unique name for your project.
   - **Labeling Mode**: Select between Single Classification, Multi Classification, or Segmentation.
   - **Classes**: Add classes relevant to your project.
   - **Data Directory**: Choose the directory where your data files are stored.
4. **Save the Project**
   Click the **Save** button to create the project. The project will appear in the Project List.

**Modifying a Project**
1. **Select the Project**
   In the Project List, locate the project you wish to modify.
2. **Edit the Project**
   Click the **Edit** button (✏️) next to the project to open the "Configure Project" page with pre-filled settings.
3. **Update Settings**
   Modify the necessary fields such as project name, labeling mode, classes, or data directory.
4. Save Changes
   Click the **Save** button to apply the changes.

**Deleting a Project**
1. **Select the Project**
   In the Project List, find the project you want to delete.
2. **Delete the Project**
   Click the **Delete** button (🗑️) next to the project. A confirmation dialog will appear.
3. **Confirm Deletion**
   Confirm the deletion to remove the project from the list.

**Sharing Project Configurations**
1. **Select the Project**
   In the Project List, choose the project you want to share.
2. **Share the Project**
   Click the **Share** button (🔗) next to the project. The app will generate a JSON configuration file.
3. **Share via Preferred Method**
   The JSON file can be shared via email, cloud storage, or any other preferred method.

**Downloading Project Configurations**
1. **Select the Project**
   In the Project List, choose the project whose configuration you want to download.
2. **Download the Configuration**
   Click the **Download** button (⬇️) next to the project. The JSON configuration file will be saved to your Downloads directory (or chosen directory on other platforms).


### Labeling Modes
The app supports three labeling modes to cater to different annotation needs:

**Single Classification**
- **Description**: Assign a single label to each data point.
- **Use Case**: Categorizing images where each image belongs to one category (e.g., cat, dog, bird).

**Multi Classification**
- **Description**: Assign multiple labels to each data point.
- **Use Case**: Situations where data points can belong to multiple categories simultaneously (e.g., an image containing both a cat and a dog).

**Segmentation**
- **Description**: Assign labels to specific regions within a data point.
- **Use Case**: Tasks requiring detailed annotations like object boundaries in images (e.g., segmenting different objects in a scene).

---

## Code Structure
The project's codebase is organized for clarity and maintainability. Below is an overview of the `lib` folder structure and detailed explanations of each component.

### lib Folder Overview
```
lib/
├── charts/
│   └── time_series_chart.dart
├── models/
│   ├── label_entry.dart
│   └── project_model.dart
├── pages/
│   ├── configure_project_page.dart
│   ├── label_list_page.dart
│   ├── labeling_page.dart
│   └── project_list_page.dart
├── utils/
│   └── storage_helper.dart
├── view_models/
│   ├── label_view_model.dart
│   └── project_view_model.dart
└── main.dart
```

### Detailed Code Explanation

**Models**

`project_model.dart`
Defines the `Project` class and the `LabelingMode` enum.

```dart
// lib/models/project_model.dart
enum LabelingMode {
  singleClassification,
  multiClassification,
  segmentation,
}

class Project {
  String id; // Unique Project ID
  String name; // Project Name
  LabelingMode mode; // Labeling Mode
  List<String> classes; // List of Classes
  String dataDirectory; // Directory Path for Data Files

  Project({
    required this.id,
    required this.name,
    required this.mode,
    required this.classes,
    required this.dataDirectory,
  });

  // Convert Project to JSON
  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'mode': mode.toString().split('.').last.toLowerCase(),
        'classes': classes,
        'dataDirectory': dataDirectory,
      };

  // Create Project from JSON
  factory Project.fromJson(Map<String, dynamic> json) => Project(
        id: json['id'],
        name: json['name'],
        mode: LabelingMode.values.firstWhere(
            (e) => e.toString().split('.').last.toLowerCase() == json['mode'],
            orElse: () => LabelingMode.singleClassification),
        classes: List<String>.from(json['classes']),
        dataDirectory: json['dataDirectory'] ?? '',
      );
}
```
`label_entry.dart`
Defines the LabelEntry class for storing labeling information.
```dart
// lib/models/label_entry.dart
class LabelEntry {
  String dataFilename;
  String dataPath;
  SingleClassificationLabel? singleClassification;
  MultiClassificationLabel? multiClassification;
  SegmentationLabel? segmentation;

  LabelEntry({
    required this.dataFilename,
    required this.dataPath,
    this.singleClassification,
    this.multiClassification,
    this.segmentation,
  });

  // Convert LabelEntry to JSON
  Map<String, dynamic> toJson() => {
        'dataFilename': dataFilename,
        'dataPath': dataPath,
        'singleClassification': singleClassification?.toJson(),
        'multiClassification': multiClassification?.toJson(),
        'segmentation': segmentation?.toJson(),
      };

  // Create LabelEntry from JSON
  factory LabelEntry.fromJson(Map<String, dynamic> json) => LabelEntry(
        dataFilename: json['dataFilename'],
        dataPath: json['dataPath'],
        singleClassification: json['singleClassification'] != null
            ? SingleClassificationLabel.fromJson(json['singleClassification'])
            : null,
        multiClassification: json['multiClassification'] != null
            ? MultiClassificationLabel.fromJson(json['multiClassification'])
            : null,
        segmentation: json['segmentation'] != null
            ? SegmentationLabel.fromJson(json['segmentation'])
            : null,
      );
}

class SingleClassificationLabel {
  String labeledAt;
  String label;

  SingleClassificationLabel({
    required this.labeledAt,
    required this.label,
  });

  Map<String, dynamic> toJson() => {
        'labeledAt': labeledAt,
        'label': label,
      };

  factory SingleClassificationLabel.fromJson(Map<String, dynamic> json) =>
      SingleClassificationLabel(
        labeledAt: json['labeledAt'],
        label: json['label'],
      );
}

class MultiClassificationLabel {
  String labeledAt;
  List<String> labels;

  MultiClassificationLabel({
    required this.labeledAt,
    required this.labels,
  });

  Map<String, dynamic> toJson() => {
        'labeledAt': labeledAt,
        'labels': labels,
      };

  factory MultiClassificationLabel.fromJson(Map<String, dynamic> json) =>
      MultiClassificationLabel(
        labeledAt: json['labeledAt'],
        labels: List<String>.from(json['labels']),
      );
}

class SegmentationLabel {
  String labeledAt;
  List<String> classes;

  SegmentationLabel({
    required this.labeledAt,
    required this.classes,
  });

  Map<String, dynamic> toJson() => {
        'labeledAt': labeledAt,
        'classes': classes,
      };

  factory SegmentationLabel.fromJson(Map<String, dynamic> json) =>
      SegmentationLabel(
        labeledAt: json['labeledAt'],
        classes: List<String>.from(json['classes']),
      );
}
```

**View Models**
`project_view_model.dart`
Manages the state and operations related to projects.

```dart
// lib/view_models/project_view_model.dart
import 'package:flutter/material.dart';
import '../models/project_model.dart';
import '../utils/storage_helper.dart';

class ProjectViewModel extends ChangeNotifier {
  List<Project> _projects = [];

  ProjectViewModel() {
    loadProjects();
  }

  List<Project> get projects => _projects;

  Future<void> loadProjects() async {
    _projects = await StorageHelper.loadProjects();
    notifyListeners();
  }

  Future<void> addProject(Project project) async {
    _projects.add(project);
    await StorageHelper.saveProjects(_projects);
    notifyListeners();
  }

  Future<void> removeProject(String projectId) async {
    _projects.removeWhere((project) => project.id == projectId);
    await StorageHelper.saveProjects(_projects);
    notifyListeners();
  }

  Future<void> updateProject(Project updatedProject) async {
    int index = _projects.indexWhere((project) => project.id == updatedProject.id);
    if (index != -1) {
      _projects[index] = updatedProject;
      await StorageHelper.saveProjects(_projects);
      notifyListeners();
    }
  }
}
```

`label_view_model.dart`
Manages the state and operations related to labeling.

```dart
// lib/view_models/label_view_model.dart
import 'package:flutter/material.dart';
import '../models/label_entry.dart';
import '../models/project_model.dart';
import '../utils/storage_helper.dart';
import 'dart:io';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'dart:convert';
import 'package:archive/archive.dart';

class LabelingViewModel extends ChangeNotifier {
  final Project project;
  List<LabelEntry> _labelEntries = [];
  int _currentIndex = 0;
  List<File> _dataFiles = []; // List of Data Files
  List<double> _currentData = []; // Time Series Data

  LabelingViewModel({required this.project}) {
    // Initialize by loading labels and data files
    loadLabels();
    loadDataFiles();
  }

  List<LabelEntry> get labelEntries => _labelEntries;
  int get currentIndex => _currentIndex;
  List<File> get dataFiles => _dataFiles;
  List<double> get currentData => _currentData;
  String get currentFileName =>
      _dataFiles.isNotEmpty ? path.basename(_dataFiles[_currentIndex].path) : '';
  LabelEntry get currentLabelEntry {
    if (_currentIndex < 0 || _currentIndex >= _dataFiles.length) {
      return LabelEntry(dataFilename: '', dataPath: '');
    }

    final dataId = _dataFiles[_currentIndex].path;
    final entry = _labelEntries.firstWhere(
        (labelEntry) => labelEntry.dataPath == dataId,
        orElse: () => LabelEntry(
              dataFilename: path.basename(dataId),
              dataPath: dataId,
            ));
    return entry;
  }

  // Load Labels from Storage
  Future<void> loadLabels() async {
    _labelEntries = await StorageHelper.loadLabelEntries();
    notifyListeners();
  }

  // Load Data Files (Filtering by .csv)
  void loadDataFiles() {
    final directory = Directory(project.dataDirectory);
    if (directory.existsSync()) {
      _dataFiles = directory
          .listSync()
          .where((file) => file is File && path.extension(file.path) == '.csv')
          .cast<File>()
          .toList();
      if (_dataFiles.isNotEmpty) {
        loadCurrentData();
      }
    }
    notifyListeners();
  }

  // Load Current Data File (Parse All Values)
  void loadCurrentData() {
    if (_currentIndex >= 0 && _currentIndex < _dataFiles.length) {
      final file = _dataFiles[_currentIndex];
      final lines = file.readAsLinesSync();

      // Parse all values and store in _currentData
      _currentData = lines
          .expand((line) => line.split(','))
          .map((part) => double.tryParse(part.trim()) ?? 0.0)
          .toList();
    }
    notifyListeners();
  }

  // Add or Update Label Entry
  void addOrUpdateLabel(int dataIndex, String label, String mode) {
    if (dataIndex < 0 || dataIndex >= _dataFiles.length) return;
    final dataId = _dataFiles[dataIndex].path;

    final existingEntryIndex =
        _labelEntries.indexWhere((entry) => entry.dataPath == dataId);

    if (existingEntryIndex != -1) {
      // Update existing entry
      LabelEntry entry = _labelEntries[existingEntryIndex];
      switch (mode) {
        case 'single_classification':
          entry.singleClassification = SingleClassificationLabel(
            labeledAt: DateTime.now().toIso8601String(),
            label: label,
          );
          break;
        case 'multi_classification':
          if (entry.multiClassification == null) {
            entry.multiClassification = MultiClassificationLabel(
              labeledAt: DateTime.now().toIso8601String(),
              labels: [label],
            );
          } else {
            if (!entry.multiClassification!.labels.contains(label)) {
              entry.multiClassification!.labels.add(label);
              entry.multiClassification!.labeledAt = DateTime.now().toIso8601String();
            }
          }
          break;
        case 'segmentation':
          // Segmentation label addition logic (customize as needed)
          break;
        default:
          break;
      }
    } else {
      // Add new entry
      LabelEntry newEntry = LabelEntry(
        dataFilename: path.basename(dataId),
        dataPath: dataId,
      );
      switch (mode) {
        case 'single_classification':
          newEntry.singleClassification = SingleClassificationLabel(
            labeledAt: DateTime.now().toIso8601String(),
            label: label,
          );
          break;
        case 'multi_classification':
          newEntry.multiClassification = MultiClassificationLabel(
            labeledAt: DateTime.now().toIso8601String(),
            labels: [label],
          );
          break;
        case 'segmentation':
          // Segmentation label addition logic (customize as needed)
          break;
        default:
          break;
      }
      _labelEntries.add(newEntry);
    }

    StorageHelper.saveLabelEntries(_labelEntries);
    notifyListeners();
  }

  // Check if Label is Selected
  bool isLabelSelected(String label, String mode) {
    LabelEntry entry = currentLabelEntry;
    switch (mode) {
      case 'single_classification':
        return entry.singleClassification?.label == label;
      case 'multi_classification':
        return entry.multiClassification?.labels.contains(label) ?? false;
      // Segmentation mode requires separate handling in UI
      default:
        return false;
    }
  }

  // Navigate to Next Data File
  void moveNext() {
    if (_currentIndex < _dataFiles.length - 1) {
      _currentIndex++;
      loadCurrentData();
    }
  }

  // Navigate to Previous Data File
  void movePrevious() {
    if (_currentIndex > 0) {
      _currentIndex--;
      loadCurrentData();
    }
  }

  // Download Labels as .zae File
  Future<String> downloadLabelsAsZae() async {
    final directory = await getApplicationDocumentsDirectory();
    final zaeFile = File('${directory.path}/labels.zae');

    final zaeContent =
        _labelEntries.map((labelEntry) => labelEntry.toJson()).toList();
    zaeFile.writeAsStringSync(jsonEncode(zaeContent));

    return zaeFile.path;
  }

  // Download Labels as ZIP File
  Future<String> downloadLabelsAsZip() async {
    final archive = Archive();

    // Add data files to archive
    for (var file in _dataFiles) {
      if (file.existsSync()) {
        final fileBytes = file.readAsBytesSync();
        archive.addFile(
            ArchiveFile(path.basename(file.path), fileBytes.length, fileBytes));
      }
    }

    // Add labels.json to archive
    final labelsJson =
        jsonEncode(_labelEntries.map((e) => e.toJson()).toList());
    archive.addFile(ArchiveFile('labels.json', labelsJson.length,
        utf8.encode(labelsJson))); // Add labels.json file

    // Encode archive to ZIP
    final zipData = ZipEncoder().encode(archive);
    if (zipData != null) {
      final directory = await getApplicationDocumentsDirectory();
      final zipFile = File('${directory.path}/labels.zip');
      zipFile.writeAsBytesSync(zipData);
      return zipFile.path;
    } else {
      throw Exception('Failed to create ZIP');
    }
  }
}
```

**Pages**

`project_list_page.dart`
Displays the list of projects and provides options to manage them.

```dart
// lib/pages/project_list_page.dart
import 'dart:convert';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:file_picker/file_picker.dart';
import '../view_models/project_view_model.dart';
import '../models/project_model.dart';
import 'configure_project_page.dart';
import '../utils/storage_helper.dart';
import 'dart:html' as html; // For web file download

class ProjectListPage extends StatelessWidget {
  const ProjectListPage({Key? key}) : super(key: key);

  // Share Project Configuration
  Future<void> _shareProject(BuildContext context, Project project) async {
    try {
      final projectJson = project.toJson();
      final jsonString = jsonEncode(projectJson);
      if (kIsWeb) {
        // Web sharing via URL or Web APIs
        // For simplicity, downloading the config file
        downloadFile('${project.name}_config.json', jsonString);
      } else {
        // Mobile/Desktop sharing
        final directory = await getTemporaryDirectory();
        final file = File('${directory.path}/${project.name}_config.json');
        await file.writeAsString(jsonString);

        await Share.shareFiles([file.path], text: '${project.name} Project Configuration');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to share project: $e')),
      );
    }
  }

  // Download Project Configuration
  Future<void> _downloadProjectConfig(BuildContext context, Project project) async {
    try {
      if (kIsWeb) {
        // Web download using HTML APIs
        String jsonString = jsonEncode(project.toJson());
        downloadFile('${project.name}_config.json', jsonString);
      } else {
        // Desktop/Mobile download
        String filePath = await StorageHelper.downloadProjectConfig(project);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Project configuration downloaded to: $filePath')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to download project config: $e')),
      );
    }
  }

  // Download File Function for Web
  void downloadFile(String filename, String content) {
    if (kIsWeb) {
      final bytes = utf8.encode(content);
      final blob = html.Blob([bytes]);
      final url = html.Url.createObjectUrlFromBlob(blob);
      final anchor = html.AnchorElement(href: url)
        ..setAttribute("download", filename)
        ..click();
      html.Url.revokeObjectUrl(url);
    }
  }

  // Import Project Configuration via File Picker
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

          final projectVM = Provider.of<ProjectViewModel>(context, listen: false);
          await projectVM.addProject(project);

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Project "${project.name}" imported successfully.')),
          );
        } else {
          throw Exception('Selected file does not exist.');
        }
      } else {
        // User canceled the picker
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('File selection canceled.')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to import project: $e')),
      );
    }
  }

  // Confirm Deletion with Dialog
  Future<void> _confirmDelete(BuildContext context, ProjectViewModel projectVM, Project project) async {
    bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Project'),
        content: Text('Are you sure you want to delete the project "${project.name}"? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await projectVM.removeProject(project.id);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Project "${project.name}" has been deleted.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ProjectViewModel>(
      builder: (context, projectVM, child) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('Project List'),
            actions: [
              IconButton(
                icon: const Icon(Icons.add),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const ConfigureProjectPage()),
                  );
                },
                tooltip: 'Create Project',
              ),
              IconButton(
                icon: const Icon(Icons.file_upload),
                onPressed: () {
                  _importProject(context);
                },
                tooltip: 'Import Project',
              ),
            ],
          ),
          body: ListView.builder(
            itemCount: projectVM.projects.length,
            itemBuilder: (context, index) {
              final project = projectVM.projects[index];
              return ListTile(
                title: Text(project.name),
                subtitle: Text('Mode: ${project.mode.toString().split('.').last}'),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ConfigureProjectPage(project: project),
                          ),
                        );
                      },
                      tooltip: 'Edit Project',
                    ),
                    IconButton(
                      icon: const Icon(Icons.download),
                      onPressed: () => _downloadProjectConfig(context, project),
                      tooltip: 'Download Config',
                    ),
                    IconButton(
                      icon: const Icon(Icons.share),
                      onPressed: () => _shareProject(context, project),
                      tooltip: 'Share Project',
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () => _confirmDelete(context, projectVM, project),
                      tooltip: 'Delete Project',
                    ),
                  ],
                ),
                onTap: () {
                  // Navigate to Labeling Page with Project Arguments
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
```
`configure_project_page.dart`
Allows users to create or modify project settings.

```dart
// lib/pages/configure_project_page.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:uuid/uuid.dart';
import '../models/project_model.dart';
import '../view_models/project_view_model.dart';

class ConfigureProjectPage extends StatefulWidget {
  final Project? project;

  const ConfigureProjectPage({Key? key, this.project}) : super(key: key);

  @override
  _ConfigureProjectPageState createState() => _ConfigureProjectPageState();
}

class _ConfigureProjectPageState extends State<ConfigureProjectPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  LabelingMode _selectedMode = LabelingMode.singleClassification;
  final List<String> _classes = [];
  String _dataDirectory = '';

  @override
  void initState() {
    super.initState();
    if (widget.project != null) {
      _nameController.text = widget.project!.name;
      _selectedMode = widget.project!.mode;
      _classes.addAll(widget.project!.classes);
      _dataDirectory = widget.project!.dataDirectory;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _saveProject() {
    if (_formKey.currentState!.validate()) {
      final projectVM = Provider.of<ProjectViewModel>(context, listen: false);
      final project = Project(
        id: widget.project?.id ?? const Uuid().v4(),
        name: _nameController.text,
        mode: _selectedMode,
        classes: _classes,
        dataDirectory: _dataDirectory,
      );

      if (widget.project == null) {
        projectVM.addProject(project);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Project "${project.name}" has been created.')),
        );
      } else {
        projectVM.updateProject(project);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Project "${project.name}" has been updated.')),
        );
      }

      Navigator.pop(context);
    }
  }

  void _addClass() {
    showDialog(
      context: context,
      builder: (context) {
        final _classController = TextEditingController();
        return AlertDialog(
          title: const Text('Add Class'),
          content: TextField(
            controller: _classController,
            decoration: const InputDecoration(labelText: 'Class Name'),
          ),
          actions: [
            TextButton(
              onPressed: () {
                if (_classController.text.isNotEmpty) {
                  setState(() {
                    _classes.add(_classController.text);
                  });
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
    setState(() {
      _classes.removeAt(index);
    });
  }

  Future<void> _pickDataDirectory() async {
    String? selectedDirectory = await FilePicker.platform.getDirectoryPath();
    if (selectedDirectory != null) {
      setState(() {
        _dataDirectory = selectedDirectory;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.project == null ? 'Create Project' : 'Edit Project'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              // Project Name
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Project Name'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a project name.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              // Labeling Mode Selection
              DropdownButtonFormField<LabelingMode>(
                value: _selectedMode,
                decoration: const InputDecoration(labelText: 'Labeling Mode'),
                items: LabelingMode.values.map((mode) {
                  String displayText;
                  switch (mode) {
                    case LabelingMode.singleClassification:
                      displayText = 'Single Classification';
                      break;
                    case LabelingMode.multiClassification:
                      displayText = 'Multi Classification';
                      break;
                    case LabelingMode.segmentation:
                      displayText = 'Segmentation';
                      break;
                  }
                  return DropdownMenuItem<LabelingMode>(
                    value: mode,
                    child: Text(displayText),
                  );
                }).toList(),
                onChanged: (LabelingMode? newMode) {
                  if (newMode != null) {
                    setState(() {
                      _selectedMode = newMode;
                    });
                  }
                },
              ),
              const SizedBox(height: 16),
              // Classes List
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Classes', style: TextStyle(fontSize: 16)),
                  IconButton(
                    icon: const Icon(Icons.add),
                    onPressed: _addClass,
                    tooltip: 'Add Class',
                  ),
                ],
              ),
              ..._classes.asMap().entries.map((entry) {
                int index = entry.key;
                String className = entry.value;
                return ListTile(
                  title: Text(className),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () => _removeClass(index),
                    tooltip: 'Delete Class',
                  ),
                );
              }).toList(),
              const SizedBox(height: 16),
              // Data Directory Selection
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      readOnly: true,
                      decoration: const InputDecoration(
                        labelText: 'Data Directory Path',
                        hintText: 'Select Directory',
                      ),
                      controller: TextEditingController(text: _dataDirectory),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please select a data directory path.';
                        }
                        return null;
                      },
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.folder_open),
                    onPressed: _pickDataDirectory,
                    tooltip: 'Select Directory',
                  ),
                ],
              ),
              const SizedBox(height: 32),
              // Save Button
              ElevatedButton(
                onPressed: _saveProject,
                child: Text(widget.project == null ? 'Create Project' : 'Update Project'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
```

`labeling_page.dart`
Handles the labeling interface where users can annotate data based on the selected labeling mode.

```dart
// lib/pages/labeling_page.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../view_models/label_view_model.dart';
import '../models/project_model.dart';
import '../charts/time_series_chart.dart';

class LabelingPage extends StatefulWidget {
  const LabelingPage({Key? key}) : super(key: key);

  @override
  _LabelingPageState createState() => _LabelingPageState();
}

class _LabelingPageState extends State<LabelingPage> {
  late FocusNode _focusNode;
  String _selectedMode = 'single_classification';
  final List<String> _modes = [
    'single_classification',
    'multi_classification',
    'segmentation'
  ];

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
    // Request focus to capture keyboard events
    WidgetsBinding.instance.addPostFrameCallback((_) {
      FocusScope.of(context).requestFocus(_focusNode);
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  // Keyboard Event Handler
  void _handleKeyEvent(RawKeyEvent event, LabelingViewModel labelingVM) {
    if (event is RawKeyDownEvent) {
      if (event.logicalKey == LogicalKeyboardKey.enter) {
        if (event.isShiftPressed) {
          labelingVM.movePrevious();
        } else {
          labelingVM.moveNext();
        }
      } else if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
        _changeMode(-1);
      } else if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
        _changeMode(1);
      } else if (LogicalKeyboardKey.digit0.keyId <= event.logicalKey.keyId &&
          event.logicalKey.keyId <= LogicalKeyboardKey.digit9.keyId) {
        int index = event.logicalKey.keyId - LogicalKeyboardKey.digit0.keyId;
        if (index < labelingVM.project.classes.length) {
          labelingVM.addOrUpdateLabel(
              labelingVM.currentIndex, labelingVM.project.classes[index], _selectedMode);
        }
      }
    }
  }

  // Change Labeling Mode
  void _changeMode(int delta) {
    int currentIndex = _modes.indexOf(_selectedMode);
    int newIndex = currentIndex + delta;

    if (newIndex < 0) {
      newIndex = _modes.length - 1; // Cycle to last mode
    } else if (newIndex >= _modes.length) {
      newIndex = 0; // Cycle to first mode
    }

    setState(() {
      _selectedMode = _modes[newIndex];
    });
  }

  // Download Labels Progress Indicator and Completion Message
  Future<void> _downloadLabels(
      BuildContext context, LabelingViewModel labelingVM, bool asZip) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
        title: Text('Downloading'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Downloading labeling data...'),
          ],
        ),
      ),
    );

    try {
      String filePath;
      if (asZip) {
        filePath = await labelingVM.downloadLabelsAsZip();
        // Implement sharing of ZIP file if needed
      } else {
        filePath = await labelingVM.downloadLabelsAsZae();
        // Implement sharing of .zae file if needed
      }

      if (!mounted) return; // Ensure widget is still mounted

      Navigator.of(context).pop(); // Close downloading dialog

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Download Complete: $filePath')),
      );
    } catch (e) {
      if (!mounted) return; // Ensure widget is still mounted

      Navigator.of(context).pop(); // Close downloading dialog
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Download Failed: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Retrieve Project from Arguments
    final Project project =
        ModalRoute.of(context)!.settings.arguments as Project;

    return ChangeNotifierProvider(
      create: (_) => LabelingViewModel(project: project),
      child: Consumer<LabelingViewModel>(
        builder: (context, labelingVM, child) {
          return Scaffold(
            appBar: AppBar(
              title: Text('${project.name} Labeling'),
              actions: [
                PopupMenuButton<String>(
                  onSelected: (value) {
                    if (value == 'zip') {
                      _downloadLabels(context, labelingVM, true);
                    } else if (value == 'no_zip') {
                      _downloadLabels(context, labelingVM, false);
                    }
                  },
                  itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                    const PopupMenuItem<String>(
                      value: 'zip',
                      child: Text('Download as ZIP'),
                    ),
                    const PopupMenuItem<String>(
                      value: 'no_zip',
                      child: Text('Download as .zae'),
                    ),
                  ],
                ),
              ],
            ),
            body: RawKeyboardListener(
              focusNode: _focusNode,
              autofocus: true,
              onKey: (event) => _handleKeyEvent(event, labelingVM),
              child: Column(
                children: [
                  // Labeling Mode Selection (Horizontal List)
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: _modes.map((mode) {
                        String displayText;
                        switch (mode) {
                          case 'single_classification':
                            displayText = 'Single Classification';
                            break;
                          case 'multi_classification':
                            displayText = 'Multi Classification';
                            break;
                          case 'segmentation':
                            displayText = 'Segmentation';
                            break;
                          default:
                            displayText = mode;
                        }

                        bool isSelected = _selectedMode == mode;

                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              _selectedMode = mode;
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                vertical: 12.0, horizontal: 16.0),
                            margin: const EdgeInsets.symmetric(horizontal: 4.0),
                            decoration: BoxDecoration(
                              color:
                                  isSelected ? Colors.blueAccent : Colors.grey[200],
                              borderRadius: BorderRadius.circular(8.0),
                            ),
                            child: Text(
                              displayText,
                              style: TextStyle(
                                color: isSelected ? Colors.white : Colors.black,
                                fontSize: 14,
                                fontWeight:
                                    isSelected ? FontWeight.bold : FontWeight.normal,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  Divider(),
                  // Data Visualization (Using fl_chart)
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: labelingVM.currentData.isNotEmpty
                          ? TimeSeriesChart(data: labelingVM.currentData)
                          : const Center(child: Text('No data available.')),
                    ),
                  ),
                  // Current Data Index and Filename Display
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text(
                      'Data ${labelingVM.currentIndex + 1}/${labelingVM.dataFiles.length} - ${labelingVM.currentFileName}',
                      style: const TextStyle(fontSize: 16),
                    ),
                  ),
                  // Label Input Keypad (Displaying Project Classes)
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Wrap(
                      spacing: 8.0,
                      children: List.generate(labelingVM.project.classes.length, (index) {
                        final label = labelingVM.project.classes[index];
                        final isSelected =
                            labelingVM.isLabelSelected(label, _selectedMode);

                        return ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                isSelected ? Colors.blueAccent : null,
                          ),
                          onPressed: () {
                            labelingVM.addOrUpdateLabel(
                                labelingVM.currentIndex, label, _selectedMode);
                          },
                          child: Text(label),
                        );
                      }),
                    ),
                  ),
                  // Current Labels Display
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text(
                      'Current Labels: ${labelingVM.currentLabelEntryToString()}',
                      style: const TextStyle(fontSize: 16),
                    ),
                  ),
                  // Navigation Buttons
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        ElevatedButton(
                          onPressed: () {
                            labelingVM.movePrevious();
                          },
                          child: const Text('Previous'),
                        ),
                        ElevatedButton(
                          onPressed: () {
                            labelingVM.moveNext();
                          },
                          child: const Text('Next'),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

// Extension for LabelingViewModel to Convert Current Label Entry to String
extension LabelingViewModelExtension on LabelingViewModel {
  String currentLabelEntryToString() {
    LabelEntry entry = currentLabelEntry;
    List<String> labelStrings = [];

    if (entry.singleClassification != null) {
      labelStrings.add('Single: ${entry.singleClassification!.label}');
    }
    if (entry.multiClassification != null &&
        entry.multiClassification!.labels.isNotEmpty) {
      labelStrings.add('Multi: ${entry.multiClassification!.labels.join(', ')}');
    }
    if (entry.segmentation != null &&
        entry.segmentation!.classes.isNotEmpty) {
      labelStrings.add(
          'Segmentation: ${entry.segmentation!.classes.join(', ')}');
    }

    return labelStrings.join(' | ');
  }
}
```

`time_series_chart.dart`
Displays time series data using fl_chart.

```dart
// lib/charts/time_series_chart.dart
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class TimeSeriesChart extends StatelessWidget {
  final List<double> data;

  const TimeSeriesChart({Key? key, required this.data}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    double minY = data.reduce((a, b) => a < b ? a : b);
    double maxY = data.reduce((a, b) => a > b ? a : b);
    double margin = (maxY - minY) * 0.1; // 10% margin for Y-axis

    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0), // Prevent cutting off bottom ticks
      child: LineChart(
        LineChartData(
          minY: minY - margin,
          maxY: maxY + margin,
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false, // Disable vertical grid lines
            getDrawingHorizontalLine: (value) {
              if (value == 0) {
                return FlLine(
                  color: Colors.grey,
                  strokeWidth: 1.5,
                );
              }
              return FlLine(
                color: Colors.grey,
                strokeWidth: 0.8,
                dashArray: [5, 5],
              );
            },
          ),
          titlesData: FlTitlesData(
            show: true,
            topTitles: AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 32,
                interval: (maxY + margin - (minY - margin)) / 5, // Set appropriate interval
                getTitlesWidget: (value, meta) {
                  return SideTitleWidget(
                    axisSide: meta.axisSide,
                    child: Text(
                      value.toStringAsFixed(1),
                      style: const TextStyle(
                        color: Colors.black,
                        fontSize: 10,
                      ),
                    ),
                  );
                },
              ),
            ),
            rightTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 40,
                interval: (maxY + margin - (minY - margin)) / 5, // Set appropriate interval
                getTitlesWidget: (value, meta) {
                  return SideTitleWidget(
                    axisSide: meta.axisSide,
                    child: Text(
                      value.toStringAsFixed(1),
                      style: const TextStyle(
                        color: Colors.black,
                        fontSize: 10,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          borderData: FlBorderData(
            show: true,
            border: Border.all(color: Colors.grey),
          ),
          lineBarsData: [
            LineChartBarData(
              spots: generateSpots(data),
              isCurved: false, // Display lines instead of curves
              color: Colors.blue,
              barWidth: 2,
              belowBarData: BarAreaData(show: false),
            ),
          ],
        ),
      ),
    );
  }

  // Convert Time Series Data to FlSpot List
  List<FlSpot> generateSpots(List<double> data) {
    List<FlSpot> spots = [];
    for (int i = 0; i < data.length; i++) {
      spots.add(FlSpot(i.toDouble(), data[i]));
    }
    return spots;
  }
}
```

**Utilities**

`storage_helper.dart`
Handles data persistence, including saving and loading projects and label entries.

```dart
// lib/utils/storage_helper.dart
import 'dart:convert';
import 'dart:io';
import '../models/project_model.dart';
import '../models/label_entry.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:archive/archive.dart';

class StorageHelper {
  // Load Projects from Storage
  static Future<List<Project>> loadProjects() async {
    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.path}/projects.json');

    if (await file.exists()) {
      String content = await file.readAsString();
      List<dynamic> jsonData = jsonDecode(content);
      return jsonData.map((e) => Project.fromJson(e)).toList();
    } else {
      return [];
    }
  }

  // Save Projects to Storage
  static Future<void> saveProjects(List<Project> projects) async {
    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.path}/projects.json');
    List<Map<String, dynamic>> jsonData =
        projects.map((e) => e.toJson()).toList();
    await file.writeAsString(jsonEncode(jsonData));
  }

  // Load Label Entries from Storage
  static Future<List<LabelEntry>> loadLabelEntries() async {
    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.path}/labels.json');

    if (await file.exists()) {
      String content = await file.readAsString();
      List<dynamic> jsonData = jsonDecode(content);
      return jsonData.map((e) => LabelEntry.fromJson(e)).toList();
    } else {
      return [];
    }
  }

  // Save Label Entries to Storage
  static Future<void> saveLabelEntries(List<LabelEntry> labelEntries) async {
    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.path}/labels.json');
    List<Map<String, dynamic>> jsonData =
        labelEntries.map((e) => e.toJson()).toList();
    await file.writeAsString(jsonEncode(jsonData));
  }

  // Download Project Configuration as JSON File
  static Future<String> downloadProjectConfig(Project project) async {
    // Determine directory based on platform
    Directory directory;
    if (Platform.isAndroid) {
      // Android: Downloads directory
      final dirs = await getExternalStorageDirectories(type: StorageDirectory.downloads);
      if (dirs == null || dirs.isEmpty) {
        throw Exception('Downloads directory not found.');
      }
      directory = dirs.first;
    } else if (Platform.isIOS) {
      // iOS: Application documents directory
      directory = await getApplicationDocumentsDirectory();
    } else if (Platform.isWindows) {
      // Windows: Downloads directory
      final downloadsDirectory = await getDownloadsDirectory();
      if (downloadsDirectory == null) {
        throw Exception('Downloads directory not found.');
      }
      directory = downloadsDirectory;
    } else {
      throw UnsupportedError('Unsupported platform.');
    }

    // Set file path
    String filePath;
    if (Platform.isWindows) {
      filePath = '${directory.path}\\${project.name}_config.json';
    } else {
      filePath = '${directory.path}/${project.name}_config.json';
    }
    File file = File(filePath);

    // Save project as JSON
    String jsonString = jsonEncode(project.toJson());
    await file.writeAsString(jsonString);

    return filePath;
  }
}
```

**Main Entry Point**

`main.dart`
Initializes the app and sets up routing.

```dart
// lib/main.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'view_models/project_view_model.dart';
import 'pages/project_list_page.dart';
import 'pages/labeling_page.dart';
import 'pages/configure_project_page.dart';

void main() {
  runApp(const FlutterLabelingApp());
}

class FlutterLabelingApp extends StatelessWidget {
  const FlutterLabelingApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<ProjectViewModel>(
      create: (_) => ProjectViewModel(),
      child: MaterialApp(
        title: 'Flutter Labeling App',
        theme: ThemeData(
          primarySwatch: Colors.blue,
        ),
        initialRoute: '/',
        routes: {
          '/': (context) => const ProjectListPage(),
          '/labeling': (context) => const LabelingPage(),
          '/configure': (context) => const ConfigureProjectPage(),
        },
      ),
    );
  }
}
```

## Contributing
Contributions are welcome! Please follow these steps to contribute:

1. **Fork the Repository**
   Click the "Fork" button at the top-right corner of the repository page.
2. **Clone Your Fork**
   ```bash
   git clone https://github.com/your-username/flutter-labeling-app.git
   cd flutter-labeling-app
   ```
3. Create a New Branch
   ```bash
   git checkout -b feature/your-feature-name
   ```
4. Make Your Changes
   Implement your feature or bug fix.
5. Commit Your Changes
   ```bash
   git commit -m "Add feature: your feature description"
   ```
6. Push to Your Fork
   ```bash
   git push origin feature/your-feature-name
   ```
7. Create a Pull Request
   Go to your forked repository on GitHub and click the "Compare & pull request" button.

---
## License
This project is licensed under the MIT License. See the LICENSE file for details.

---
## Additional Notes for Developers
- **State Management**: The app uses the `Provider` package for state management, ensuring efficient and scalable state handling.
- **File Handling**: The `file_picker` package is utilized for selecting files and directories, making file operations user-friendly.
- **Data Persistence**: Project configurations and label entries are stored as JSON files in the application documents directory, ensuring data integrity and ease of access.
- **Cross-Platform Considerations**: While the app is optimized for Windows, it includes web support. Developers should be mindful of platform-specific file handling and UI adjustments.
- **Error Handling**: Comprehensive error handling is implemented across the app to ensure robustness. Developers are encouraged to maintain and extend this for new features.
- **UI/UX**: The app features a clean and intuitive interface. Future enhancements can focus on improving user experience based on feedback.


For any further questions or support, please open an issue on the GitHub repository or contact the maintainer directly.

Happy labeling!

<!-- 웹 호스트
https://cajava.tistory.com/30 -->