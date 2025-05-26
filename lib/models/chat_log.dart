import 'package:flutter/foundation.dart';

/// チャットログを管理するモデル
class ChatLog {
  final String id;
  final DateTime date;
  final String mood;
  final String? reflection; // Made nullable as it's no longer from a dedicated screen
  final String? summary; // New field for conversation summary
  final int characterId;
  final String deviceId; // デバイス固有のID

  ChatLog({
    required this.id,
    required this.date,
    required this.mood,
    this.reflection, // Made nullable
    this.summary,
    required this.characterId,
    required this.deviceId,
  });

  // JSONからChatLogを作成
  factory ChatLog.fromJson(Map<String, dynamic> json) {
    return ChatLog(
      id: json['id'] as String,
      date: DateTime.parse(json['date'] as String),
      mood: json['mood'] as String,
      reflection: json['reflection'] as String?,
      summary: json['summary'] as String?,
      characterId: json['character_id'] as int,
      deviceId: json['device_id'] as String,
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
      'character_id': characterId,
      'device_id': deviceId,
    };
  }
}
