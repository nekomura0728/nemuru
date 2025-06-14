/// ユーザーの傾向を軽量で表現するプロファイル
class UserProfile {
  final String frequentMood;        // 最頻気分
  final List<String> commonTopics;  // よく話すトピック（キーワード）
  final int conversationCount;      // 総会話回数
  final int preferredCharacterId;   // よく選ぶキャラクターID
  final String relationshipLevel;   // 関係性レベル（初回、慣れてきた、親しい）

  UserProfile({
    required this.frequentMood,
    required this.commonTopics,
    required this.conversationCount,
    required this.preferredCharacterId,
    required this.relationshipLevel,
  });

  /// 関係性レベルを会話回数から判定
  static String _getRelationshipLevel(int count) {
    if (count <= 2) return '初回';
    if (count <= 10) return '慣れてきた';
    return '親しい';
  }

  /// 空のプロファイル（初回ユーザー用）
  static UserProfile empty() {
    return UserProfile(
      frequentMood: '',
      commonTopics: [],
      conversationCount: 0,
      preferredCharacterId: 0,
      relationshipLevel: '初回',
    );
  }

  /// JSONシリアライズ用
  Map<String, dynamic> toJson() {
    return {
      'frequentMood': frequentMood,
      'commonTopics': commonTopics,
      'conversationCount': conversationCount,
      'preferredCharacterId': preferredCharacterId,
      'relationshipLevel': relationshipLevel,
    };
  }

  /// JSONデシリアライズ用
  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      frequentMood: json['frequentMood'] ?? '',
      commonTopics: List<String>.from(json['commonTopics'] ?? []),
      conversationCount: json['conversationCount'] ?? 0,
      preferredCharacterId: json['preferredCharacterId'] ?? 0,
      relationshipLevel: json['relationshipLevel'] ?? '初回',
    );
  }

  /// パーソナライゼーション用の簡潔な説明文を生成
  String getPersonalizationContext() {
    if (conversationCount == 0) {
      return 'このユーザーは初回の方です。優しく丁寧に対応してください。';
    }

    final List<String> context = [];
    
    // 気分の傾向
    if (frequentMood.isNotEmpty) {
      final moodDescription = {
        '喜': '喜びを感じることが多い',
        '怒': 'ストレスや怒りを感じることが多い',
        '哀': '悲しみや落ち込みを感じることが多い',
        '楽': '楽しみや充実感を感じることが多い',
        '疲': '疲れや疲労感を感じることが多い',
        '焦': '焦りや不安を感じることが多い',
      };
      context.add('普段${moodDescription[frequentMood] ?? '様々な気分を'}方');
    }

    // 話題の傾向
    if (commonTopics.isNotEmpty) {
      final topicsText = commonTopics.take(2).join('や');
      context.add('${topicsText}の話をよくする');
    }

    // 関係性
    final relationshipText = {
      '初回': '初回なので丁寧に',
      '慣れてきた': '少し親しみやすい口調で',
      '親しい': '親しみやすく温かい口調で',
    };
    context.add('${relationshipText[relationshipLevel]}対応してください');

    return 'このユーザーは${context.join('、')}。';
  }
}