// lib/src/platform_helpers/storage/switchable_storage_helper.dart
import 'package:flutter/foundation.dart';
import 'package:zae_labeler/src/core/models/data/data_info.dart';
import 'package:zae_labeler/src/core/models/label/label_model.dart';
import 'package:zae_labeler/src/core/models/project/project_model.dart';
import 'package:zae_labeler/src/platform_helpers/storage/storage_policies.dart';
import 'interface_storage_helper.dart';
import 'storage_helper_factory.dart'; // createLocalStorageHelper()
import 'cloud_storage_helper.dart'; // CloudStorageHelper

class SwitchableStorageHelper with ChangeNotifier implements StorageHelperInterface {
  final StorageHelperInterface _local;
  final StorageHelperInterface _cloud;
  StorageMode _mode;
  ReadPolicy readPolicy;
  WritePolicy writePolicy;

  SwitchableStorageHelper(StorageHelperInterface initial)
    : _local = createLocalStorageHelper(),
      _cloud = CloudStorageHelper(),
      _mode = (initial is CloudStorageHelper) ? StorageMode.cloud : StorageMode.local,
      readPolicy = ReadPolicy.auto,
      writePolicy = (initial is CloudStorageHelper) ? WritePolicy.cloudOnly : WritePolicy.localOnly;

  SwitchableStorageHelper.explicit({
    required StorageHelperInterface local,
    required StorageHelperInterface cloud,
    StorageMode initialMode = StorageMode.local,
    this.readPolicy = ReadPolicy.auto,
    this.writePolicy = WritePolicy.localOnly,
  }) : _local = local,
       _cloud = cloud,
       _mode = initialMode;

  StorageMode get currentMode => _mode;
  StorageHelperInterface get _delegate => _mode == StorageMode.local ? _local : _cloud;

  Future<void> switchToLocal() async {
    _mode = StorageMode.local;
    writePolicy = WritePolicy.localOnly;
    debugPrint('[Switchable] -> local');
    notifyListeners();
  }

  Future<void> switchToCloud() async {
    _mode = StorageMode.cloud;
    writePolicy = WritePolicy.cloudOnly;
    debugPrint('[Switchable] -> cloud');
    notifyListeners();
  }

  /// ✅ 단발성 "클라우드 읽기"가 필요할 때(예: 진행률 프리로드)
  Future<T> withCloud<T>(Future<T> Function(StorageHelperInterface cloud) task) {
    return task(_cloud);
  }

  // =========================
  // 아래부터 인터페이스 메서드 라우팅
  // * 읽기: readPolicy 고려 (필요 메서드만)
  // * 쓰기: writePolicy 고려
  // * 나머지는 현 delegate로 위임(완전 호환)
  // =========================

  @override
  Future<void> saveAllLabels(String projectId, List<LabelModel> models) {
    if (writePolicy == WritePolicy.localOnly) {
      return _local.saveAllLabels(projectId, models);
    }
    return _cloud.saveAllLabels(projectId, models);
  }

  @override
  Future<void> saveLabelData(String projectId, String dataId, String dataPath, LabelModel labelModel) {
    if (writePolicy == WritePolicy.localOnly) {
      return _local.saveLabelData(projectId, dataId, dataPath, labelModel);
    }
    return _cloud.saveLabelData(projectId, dataId, dataPath, labelModel);
  }

  @override
  Future<LabelModel> loadLabelData(String projectId, String dataId, String dataPath, LabelingMode mode) async {
    switch (readPolicy) {
      case ReadPolicy.cloudFirst:
        try {
          final m = await _cloud.loadLabelData(projectId, dataId, dataPath, mode);
          // (선택) 로컬 캐시 보강이 필요하면 여기서 _local.saveLabelData(...) 호출
          return m;
        } catch (_) {
          return _local.loadLabelData(projectId, dataId, dataPath, mode);
        }
      case ReadPolicy.localFirst:
        try {
          return await _local.loadLabelData(projectId, dataId, dataPath, mode);
        } catch (_) {
          return _cloud.loadLabelData(projectId, dataId, dataPath, mode);
        }
      case ReadPolicy.auto:
        // 프리로드/요약은 보통 클라우드가 최신 → auto를 cloudFirst로 해석
        try {
          final m = await _cloud.loadLabelData(projectId, dataId, dataPath, mode);
          return m;
        } catch (_) {
          return _local.loadLabelData(projectId, dataId, dataPath, mode);
        }
    }
  }

  @override
  Future<String> exportAllLabels(Project project, List<LabelModel> labels, List<DataInfo> dataInfos) {
    // 쓰기는 정책에 따름
    if (writePolicy == WritePolicy.localOnly) {
      return _local.exportAllLabels(project, labels, dataInfos);
    }
    return _cloud.exportAllLabels(project, labels, dataInfos);
  }

