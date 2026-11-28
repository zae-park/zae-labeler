@TestOn('browser')
library;

// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use
import 'dart:convert';
import 'dart:html' as html;

import 'package:flutter_test/flutter_test.dart';

import 'package:zae_labeler/src/core/models/label/label_model.dart';
import 'package:zae_labeler/src/platform_helpers/storage/web_storage_helper.dart';

/// 예전 앱 버전이 쓰던 포맷 그대로: 프로젝트당 배열 1개.
void _seedLegacy(String projectId, List<LabelModel> labels) {
  html.window.localStorage['zae_labeler:labels:$projectId'] = jsonEncode([
    for (final m in labels)
      {
        'data_id': m.dataId,
        'data_path': m.dataPath,
        'mode': m.mode.name,
        'labeled_at': m.labeledAt.toIso8601String(),
        'label_data': LabelModelConverter.toJson(m),
      },
  ]);
}

Iterable<String> _keys(String prefix) => html.window.localStorage.keys.where((k) => k.startsWith(prefix));

void main() {
  setUp(() {
    for (final k in _keys('zae_labeler:labels').toList()) {
      html.window.localStorage.remove(k);
    }
  });

  test('예전 포맷 라벨이 첫 접근 시 그대로 읽히고 항목별 키로 옮겨진다', () async {
    final t = DateTime(2025, 1, 1);
    _seedLegacy('p1', [
      SingleClassificationLabelModel(dataId: 'a', label: 'cat', labeledAt: t),
      SingleClassificationLabelModel(dataId: 'b', label: 'dog', labeledAt: t),
    ]);

    final helper = StorageHelperImpl();
    final labels = await helper.loadAllLabelModels('p1');

    expect({for (final l in labels) l.dataId: l.label}, {'a': 'cat', 'b': 'dog'});
    expect(html.window.localStorage['zae_labeler:labels:p1'], isNull);
    expect(_keys('zae_labeler:labels:v2:p1:'), hasLength(2));
  });

  test('세그멘테이션·교차 라벨도 손실 없이 옮겨진다', () async {
    final t = DateTime(2025, 1, 1);
    _seedLegacy('seg', [
      MultiClassSegmentationLabelModel(
        dataId: 'img',
        labeledAt: t,
        label: const SegmentationData(
          segments: {
            'road': Segment(indices: {(0, 0), (1, 0)}, classLabel: 'road'),
          },
        ),
      ),
    ]);
    _seedLegacy('cross', [
      CrossClassificationLabelModel(
        dataId: 'a_b',
        labeledAt: t,
        label: const CrossDataPair(sourceId: 'a', targetId: 'b', relation: 'same'),
      ),
    ]);

    final helper = StorageHelperImpl();
    final seg = await helper.loadLabelData('seg', 'img', '', LabelingMode.multiClassSegmentation);
    final cross = await helper.loadLabelData('cross', 'a_b', '', LabelingMode.crossClassification);

    expect((seg.label as SegmentationData).segments['road']!.indices, {(0, 0), (1, 0)});
    expect((cross.label as CrossDataPair).relation, 'same');
  });

  test('마이그레이션 후 저장·교체·삭제가 새 포맷으로 동작한다', () async {
    final t = DateTime(2025, 1, 1);
    _seedLegacy('p2', [SingleClassificationLabelModel(dataId: 'a', label: 'cat', labeledAt: t)]);
    final helper = StorageHelperImpl();

    await helper.saveLabelData('p2', 'b', '', SingleClassificationLabelModel(dataId: 'b', label: 'dog', labeledAt: t));
    expect((await helper.loadAllLabelModels('p2')).map((l) => l.dataId).toSet(), {'a', 'b'});
    expect(html.window.localStorage['zae_labeler:labels:p2'], isNull);

    await helper.saveAllLabels('p2', [SingleClassificationLabelModel(dataId: 'c', label: 'cat', labeledAt: t)]);
    expect((await helper.loadAllLabelModels('p2')).map((l) => l.dataId), ['c']);

    await helper.deleteProjectLabels('p2');
    expect(await helper.loadAllLabelModels('p2'), isEmpty);
    expect(_keys('zae_labeler:labels:v2:p2:'), isEmpty);
  });
}
