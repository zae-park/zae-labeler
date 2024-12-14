// lib/src/view_models/labeling_view_model.dart
import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/data_model.dart';

class FileDataViewModel extends ChangeNotifier {
  final List<FileData> _fileDataList = []; // 선택된 파일 데이터 목록

  List<FileData> get fileDataList => List.unmodifiable(_fileDataList);

  void addFileData(FileData fileData) {
    _fileDataList.add(fileData);
    notifyListeners();
  }

  void clearFileData() {
    _fileDataList.clear();
    notifyListeners();
  }

  Future<void> _pickFiles(BuildContext context) async {
  FilePickerResult? result = await FilePicker.platform.pickFiles(
    allowMultiple: true,
    withData: true, // 파일 데이터를 가져옵니다.
  );

  if (result != null) {
    final fileDataVM = Provider.of<FileDataViewModel>(context, listen: false);

    for (var file in result.files) {
      final fileData = FileData(
        name: file.name,
        type: file.extension ?? 'unknown',
        content: base64Encode(file.bytes ?? []), // 파일 내용을 base64로 저장
      );
      fileDataVM.addFileData(fileData); // ViewModel에 추가
    }
  }
}


}
