import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:nemuru/models/chat_log.dart';
import 'package:nemuru/models/message.dart';
import 'package:nemuru/services/subscription_service.dart';
import 'package:nemuru/services/device_id_service.dart';
import 'package:uuid/uuid.dart';

/// チャットログを管理するサービス（完全ローカル保存）
class ChatLogService extends ChangeNotifier {
  final SubscriptionService _subscriptionService;
  final List<ChatLog> _logs = [];
  
  // ローカル保存用のキー
  static const String _logsKey = 'chat_logs';
  
  // ゲッター
  List<ChatLog> get logs => List.unmodifiable(_logs);

  ChatLogService(this._subscriptionService) {
    _init();
  }

  // Initialize the service by loading logs from local storage
  Future<void> _init() async {
    await _loadLogsFromLocal();
  }

  // Load logs from SharedPreferences
  Future<void> _loadLogsFromLocal() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final logsJson = prefs.getStringList(_logsKey) ?? [];
      
      _logs.clear();
      
      for (final logJson in logsJson) {
        try {
          final logData = jsonDecode(logJson) as Map<String, dynamic>;
          _logs.add(ChatLog.fromJson(logData));
        } catch (e) {
          if (kDebugMode) print('Error parsing log: $e');
        }
      }
      
      // 日付順に並べ替え（新しい順）
      _logs.sort((a, b) => b.date.compareTo(a.date));
      
      notifyListeners();
    } catch (e) {
      if (kDebugMode) {
        print('Error loading logs from local storage: $e');
      }
    }
  }

  // Save logs to SharedPreferences
  Future<void> _saveLogsToLocal() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final logsJson = _logs.map((log) => jsonEncode(log.toJson())).toList();
      await prefs.setStringList(_logsKey, logsJson);
    } catch (e) {
      if (kDebugMode) {
        print('Error saving logs to local storage: $e');
      }
    }
  }

  List<ChatLog> getAllLogs() {
    return _logs;
  }

  List<ChatLog> getAvailableLogs() {
    return _logs.where((log) => _subscriptionService.isLogAvailable(log.date)).toList();
  }

  ChatLog? getLogByDate(DateTime date) {
    final formattedDate = DateTime(date.year, date.month, date.day);
    try {
      return _logs.firstWhere(
        (log) => DateTime(log.date.year, log.date.month, log.date.day).isAtSameMomentAs(formattedDate)
      );
    } catch (e) {
      return null;
    }
  }

  Future<ChatLog> createLog({
    required String mood,
    String? reflection,
    required int characterId,
  }) async {
    final now = DateTime.now();
    final id = const Uuid().v4();
    // デバイスIDを取得
    final deviceId = await DeviceIdService.getDeviceId();

    final newLog = ChatLog(
      id: id,
      date: now,
      mood: mood,
      reflection: reflection,
      // summary will be null initially
      characterId: characterId,
      deviceId: deviceId,
    );

    // 会話カウントを増加させる前に、制限チェックを行う
    final isPremium = _subscriptionService.isPremium;
    final todayCount = _subscriptionService.todayConversationCount;
    final limit = isPremium 
        ? SubscriptionService.premiumConversationLimit 
        : SubscriptionService.freeConversationLimit;
        
    // 既に制限に達している場合はエラーをスロー
    if ((isPremium && todayCount >= SubscriptionService.premiumConversationLimit) ||
        (!isPremium && todayCount >= SubscriptionService.freeConversationLimit)) {
      throw Exception('会話制限に達しました。プレミアムプラン: $isPremium, 今日の会話数: $todayCount, 制限: $limit');
    }
    
    try {
      _logs.insert(0, newLog);
      await _saveLogsToLocal();
      await _subscriptionService.incrementConversationCount();
      notifyListeners();
      return newLog;
    } catch (e) {
      if (kDebugMode) {
        print('Error creating log: $e');
      }
      rethrow;
    }
  }

  Future<void> deleteLog(String id) async {
    try {
      _logs.removeWhere((log) => log.id == id);
      await _saveLogsToLocal();
      notifyListeners();
    } catch (e) {
      if (kDebugMode) {
        print('Error deleting log: $e');
      }
    }
  }
  
  bool isLogAvailable(ChatLog log) {
    return _subscriptionService.isLogAvailable(log.date);
  }
  
  bool hasReachedDailyLimit() {
    return _subscriptionService.hasReachedFreeLimit;
  }

  Future<void> updateLogSummary(String logId, String summary, {List<Message>? fullConversation}) async {
    final index = _logs.indexWhere((log) => log.id == logId);
    if (index != -1) {
      // デバッグ: summaryの長さを確認
      if (kDebugMode) {
        print('DEBUG: updateLogSummary - summary length: ${summary.length}');
        if (summary.contains('【アドバイス】')) {
          final adviceIndex = summary.indexOf('【アドバイス】');
          final adviceContent = summary.substring(adviceIndex);
          print('DEBUG: Advice content length: ${adviceContent.length}');
          print('DEBUG: Last 50 chars: ${summary.substring(summary.length - min(50, summary.length))}');
        }
      }
      
      final oldLog = _logs[index];
      final updatedLog = ChatLog(
        id: oldLog.id,
        date: oldLog.date,
        mood: oldLog.mood,
        reflection: oldLog.reflection,
        summary: summary, // Update the summary
        characterId: oldLog.characterId,
        deviceId: oldLog.deviceId,
        fullConversation: fullConversation ?? oldLog.fullConversation,
      );

      try {
        _logs[index] = updatedLog;
        await _saveLogsToLocal();
        notifyListeners();
      } catch (e) {
        if (kDebugMode) {
          print('Error updating log summary: $e');
        }
        rethrow;
      }
    }
  }
}