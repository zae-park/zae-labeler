// lib/src/view_models/labeling_view_model.dart
import 'package:flutter/material.dart';
import '../models/label_model.dart';
import '../models/project_model.dart';
import '../utils/storage_helper.dart';
import 'dart:io';
import 'package:path/path.dart' as path;
import 'package:share_plus/share_plus.dart';
import 'package:archive/archive.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:convert'; // jsonEncode를 사용하기 위해 추가
import 'package:flutter/services.dart'; // RawKeyDownEvent 및 LogicalKeyboardKey 사용을 위해 추가

class LabelingViewModel extends ChangeNotifier {
  final Project project;
  List<Label> _labels = [];
  int _currentIndex = 0;
  List<File> _dataFiles = []; // 데이터 파일 목록
  List<double> _currentData = []; // 시계열 데이터
  bool _isDownloading = false;

  LabelingViewModel({required this.project}) {
    // 초기화 시 라벨 로드 및 데이터 로드
    loadLabels();
    loadDataFiles();
  }

  List<Label> get labels => _labels;
  int get currentIndex => _currentIndex;
  List<File> get dataFiles => _dataFiles;
  List<double> get currentData => _currentData;
  String get currentFileName => _dataFiles.isNotEmpty
      ? path.basename(_dataFiles[_currentIndex].path)
      : '';
  String get currentLabel {
    if (_currentIndex < 0 || _currentIndex >= _dataFiles.length) {
      return '';
    }

    final dataId = _dataFiles[_currentIndex].path;
    final label = _labels.firstWhere((labelItem) => labelItem.dataId == dataId,
        orElse: () => Label(dataId: dataId, labels: []));

    return label.labels.join(', ');
  }

  // 라벨 로드
  Future<void> loadLabels() async {
    _labels = await StorageHelper.loadLabels();
    notifyListeners();
  }

  // 데이터 파일 로드 (특정 포맷만 필터링, 예: .csv)
  void loadDataFiles() {
    final directory = Directory(project.dataDirectory);
    if (directory.existsSync()) {
      _dataFiles = directory
          .listSync()
          .where((file) => file is File && path.extension(file.path) == '.csv')
          .cast<File>()
          .toList();
      if (_dataFiles.isNotEmpty) {
        loadCurrentData();
      }
    }
    notifyListeners();
  }

  // 현재 데이터 파일 로드 (예시로 CSV 파일의 첫 번째 열을 시계열 데이터로 사용)
  void loadCurrentData() {
    if (_currentIndex >= 0 && _currentIndex < _dataFiles.length) {
      final file = _dataFiles[_currentIndex];
      final lines = file.readAsLinesSync();
      _currentData = lines.map((line) {
        final parts = line.split(',');
        return double.tryParse(parts[0]) ?? 0.0;
      }).toList();
    }
    notifyListeners();
  }

  // 라벨 추가 또는 수정
  void addOrUpdateLabel(int dataIndex, String label) {
    if (dataIndex < 0 || dataIndex >= _dataFiles.length) return;
    final dataId = _dataFiles[dataIndex].path;

    final existingLabelIndex =
        _labels.indexWhere((labelItem) => labelItem.dataId == dataId);

    if (existingLabelIndex != -1) {
      // 이미 존재하는 라벨 업데이트
      _labels[existingLabelIndex].labels = [label];
    } else {
      // 새로운 라벨 추가
      _labels.add(Label(dataId: dataId, labels: [label]));
    }

    StorageHelper.saveLabels(_labels);
    notifyListeners();
  }

  // 현재 라벨이 선택되었는지 확인
  bool isLabelSelected(String label) {
    return currentLabel.contains(label);
  }

  // 데이터 이동
  void moveNext() {
    if (_currentIndex < _dataFiles.length - 1) {
      _currentIndex++;
      loadCurrentData();
    }
  }

  void movePrevious() {
    if (_currentIndex > 0) {
      _currentIndex--;
      loadCurrentData();
    }
  }

  // 다운로드 기능
  Future<void> downloadLabels(BuildContext context) async {
    if (_isDownloading) return;

    _isDownloading = true;
    notifyListeners();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
        title: Text('다운로드 중'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('라벨링 데이터를 다운로드하고 있습니다...'),
          ],
        ),
      ),
    );

    try {
      final directory = await getExternalStorageDirectory();
      if (directory == null) {
        throw Exception('저장소에 접근할 수 없습니다.');
      }

      final zaeFile = File('${directory.path}/labels.zae');

      final zaeContent = _labels.map((label) => label.toJson()).toList();
      zaeFile.writeAsStringSync(jsonEncode(zaeContent));

      if (!mounted) return;

      Navigator.of(context).pop(); // 다운로드 중 다이얼로그 닫기

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('다운로드 완료: ${zaeFile.path}')),
      );
    } catch (e) {
      if (!mounted) return;

      Navigator.of(context).pop(); // 다운로드 중 다이얼로그 닫기
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('다운로드 실패: $e')),
      );
    } finally {
      _isDownloading = false;
      notifyListeners();
    }
  }

  // .zae 파일만 다운로드
  Future<void> downloadLabelsAsZae(BuildContext context) async {
    if (_isDownloading) return;

    _isDownloading = true;
    notifyListeners();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
        title: Text('다운로드 중'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('라벨링 데이터를 다운로드하고 있습니다...'),
          ],
        ),
      ),
    );

    try {
      final directory = await getApplicationDocumentsDirectory();
      final zaeFile = File('${directory.path}/labels.zae');

      final zaeContent = _labels.map((label) => label.toJson()).toList();
      zaeFile.writeAsStringSync(jsonEncode(zaeContent));

      if (!mounted) return;

      Navigator.of(context).pop(); // 다운로드 중 다이얼로그 닫기

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('다운로드 완료: ${zaeFile.path}')),
      );

      Share.shareXFiles([XFile(zaeFile.path)], text: '라벨링 데이터 .zae 파일입니다.');
    } catch (e) {
      if (!mounted) return;

      Navigator.of(context).pop(); // 다운로드 중 다이얼로그 닫기
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('다운로드 실패: $e')),
      );
    } finally {
      _isDownloading = false;
      notifyListeners();
    }
  }
}
