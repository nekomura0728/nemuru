import 'package:flutter/material.dart';

/// UI関連の定数を管理するクラス
class UIConstants {
  // プライベートコンストラクタ（インスタンス化を防ぐ）
  UIConstants._();

  // ========== アニメーション関連 ==========
  /// 標準的なアニメーション時間
  static const Duration standardAnimationDuration = Duration(milliseconds: 300);
  
  /// 長いアニメーション時間
  static const Duration longAnimationDuration = Duration(milliseconds: 500);
  
  /// 流れ星アニメーション時間
  static const Duration shootingStarAnimationDuration = Duration(seconds: 10);
  
  /// ダイアログ表示前の待機時間
  static const Duration dialogDelay = Duration(milliseconds: 1000);
  
  /// エラー表示時間
  static const Duration errorDisplayDuration = Duration(seconds: 4);

  // ========== サイズ関連 ==========
  /// 標準的なボーダー半径
  static const double standardBorderRadius = 16.0;
  
  /// 小さなボーダー半径
  static const double smallBorderRadius = 8.0;
  
  /// 大きなボーダー半径
  static const double largeBorderRadius = 24.0;
  
  /// ボタンのボーダー半径
  static const double buttonBorderRadius = 20.0;
  
  /// 円形ボタンのボーダー半径
  static const double circularButtonBorderRadius = 30.0;
  
  /// カードの標準elevation
  static const double cardElevation = 2.0;
  
  /// ボタンの標準elevation
  static const double buttonElevation = 5.0;

  // ========== パディング・マージン関連 ==========
  /// 標準的なパディング
  static const double standardPadding = 16.0;
  
  /// 小さなパディング
  static const double smallPadding = 8.0;
  
  /// 大きなパディング
  static const double largePadding = 24.0;
  
  /// 極小パディング
  static const double tinyPadding = 4.0;
  
  /// 標準的なマージン
  static const double standardMargin = 16.0;
  
  /// 小さなマージン
  static const double smallMargin = 8.0;
  
  /// 大きなマージン
  static const double largeMargin = 24.0;
  
  /// 極小マージン
  static const double tinyMargin = 4.0;

  // ========== フォントサイズ関連 ==========
  /// 大見出しフォントサイズ
  static const double displayLargeFontSize = 26.0;
  
  /// 中見出しフォントサイズ
  static const double displayMediumFontSize = 22.0;
  
  /// 小見出しフォントサイズ
  static const double displaySmallFontSize = 18.0;
  
  /// タイトルフォントサイズ
  static const double titleFontSize = 20.0;
  
  /// 本文フォントサイズ
  static const double bodyFontSize = 16.0;
  
  /// 小さな本文フォントサイズ
  static const double bodySmallFontSize = 14.0;
  
  /// キャプションフォントサイズ
  static const double captionFontSize = 12.0;
  
  /// オンボーディングタイトルフォントサイズ
  static const double onboardingTitleFontSize = 32.0;

  // ========== アイコンサイズ関連 ==========
  /// 標準的なアイコンサイズ
  static const double standardIconSize = 24.0;
  
  /// 小さなアイコンサイズ
  static const double smallIconSize = 20.0;
  
  /// 大きなアイコンサイズ
  static const double largeIconSize = 30.0;
  
  /// エラーアイコンサイズ
  static const double errorIconSize = 28.0;
  
  /// 気分選択アイコンサイズ
  static const double moodIconSize = 40.0;

  // ========== グリッド関連 ==========
  /// 気分選択グリッドの列数
  static const int moodGridCrossAxisCount = 3;
  
  /// 気分選択グリッドのアスペクト比
  static const double moodGridChildAspectRatio = 0.9;
  
  /// キャラクター選択グリッドの列数
  static const int characterGridCrossAxisCount = 3;
  
  /// キャラクター選択グリッドのアスペクト比
  static const double characterGridChildAspectRatio = 0.8;
  
  /// オンボーディングキャラクターグリッドの列数
  static const int onboardingCharacterGridCrossAxisCount = 2;
  
  /// グリッドの標準スペーシング
  static const double gridSpacing = 16.0;
  
