import 'dart:convert';
import 'dart:io';
// import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:archive/archive.dart';
import '../../models/label_model.dart';
import '../../models/label_models/classification_label_model.dart';
import '../../models/label_models/segmentation_label_model.dart';
import '../../models/project_model.dart';
import '../../models/data_model.dart';
import './interface_storage_helper.dart';

class StorageHelperImpl implements StorageHelperInterface {
  // ==============================
  // 📌 **Project Configuration IO**
  // ==============================

  @override
  Future<void> saveProjectConfig(List<Project> projects) async {
    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.path}/projects.json');
    final projectsJson = jsonEncode(projects.map((e) => e.toJson()).toList());
    await file.writeAsString(projectsJson);
  }

  @override
  Future<List<Project>> loadProjectFromConfig(String projectConfig) async {
    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.path}/projects.json');
    if (await file.exists()) {
      final content = await file.readAsString();
      List<dynamic> jsonData = jsonDecode(content);
      return jsonData.map((e) => Project.fromJson(e)).toList();
    }
    return [];
  }

  @override
  Future<String> downloadProjectConfig(Project project) async {
    final directory = await getApplicationDocumentsDirectory();
    final filePath = '${directory.path}/${project.name}_config.json';
    final file = File(filePath);
    final jsonString = jsonEncode(project.toJson());
    await file.writeAsString(jsonString);
    return filePath;
  }

  // ==============================
  // 📌 **Single Label Data IO**
  // ==============================

  @override
  Future<void> saveLabelData(String projectId, String dataPath, LabelModel labelModel) async {
    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.path}/labels_project_$projectId.json');

    List<Map<String, dynamic>> existingEntries = [];
    if (await file.exists()) {
      final content = await file.readAsString();
      final jsonData = jsonDecode(content);
      existingEntries = (jsonData as List).map((e) => e as Map<String, dynamic>).toList();
    }

    // ✅ `LabelModel`을 JSON으로 변환
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

    await file.writeAsString(jsonEncode(existingEntries));
  }

  @override
  Future<LabelModel> loadLabelData(String projectId, String dataPath, LabelingMode mode) async {
    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.path}/labels_project_$projectId.json');

    if (await file.exists()) {
      final content = await file.readAsString();
      final jsonData = jsonDecode(content);
      final entries = (jsonData as List).map((e) => e as Map<String, dynamic>).toList();
      Map<String, dynamic>? labelEntry = entries.firstWhere((entry) => entry['data_path'] == dataPath, orElse: () => {});

      if (labelEntry.isNotEmpty) {
        return _convertJsonToLabelModel(mode, labelEntry['label_data']);
      }
    }
    return _convertJsonToLabelModel(mode, {});
  }

  // ==============================
  // 📌 **Project-wide Label IO**
  // ==============================

  // Entire LabelModel IO
  @override
  Future<void> saveAllLabels(String projectId, List<LabelModel> labels) async {
    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.path}/labels_project_$projectId.json');

    // ✅ LabelModel을 JSON으로 변환 후 저장
    List<Map<String, dynamic>> labelEntries = labels
        .map((label) => {
              'mode': label.runtimeType.toString(),
              'labeled_at': label.labeledAt.toIso8601String(),
              'label_data': _convertLabelModelToJson(label),
            })
        .toList();

    // await file.writeAsString(jsonEncode(labelEntries));
    await file.writeAsString(utf8.decode(utf8.encode(jsonEncode(labelEntries))));
  }

  @override
  Future<List<LabelModel>> loadAllLabels(String projectId) async {
    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.path}/labels_project_$projectId.json');

    if (await file.exists()) {
      final content = await file.readAsString();
      final jsonData = jsonDecode(content);
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
    final directory = await getApplicationDocumentsDirectory();
    final zipFile = File('${directory.path}/${project.name}_labels.zip');
    final zipData = ZipEncoder().encode(archive);
    await zipFile.writeAsBytes(zipData!);

    return zipFile.path;
  }

  @override
  Future<List<LabelModel>> importAllLabels() async {
    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.path}/labels_import.json');

    if (await file.exists()) {
      final content = await file.readAsString();
      final jsonData = jsonDecode(content);
      return (jsonData as List).map((entry) {
        final mode = LabelingMode.values.firstWhere((e) => e.toString() == entry['mode']);
        return _convertJsonToLabelModel(mode, entry['label_data']);
      }).toList();
    }
    return [];
  }

  /// ✅ `LabelModel`을 JSON으로 변환하는 메서드
  Map<String, dynamic> _convertLabelModelToJson(LabelModel labelModel) {
    if (labelModel is SingleClassificationLabelModel) {
      return {
        'labeled_at': labelModel.labeledAt.toIso8601String(),
        'label': labelModel.label,
      };
    } else if (labelModel is MultiClassificationLabelModel) {
      return {
        'labeled_at': labelModel.labeledAt.toIso8601String(),
        'labels': labelModel.label,
      };
    } else if (labelModel is SingleClassSegmentationLabelModel) {
      return {
        'labeled_at': labelModel.labeledAt.toIso8601String(),
        'segmentation': labelModel.label.toJson(),
      };
    } else if (labelModel is MultiClassSegmentationLabelModel) {
      return {
        'labeled_at': labelModel.labeledAt.toIso8601String(),
        'segmentation': labelModel.label.toJson(),
      };
    }
    throw Exception("Unknown LabelModel type");
  }

  /// ✅ JSON 데이터를 `LabelModel` 객체로 변환하는 메서드
  LabelModel _convertJsonToLabelModel(LabelingMode mode, Map<String, dynamic> json) {
    try {
      switch (mode) {
        case LabelingMode.singleClassification:
          return SingleClassificationLabelModel(
            labeledAt: DateTime.parse(json['labeled_at']),
            label: json['label'],
          );
        case LabelingMode.multiClassification:
          return MultiClassificationLabelModel(
            labeledAt: DateTime.parse(json['labeled_at']),
            label: List<String>.from(json['labels']),
          );
        case LabelingMode.singleClassSegmentation:
          return SingleClassSegmentationLabelModel(
            labeledAt: DateTime.parse(json['labeled_at']),
            label: SegmentationData.fromJson(json['segmentation']),
          );
        case LabelingMode.multiClassSegmentation:
          return MultiClassSegmentationLabelModel(
            labeledAt: DateTime.parse(json['labeled_at']),
            label: SegmentationData.fromJson(json['segmentation']),
          );
      }
    } catch (e) {
      print("⚠️ LabelModel 변환 실패: $e");
      return SingleClassificationLabelModel.empty(); // 예외 발생 시 기본값 반환
    }
  }
}
