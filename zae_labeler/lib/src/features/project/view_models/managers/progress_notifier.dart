// lib/src/features/project/view_models/progress_notifier.dart
import 'package:flutter/material.dart';

class ProgressNotifier extends ChangeNotifier {
  final Map<String, double> _progressMap = {};

  double? getProgress(String projectId) => _progressMap[projectId];

  void updateProgress(String projectId, double ratio) {
    _progressMap[projectId] = ratio;
    notifyListeners();
  }

  void clear() {
    _progressMap.clear();
    notifyListeners();
  }
}
