import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:nemuru/services/preferences_service.dart';
import 'package:nemuru/constants/app_constants.dart';

/// サブスクリプション状態を管理するサービス
class SubscriptionService extends ChangeNotifier {
  final PreferencesService _preferencesService;
  
  // 無料プランの制限（定数から取得）
  static const int freeConversationLimit = AppConstants.freeConversationLimit;
  static const int freeCharacterLimit = AppConstants.freeCharacterLimit;
  static const int freeLogDaysLimit = AppConstants.freeLogDaysLimit;
  static const int freeConversationTurns = AppConstants.freeConversationTurns;
  
  // プレミアムプランの制限（定数から取得）
  static const int premiumConversationLimit = AppConstants.premiumConversationLimit;
  static const int premiumConversationTurns = AppConstants.premiumConversationTurns;

  // 今日の会話回数
  int _todayConversationCount = 0;
  // 月間の会話回数
  int _monthlyConversationCount = 0;
  // 最後に会話した日付
  DateTime? _lastConversationDate;
  // 最後に月間カウンターをリセットした日付
  DateTime? _lastMonthlyResetDate;

  SubscriptionService(this._preferencesService) {
    _loadCounts();
  }

  // ゲッター
  bool get isPremium => _preferencesService.isPremium;
  int get todayConversationCount => _todayConversationCount;
  int get monthlyConversationCount => _monthlyConversationCount;
  int get remainingFreeConversations => freeConversationLimit - _todayConversationCount;
  bool get hasReachedFreeLimit => !isPremium && _todayConversationCount >= freeConversationLimit;
  bool get hasReachedPremiumLimit => isPremium && _todayConversationCount >= premiumConversationLimit;

  // プレミアムプランの設定
  Future<void> setPremium(bool value) async {
    await _preferencesService.setPremium(value);
    notifyListeners();
  }

  // 会話カウンターを増やす
  Future<void> incrementConversationCount() async {
    final now = DateTime.now();
    
    // 日付が変わっていたら、日次カウンターをリセット
    if (_lastConversationDate != null && 
        (_lastConversationDate!.day != now.day || 
         _lastConversationDate!.month != now.month || 
         _lastConversationDate!.year != now.year)) {
      _todayConversationCount = 0;
    }
    
    // 月が変わっていたら、月間カウンターをリセット
    if (_lastMonthlyResetDate != null && 
        (_lastMonthlyResetDate!.month != now.month || 
         _lastMonthlyResetDate!.year != now.year)) {
      _monthlyConversationCount = 0;
      _lastMonthlyResetDate = now;
      await _preferencesService.saveLastMonthlyResetDate(now);
      await _preferencesService.saveMonthlyConversationCount(0);
    }
    
    // カウンターを増やす
    _todayConversationCount++;
    _monthlyConversationCount++;
    _lastConversationDate = now;
    
    // 保存
    await _preferencesService.saveTodayConversationCount(_todayConversationCount);
    await _preferencesService.saveLastConversationDate(now);
    await _preferencesService.saveMonthlyConversationCount(_monthlyConversationCount);
    
    notifyListeners();
  }

  // 日付が変わったかチェックして、必要ならカウンターをリセット
  Future<void> checkAndResetCounters() async {
    final now = DateTime.now();
    
    // 最後の会話日がなければ初期化
    if (_lastConversationDate == null) {
      return;
    }
    
    // 日付が変わっていたら、日次カウンターをリセット
    if (_lastConversationDate!.day != now.day || 
        _lastConversationDate!.month != now.month || 
        _lastConversationDate!.year != now.year) {
      _todayConversationCount = 0;
      await _preferencesService.saveTodayConversationCount(0);
      notifyListeners();
    }
    
    // 月が変わっていたら、月間カウンターをリセット
    if (_lastMonthlyResetDate != null && 
        (_lastMonthlyResetDate!.month != now.month || 
         _lastMonthlyResetDate!.year != now.year)) {
      _monthlyConversationCount = 0;
      _lastMonthlyResetDate = now;
      await _preferencesService.saveLastMonthlyResetDate(now);
      await _preferencesService.saveMonthlyConversationCount(0);
      notifyListeners();
    }
  }

  // キャラクターが無料プランで利用可能かどうか
  bool isCharacterAvailable(int characterId) {
    if (isPremium) {
      return true; // プレミアムプランなら全キャラクター利用可能
    } else {
      return characterId < freeCharacterLimit; // 無料プランなら制限あり
    }
  }

  // ログが閲覧可能かどうか（日付ベース）
  bool isLogAvailable(DateTime logDate) {
    if (isPremium) {
      return true; // プレミアムプランなら全期間閲覧可能
    } else {
      final now = DateTime.now();
      final difference = now.difference(logDate).inDays;
      return difference <= freeLogDaysLimit; // 無料プランなら3日以内のみ
    }
  }

  // プレミアム状態を手動で設定（購入復元時などに使用）
  Future<void> setPremiumStatus(bool isPremium) async {
    await _preferencesService.setPremium(isPremium);
    notifyListeners();
  }

  // デバッグ用：購入状態を強制的にフリーにリセット
  Future<void> forceResetToFree() async {
    await _preferencesService.setPremium(false);
    _todayConversationCount = 0;
    _monthlyConversationCount = 0;
    await _preferencesService.saveTodayConversationCount(0);
    await _preferencesService.saveMonthlyConversationCount(0);
    notifyListeners();
  }

  // カウンターをロード
  void _loadCounts() async {
    _todayConversationCount = _preferencesService.todayConversationCount;
    _monthlyConversationCount = _preferencesService.monthlyConversationCount;
    _lastConversationDate = _preferencesService.lastConversationDate;
    _lastMonthlyResetDate = _preferencesService.lastMonthlyResetDate;
    
    // アプリ起動時にカウンターをチェック・リセット
    await checkAndResetCounters();
  }
}
