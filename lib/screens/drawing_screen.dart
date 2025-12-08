import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:uuid/uuid.dart';

class DrawingScreen extends StatefulWidget {
  const DrawingScreen({super.key});

  @override
  State<DrawingScreen> createState() => _DrawingScreenState();
}

class _DrawingScreenState extends State<DrawingScreen> {
  final GlobalKey _canvasKey = GlobalKey();
  final List<DrawingPoint> _points = [];
  final List<List<DrawingPoint>> _undoHistory = [];
  Color _selectedColor = const Color(0xFF2DBD6C);
  double _strokeWidth = 3.0;
  DrawingTool _selectedTool = DrawingTool.pen;
  bool _isSaving = false;

  final List<Color> _colors = [
    const Color(0xFF2DBD6C), // Nova green
    Colors.black,
    Colors.red,
    Colors.blue,
    Colors.orange,
    Colors.purple,
    Colors.yellow,
    Colors.pink,
  ];

  void _addPoint(Offset position) {
    setState(() {
      if (_selectedTool == DrawingTool.eraser) {
        _points.add(DrawingPoint(
          position: position,
          paint: Paint()
            ..color = Colors.white
            ..strokeWidth = _strokeWidth * 3
            ..strokeCap = StrokeCap.round
            ..blendMode = BlendMode.clear,
        ));
      } else {
        _points.add(DrawingPoint(
          position: position,
          paint: Paint()
            ..color = _selectedTool == DrawingTool.highlighter
                ? _selectedColor.withOpacity(0.3)
                : _selectedColor
            ..strokeWidth = _selectedTool == DrawingTool.highlighter
                ? _strokeWidth * 4
                : _strokeWidth
            ..strokeCap = StrokeCap.round,
        ));
      }
    });
  }

  void _endDrawing() {
    if (_points.isNotEmpty) {
      _undoHistory.add(List.from(_points));
      _points.add(DrawingPoint(position: Offset.zero, paint: Paint(), isBreak: true));
    }
  }

  void _undo() {
    if (_undoHistory.isEmpty) return;
    
    setState(() {
      _undoHistory.removeLast();
      _points.clear();
      for (var history in _undoHistory) {
        _points.addAll(history);
        _points.add(DrawingPoint(position: Offset.zero, paint: Paint(), isBreak: true));
      }
    });
  }

  void _clear() {
    setState(() {
      _points.clear();
      _undoHistory.clear();
    });
  }

  Future<void> _saveDrawing() async {
    if (_points.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nothing to save!')),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final boundary = _canvasKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      final pngBytes = byteData!.buffer.asUint8List();

      final appDir = await getApplicationDocumentsDirectory();
      final drawingsDir = Directory(path.join(appDir.path, 'nova_drawings'));
      if (!await drawingsDir.exists()) {
        await drawingsDir.create(recursive: true);
      }

      final fileName = '${const Uuid().v4()}.png';
      final filePath = path.join(drawingsDir.path, fileName);
      final file = File(filePath);
      await file.writeAsBytes(pngBytes);

      if (mounted) {
        Navigator.pop(context, filePath);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving drawing: $e')),
        );
      }
    } finally {
      setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xFF2DBD6C),
        foregroundColor: Colors.white,
        title: const Text('Draw'),
        actions: [
          IconButton(
            icon: const Icon(Icons.undo),
            onPressed: _undoHistory.isEmpty ? null : _undo,
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: _points.isEmpty ? null : _clear,
          ),
          IconButton(
            icon: _isSaving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                  )
                : const Icon(Icons.check),
            onPressed: _isSaving ? null : _saveDrawing,
          ),
        ],
      ),
      body: Column(
        children: [
          // Drawing canvas
          Expanded(
            child: RepaintBoundary(
              key: _canvasKey,
              child: GestureDetector(
                onPanStart: (details) {
                  _addPoint(details.localPosition);
                },
                onPanUpdate: (details) {
                  _addPoint(details.localPosition);
                },
                onPanEnd: (details) {
                  _endDrawing();
                },
                child: CustomPaint(
                  painter: DrawingPainter(_points),
                  size: Size.infinite,
                ),
              ),
            ),
          ),
          // Toolbar
          Container(
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Tools
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _ToolButton(
                      icon: Icons.edit,
                      label: 'Pen',
                      isSelected: _selectedTool == DrawingTool.pen,
                      onTap: () => setState(() => _selectedTool = DrawingTool.pen),
                    ),
                    _ToolButton(
                      icon: Icons.border_color,
                      label: 'Highlighter',
                      isSelected: _selectedTool == DrawingTool.highlighter,
                      onTap: () => setState(() => _selectedTool = DrawingTool.highlighter),
                    ),
                    _ToolButton(
                      icon: Icons.auto_fix_high,
                      label: 'Eraser',
                      isSelected: _selectedTool == DrawingTool.eraser,
                      onTap: () => setState(() => _selectedTool = DrawingTool.eraser),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Stroke width slider
                Row(
                  children: [
                    const Icon(Icons.line_weight, size: 20),
                    Expanded(
                      child: Slider(
                        value: _strokeWidth,
                        min: 1.0,
                        max: 10.0,
                        divisions: 9,
                        activeColor: const Color(0xFF2DBD6C),
                        onChanged: (value) {
                          setState(() => _strokeWidth = value);
                        },
                      ),
                    ),
                    Text('${_strokeWidth.toInt()}'),
                  ],
                ),
                const SizedBox(height: 8),
                // Color palette
                SizedBox(
                  height: 50,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _colors.length,
                    itemBuilder: (context, index) {
                      final color = _colors[index];
                      final isSelected = _selectedColor == color;
                      return GestureDetector(
                        onTap: () => setState(() => _selectedColor = color),
                        child: Container(
                          width: 50,
                          height: 50,
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          decoration: BoxDecoration(
                            color: color,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isSelected ? const Color(0xFF2DBD6C) : Colors.grey.shade300,
                              width: isSelected ? 3 : 2,
                            ),
                            boxShadow: isSelected
                                ? [
                                    BoxShadow(
                                      color: color.withOpacity(0.5),
                                      blurRadius: 8,
                                      spreadRadius: 2,
                                    ),
                                  ]
                                : null,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ToolButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _ToolButton({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF2DBD6C) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? const Color(0xFF2DBD6C) : Colors.grey.shade300,
            width: 2,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isSelected ? Colors.white : Colors.grey.shade700,
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: isSelected ? Colors.white : Colors.grey.shade700,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

enum DrawingTool { pen, highlighter, eraser }

class DrawingPoint {
  final Offset position;
  final Paint paint;
  final bool isBreak;

  DrawingPoint({
    required this.position,
    required this.paint,
    this.isBreak = false,
  });
}

class DrawingPainter extends CustomPainter {
  final List<DrawingPoint> points;

  DrawingPainter(this.points);

  @override
  void paint(Canvas canvas, Size size) {
    for (int i = 0; i < points.length - 1; i++) {
      if (points[i].isBreak || points[i + 1].isBreak) {
        continue;
      }
      canvas.drawLine(points[i].position, points[i + 1].position, points[i].paint);
    }
  }

  @override
  bool shouldRepaint(DrawingPainter oldDelegate) {
    return true;
  }
}
