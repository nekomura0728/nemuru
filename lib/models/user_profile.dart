/// ユーザーの傾向を軽量で表現するプロファイル
class UserProfile {
  final String frequentMood;        // 最頻気分
  final String? secondMood;         // 2番目に多い気分
  final List<String> commonTopics;  // よく話すトピック（キーワード）
  final Map<String, int>? topicCategories;  // 話題カテゴリ別の出現回数
  final int conversationCount;      // 総会話回数
  final double averageConversationLength;  // 平均会話長（メッセージ数）
  final int preferredCharacterId;   // よく選ぶキャラクターID
  final String relationshipLevel;   // 関係性レベル（初回、慣れてきた、親しい）
  final List<String>? recentMoodPattern;  // 最近7日間の気分パターン

  UserProfile({
    required this.frequentMood,
    this.secondMood,
    required this.commonTopics,
    this.topicCategories,
    required this.conversationCount,
    required this.averageConversationLength,
    required this.preferredCharacterId,
    required this.relationshipLevel,
    this.recentMoodPattern,
  });


  /// 空のプロファイル（初回ユーザー用）
  static UserProfile empty() {
    return UserProfile(
      frequentMood: '',
      secondMood: null,
      commonTopics: [],
      topicCategories: null,
      conversationCount: 0,
      averageConversationLength: 0.0,
      preferredCharacterId: 0,
      relationshipLevel: '初回',
      recentMoodPattern: null,
    );
  }

  /// JSONシリアライズ用
  Map<String, dynamic> toJson() {
    return {
      'frequentMood': frequentMood,
      'secondMood': secondMood,
      'commonTopics': commonTopics,
      'topicCategories': topicCategories,
      'conversationCount': conversationCount,
      'averageConversationLength': averageConversationLength,
      'preferredCharacterId': preferredCharacterId,
      'relationshipLevel': relationshipLevel,
      'recentMoodPattern': recentMoodPattern,
    };
  }

  /// JSONデシリアライズ用
  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      frequentMood: json['frequentMood'] ?? '',
      secondMood: json['secondMood'],
      commonTopics: List<String>.from(json['commonTopics'] ?? []),
      topicCategories: json['topicCategories'] != null
          ? Map<String, int>.from(json['topicCategories'])
          : null,
      conversationCount: json['conversationCount'] ?? 0,
      averageConversationLength: (json['averageConversationLength'] ?? 0.0).toDouble(),
      preferredCharacterId: json['preferredCharacterId'] ?? 0,
      relationshipLevel: json['relationshipLevel'] ?? '初回',
      recentMoodPattern: json['recentMoodPattern'] != null
          ? List<String>.from(json['recentMoodPattern'])
          : null,
    );
  }

  /// パーソナライゼーション用の簡潔な説明文を生成
  String getPersonalizationContext() {
    if (conversationCount == 0) {
      return 'このユーザーは初回の方です。優しく丁寧に対応してください。';
    }

    final List<String> context = [];
    
    // 気分の傾向（深度分析を含む）
    if (frequentMood.isNotEmpty) {
      final moodDescription = {
        '喜': '喜びを感じることが多い',
        '怒': 'ストレスや怒りを感じることが多い',
        '哀': '悲しみや落ち込みを感じることが多い',
        '楽': '楽しみや充実感を感じることが多い',
        '疲': '疲れや疲労感を感じることが多い',
        '焦': '焦りや不安を感じることが多い',
      };
      
      String moodText = '普段${moodDescription[frequentMood] ?? '様々な気分を'}方';
      
      // 2番目に多い気分も考慮
      if (secondMood != null && secondMood!.isNotEmpty) {
        final secondDesc = moodDescription[secondMood];
        if (secondDesc != null) {
          moodText += 'で、時々${secondDesc.replaceAll('ことが多い', '')}こともある';
        }
      }
      
      // 最近の気分パターン
      if (recentMoodPattern != null && recentMoodPattern!.length >= 3) {
        final lastThreeMoods = recentMoodPattern!.take(3).toList();
        if (lastThreeMoods.every((mood) => mood == '疲' || mood == '焦')) {
          moodText += '（最近特にお疲れのようです）';
        }
      }
      
      context.add(moodText);
    }

    // 話題の傾向（カテゴリ分析を含む）
    if (commonTopics.isNotEmpty) {
      final topicsText = commonTopics.take(2).join('や');
      String topicDescription = topicsText + 'の話をよくする';
      
      // カテゴリ別の傾向を追加
      if (topicCategories != null && topicCategories!.isNotEmpty) {
        final topCategory = topicCategories!.entries
            .reduce((a, b) => a.value > b.value ? a : b)
            .key;
        
        final categoryDescription = {
          '仕事': '仕事関連の話題が中心',
          '人間関係': '人とのつながりを大切に',
          '健康': '健康への意識が高い',
          '趣味': '趣味を楽しんでいる',
        };
        
        if (categoryDescription.containsKey(topCategory)) {
          topicDescription = '$topicDescription（${categoryDescription[topCategory]!}）';
        }
      }
      
      context.add(topicDescription);
    }

    // 関係性（質的判定を含む）
    final relationshipText = {
      '初回': '初回なので丁寧に',
      '慣れてきた': '少し親しみやすい口調で',
      '親しい': '親しみやすく温かい口調で',
    };
    
    String relationshipDescription = relationshipText[relationshipLevel] ?? '適切な口調で';
    
    // 会話の質を考慮
    if (averageConversationLength > 10.0) {
      relationshipDescription += '（じっくり話を聞いてくれる方）';
    }
    
    context.add('${relationshipDescription}対応してください');

    return 'このユーザーは${context.join('、')}。';
  }
}