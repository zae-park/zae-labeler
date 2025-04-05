// 📁 views/widgets/grid_painter.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../view_models/sub_view_models/segmentation_labeling_view_model.dart';

enum SegmentationMode { pixelMask }

class GridPainterWidget extends StatefulWidget {
  final SegmentationMode mode;
  final void Function(List<List<int>> labeledData) onLabelUpdated;

  const GridPainterWidget({
    Key? key,
    required this.mode,
    required this.onLabelUpdated,
  }) : super(key: key);

  @override
  State<GridPainterWidget> createState() => _GridPainterWidgetState();
}

class _GridPainterWidgetState extends State<GridPainterWidget> {
  bool _isDragging = false;

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<SegmentationLabelingViewModel>();
    final gridSize = viewModel.gridSize;
    final labelGrid = viewModel.labelGrid;

    return LayoutBuilder(
      builder: (context, constraints) {
        final cellSize = constraints.maxWidth / gridSize;

        return Listener(
          behavior: HitTestBehavior.opaque, // <- 이게 중요!
          onPointerDown: (event) {
            setState(() => _isDragging = true);
            _paintAt(event.localPosition, cellSize, viewModel);
          },
          onPointerMove: (event) {
            if (_isDragging) {
              _paintAt(event.localPosition, cellSize, viewModel);
            }
          },
          onPointerUp: (_) => setState(() => _isDragging = false),
          onPointerCancel: (_) => setState(() => _isDragging = false),

          child: CustomPaint(
            size: Size.square(constraints.maxWidth),
            painter: _GridPainter(labelGrid: labelGrid, cellSize: cellSize),
          ),
        );
      },
    );
  }

  void _paintAt(Offset position, double cellSize, SegmentationLabelingViewModel viewModel) {
    final x = (position.dx / cellSize).floor();
    final y = (position.dy / cellSize).floor();

    if (x >= 0 && y >= 0 && x < viewModel.gridSize && y < viewModel.gridSize) {
      final classLabel = viewModel.selectedClass;
      if (classLabel != null) {
        viewModel.updateSegmentationLabel(x, y, 1); // 1 = selected (binary mask)
        viewModel.addPixel(x, y);
      }
    }
  }
}

class _GridPainter extends CustomPainter {
  final List<List<int>> labelGrid;
  final double cellSize;

  _GridPainter({required this.labelGrid, required this.cellSize});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.fill
      ..color = Colors.red.withOpacity(0.7);

    for (int y = 0; y < labelGrid.length; y++) {
      for (int x = 0; x < labelGrid[y].length; x++) {
        if (labelGrid[y][x] == 1) {
          final rect = Rect.fromLTWH(x * cellSize, y * cellSize, cellSize, cellSize);
          canvas.drawRect(rect, paint);
        }
      }
    }

    final borderPaint = Paint()
      ..style = PaintingStyle.stroke
      ..color = Colors.grey.withOpacity(0.3)
      ..strokeWidth = 0.5;

    for (int i = 0; i <= labelGrid.length; i++) {
      canvas.drawLine(Offset(0, i * cellSize), Offset(size.width, i * cellSize), borderPaint);
      canvas.drawLine(Offset(i * cellSize, 0), Offset(i * cellSize, size.height), borderPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

/// ✅ 좌표를 표현하는 간단한 구조체
class Point {
  final int dx;
  final int dy;

  const Point(this.dx, this.dy);
}


// import 'package:flutter/material.dart';
// import 'package:provider/provider.dart';
// import '../../view_models/labeling_view_model.dart';

// enum SegmentationMode { pixelMask, boundingBox }

// class GridPainterWidget extends StatelessWidget {
//   final SegmentationMode mode;
//   final Function(List<List<int>> labeledData) onLabelUpdated;

//   const GridPainterWidget({
//     required this.mode,
//     required this.onLabelUpdated,
//     Key? key,
//   }) : super(key: key);

//   @override
//   Widget build(BuildContext context) {
//     return Consumer<SegmentationLabelingViewModel>(
//       builder: (context, labelingVM, child) {
//         return GestureDetector(
//           onPanUpdate: (details) {
//             int gridSize = labelingVM.gridSize;
//             double dx = details.localPosition.dx;
//             double dy = details.localPosition.dy;
//             int x = (dx / (500 / gridSize)).floor();
//             int y = (dy / (500 / gridSize)).floor();

//             if (mode == SegmentationMode.pixelMask) {
//               labelingVM.updateSegmentationLabel(x, y, 1);
//               onLabelUpdated(labelingVM.labelGrid);
//             }
//           },
//           onPanStart: (details) => labelingVM.startBoxSelection(details.localPosition),
//           onPanEnd: (_) => labelingVM.endBoxSelection(),
//           child: CustomPaint(
//             painter: GridPainter(
//               labelingVM.labelGrid,
//               labelingVM.gridSize,
//               labelingVM.startDrag,
//               labelingVM.currentPointerPosition,
//             ),
//             size: const Size(500, 500),
//           ),
//         );
//       },
//     );
//   }
// }

// class GridPainter extends CustomPainter {
//   final List<List<int>> labelGrid;
//   final int gridSize;
//   final Offset? startDrag;
//   final Offset? currentPointerPosition;

//   GridPainter(this.labelGrid, this.gridSize, this.startDrag, this.currentPointerPosition);

//   @override
//   void paint(Canvas canvas, Size size) {
//     double cellSize = size.width / gridSize;
//     Paint gridPaint = Paint()..color = Colors.grey.withOpacity(0.5);
//     Paint labelPaint = Paint()..color = Colors.blue.withOpacity(0.5);
//     Paint boundingBoxPaint = Paint()
//       ..color = Colors.red
//       ..style = PaintingStyle.stroke
//       ..strokeWidth = 2;

//     for (int y = 0; y < gridSize; y++) {
//       for (int x = 0; x < gridSize; x++) {
//         if (labelGrid[y][x] != 0) {
//           canvas.drawRect(
//             Rect.fromLTWH(x * cellSize, y * cellSize, cellSize, cellSize),
//             labelPaint,
//           );
//         }
//         canvas.drawRect(
//           Rect.fromLTWH(x * cellSize, y * cellSize, cellSize, cellSize),
//           gridPaint,
//         );
//       }
//     }

//     if (startDrag != null && currentPointerPosition != null) {
//       canvas.drawRect(
//         Rect.fromPoints(startDrag!, currentPointerPosition!),
//         boundingBoxPaint,
//       );
//     }
//   }

//   @override
//   bool shouldRepaint(CustomPainter oldDelegate) => true;
// }