  /// グリッドの小さなスペーシング
  static const double gridSmallSpacing = 12.0;

  // ========== テキストフィールド関連 ==========
  /// テキストフィールドの最大行数
  static const int textFieldMaxLines = 5;
  
  /// テキストフィールドの最大文字数
  static const int textFieldMaxLength = 300;

  // ========== 透明度関連 ==========
  /// 標準的な透明度（薄い）
  static const double standardAlpha = 0.1;
  
  /// 中程度の透明度
  static const double mediumAlpha = 0.3;
  
  /// 濃い透明度
  static const double darkAlpha = 0.5;
  
  /// 非常に薄い透明度
  static const double lightAlpha = 0.05;
  
  /// 星の透明度範囲
  static const double starMinOpacity = 0.3;
  static const double starMaxOpacity = 1.0;

  // ========== 星空関連 ==========
  /// ダークモードでの星の数
  static const int darkModeStarCount = 100;
  
  /// ライトモードでの星の数
  static const int lightModeStarCount = 30;
  
  /// 流れ星の数
  static const int shootingStarCount = 5;
  
  /// 星のサイズ範囲
  static const double starMinSize = 0.5;
  static const double starMaxSize = 2.5;

  // ========== コンテナサイズ関連 ==========
  /// オンボーディングアイコンコンテナサイズ
  static const double onboardingIconContainerSize = 200.0;
  
  /// 最小ボタン高さ
  static const double minButtonHeight = 56.0;
  
  /// カレンダーセルサイズ
  static const double calendarCellSize = 40.0;
  
  /// カレンダーセルマージン
  static const double calendarCellMargin = 1.0;

  // ========== EdgeInsets定数 ==========
  /// 標準的なEdgeInsets.all
  static const EdgeInsets standardPaddingAll = EdgeInsets.all(standardPadding);
  
  /// 小さなEdgeInsets.all
  static const EdgeInsets smallPaddingAll = EdgeInsets.all(smallPadding);
  
  /// 大きなEdgeInsets.all
  static const EdgeInsets largePaddingAll = EdgeInsets.all(largePadding);
  
  /// 水平方向の標準パディング
  static const EdgeInsets standardHorizontalPadding = EdgeInsets.symmetric(horizontal: standardPadding);
  
  /// 垂直方向の標準パディング
  static const EdgeInsets standardVerticalPadding = EdgeInsets.symmetric(vertical: standardPadding);
  
  /// ボタンの標準パディング
  static const EdgeInsets buttonPadding = EdgeInsets.symmetric(horizontal: 24, vertical: 12);
  
  /// 小さなボタンのパディング
  static const EdgeInsets smallButtonPadding = EdgeInsets.symmetric(horizontal: 16, vertical: 8);
  
  /// 大きなボタンのパディング
  static const EdgeInsets largeButtonPadding = EdgeInsets.symmetric(horizontal: 32, vertical: 12);
  
  /// テキストフィールドのパディング
  static const EdgeInsets textFieldPadding = EdgeInsets.symmetric(horizontal: 16, vertical: 16);

  // ========== SizedBox定数 ==========
  /// 標準的な縦スペース
  static const SizedBox standardVerticalSpace = SizedBox(height: standardPadding);
  
  /// 小さな縦スペース
  static const SizedBox smallVerticalSpace = SizedBox(height: smallPadding);
  
  /// 大きな縦スペース
  static const SizedBox largeVerticalSpace = SizedBox(height: largePadding);
  
  /// 極大な縦スペース
  static const SizedBox extraLargeVerticalSpace = SizedBox(height: 40);
  
  /// 標準的な横スペース
  static const SizedBox standardHorizontalSpace = SizedBox(width: standardPadding);
  
  /// 小さな横スペース
  static const SizedBox smallHorizontalSpace = SizedBox(width: smallPadding);
  
  /// 極小な横スペース
  static const SizedBox tinyHorizontalSpace = SizedBox(width: tinyPadding);
  
  /// 極小な縦スペース
  static const SizedBox tinyVerticalSpace = SizedBox(height: tinyPadding);
}