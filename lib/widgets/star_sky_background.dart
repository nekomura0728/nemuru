import 'package:flutter/material.dart';
import 'package:nemuru/constants/ui_constants.dart';
import 'dart:math';

// 星のデータを保持するクラス
class Star {
  final double x; // 画面上のx座標（0.0〜1.0）
  final double y; // 画面上のy座標（0.0〜1.0）
  final double size; // 星のサイズ
  final double opacity; // 星の透明度

  const Star({
    required this.x,
    required this.y,
    required this.size,
    required this.opacity,
  });
}

// 星空の背景を描画するためのカスタムペインター
class StarSkyPainter extends CustomPainter {
  final bool isDarkMode;
  final List<Star> stars;

  const StarSkyPainter({required this.isDarkMode, required this.stars});

  @override
  void paint(Canvas canvas, Size size) {
    // 星を描画
    for (final star in stars) {
      final paint = Paint()
        ..color = isDarkMode
            ? Colors.white.withValues(alpha: star.opacity)
            : Colors.blueGrey.withValues(alpha: star.opacity * 0.7)
        ..style = PaintingStyle.fill;

      // 星の位置を計算
      final x = star.x * size.width;
      final y = star.y * size.height;

      // 星を描画（小さな円）
      canvas.drawCircle(Offset(x, y), star.size, paint);

      // 輝きを追加（より大きな透明な円）
      if (isDarkMode && star.size > UIConstants.starMinSize + 1.0) {
        final glowPaint = Paint()
          ..color = Colors.white.withValues(alpha: star.opacity * 0.3)
          ..style = PaintingStyle.fill;
        canvas.drawCircle(Offset(x, y), star.size * 2, glowPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// 星空背景ウィジェット
class StarSkyBackground extends StatefulWidget {
  final Widget child;
  final bool isDarkMode;

  const StarSkyBackground({
    super.key,
    required this.child,
    required this.isDarkMode,
  });

  @override
  State<StarSkyBackground> createState() => _StarSkyBackgroundState();
}

class _StarSkyBackgroundState extends State<StarSkyBackground> {
  late final List<Star> _stars;

  @override
  void initState() {
    super.initState();
    _generateStars();
  }

  void _generateStars() {
    final random = Random();
    final starCount = UIConstants.darkModeStarCount;
    _stars = List.generate(starCount, (index) {
      return Star(
        x: random.nextDouble(),
        y: random.nextDouble(),
        size: random.nextDouble() * (UIConstants.starMaxSize - UIConstants.starMinSize) + UIConstants.starMinSize,
        opacity: random.nextDouble() * (UIConstants.starMaxOpacity - UIConstants.starMinOpacity) + UIConstants.starMinOpacity,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: widget.isDarkMode
              ? [
                  const Color(0xFF050A12),
                  const Color(0xFF0A1525),
                ]
              : [
                  const Color(0xFFD8E8FF),
                  const Color(0xFFEAEAEA),
                ],
        ),
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: CustomPaint(
              painter: StarSkyPainter(
                isDarkMode: widget.isDarkMode,
                stars: widget.isDarkMode
                    ? _stars
                    : _stars.take(UIConstants.lightModeStarCount).toList(),
              ),
            ),
          ),
          widget.child,
        ],
      ),
    );
  }
}