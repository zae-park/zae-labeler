import 'dart:convert';
import 'dart:html' as html;
import 'dart:async';
import 'package:archive/archive.dart';
import 'package:flutter/services.dart';
import 'package:zae_labeler/src/models/data_model.dart';

import '../../models/project_model.dart';
import '../../models/label_model.dart';
import '../../models/label_models/classification_label_model.dart';
import '../../models/label_models/segmentation_label_model.dart';
import 'interface_storage_helper.dart';

class StorageHelperImpl implements StorageHelperInterface {
  // ==============================
  // 📌 **Project Configuration IO**
  // ==============================

  @override
  Future<void> saveProjectConfig(List<Project> projects) async {
    final projectsJson = jsonEncode(projects.map((e) => e.toJson()).toList());
    html.window.localStorage['projects'] = projectsJson;
  }

  @override
  Future<List<Project>> loadProjectFromConfig(String projectConfig) async {
    final projectsJson = html.window.localStorage['projects'];
    if (projectsJson != null) {
      final jsonData = jsonDecode(projectsJson);
      return (jsonData as List).map((e) => Project.fromJson(e)).toList();
    }
    return [];
  }

  @override
  Future<String> downloadProjectConfig(Project project) async {
    final jsonString = jsonEncode(project.toJson());
    final blob = html.Blob([jsonString]);
    final url = html.Url.createObjectUrlFromBlob(blob);
    html.AnchorElement(href: url)
      ..setAttribute("download", "${project.name}_config.json")
      ..click();
    html.Url.revokeObjectUrl(url);
    return "${project.name}_config.json (downloaded in browser)";
  }

  // ==============================
  // 📌 **Single Label Data IO**
  // ==============================

  @override
  Future<void> saveLabelData(String projectId, String dataPath, LabelModel labelModel) async {
    final storageKey = 'labels_project_$projectId';
    final labelsJson = html.window.localStorage[storageKey];

    List<Map<String, dynamic>> existingEntries = [];
    if (labelsJson != null) {
      final jsonData = jsonDecode(labelsJson);
      existingEntries = (jsonData as List).map((e) => e as Map<String, dynamic>).toList();
    }

    Map<String, dynamic> labelEntry = {
      'data_path': dataPath,
      'mode': labelModel.runtimeType.toString(),
      'labeled_at': labelModel.labeledAt.toIso8601String(),
      'label_data': _convertLabelModelToJson(labelModel),
    };

    int index = existingEntries.indexWhere((entry) => entry['data_path'] == dataPath);
    if (index != -1) {
      existingEntries[index] = labelEntry;
    } else {
      existingEntries.add(labelEntry);
    }

    html.window.localStorage[storageKey] = jsonEncode(existingEntries);
  }

  @override
  Future<LabelModel> loadLabelData(String projectId, String dataPath, LabelingMode mode) async {
    final storageKey = 'labels_project_$projectId';
    final labelsJson = html.window.localStorage[storageKey];

    if (labelsJson != null) {
      final jsonData = jsonDecode(labelsJson);
      final entries = (jsonData as List).map((e) => e as Map<String, dynamic>).toList();
      Map<String, dynamic>? labelEntry = entries.firstWhere(
        (entry) => entry['data_path'] == dataPath,
        orElse: () => {},
      );

      if (labelEntry.isNotEmpty) {
        return _convertJsonToLabelModel(mode, labelEntry['label_data']);
      }
    }
    return _convertJsonToLabelModel(mode, {});
  }

  // ==============================
  // 📌 **Project-wide Label IO**
  // ==============================

  @override
  Future<void> saveAllLabels(String projectId, List<LabelModel> labels) async {
    final storageKey = 'labels_project_$projectId';

    List<Map<String, dynamic>> labelEntries = labels
        .map((label) => {
              'mode': label.runtimeType.toString(),
              'labeled_at': label.labeledAt.toIso8601String(),
              'label_data': _convertLabelModelToJson(label),
            })
        .toList();

    html.window.localStorage[storageKey] = jsonEncode(labelEntries);
  }

  // ✅ 모든 Label 불러오기
  @override
  Future<List<LabelModel>> loadAllLabels(String projectId) async {
    final storageKey = 'labels_project_$projectId';
    final labelsJson = html.window.localStorage[storageKey];

    if (labelsJson != null) {
      final jsonData = jsonDecode(labelsJson);
      return (jsonData as List).map((entry) {
        final mode = LabelingMode.values.firstWhere((e) => e.toString() == entry['mode']);
        return _convertJsonToLabelModel(mode, entry['label_data']);
      }).toList();
    }
    return [];
  }

  // ==============================
  // 📌 **Label Data Import/Export**
  // ==============================

