
import 'message.dart';

/// チャットログを管理するモデル
class ChatLog {
  final String id;
  final DateTime date;
  final String mood;
  final String? reflection; // Made nullable as it's no longer from a dedicated screen
  final String? summary; // New field for conversation summary
  // adviceフィールドはデータベースに存在しないため、一時的にコメントアウト
  // final String? advice; // AIからのアドバイス
  final int characterId;
  final String deviceId; // デバイス固有のID
  final List<Message>? fullConversation; // 会話の全ログ

  ChatLog({
    required this.id,
    required this.date,
    required this.mood,
    this.reflection, // Made nullable
    this.summary,
    // this.advice, // AIからのアドバイス
    required this.characterId,
    required this.deviceId,
    this.fullConversation,
  });

  // JSONからChatLogを作成
  factory ChatLog.fromJson(Map<String, dynamic> json) {
    return ChatLog(
      id: json['id'] as String,
      date: DateTime.parse(json['date'] as String),
      mood: json['mood'] as String,
      reflection: json['reflection'] as String?,
      summary: json['summary'] as String?,
      // advice: json['advice'] as String?,
      characterId: json['character_id'] as int,
      deviceId: json['device_id'] as String,
      fullConversation: json['full_conversation'] != null
          ? (json['full_conversation'] as List)
              .map((msg) => Message.fromJson(msg))
              .toList()
          : null,
    );
  }

  // ChatLogをJSONに変換
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'date': date.toIso8601String(),
      'mood': mood,
      'reflection': reflection, // Will be null if not provided
      'summary': summary,
      // 'advice': advice,
      'character_id': characterId,
      'device_id': deviceId,
      'full_conversation': fullConversation?.map((msg) => msg.toJson()).toList(),
    };
  }
}