  // 데이터 바이트 읽기(에셋): 기본은 로컬 우선이 UX에 유리
  @override
  Future<Uint8List> readDataBytes(DataInfo info) async {
    switch (readPolicy) {
      case ReadPolicy.localFirst:
        try {
          return await _local.readDataBytes(info);
        } catch (_) {
          return _cloud.readDataBytes(info);
        }
      case ReadPolicy.cloudFirst:
        try {
          return await _cloud.readDataBytes(info);
        } catch (_) {
          return _local.readDataBytes(info);
        }
      case ReadPolicy.auto:
        // 이미지/미리보기는 보통 로컬 캐시가 더 빠름
        try {
          return await _local.readDataBytes(info);
        } catch (_) {
          return _cloud.readDataBytes(info);
        }
    }
  }

  // 업로드 류는 쓰기 정책 적용
  @override
  Future<String> uploadText(String objectKey, String text, {String? contentType}) {
    return (writePolicy == WritePolicy.localOnly)
        ? _local.uploadText(objectKey, text, contentType: contentType)
        : _cloud.uploadText(objectKey, text, contentType: contentType);
  }

  @override
  Future<String> uploadBase64(String objectKey, String rawBase64, {String? contentType}) {
    return (writePolicy == WritePolicy.localOnly)
        ? _local.uploadBase64(objectKey, rawBase64, contentType: contentType)
        : _cloud.uploadBase64(objectKey, rawBase64, contentType: contentType);
  }

  @override
  Future<String> uploadBytes(String objectKey, Uint8List bytes, {String? contentType}) {
    return (writePolicy == WritePolicy.localOnly)
        ? _local.uploadBytes(objectKey, bytes, contentType: contentType)
        : _cloud.uploadBytes(objectKey, bytes, contentType: contentType);
  }

  // 그 외 메서드들은 현재 모드(delegate)에 그대로 위임 (완전 호환)
  @override
  Future<void> saveProjectConfig(List<Project> projects) => _delegate.saveProjectConfig(projects);
  @override
  Future<List<Project>> loadProjectFromConfig(String projectConfig) => _delegate.loadProjectFromConfig(projectConfig);
  @override
  Future<String> downloadProjectConfig(Project project) => _delegate.downloadProjectConfig(project);
  @override
  Future<void> saveProjectList(List<Project> projects) => _delegate.saveProjectList(projects);
  @override
  Future<List<Project>> loadProjectList() => _delegate.loadProjectList();
  @override
  Future<void> deleteProject(String projectId) => _delegate.deleteProject(projectId);
  @override
  Future<void> deleteProjectLabels(String projectId) => _delegate.deleteProjectLabels(projectId);

  // (필요 시 ensureLocalObjectUrl/revokeLocalObjectUrl 등도 정책 해석해 위임)
  @override
  Future<String?> ensureLocalObjectUrl(DataInfo info) => _delegate.ensureLocalObjectUrl(info);
  @override
  Future<void> revokeLocalObjectUrl(String objectUrl) => _delegate.revokeLocalObjectUrl(objectUrl);

  // 프로젝트 경로 업로드(키 prefix 포함)도 동일 패턴으로…
  @override
  Future<String> uploadProjectText(String projectId, String objectKey, String text, {String? contentType}) => (writePolicy == WritePolicy.localOnly)
      ? _local.uploadProjectText(projectId, objectKey, text, contentType: contentType)
      : _cloud.uploadProjectText(projectId, objectKey, text, contentType: contentType);

  @override
  Future<String> uploadProjectBase64(String projectId, String objectKey, String rawBase64, {String? contentType}) => (writePolicy == WritePolicy.localOnly)
      ? _local.uploadProjectBase64(projectId, objectKey, rawBase64, contentType: contentType)
      : _cloud.uploadProjectBase64(projectId, objectKey, rawBase64, contentType: contentType);

  @override
  Future<String> uploadProjectBytes(String projectId, String objectKey, Uint8List bytes, {String? contentType}) => (writePolicy == WritePolicy.localOnly)
      ? _local.uploadProjectBytes(projectId, objectKey, bytes, contentType: contentType)
      : _cloud.uploadProjectBytes(projectId, objectKey, bytes, contentType: contentType);

  @override
  Future<void> clearAllCache() => _delegate.clearAllCache();

  @override
  Future<List<LabelModel>> importAllLabels() => _delegate.importAllLabels();

  @override
  Future<List<LabelModel>> loadAllLabelModels(String projectId) => _delegate.loadAllLabelModels(projectId);

  // 필요시 더 많은 메서드를 정책 기반으로 정교하게 분기
}