  @override
  Future<String> exportAllLabels(Project project, List<LabelModel> labelModels, List<DataPath> fileDataList) async {
    final archive = Archive();

    // ✅ DataPath에서 데이터 로드 및 ZIP 추가
    for (var dataPath in fileDataList) {
      final content = await dataPath.loadData();
      if (content != null) {
        final fileBytes = utf8.encode(content);
        archive.addFile(ArchiveFile(dataPath.fileName, fileBytes.length, fileBytes));
      }
    }

    // ✅ JSON 직렬화된 라벨 데이터 추가 (LabelModel.toJson() 사용)
    List<Map<String, dynamic>> labelEntries = labelModels
        .map((label) => {
              'mode': label.runtimeType.toString(),
              'labeled_at': label.labeledAt.toIso8601String(),
              'label_data': _convertLabelModelToJson(label),
            })
        .toList();

    final labelsJson = jsonEncode(labelEntries);
    archive.addFile(ArchiveFile('labels.json', labelsJson.length, utf8.encode(labelsJson)));

    // ✅ ZIP 파일 생성
    final zipData = ZipEncoder().encode(archive);

    // ✅ Blob 생성 및 다운로드 링크 구성
    final blob = html.Blob([Uint8List.fromList(zipData!)]);
    final url = html.Url.createObjectUrlFromBlob(blob);
    html.AnchorElement(href: url)
      ..setAttribute("download", "${project.name}_labels.zip")
      ..click();
    html.Url.revokeObjectUrl(url);

    return "${project.name}_labels.zip (downloaded in browser)";
  }

  @override
  Future<List<LabelModel>> importAllLabels() async {
    final completer = Completer<List<LabelModel>>();

    final input = html.FileUploadInputElement();
    input.accept = '.json';
    input.multiple = false;

    input.onChange.listen((event) async {
      final files = input.files;
      if (files != null && files.isNotEmpty) {
        final reader = html.FileReader();
        reader.readAsText(files[0]);

        reader.onLoadEnd.listen((event) {
          try {
            final jsonData = jsonDecode(reader.result as String);
            if (jsonData is List) {
              final labels = jsonData.map((entry) {
                final mode = LabelingMode.values.firstWhere((e) => e.toString() == entry['mode']);
                return _convertJsonToLabelModel(mode, entry['label_data']);
              }).toList();
              completer.complete(labels);
            } else {
              throw const FormatException('Invalid JSON format. Expected a list.');
            }
          } catch (e) {
            completer.completeError(e);
          }
        });
        reader.onError.listen((error) => completer.completeError(error));
      } else {
        completer.completeError(Exception('No file selected.'));
      }
    });

    input.click();
    return completer.future;
  }

  /// ✅ `LabelModel`을 JSON으로 변환하는 메서드
  Map<String, dynamic> _convertLabelModelToJson(LabelModel labelModel) {
    if (labelModel is SingleClassificationLabelModel) {
      return {'labeled_at': labelModel.labeledAt.toIso8601String(), 'label': labelModel.label};
    } else if (labelModel is MultiClassificationLabelModel) {
      return {'labeled_at': labelModel.labeledAt.toIso8601String(), 'labels': labelModel.label};
    } else if (labelModel is SingleClassSegmentationLabelModel) {
      return {'labeled_at': labelModel.labeledAt.toIso8601String(), 'segmentation': labelModel.label.toJson()};
    } else if (labelModel is MultiClassSegmentationLabelModel) {
      return {'labeled_at': labelModel.labeledAt.toIso8601String(), 'segmentation': labelModel.label.toJson()};
    }
    throw Exception("Unknown LabelModel type");
  }

  /// ✅ JSON 데이터를 `LabelModel` 객체로 변환하는 메서드
  LabelModel _convertJsonToLabelModel(LabelingMode mode, Map<String, dynamic> json) {
    try {
      switch (mode) {
        case LabelingMode.singleClassification:
          return SingleClassificationLabelModel(labeledAt: DateTime.parse(json['labeled_at']), label: json['label']);
        case LabelingMode.multiClassification:
          return MultiClassificationLabelModel(labeledAt: DateTime.parse(json['labeled_at']), label: List<String>.from(json['labels']));
        case LabelingMode.singleClassSegmentation:
          return SingleClassSegmentationLabelModel(labeledAt: DateTime.parse(json['labeled_at']), label: SegmentationData.fromJson(json['segmentation']));
        case LabelingMode.multiClassSegmentation:
          return MultiClassSegmentationLabelModel(labeledAt: DateTime.parse(json['labeled_at']), label: SegmentationData.fromJson(json['segmentation']));
      }
    } catch (e) {
      return SingleClassificationLabelModel.empty();
    }
  }
}
