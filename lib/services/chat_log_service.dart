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
          // Skip invalid log entries
        }
      }
      
      // 日付順に並べ替え（新しい順）
      _logs.sort((a, b) => b.date.compareTo(a.date));
      
      notifyListeners();
    } catch (e) {
      // Handle loading error silently
    }
  }

  // Save logs to SharedPreferences
  Future<void> _saveLogsToLocal() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final logsJson = _logs.map((log) => jsonEncode(log.toJson())).toList();
      await prefs.setStringList(_logsKey, logsJson);
    } catch (e) {
      // Handle saving error silently
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
      rethrow;
    }
  }

  Future<void> deleteLog(String id) async {
    try {
      _logs.removeWhere((log) => log.id == id);
      await _saveLogsToLocal();
      notifyListeners();
    } catch (e) {
      // Handle deletion error silently
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
      // Update log summary
      
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
        rethrow;
      }
    }
  }

  /// ユーザーの傾向を分析してプロファイルを生成
  UserProfile analyzeUserProfile() {
    if (_logs.isEmpty) {
      return UserProfile.empty();
    }

    // 1. 気分の傾向を分析（深度分析を含む）
    final Map<String, int> moodCount = {};
    for (final log in _logs) {
      moodCount[log.mood] = (moodCount[log.mood] ?? 0) + 1;
    }
    
    // 最頻気分
    final sortedMoods = moodCount.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final frequentMood = sortedMoods.isNotEmpty ? sortedMoods[0].key : '';
    
    // 2番目に多い気分
    final secondMood = sortedMoods.length > 1 ? sortedMoods[1].key : null;
    
    // 最近7日間の気分パターン
    final now = DateTime.now();
    final sevenDaysAgo = now.subtract(const Duration(days: 7));
    final recentLogs = _logs.where((log) => log.date.isAfter(sevenDaysAgo)).toList();
    final recentMoodPattern = recentLogs.map((log) => log.mood).toList();

    // 2. よく話すトピックを分析（キーワード抽出）
    final commonTopics = _extractCommonTopics();
    final topicCategories = _analyzeTopicCategories();

    // 3. 会話回数と質
    final conversationCount = _logs.length;
    
    // 平均会話長を計算
    double averageConversationLength = 0.0;
    if (_logs.isNotEmpty) {
      int totalMessages = 0;
      for (final log in _logs) {
        if (log.fullConversation != null) {
          totalMessages += log.fullConversation!.length;
        }
      }
      averageConversationLength = totalMessages / _logs.length;
    }

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

    // 5. 関係性レベル（質的判定を含む）
    final relationshipLevel = _getRelationshipLevel(conversationCount, averageConversationLength);

    return UserProfile(
      frequentMood: frequentMood,
      secondMood: secondMood,
      commonTopics: commonTopics,
      topicCategories: topicCategories,
      conversationCount: conversationCount,
      averageConversationLength: averageConversationLength,
      preferredCharacterId: preferredCharacterId,
      relationshipLevel: relationshipLevel,
      recentMoodPattern: recentMoodPattern,
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

    // 拡張キーワードリスト（より幅広い話題をカバー）
    final keywords = <String>[
      // 仕事関連
      '仕事', '会社', '職場', '上司', '同僚', 'プロジェクト', '会議', '残業',
      // 人間関係
      '友達', '家族', '恋愛', '恋人', 'パートナー', '子供', '親', '友人',
      // 健康・生活
      '健康', '睡眠', '疲れ', '体調', '運動', '食事', 'ダイエット',
      // 感情・精神
      '不安', 'ストレス', '悩み', '心配', 'プレッシャー', '緊張',
      // 趣味・娯楽
      '趣味', '遊び', '旅行', '映画', '音楽', 'ゲーム', '読書',
      // 学習・成長
      '勉強', '学校', '試験', '資格', 'スキル', '成長'
    ];
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

  /// 話題をカテゴリ別に分析
  Map<String, int> _analyzeTopicCategories() {
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

    if (allTexts.isEmpty) return {};

    // カテゴリ別キーワードマッピング
    final categoryKeywords = {
      '仕事': ['仕事', '会社', '職場', '上司', '同僚', 'プロジェクト', '会議', '残業'],
      '人間関係': ['友達', '家族', '恋愛', '恋人', 'パートナー', '子供', '親', '友人'],
      '健康': ['健康', '睡眠', '疲れ', '体調', '運動', '食事', 'ダイエット'],
      '趣味': ['趣味', '遊び', '旅行', '映画', '音楽', 'ゲーム', '読書'],
    };
    
    final categoryCount = <String, int>{};
    
    for (final text in allTexts) {
      for (final category in categoryKeywords.keys) {
        for (final keyword in categoryKeywords[category]!) {
          if (text.contains(keyword)) {
            categoryCount[category] = (categoryCount[category] ?? 0) + 1;
            break; // 同じカテゴリで複数マッチしても1回だけカウント
          }
        }
      }
    }
    
    return categoryCount;
  }

  /// 関係性レベルを判定（会話の質も考慮）
  String _getRelationshipLevel(int count, double averageLength) {
    // 基本的な回数による判定
    if (count <= 2) {
      return '初回';
    }
    
    if (count <= 10) {
      // 会話の質を考慮して調整
      if (averageLength > 12.0) {
        return '親しい'; // 短期間でも深い会話をしている
      }
      return '慣れてきた';
    }
    
    // 長期間の関係
    if (averageLength > 15.0) {
      return '親しい'; // 深い関係
    } else if (averageLength < 6.0) {
      return '慣れてきた'; // 表面的な関係のまま
    } else {
      return '親しい'; // 通常の親しい関係
    }
  }
}