import 'package:flutter/material.dart';
import '../../models/voiceover_segment.dart';

class VoiceoverSegmentWidget extends StatefulWidget {
  final VoiceoverSegment segment;
  final double width;
  final bool isSelected;
  final VoidCallback onTap;
  final Function(double) onDragStart;
  final Function(double) onDragUpdate;
  final Function(double) onDragEnd;
  final Function(double) onTrimStart;
  final Function(double) onTrimEnd;

  const VoiceoverSegmentWidget({
    super.key,
    required this.segment,
    required this.width,
    this.isSelected = false,
    required this.onTap,
    required this.onDragStart,
    required this.onDragUpdate,
    required this.onDragEnd,
    required this.onTrimStart,
    required this.onTrimEnd,
  });

  @override
  State<VoiceoverSegmentWidget> createState() => _VoiceoverSegmentWidgetState();
}

class _VoiceoverSegmentWidgetState extends State<VoiceoverSegmentWidget> {
  double? _lastGlobalX;
  bool _isDragging = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      // Long press to move
      onLongPressStart: (details) {
        setState(() {
          _isDragging = true;
          _lastGlobalX = details.globalPosition.dx;
        });
        widget.onTap(); // Select on drag start
        widget.onDragStart(details.localPosition.dx);
      },
      onLongPressMoveUpdate: (details) {
        if (_lastGlobalX != null) {
          final dx = details.globalPosition.dx - _lastGlobalX!;
          widget.onDragUpdate(dx);
          _lastGlobalX = details.globalPosition.dx;
        }
      },
      onLongPressEnd: (details) {
        setState(() {
          _isDragging = false;
          _lastGlobalX = null;
        });
        widget.onDragEnd(0);
      },
      child: Transform.scale(
        scale: _isDragging ? 1.05 : 1.0, // Visual feedback
        child: Container(
          width: widget.width,
          height: 50,
          decoration: BoxDecoration(
            color: widget.isSelected
                ? const Color(0xFFAB7FFF)
                : const Color(0xFFAB7FFF).withValues(alpha: 0.7),
            borderRadius: BorderRadius.circular(8),
            border: widget.isSelected
                ? Border.all(color: Colors.white, width: 2)
                : null,
            boxShadow: _isDragging
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.5),
                      blurRadius: 10,
                      spreadRadius: 2,
                    )
                  ]
                : null,
          ),
          child: Stack(
            children: [
              // Segment Content (Name/Waveform placeholder)
              Center(
                child: Text(
                  'Voiceover',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),

              // Left Trim Handle (Keep horizontal drag for trimming)
              if (widget.isSelected)
                Positioned(
                  left: 0,
                  top: 0,
                  bottom: 0,
                  width: 20,
                  child: GestureDetector(
                    onHorizontalDragUpdate: (details) =>
                        widget.onTrimStart(details.delta.dx),
                    child: Container(
                      color: Colors.white.withValues(alpha: 0.3),
                      child: const Icon(Icons.chevron_left,
                          size: 16, color: Colors.white),
                    ),
                  ),
                ),

              // Right Trim Handle
              if (widget.isSelected)
                Positioned(
                  right: 0,
                  top: 0,
                  bottom: 0,
                  width: 20,
                  child: GestureDetector(
                    onHorizontalDragUpdate: (details) =>
                        widget.onTrimEnd(details.delta.dx),
                    child: Container(
                      color: Colors.white.withValues(alpha: 0.3),
                      child: const Icon(Icons.chevron_right,
                          size: 16, color: Colors.white),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
