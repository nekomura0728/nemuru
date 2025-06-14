import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:nemuru/models/chat_log.dart';
import 'package:nemuru/models/message.dart';
import 'package:nemuru/models/user_profile.dart';
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

  /// ユーザーの傾向を分析してプロファイルを生成
  UserProfile analyzeUserProfile() {
    if (_logs.isEmpty) {
      return UserProfile.empty();
    }

    // 1. 気分の傾向を分析
    final Map<String, int> moodCount = {};
    for (final log in _logs) {
      moodCount[log.mood] = (moodCount[log.mood] ?? 0) + 1;
    }
    final frequentMood = moodCount.entries
        .reduce((a, b) => a.value > b.value ? a : b)
        .key;

    // 2. よく話すトピックを分析（キーワード抽出）
    final commonTopics = _extractCommonTopics();

    // 3. 会話回数
    final conversationCount = _logs.length;

    // 4. よく選ぶキャラクター
    final Map<int, int> characterCount = {};
    for (final log in _logs) {
      characterCount[log.characterId] = (characterCount[log.characterId] ?? 0) + 1;
    }
    final preferredCharacterId = characterCount.entries.isNotEmpty
        ? characterCount.entries
            .reduce((a, b) => a.value > b.value ? a : b)
            .key
        : 0;

    // 5. 関係性レベル
    final relationshipLevel = _getRelationshipLevel(conversationCount);

    return UserProfile(
      frequentMood: frequentMood,
      commonTopics: commonTopics,
      conversationCount: conversationCount,
      preferredCharacterId: preferredCharacterId,
      relationshipLevel: relationshipLevel,
    );
  }

  /// よく話すトピックのキーワードを抽出
  List<String> _extractCommonTopics() {
    final List<String> allTexts = [];
    
    // reflectionとsummaryからテキストを収集
    for (final log in _logs) {
      if (log.reflection != null && log.reflection!.isNotEmpty) {
        allTexts.add(log.reflection!);
      }
      if (log.summary != null && log.summary!.isNotEmpty) {
        allTexts.add(log.summary!);
      }
    }

    if (allTexts.isEmpty) return [];

    // 簡単なキーワード抽出（よく出現する単語）
    final keywords = <String>['仕事', '疲れ', '友達', '家族', '勉強', '恋愛', '健康', '趣味', '睡眠', '不安', 'ストレス'];
    final topicCount = <String, int>{};

    for (final text in allTexts) {
      for (final keyword in keywords) {
        if (text.contains(keyword)) {
          topicCount[keyword] = (topicCount[keyword] ?? 0) + 1;
        }
      }
    }

    // 出現回数順にソートして上位3つを返す
    final sortedTopics = topicCount.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    
    return sortedTopics.take(3).map((e) => e.key).toList();
  }

  /// 関係性レベルを判定
  String _getRelationshipLevel(int count) {
    if (count <= 2) return '初回';
    if (count <= 10) return '慣れてきた';
    return '親しい';
  }
}