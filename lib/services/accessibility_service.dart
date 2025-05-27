import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AccessibilityService extends ChangeNotifier {
  static const String _fontScaleKey = 'font_scale_factor';
  
  double _fontScaleFactor = 1.0;
  SharedPreferences? _prefs;

  double get fontScaleFactor => _fontScaleFactor;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    _fontScaleFactor = _prefs?.getDouble(_fontScaleKey) ?? 1.0;
    notifyListeners();
  }

  Future<void> setFontScaleFactor(double scale) async {
    if (scale < 0.8 || scale > 2.0) return; // 制限を設ける
    
    _fontScaleFactor = scale;
    await _prefs?.setDouble(_fontScaleKey, scale);
    notifyListeners();
  }

  // スケールされたフォントサイズを取得
  double getScaledFontSize(double baseSize) {
    return baseSize * _fontScaleFactor;
  }

  // プリセットのスケール値
  static const List<FontScaleOption> fontScaleOptions = [
    FontScaleOption('小', 0.8),
    FontScaleOption('標準', 1.0),
    FontScaleOption('大', 1.2),
    FontScaleOption('特大', 1.5),
    FontScaleOption('最大', 2.0),
  ];
}

class FontScaleOption {
  final String label;
  final double scale;
  
  const FontScaleOption(this.label, this.scale);
}