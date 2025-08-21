// 📁 lib/src/views/widgets/segmentation/grid_painter.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:zae_labeler/src/features/label/view_models/sub_view_models/segmentation_labeling_view_model.dart';

enum SegmentationMode { pixelMask, boundingBox }

class GridPainterWidget extends StatelessWidget {
  final SegmentationMode mode;
  final void Function(List<List<int>> labeledData)? onLabelUpdated; // 옵셔널

  const GridPainterWidget({
    super.key,
    required this.mode,
    this.onLabelUpdated,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<SegmentationLabelingViewModel>(
      builder: (context, vm, _) {
        return GestureDetector(
          onPanUpdate: (details) {
            final gridSize = vm.gridSize;
            final dx = details.localPosition.dx;
            final dy = details.localPosition.dy;
            final x = (dx / (500 / gridSize)).floor();
            final y = (dy / (500 / gridSize)).floor();

            if (mode == SegmentationMode.pixelMask) {
              vm.updateSegmentationLabel(x, y, 1); // UI 그리드 상태 업데이트
              onLabelUpdated?.call(vm.labelGrid); // 필요시 콜백
            }
            // boundingBox 모드는 드래그 박스로 UI만 표시 (저장은 별도 로직)
          },
          onPanStart: (details) => vm.startBoxSelection(details.localPosition),
          onPanEnd: (_) => vm.endBoxSelection(),
          child: CustomPaint(
            painter: GridPainter(
              vm.labelGrid,
              vm.gridSize,
              vm.startDrag,
              vm.currentPointerPosition,
            ),
            size: const Size(500, 500),
          ),
        );
      },
    );
  }
}

class GridPainter extends CustomPainter {
  final List<List<int>> labelGrid;
  final int gridSize;
  final Offset? startDrag;
  final Offset? currentPointerPosition;

  GridPainter(this.labelGrid, this.gridSize, this.startDrag, this.currentPointerPosition);

  @override
  void paint(Canvas canvas, Size size) {
    final cellSize = size.width / gridSize;
    final gridPaint = Paint()..color = Colors.grey.withOpacity(0.5);
    final labelPaint = Paint()..color = Colors.blue.withOpacity(0.5);
    final boxPaint = Paint()
      ..color = Colors.red
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    for (int y = 0; y < gridSize; y++) {
      for (int x = 0; x < gridSize; x++) {
        if (labelGrid[y][x] != 0) {
          canvas.drawRect(Rect.fromLTWH(x * cellSize, y * cellSize, cellSize, cellSize), labelPaint);
        }
        canvas.drawRect(Rect.fromLTWH(x * cellSize, y * cellSize, cellSize, cellSize), gridPaint);
      }
    }

    if (startDrag != null && currentPointerPosition != null) {
      canvas.drawRect(Rect.fromPoints(startDrag!, currentPointerPosition!), boxPaint);
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}
