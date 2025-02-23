import 'package:flutter/material.dart';

enum SegmentationMode { pixelMask, boundingBox }

class GridPainterWidget extends StatefulWidget {
  final SegmentationMode mode;
  final int gridSize; // 그리드 크기 (ex: 32x32)
  final Function(List<List<int>> labeledData) onLabelUpdated; // 라벨 변경 시 콜백

  const GridPainterWidget({
    required this.mode,
    required this.gridSize,
    required this.onLabelUpdated,
    Key? key,
  }) : super(key: key);

  @override
  _SegmentationLabelingWidgetState createState() => _SegmentationLabelingWidgetState();
}

class _SegmentationLabelingWidgetState extends State<GridPainterWidget> {
  late List<List<int>> labelGrid; // 2D 배열 형태의 라벨링 데이터
  int selectedLabel = 1; // 선택된 클래스 ID
  Offset? startDrag; // Box 드래그 시작점
  Offset? currentPointerPosition; // 현재 마우스 위치

  @override
  void initState() {
    super.initState();
    labelGrid = List.generate(widget.gridSize, (_) => List.filled(widget.gridSize, 0)); // 초기화
  }

  void _updateLabel(int x, int y) {
    if (widget.mode == SegmentationMode.pixelMask) {
      setState(() {
        labelGrid[y][x] = selectedLabel;
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
        labelGrid[i][j] = selectedLabel;
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
    return GestureDetector(
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
      child: Container(
        width: 500,
        height: 500,
        decoration: BoxDecoration(border: Border.all(color: Colors.black)),
        child: Stack(
          children: [
            GridView.builder(
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: widget.gridSize,
              ),
              itemCount: widget.gridSize * widget.gridSize,
              itemBuilder: (context, index) {
                int x = index % widget.gridSize;
                int y = index ~/ widget.gridSize;
                return Container(
                  margin: const EdgeInsets.all(1),
                  decoration: BoxDecoration(
                    color: labelGrid[y][x] == 0 ? Colors.white : Colors.blue.withOpacity(0.5),
                    border: Border.all(color: Colors.grey, width: 0.5),
                  ),
                );
              },
            ),
            if (currentPointerPosition != null)
              Positioned(
                left: currentPointerPosition!.dx,
                top: currentPointerPosition!.dy,
                child: Text("(${currentPointerPosition!.dx.toInt()}, ${currentPointerPosition!.dy.toInt()})",
                    style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
              ),
          ],
        ),
      ),
    );
  }
}
