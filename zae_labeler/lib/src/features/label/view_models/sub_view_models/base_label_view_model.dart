// 📁 sub_view_models/base_label_view_model.dart
import 'package:flutter/foundation.dart';
import '../../models/label_model.dart' show LabelModel, LabelingMode;
import '../../use_cases/label_use_cases.dart'; // 파사드
import '../../logic/label_input_mapper.dart';

/// Base VM for labeling.
/// - Repo 직접 접근 금지: LabelUseCases 파사드만 사용
abstract class LabelViewModel extends ChangeNotifier {
  final String projectId;
  final LabelUseCases labelUseCases;

  String dataId;
  String dataFilename;
  String dataPath;
  LabelingMode mode;
  LabelModel labelModel;
  LabelInputMapper labelInputMapper;

  LabelViewModel({
    required this.projectId,
    required this.dataId,
    required this.dataFilename,
    required this.dataPath,
    required this.mode,
    required this.labelModel,
    required this.labelUseCases,
    required this.labelInputMapper,
  });

  /// 저장소에서 라벨을 로드(없으면 생성)
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

  /// 라벨 객체 교체 + 저장
  Future<void> updateLabel(LabelModel newModel) async {
    labelModel = newModel;
    await saveLabel();
    notifyListeners();
  }

  /// UI 입력 → LabelModel 매핑 → 저장
  Future<void> updateLabelFromInput(dynamic labelData) async {
    final newModel = labelInputMapper.map(labelData, dataId: dataId, dataPath: dataPath);
    await updateLabel(newModel);
  }

  // 하위 VM에서만 의미가 있는 기능은 abstract로 유지
  bool isLabelSelected(String labelItem) => throw UnimplementedError("Only for classification");
  Future<void> toggleLabel(String labelItem) => throw UnimplementedError("Only for classification");
  Future<void> addPixel(int x, int y, String classLabel) => throw UnimplementedError("Only for segmentation");
  Future<void> removePixel(int x, int y) => throw UnimplementedError("Only for segmentation");
}
