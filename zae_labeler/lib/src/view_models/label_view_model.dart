import 'package:zae_labeler/src/utils/proxy_storage_helper/interface_storage_helper.dart';

import '../models/label_model.dart';
import 'sub_view_models/base_label_view_model.dart';
import 'sub_view_models/classification_label_view_model.dart';
import 'sub_view_models/segmentation_label_view_model.dart';
export 'sub_view_models/base_label_view_model.dart';
export 'sub_view_models/classification_label_view_model.dart';
export 'sub_view_models/segmentation_label_view_model.dart';

// /// ✅ Label 저장 및 로드를 관리하는 ViewModel
// class LabelViewModel {
//   final String projectId; // ✅ 프로젝트 ID
//   final String dataId; // ✅ 데이터 ID
//   final String dataFilename; // ✅ 데이터 파일명
//   final String dataPath; // ✅ 데이터 파일 경로
//   final LabelingMode mode; // ✅ 현재 데이터의 LabelingMode
//   LabelModel labelModel; // ✅ 현재 라벨링 모델

//   LabelViewModel(
//       {required this.projectId, required this.dataId, required this.dataFilename, required this.dataPath, required this.mode, required this.labelModel});

//   /// ✅ Label 데이터를 StorageHelper에 저장
//   Future<void> saveLabel() async {
//     await StorageHelper.instance.saveLabelData(projectId, dataId, dataPath, labelModel);
//   }

//   /// ✅ StorageHelper에서 Label 데이터를 불러옴
//   Future<void> loadLabel() async {
//     labelModel = await StorageHelper.instance.loadLabelData(projectId, dataId, dataPath, mode);
//   }

//   /// ✅ 새로운 Label 데이터로 업데이트
//   void updateLabel<T>(T newLabelData) {
//     labelModel = labelModel.updateLabel(newLabelData);
//   }

//   bool isSelected(String label) => labelModel.isSelected(label);
// }

class LabelViewModelFactory {
  static LabelViewModel create({
    required String projectId,
    required String dataId,
    required String dataFilename,
    required String dataPath,
    required LabelingMode mode,
    required StorageHelperInterface storageHelper,
  }) {
    switch (mode) {
      case LabelingMode.singleClassification:
      case LabelingMode.multiClassification:
        return ClassificationLabelViewModel(
          projectId: projectId,
          dataId: dataId,
          dataFilename: dataFilename,
          dataPath: dataPath,
          mode: mode,
          labelModel: LabelModelFactory.createNew(mode, dataId: dataId),
          storageHelper: storageHelper,
        );

      case LabelingMode.crossClassification:
        return CrossClassificationLabelViewModel(
          projectId: projectId,
          dataId: dataId,
          dataFilename: dataFilename,
          dataPath: dataPath,
          mode: mode,
          labelModel: LabelModelFactory.createNew(mode, dataId: dataId),
          storageHelper: storageHelper,
        );

      case LabelingMode.singleClassSegmentation:
      case LabelingMode.multiClassSegmentation:
        return SegmentationLabelViewModel(
          projectId: projectId,
          dataId: dataId,
          dataFilename: dataFilename,
          dataPath: dataPath,
          mode: mode,
          labelModel: LabelModelFactory.createNew(mode, dataId: dataId),
          storageHelper: storageHelper,
        );
    }
  }
}


// // lib/src/models/label_entry.dart
// import 'label_model.dart';
// import 'label_models/classification_label_model.dart';
// import 'label_models/segmentation_label_model.dart';

// /*
// 이 파일은 데이터 파일에 대한 라벨 정보의 정의를 포함합니다.
//   - LabelEntry 클래스는 단일 분류(Single Classification), 다중 분류(Multi Classification), 세그멘테이션(Segmentation) 등의 작업을 지원하며,
//     현재 프로젝트의 LabelingMode에 따라 단일 라벨 정보만 저장합니다.
// */

