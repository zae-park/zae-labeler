// lib/src/pages/configure_project_page.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/project_model.dart';
import '../view_models/project_view_model.dart';
import 'package:uuid/uuid.dart';

class ConfigureProjectPage extends StatefulWidget {
  final Project? project;

  const ConfigureProjectPage({Key? key, this.project}) : super(key: key);

  @override
  _ConfigureProjectPageState createState() => _ConfigureProjectPageState();
}

class _ConfigureProjectPageState extends State<ConfigureProjectPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  String _selectedMode = 'single_classification';
  final List<String> _classes = [];
  String _dataDirectory = '';

  @override
  void initState() {
    super.initState();
    if (widget.project != null) {
      _nameController.text = widget.project!.name;
      _selectedMode =
          widget.project!.mode.toString().split('.').last.toLowerCase();
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
        mode: LabelingMode.values.firstWhere(
            (e) => e.toString().split('.').last.toLowerCase() == _selectedMode,
            orElse: () => LabelingMode.singleClassification),
        classes: _classes,
        dataDirectory: _dataDirectory,
      );

      if (widget.project == null) {
        projectVM.addProject(project);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${project.name} 프로젝트가 생성되었습니다.')),
        );
      } else {
        projectVM.updateProject(project);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${project.name} 프로젝트가 수정되었습니다.')),
        );
      }

      Navigator.pop(context);
    }
  }

  void _addClass() {
    showDialog(
      context: context,
      builder: (context) {
        final classController = TextEditingController();
        return AlertDialog(
          title: const Text('클래스 추가'),
          content: TextField(
            controller: classController,
            decoration: const InputDecoration(labelText: '클래스 이름'),
          ),
          actions: [
            TextButton(
              onPressed: () {
                if (classController.text.isNotEmpty) {
                  setState(() {
                    _classes.add(classController.text);
                  });
                  Navigator.pop(context);
                }
              },
              child: const Text('추가'),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.project == null ? '프로젝트 생성' : '프로젝트 수정'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              // 프로젝트 이름
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: '프로젝트 이름'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return '프로젝트 이름을 입력하세요';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              // 라벨링 모드 선택
              DropdownButtonFormField<String>(
                value: _selectedMode,
                decoration: const InputDecoration(labelText: '라벨링 모드'),
                items: const [
                  DropdownMenuItem(
                    value: 'single_classification',
                    child: Text('Single Classification'),
                  ),
                  DropdownMenuItem(
                    value: 'multi_classification',
                    child: Text('Multi Classification'),
                  ),
                  DropdownMenuItem(
                    value: 'segmentation',
                    child: Text('Segmentation'),
                  ),
                ],
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _selectedMode = value;
                    });
                  }
                },
              ),
              const SizedBox(height: 16),
              // 클래스 목록
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('클래스 목록', style: TextStyle(fontSize: 16)),
                  IconButton(
                    icon: const Icon(Icons.add),
                    onPressed: _addClass,
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
                  ),
                );
              }).toList(),
              const SizedBox(height: 16),
              // 데이터 디렉토리
              TextFormField(
                initialValue: _dataDirectory,
                decoration: const InputDecoration(labelText: '데이터 디렉토리 경로'),
                onChanged: (value) {
                  _dataDirectory = value;
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return '데이터 디렉토리 경로를 입력하세요';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 32),
              // 저장 버튼
              ElevatedButton(
                onPressed: _saveProject,
                child: Text(widget.project == null ? '프로젝트 생성' : '프로젝트 수정'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
