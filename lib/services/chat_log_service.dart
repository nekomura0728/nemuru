import 'dart:convert'; // For jsonDecode if messages are stored as string initially
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart'; // Supabase import
import 'package:nemuru/models/chat_log.dart';

import 'package:nemuru/services/subscription_service.dart';
import 'package:nemuru/services/device_id_service.dart';
import 'package:uuid/uuid.dart';

/// チャットログを管理するサービス
class ChatLogService extends ChangeNotifier {
  final SubscriptionService _subscriptionService;
  final List<ChatLog> _logs = [];

  // Supabase client instance
  final _supabase = Supabase.instance.client;
  // Name of the Supabase table
  static const String _tableName = 'chat_logs';

  ChatLogService(this._subscriptionService) {
    _init();
  }

  // Initialize the service by loading logs from Supabase
  Future<void> _init() async {
    await _loadLogsFromSupabase();
  }

  // Load logs from Supabase
  Future<void> _loadLogsFromSupabase() async {
    try {
      // デバイスIDを取得
      final deviceId = await DeviceIdService.getDeviceId();
      
      // デバイスIDでフィルタリングしてログを取得
      final response = await _supabase
          .from(_tableName)
          .select()
          .eq('device_id', deviceId) // デバイスIDでフィルタリング
          .order('date', ascending: false); // 日付順に並べ替え（新しい順）

      _logs.clear(); // Clear local cache

      if (response is List) {
        for (var logData in response) {
          if (logData is Map<String, dynamic>) {
            // messages field is removed, summary will be handled by ChatLog.fromJson
            _logs.add(ChatLog.fromJson(logData));
          } else {
             if (kDebugMode) print('Unexpected logData format: $logData');
          }
        }
      } else {
         if (kDebugMode) print('Unexpected response format from Supabase: $response');
      }
      notifyListeners();
    } catch (e) {
      if (kDebugMode) {
        print('Error loading logs from Supabase: $e');
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

    try {
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
      
      final logData = newLog.toJson();
      await _supabase.from(_tableName).insert(logData);
      _logs.insert(0, newLog);
      await _subscriptionService.incrementConversationCount();
      notifyListeners();
      return newLog;
    } catch (e) {
      if (kDebugMode) {
        print('Error creating log in Supabase: $e');
      }
      rethrow;
    }
  }

  Future<void> deleteLog(String id) async {
    try {
      // デバイスIDを取得
      final deviceId = await DeviceIdService.getDeviceId();
      
      await _supabase
          .from(_tableName)
          .delete()
          .eq('id', id)
          .eq('device_id', deviceId); // デバイスIDによる制限を追加
          
      _logs.removeWhere((log) => log.id == id);
      notifyListeners();
    } catch (e) {
      if (kDebugMode) {
        print('Error deleting log from Supabase: $e');
      }
    }
  }
  
  bool isLogAvailable(ChatLog log) {
    return _subscriptionService.isLogAvailable(log.date);
  }
  
  bool hasReachedDailyLimit() {
    return _subscriptionService.hasReachedFreeLimit;
  }

  Future<void> updateLogSummary(String logId, String summary) async {
    final index = _logs.indexWhere((log) => log.id == logId);
    if (index != -1) {
      final oldLog = _logs[index];
      final updatedLog = ChatLog(
        id: oldLog.id,
        date: oldLog.date,
        mood: oldLog.mood,
        reflection: oldLog.reflection,
        summary: summary, // Update the summary
        characterId: oldLog.characterId,
        deviceId: oldLog.deviceId,
      );

      try {
        // デバイスIDを取得
        final deviceId = await DeviceIdService.getDeviceId();
        
        await _supabase
            .from(_tableName)
            .update({'summary': summary})
            .eq('id', logId)
            .eq('device_id', deviceId); // デバイスIDによる制限を追加

        _logs[index] = updatedLog;
        notifyListeners();
      } catch (e) {
        if (kDebugMode) {
          print('Error updating log summary in Supabase: $e');
        }
        rethrow;
      }
    }
  }
}