import 'package:flutter/material.dart';

enum SegmentationMode { pixelMask, boundingBox }

class GridPainterWidget extends StatefulWidget {
  final SegmentationMode mode;
  final int gridSize;
  final Function(List<List<int>> labeledData) onLabelUpdated;

  const GridPainterWidget({
    required this.mode,
    required this.gridSize,
    required this.onLabelUpdated,
    Key? key,
  }) : super(key: key);

  @override
  SegmentationLabelingWidgetState createState() => SegmentationLabelingWidgetState();
}

class SegmentationLabelingWidgetState extends State<GridPainterWidget> {
  late List<List<int>> labelGrid;
  int selectedLabel = 1;
  Offset? startDrag;
  Offset? currentPointerPosition;
  double brushSize = 1.0; // ✅ 브러시 크기 추가

  @override
  void initState() {
    super.initState();
    labelGrid = List.generate(widget.gridSize, (_) => List.filled(widget.gridSize, 0));
  }

  void _updateLabel(int x, int y) {
    if (widget.mode == SegmentationMode.pixelMask) {
      setState(() {
        for (int i = -brushSize ~/ 2; i <= brushSize ~/ 2; i++) {
          for (int j = -brushSize ~/ 2; j <= brushSize ~/ 2; j++) {
            int newX = x + j;
            int newY = y + i;
            if (newX >= 0 && newX < widget.gridSize && newY >= 0 && newY < widget.gridSize) {
              labelGrid[newY][newX] = selectedLabel;
            }
          }
        }
      });
    }
    widget.onLabelUpdated(labelGrid);
  }

  void _startBoxSelection(Offset position) {
    if (widget.mode == SegmentationMode.boundingBox) {
      setState(() {
        startDrag = position;
      });
    }
  }

  void _updateBoxSelection(Offset position) {
    if (startDrag == null) return;
    setState(() {
      currentPointerPosition = position;
    });
  }

  void _endBoxSelection() {
    if (startDrag == null || currentPointerPosition == null) return;

    int x1 = (startDrag!.dx / (500 / widget.gridSize)).floor();
    int y1 = (startDrag!.dy / (500 / widget.gridSize)).floor();
    int x2 = (currentPointerPosition!.dx / (500 / widget.gridSize)).floor();
    int y2 = (currentPointerPosition!.dy / (500 / widget.gridSize)).floor();

    for (int i = y1; i <= y2; i++) {
      for (int j = x1; j <= x2; j++) {
        if (i >= 0 && i < widget.gridSize && j >= 0 && j < widget.gridSize) {
          labelGrid[i][j] = selectedLabel;
        }
      }
    }

    widget.onLabelUpdated(labelGrid);

    setState(() {
      startDrag = null;
      currentPointerPosition = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // ✅ 브러시 크기 조절 Slider 추가
        if (widget.mode == SegmentationMode.pixelMask)
          Slider(
            value: brushSize,
            min: 1,
            max: 5,
            divisions: 4,
            label: "${brushSize.toInt()} px",
            onChanged: (value) {
              setState(() {
                brushSize = value;
              });
            },
          ),

        GestureDetector(
          onPanUpdate: (details) {
            double dx = details.localPosition.dx;
            double dy = details.localPosition.dy;
            int x = (dx / (500 / widget.gridSize)).floor();
            int y = (dy / (500 / widget.gridSize)).floor();

            if (widget.mode == SegmentationMode.pixelMask) {
              _updateLabel(x, y);
            } else {
              _updateBoxSelection(details.localPosition);
            }
          },
          onPanStart: (details) => _startBoxSelection(details.localPosition),
          onPanEnd: (_) => _endBoxSelection(),
          child: CustomPaint(
            painter: GridPainter(labelGrid, widget.gridSize, startDrag, currentPointerPosition),
            size: const Size(500, 500),
          ),
        ),
      ],
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
      double x1 = startDrag!.dx;
      double y1 = startDrag!.dy;
      double x2 = currentPointerPosition!.dx;
      double y2 = currentPointerPosition!.dy;
      canvas.drawRect(Rect.fromPoints(Offset(x1, y1), Offset(x2, y2)), boundingBoxPaint);
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}
