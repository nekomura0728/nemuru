import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// キャラクター画像を表示するウィジェット
class CharacterImageWidget extends StatefulWidget {
  final int characterId;
  final double width;
  final double height;

  const CharacterImageWidget({
    super.key,
    required this.characterId,
    required this.width,
    required this.height,
  });

  @override
  State<CharacterImageWidget> createState() => _CharacterImageWidgetState();
}

class _CharacterImageWidgetState extends State<CharacterImageWidget> {
  ui.Image? _image;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadImage();
  }

  @override
  void didUpdateWidget(CharacterImageWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.characterId != widget.characterId) {
      _loadImage();
    }
  }

  Future<void> _loadImage() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final String imagePath = 'assets/images/${widget.characterId}.png';
      final ByteData data = await rootBundle.load(imagePath);
      final Uint8List bytes = data.buffer.asUint8List();
      final ui.Codec codec = await ui.instantiateImageCodec(bytes);
      final ui.FrameInfo fi = await codec.getNextFrame();
      
      if (mounted) {
        setState(() {
          _image = fi.image;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Container(
        width: widget.width,
        height: widget.height,
        decoration: BoxDecoration(
          color: Colors.grey.shade200,
          borderRadius: BorderRadius.circular(8),
        ),
      );
    }

    if (_image == null) {
      return Container(
        width: widget.width,
        height: widget.height,
        decoration: BoxDecoration(
          color: Colors.grey.shade200,
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Icon(Icons.error, color: Colors.grey),
      );
    }

    return SizedBox(
      width: widget.width,
      height: widget.height,
      child: CustomPaint(
        painter: _CharacterImagePainter(image: _image!),
      ),
    );
  }
}

class _CharacterImagePainter extends CustomPainter {
  final ui.Image image;

  _CharacterImagePainter({required this.image});

  @override
  void paint(Canvas canvas, Size size) {
    final Rect destRect = Rect.fromLTWH(0, 0, size.width, size.height);
    final paint = Paint()..filterQuality = FilterQuality.high;
    
    canvas.drawImageRect(
      image,
      Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble()),
      destRect,
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant _CharacterImagePainter oldDelegate) {
    return oldDelegate.image != image;
  }
}