import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// キャラクター画像を描画するためのカスタムペインター
/// 1枚の画像から12種類のキャラクターを切り抜いて表示します
class CharacterImagePainter extends CustomPainter {
  final String imagePath;
  final int characterId;
  ui.Image? _image;
  bool _isImageLoaded = false;

  CharacterImagePainter({
    required this.imagePath,
    required this.characterId,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (!_isImageLoaded) {
      _loadImage().then((_) {
        _isImageLoaded = true;
      });
      
      // 画像が読み込まれるまでプレースホルダーを表示
      final paint = Paint()
        ..color = Colors.grey.shade200
        ..style = PaintingStyle.fill;
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(0, 0, size.width, size.height),
          const Radius.circular(8),
        ),
        paint,
      );
      return;
    }
    
    if (_image == null) return;
    
    // 個別の画像をそのまま表示するシンプルな方法に変更
    final Rect destRect = Rect.fromLTWH(
      0,
      0,
      size.width,
      size.height,
    );
    
    final paint = Paint()
      ..filterQuality = FilterQuality.high;
    
    // 画像全体をそのまま表示
    canvas.drawImageRect(
      _image!, 
      Rect.fromLTWH(0, 0, _image!.width.toDouble(), _image!.height.toDouble()), 
      destRect, 
      paint
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
  
  Future<void> _loadImage() async {
    // キャラクターIDに基づいてアイコン画像をロード
    // 1〜12はキャラクターアイコン
    // キャラクターIDは1から始まるので、配列のインデックスと合わせる
    String actualImagePath = 'assets/images/${characterId}.png';
    
    final ByteData data = await rootBundle.load(actualImagePath);
    final Uint8List bytes = data.buffer.asUint8List();
    final ui.Codec codec = await ui.instantiateImageCodec(bytes);
    final ui.FrameInfo fi = await codec.getNextFrame();
    _image = fi.image;
    return;
  }
}
