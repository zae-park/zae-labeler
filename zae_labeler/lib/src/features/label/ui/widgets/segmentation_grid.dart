// lib/src/features/label/ui/widgets/segmentation_grid.dart
import 'package:flutter/material.dart';

import '../../view_models/segmentation_labeling_view_model.dart';

/// 클래스 인덱스별 표시 색상 (index 0부터).
const List<Color> segmentationPalette = [
  Colors.red,
  Colors.blue,
  Colors.green,
  Colors.orange,
  Colors.purple,
  Colors.teal,
  Colors.pink,
  Colors.amber,
  Colors.indigo,
  Colors.brown,
];

Color segmentationColorFor(int classIndex) => segmentationPalette[classIndex % segmentationPalette.length];

/// 픽셀 마스크 그리드 오버레이.
/// - 드래그 동안 셀을 stroke에 모으고(즉시 표시), 손을 떼면 VM이 한 번 저장합니다.
class SegmentationGrid extends StatelessWidget {
  final SegmentationLabelingViewModel viewModel;

  const SegmentationGrid({super.key, required this.viewModel});

  @override
  Widget build(BuildContext context) {
    final vm = viewModel;
    return LayoutBuilder(
      builder: (context, constraints) {
        final side = constraints.biggest.shortestSide;
        final cellSize = side / vm.gridSize;

        void paintAt(Offset p) => vm.paintCell((p.dx / cellSize).floor(), (p.dy / cellSize).floor());

        return Center(
          child: SizedBox.square(
            dimension: side,
            child: Listener(
              behavior: HitTestBehavior.opaque,
              onPointerDown: (e) {
                vm.beginStroke();
                paintAt(e.localPosition);
              },
              onPointerMove: (e) => paintAt(e.localPosition),
              onPointerUp: (_) => vm.endStroke(),
              onPointerCancel: (_) => vm.endStroke(),
              child: CustomPaint(
                painter: _GridPainter(
                  labelGrid: vm.labelGrid,
                  pendingStroke: vm.pendingStroke,
                  pendingColor: vm.isErasing ? Colors.white : _selectedColor(vm),
                  cellSize: cellSize,
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Color _selectedColor(SegmentationLabelingViewModel vm) {
    final idx = vm.selectedClass == null ? -1 : vm.project.classes.indexOf(vm.selectedClass!);
    return idx < 0 ? Colors.grey : segmentationColorFor(idx);
  }
}

class _GridPainter extends CustomPainter {
  final List<List<int>> labelGrid;
  final Set<(int, int)> pendingStroke;
  final Color pendingColor;
  final double cellSize;

  _GridPainter({required this.labelGrid, required this.pendingStroke, required this.pendingColor, required this.cellSize});

  @override
  void paint(Canvas canvas, Size size) {
    final fill = Paint()..style = PaintingStyle.fill;

    for (int y = 0; y < labelGrid.length; y++) {
      for (int x = 0; x < labelGrid[y].length; x++) {
        final v = labelGrid[y][x];
        if (v == SegmentationLabelingViewModel.emptyCell) continue;
        final base = v == SegmentationLabelingViewModel.unknownClassCell ? Colors.grey : segmentationColorFor(v - 1);
        fill.color = base.withValues(alpha: 0.6);
        canvas.drawRect(Rect.fromLTWH(x * cellSize, y * cellSize, cellSize, cellSize), fill);
      }
    }

    fill.color = pendingColor.withValues(alpha: 0.8);
    for (final (x, y) in pendingStroke) {
      canvas.drawRect(Rect.fromLTWH(x * cellSize, y * cellSize, cellSize, cellSize), fill);
    }

    final border = Paint()
      ..style = PaintingStyle.stroke
      ..color = Colors.grey.withValues(alpha: 0.3)
      ..strokeWidth = 0.5;
    for (int i = 0; i <= labelGrid.length; i++) {
      canvas.drawLine(Offset(0, i * cellSize), Offset(size.width, i * cellSize), border);
      canvas.drawLine(Offset(i * cellSize, 0), Offset(i * cellSize, size.height), border);
    }
  }

  @override
  bool shouldRepaint(covariant _GridPainter old) =>
      old.labelGrid != labelGrid || old.pendingStroke.length != pendingStroke.length || old.pendingColor != pendingColor || old.cellSize != cellSize;
}
