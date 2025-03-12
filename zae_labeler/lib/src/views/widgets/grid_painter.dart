import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../view_models/labeling_view_model.dart';

enum SegmentationMode { pixelMask, boundingBox }

class GridPainterWidget extends StatelessWidget {
  final SegmentationMode mode;
  final Function(List<List<int>> labeledData) onLabelUpdated;

  const GridPainterWidget({
    required this.mode,
    required this.onLabelUpdated,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<SegmentationLabelingViewModel>(
      builder: (context, labelingVM, child) {
        return GestureDetector(
          onPanUpdate: (details) {
            int gridSize = labelingVM.gridSize;
            double dx = details.localPosition.dx;
            double dy = details.localPosition.dy;
            int x = (dx / (500 / gridSize)).floor();
            int y = (dy / (500 / gridSize)).floor();

            if (mode == SegmentationMode.pixelMask) {
              labelingVM.updateSegmentationLabel(x, y);
            } else {
              labelingVM.updateBoxSelection(details.localPosition);
            }
          },
          onPanStart: (details) => labelingVM.startBoxSelection(details.localPosition),
          onPanEnd: (_) => labelingVM.endBoxSelection(),
          child: CustomPaint(
            painter: GridPainter(
              labelingVM.labelGrid,
              labelingVM.gridSize,
              labelingVM.startDrag,
              labelingVM.currentPointerPosition,
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
    double cellSize = size.width / gridSize;
    Paint gridPaint = Paint()..color = Colors.grey.withOpacity(0.5);
    Paint labelPaint = Paint()..color = Colors.blue.withOpacity(0.5);
    Paint boundingBoxPaint = Paint()
      ..color = Colors.red
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    for (int y = 0; y < gridSize; y++) {
      for (int x = 0; x < gridSize; x++) {
        if (labelGrid[y][x] != 0) {
          canvas.drawRect(
            Rect.fromLTWH(x * cellSize, y * cellSize, cellSize, cellSize),
            labelPaint,
          );
        }
        canvas.drawRect(
          Rect.fromLTWH(x * cellSize, y * cellSize, cellSize, cellSize),
          gridPaint,
        );
      }
    }

    if (startDrag != null && currentPointerPosition != null) {
      canvas.drawRect(
        Rect.fromPoints(startDrag!, currentPointerPosition!),
        boundingBoxPaint,
      );
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}
