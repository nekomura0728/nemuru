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
    
    // 1枚の画像から12種類のキャラクターを切り抜く
    // 画像は4x3のグリッドで配置されていると仮定
    final int row = characterId ~/ 4; // 行（0, 1, 2）
    final int col = characterId % 4;  // 列（0, 1, 2, 3）
    
    // 画像の全体サイズを取得
    final double sourceWidth = _image!.width / 4;
    final double sourceHeight = _image!.height / 3;
    
    // 各キャラクターの実際の表示領域を計算
    // トリミングを改善するために、各セルの中心部分を使用
    // 各セルの20%の余白を設けて切り抜く
    final double margin = 0.2; // 20%の余白
    final double effectiveWidth = sourceWidth * (1 - margin * 2);
    final double effectiveHeight = sourceHeight * (1 - margin * 2);
    
    final Rect sourceRect = Rect.fromLTWH(
      col * sourceWidth + sourceWidth * margin,
      row * sourceHeight + sourceHeight * margin,
      effectiveWidth,
      effectiveHeight,
    );
    
    final Rect destRect = Rect.fromLTWH(
      0,
      0,
      size.width,
      size.height,
    );
    
    final paint = Paint()
      ..filterQuality = FilterQuality.medium;
    
    canvas.drawImageRect(_image!, sourceRect, destRect, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
  
  Future<void> _loadImage() async {
    final ByteData data = await rootBundle.load(imagePath);
    final Uint8List bytes = data.buffer.asUint8List();
    final ui.Codec codec = await ui.instantiateImageCodec(bytes);
    final ui.FrameInfo fi = await codec.getNextFrame();
    _image = fi.image;
  }
}
