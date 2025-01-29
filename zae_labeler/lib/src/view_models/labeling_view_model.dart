// lib/src/view_models/labeling_view_model.dart
import 'dart:convert';
import 'dart:io';
import 'package:path/path.dart' as path;
import 'package:flutter/material.dart';
import '../models/label_entry.dart';
import '../models/project_model.dart';
import '../models/data_model.dart';
import '../utils/storage_helper.dart';

class LabelingViewModel extends ChangeNotifier {
  final Project project;
  final StorageHelper storageHelper; // ✅ Dependency Injection 허용

  int _currentIndex = 0;
  UnifiedData? _currentUnifiedData;

  LabelingViewModel({required this.project, required this.storageHelper});

  List<LabelEntry> get labelEntries => project.labelEntries;
  int get currentIndex => _currentIndex;
  UnifiedData? get currentUnifiedData => _currentUnifiedData;

  String get currentDataFileName => labelEntries.isNotEmpty ? path.basename(labelEntries[_currentIndex].dataFilename) : "";

  List<double>? get currentSeriesData => _currentUnifiedData?.seriesData;
  Map<String, dynamic>? get currentObjectData => _currentUnifiedData?.objectData;
  File? get currentImageFile => _currentUnifiedData?.file;

  Future<void> initialize() async {
    if (project.labelEntries.isEmpty) {
      project.labelEntries = []; // 프로젝트 내에서 직접 관리
    }
    await updateLabelState();
    notifyListeners();
  }

  LabelEntry get currentLabelEntry {
    if (_currentIndex < 0 || _currentIndex >= project.labelEntries.length) {
      return LabelEntry(dataFilename: '', dataPath: '');
    }
    return project.labelEntries[_currentIndex];
  }

  Future<void> updateLabelState() async {
    if (_currentIndex < 0 || _currentIndex >= project.dataPaths.length) return;
    _currentUnifiedData = await UnifiedData.fromDataPath(project.dataPaths[_currentIndex]);
    notifyListeners();
  }

  void addOrUpdateLabel(String label, String mode) {
    final dataId = project.dataPaths[_currentIndex].fileName;
    final existingEntryIndex = project.labelEntries.indexWhere((entry) => entry.dataPath == dataId);

    if (existingEntryIndex != -1) {
      LabelEntry entry = project.labelEntries[existingEntryIndex];
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
          // Segmentation 라벨 추가 로직 필요
          break;
        default:
          break;
      }
    } else {
      project.labelEntries.add(LabelEntry(
        dataFilename: dataId,
        dataPath: dataId,
        singleClassification: SingleClassificationLabel(
          labeledAt: DateTime.now().toIso8601String(),
          label: label,
        ),
      ));
    }

    // Save updated project
    storageHelper.saveProjects([project]); // ✅ Mock 가능하도록 수정
    notifyListeners();
  }

  bool isLabelSelected(String label, String mode) {
    LabelEntry entry = currentLabelEntry;
    switch (mode) {
      case 'single_classification':
        return entry.singleClassification?.label == label;
      case 'multi_classification':
        return entry.multiClassification?.labels.contains(label) ?? false;
      default:
        return false;
    }
  }

  void moveNext() {
    if (_currentIndex < project.dataPaths.length - 1) {
      _currentIndex++;
      updateLabelState();
      notifyListeners();
    }
  }

  void movePrevious() {
    if (_currentIndex > 0) {
      _currentIndex--;
      updateLabelState();
      notifyListeners();
    }
  }

  Future<String> downloadLabelsAsZip() async {
    return await StorageHelper().downloadLabelsAsZip(project, project.labelEntries, []);
  }
}
