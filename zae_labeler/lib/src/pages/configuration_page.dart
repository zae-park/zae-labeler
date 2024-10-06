// lib/src/pages/configuration_page.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../view_models/configuration_view_model.dart';
import '../view_models/project_manager_view_model.dart';
import '../models/project_model.dart';

class ConfigurationPage extends StatelessWidget {
  final _formKey = GlobalKey<FormState>();
  final _projectNameController = TextEditingController();
  final _classController = TextEditingController();

  ConfigurationPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ConfigurationViewModel(),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('프로젝트 구성'),
        ),
        body: Consumer<ConfigurationViewModel>(
          builder: (context, configVM, child) {
            return Padding(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: ListView(
                  children: [
                    // 프로젝트 이름 입력
                    TextFormField(
                      controller: _projectNameController,
                      decoration: const InputDecoration(labelText: '프로젝트 이름'),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return '프로젝트 이름을 입력해주세요.';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),
                    // 라벨링 모드 선택
                    const Text(
                      '라벨링 모드 선택',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    ListTile(
                      title: const Text('Single Classification'),
                      leading: Radio<LabelingMode>(
                        value: LabelingMode.singleClassification,
                        groupValue: configVM.selectedMode,
                        onChanged: (LabelingMode? value) {
                          if (value != null) configVM.selectMode(value);
                        },
                      ),
                    ),
                    ListTile(
                      title: const Text('Multi Classification'),
                      leading: Radio<LabelingMode>(
                        value: LabelingMode.multiClassification,
                        groupValue: configVM.selectedMode,
                        onChanged: (LabelingMode? value) {
                          if (value != null) configVM.selectMode(value);
                        },
                      ),
                    ),
                    ListTile(
                      title: const Text('Segmentation'),
                      leading: Radio<LabelingMode>(
                        value: LabelingMode.segmentation,
                        groupValue: configVM.selectedMode,
                        onChanged: (LabelingMode? value) {
                          if (value != null) configVM.selectMode(value);
                        },
                      ),
                    ),
                    const SizedBox(height: 20),
                    // 클래스 설정
                    const Text(
                      '라벨 클래스 설정 (최대 10개)',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    Wrap(
                      spacing: 8.0,
                      children: configVM.classes
                          .map((cls) => Chip(
                                label: Text(cls),
                                onDeleted: () {
                                  configVM.removeClass(cls);
                                },
                              ))
                          .toList(),
                    ),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _classController,
                            decoration:
                                const InputDecoration(labelText: '클래스 이름'),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.add),
                          onPressed: () {
                            final cls = _classController.text.trim();
                            if (cls.isNotEmpty) {
                              configVM.addClass(cls);
                              _classController.clear();
                            }
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    // 데이터 디렉토리 선택 버튼
                    ElevatedButton(
                      onPressed: () async {
                        await configVM.setDataDirectory();
                      },
                      child: Text(configVM.dataDirectory.isEmpty
                          ? '데이터 디렉토리 선택'
                          : '선택된 디렉토리: ${configVM.dataDirectory}'),
                    ),
                    const SizedBox(height: 20),
                    // 확인 버튼
                    ElevatedButton(
                      onPressed: () {
                        if (_formKey.currentState!.validate()) {
                          if (configVM.selectedMode == null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('라벨링 모드를 선택해주세요.')),
                            );
                            return;
                          }
                          if (configVM.classes.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('클래스를 추가해주세요.')),
                            );
                            return;
                          }
                          if (configVM.dataDirectory.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text('데이터 디렉토리를 선택해주세요.')),
                            );
                            return;
                          }
                          // 프로젝트 생성
                          Provider.of<ProjectManagerViewModel>(context,
                                  listen: false)
                              .createProject(
                            _projectNameController.text.trim(),
                            configVM.selectedMode!,
                            configVM.classes,
                            configVM.dataDirectory,
                          );
                          // 프로젝트 목록 페이지로 이동
                          Navigator.pop(context);
                        }
                      },
                      child: const Text('확인'),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
