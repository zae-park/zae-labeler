// 📁 sub_view_models/base_label_view_model.dart
import 'package:flutter/foundation.dart';
import 'package:zae_labeler/src/core/models/data/unified_data.dart';
import 'package:zae_labeler/src/core/models/project/project_model.dart';
import '../../models/label_model.dart' show LabelModel, LabelingMode, LabelModelFactory;
import '../../logic/label_input_mapper.dart';
import '../../use_cases/label_use_cases.dart';

abstract class LabelViewModel extends ChangeNotifier {
  // 단일 주입: 프로젝트, 데이터, 라벨 파사드
  final Project project;
  final UnifiedData data;
  final LabelUseCases labelUseCases;

  // 선택 주입: 초기 라벨/입력 매퍼
  late LabelModel labelModel;
  final LabelInputMapper labelInputMapper;

  // 유틸: 자주 쓰는 값은 getter로 제공
  String get projectId => project.id;
  String get dataId => data.dataId;
  String get dataFilename => data.fileName;
  String get dataPath => data.dataInfo.filePath ?? '';
  LabelingMode get mode => project.mode;

  LabelViewModel({required this.project, required this.data, required this.labelUseCases, LabelModel? initialLabel, LabelInputMapper? mapper})
      : labelInputMapper = mapper ?? LabelInputMapper.forMode(project.mode) {
    // 초기 라벨이 있으면 임시로 세팅, 없으면 비어있는 모델을 준비
    labelModel = initialLabel ?? LabelModelFactory.createNew(project.mode, dataId: dataId);
  }

  /// 저장소에서 라벨 로드(없으면 생성해서 반환)
  Future<void> loadLabel() async {
    debugPrint("[BaseLabelVM.loadLabel] BEFORE: ${labelModel.runtimeType}");
    labelModel = await labelUseCases.loadOrCreate(projectId: projectId, dataId: dataId, dataPath: dataPath, mode: mode);
    debugPrint("[BaseLabelVM.loadLabel] AFTER: ${labelModel.runtimeType}");
    notifyListeners();
  }

  /// 현재 라벨 저장
  Future<void> saveLabel() async {
    debugPrint("[BaseLabelVM.saveLabel] labelModel: $labelModel");
    await labelUseCases.save(projectId: projectId, dataId: dataId, dataPath: dataPath, model: labelModel);
  }

  /// 모델 교체 + 저장
  Future<void> updateLabel(LabelModel newModel) async {
    labelModel = newModel;
    await saveLabel();
    notifyListeners();
  }

  /// UI 입력값 → 모델 변환 → 저장
  Future<void> updateLabelFromInput(dynamic labelData) async {
    final newModel = labelInputMapper.map(labelData, dataId: dataId, dataPath: dataPath);
    await updateLabel(newModel);
  }

  // 하위 타입에서만 의미 있는 동작
  bool isLabelSelected(String labelItem) => throw UnimplementedError("Only for classification");
  Future<void> toggleLabel(String labelItem) => throw UnimplementedError("Only for classification");
  Future<void> addPixel(int x, int y, String classLabel) => throw UnimplementedError("Only for segmentation");
  Future<void> removePixel(int x, int y) => throw UnimplementedError("Only for segmentation");
}
