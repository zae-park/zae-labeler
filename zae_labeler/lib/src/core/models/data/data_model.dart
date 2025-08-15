// lib/src/models/data_model.dart

/*
이 파일은 데이터 모델을 정의하며, 다양한 데이터 유형(시계열, JSON 오브젝트, 이미지 등)을 다루기 위한 클래스들을 포함합니다.
DataInfo: 원본 데이터의 경로/메타데이터
UnifiedData: 실제 파싱된 콘텐츠 및 라벨링 상태
*/

import 'dart:convert';
import 'dart:io';

import 'package:uuid/uuid.dart';

import 'package:zae_labeler/features/label/models/file_type.dart';
import '../../../features/label/models/label_model.dart';

/// ✅ Represents a data path that can be used to load file content (Web or Native)
class DataInfo {
  final String id; // 고유 식별자
  final String fileName; // 파일 이름
  final String? base64Content; // Web용 base64 인코딩 데이터
  final String? filePath; // Native용 파일 경로

  DataInfo({String? id, required this.fileName, this.base64Content, this.filePath}) : id = id ?? const Uuid().v4();

  /// 실제 파일 내용 로드 (Web/Naitve 환경 자동 대응)
  Future<String?> loadData() async {
    if (base64Content != null) {
      if ([".png", ".jpg", ".jpeg"].any((ext) => fileName.endsWith(ext))) {
        return base64Content; // 이미지일 경우 디코딩 없음
      }
      return utf8.decode(base64Decode(base64Content!));
    } else if (filePath != null) {
      final file = File(filePath!);
      if (file.existsSync()) return await file.readAsString();
    }
    return null;
  }

  factory DataInfo.fromJson(Map<String, dynamic> json) => DataInfo(
        id: json['id'],
        fileName: json['fileName'],
        base64Content: json['base64Content'],
        filePath: json['filePath'],
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'fileName': fileName,
        'base64Content': base64Content,
        'filePath': filePath,
      };
}

/// ✅ Unified data object after loading/parsing the content
class UnifiedData {
  final DataInfo dataInfo;
  final FileType fileType;
  final List<double>? seriesData;
  final Map<String, dynamic>? objectData;
  final String? content; // Base64 이미지
  final File? file; // Native 환경에서의 파일 객체
  LabelStatus status;

  String get dataId => dataInfo.id;
  String? get dataPath => file?.path;
  String get fileName => dataInfo.fileName;

  UnifiedData({
    required this.dataInfo,
    required this.fileType,
    this.seriesData,
    this.objectData,
    this.content,
    this.file,
    this.status = LabelStatus.incomplete,
  });

  factory UnifiedData.empty() => UnifiedData(dataInfo: DataInfo(fileName: 'empty'), fileType: FileType.unsupported);

  DataInfo toDataInfo() => DataInfo(id: dataId, fileName: fileName, filePath: file?.path, base64Content: content);

  /// 데이터 파일 내용에 따라 파싱된 UnifiedData 객체 생성
  static Future<UnifiedData> fromDataInfo(DataInfo dataInfo) async {
    final fileName = dataInfo.fileName;

    if (fileName.endsWith('.csv')) {
      final content = await dataInfo.loadData();
      final seriesData = _parseSeriesData(content ?? '');
      return UnifiedData(dataInfo: dataInfo, fileType: FileType.series, seriesData: seriesData);
    } else if (fileName.endsWith('.json')) {
      final content = await dataInfo.loadData();
      final objectData = _parseObjectData(content ?? '');
      return UnifiedData(dataInfo: dataInfo, fileType: FileType.object, objectData: objectData);
    } else if ([".png", ".jpg", ".jpeg"].any((ext) => fileName.endsWith(ext))) {
      final content = await dataInfo.loadData();
      return UnifiedData(
        dataInfo: dataInfo,
        fileType: FileType.image,
        content: content,
        file: dataInfo.filePath != null ? File(dataInfo.filePath!) : null,
      );
    }

    return UnifiedData(dataInfo: dataInfo, fileType: FileType.unsupported);
  }

  static Future<UnifiedData> fromDataId({required List<DataInfo> dataInfos, required String dataId}) async {
    final dataInfo = dataInfos.firstWhere((e) => e.id == dataId, orElse: () => throw Exception("dataId not found: $dataId"));
    return UnifiedData.fromDataInfo(dataInfo);
  }

  UnifiedData copyWith({
    DataInfo? dataInfo,
    FileType? fileType,
    File? file,
    List<double>? seriesData,
    Map<String, dynamic>? objectData,
    String? content,
    LabelStatus? status,
  }) {
    return UnifiedData(
      dataInfo: dataInfo ?? this.dataInfo,
      fileType: fileType ?? this.fileType,
      file: file ?? this.file,
      seriesData: seriesData ?? this.seriesData,
      objectData: objectData ?? this.objectData,
      content: content ?? this.content,
      status: status ?? this.status,
    );
  }

  static List<double> _parseSeriesData(String content) {
    final lines = content.split('\n');
    return lines.expand((line) => line.split(',')).map((v) => double.tryParse(v.trim()) ?? 0.0).toList();
  }

  static Map<String, dynamic> _parseObjectData(String content) {
    try {
      return jsonDecode(content) as Map<String, dynamic>;
    } catch (_) {
      return {};
    }
  }
}