// /// ✅ `LabelingMode`와 JSON 변환 클래스를 매핑하는 맵.
// /// - 새로운 `LabelingMode`가 추가될 경우 이 맵에만 추가하면 됨.
// final Map<LabelingMode, Function(Map<String, dynamic>)> labelFactory = {
//   LabelingMode.singleClassification: (json) => SingleClassificationLabel.fromJson(json),
//   LabelingMode.multiClassification: (json) => MultiClassificationLabel.fromJson(json),
//   LabelingMode.singleClassSegmentation: (json) => SingleClassSegmentationLabel.fromJson(json),
//   LabelingMode.multiClassSegmentation: (json) => MultiClassSegmentationLabel.fromJson(json),
// };

// /// ✅ `labelData`를 자동으로 생성하는 함수.
// /// - `LabelingMode`에 따라 올바른 라벨 클래스 인스턴스를 생성함.
// T? _createLabelData<T>(LabelingMode mode, Map<String, dynamic>? json) {
//   if (json == null) return null;
//   return labelFactory[mode]?.call(json) as T?;
// }

// /// ✅ 특정 데이터 파일에 대한 라벨 정보를 저장하는 클래스.
// /// - 프로젝트의 `LabelingMode`에 따라 하나의 라벨만 포함.
// /// - 단일 분류, 다중 분류 또는 세그멘테이션 중 하나만 저장됨.
// ///
// /// 📌 **예제 코드**
// /// ```dart
// /// LabelEntry entry = LabelEntry(
// ///   dataFilename: "image1.png",
// ///   dataPath: "/dataset/images/image1.png",
// ///   labelingMode: LabelingMode.singleClassification,
// ///   label: SingleClassificationLabel(labeledAt: "2024-06-10T12:00:00Z", label: "cat"),
// /// );
// ///
// /// print(entry.toJson());
// /// ```
// class LabelEntry<T extends LabelModel> {
//   final String dataFilename; // **데이터 파일 이름**
//   final String dataPath; // **데이터 파일 경로**
//   final LabelingMode labelingMode; // **해당 Entry가 속한 Labeling Mode**
//   final T labelData; // **라벨 데이터 (T 타입)**

//   LabelEntry({required this.dataFilename, required this.dataPath, required this.labelingMode, required this.labelData});

//   /// ✅ `LabelingMode`에 따른 빈 LabelModel 반환 함수
//   static LabelModel _getEmptyLabel(LabelingMode mode) {
//     switch (mode) {
//       case LabelingMode.singleClassification:
//         return SingleClassificationLabel.empty();
//       case LabelingMode.multiClassification:
//         return MultiClassificationLabel.empty();
//       case LabelingMode.singleClassSegmentation:
//         return SingleClassSegmentationLabel.empty();
//       case LabelingMode.multiClassSegmentation:
//         return MultiClassSegmentationLabel.empty();
//     }
//   }

//   /// **빈 LabelEntry 객체를 생성하는 팩토리 메서드.**
//   factory LabelEntry.empty(LabelingMode mode) {
//     return LabelEntry(dataFilename: '', dataPath: '', labelingMode: mode, labelData: _getEmptyLabel(mode) as T);
//   }

//   /// **LabelEntry 객체를 JSON 형식으로 변환.**
//   Map<String, dynamic> toJson() => {
//         'data_filename': dataFilename,
//         'data_path': dataPath,
//         'labeling_mode': labelingMode.toString().split('.').last,
//         'label_data': labelData.toJson(),
//       };

//   /// **JSON 데이터를 기반으로 LabelEntry 객체를 생성하는 팩토리 메서드.**
//   factory LabelEntry.fromJson(Map<String, dynamic> json) {
//     LabelingMode mode = LabelingMode.values.firstWhere(
//       (e) => e.toString().split('.').last == json['labeling_mode'],
//       orElse: () => LabelingMode.singleClassification,
//     );

//     return LabelEntry(
//       dataFilename: json['data_filename'] ?? 'unknown.json',
//       dataPath: json['data_path'] ?? 'unknown_path',
//       labelingMode: mode,
//       labelData: _createLabelData(mode, json['label_data']),
//     );
//   }

//   /// ✅ copyWith() 추가
//   LabelEntry<T> copyWith({T? labelData}) {
//     return LabelEntry<T>(dataFilename: dataFilename, dataPath: dataPath, labelingMode: labelingMode, labelData: labelData ?? this.labelData);
//   }
// }
