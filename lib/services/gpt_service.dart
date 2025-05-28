import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:nemuru/models/character.dart';
import 'package:nemuru/models/message.dart';
import 'package:nemuru/services/preferences_service.dart';
import 'package:nemuru/services/error_handling_service.dart';

class GPTService {
  // バックエンドAPIのエンドポイント（Supabase Edge Functions）
  static const String _chatCompletionsBaseUrl = 'https://ldellkrfbgzrheisjret.supabase.co/functions/v1/chat-completion';
  static const String _summarizeBaseUrl = 'https://ldellkrfbgzrheisjret.supabase.co/functions/v1/chat-completion'; // 同じエンドポイントを使用（必要に応じて専用のsummarize関数を作成可能）

  // 会話履歴を保持
  final List<Message> _conversationHistory = [];
  int _messageCount = 0; // 実際の会話カウント（初回の気分選択と質問応答を除く）
  bool _isInitialExchangeComplete = false; // 初回の気分選択と質問応答が完了したか
  String _currentMood = '';
  
  // 会話履歴を取得
  List<Message> get conversationHistory => List.unmodifiable(_conversationHistory);
  
  // 会話回数を取得（初回の気分選択と質問応答を除く）
  int get messageCount => _messageCount;
  
  // 全メッセージ数を取得（初回の気分選択と質問応答も含む）
  int get totalMessageCount => _conversationHistory.length;
  
  // 会話履歴をクリア
  void clearConversation() {
    _conversationHistory.clear();
    _messageCount = 0;
    _isInitialExchangeComplete = false;
    _currentMood = '';
  }

  // 最後のn個のメッセージを取得するヘルパーメソッド
  List<Message> _getLastMessages(List<Message> messages, int n) {
    if (messages.length <= n) return messages;
    return messages.sublist(messages.length - n);
  }

  // ユーザーメッセージを会話履歴に追加する（同期処理）
  void addUserMessage(String userInput) {
    final userMessage = Message(content: userInput, isUser: true);
    _conversationHistory.add(userMessage);
    _messageCount++; // ユーザーメッセージは常にカウント
  }

  // AIの応答を生成し、会話履歴に追加する（非同期処理）
  Future<String> generateAndAddAIResponse({String? initialContextOverride, BuildContext? context}) async {
    // APIに渡す現在のユーザー入力を準備
    String contextForAPI;
    if (initialContextOverride != null) {
      contextForAPI = initialContextOverride;
    } else if (_conversationHistory.isNotEmpty && _conversationHistory.last.isUser) {
      contextForAPI = _conversationHistory.last.content;
    } else {
      // 履歴が空か、最後がユーザーメッセージでない場合
      contextForAPI = ''; 
    }

    // エラーハンドリングを改善したAPI呼び出し
    String aiResponse;
    try {
      // BuildContextを渡してエラーダイアログを表示できるようにする
      aiResponse = await _generateResponseFromAPI(contextForAPI, context: context);
    } catch (e) {
      print('Error generating response from backend: $e');
      
      // エラータイプに基づいたメッセージを表示
      if (context != null) {
        final errorHandlingService = ErrorHandlingService();
        final errorType = errorHandlingService.getErrorTypeFromException(e);
        
        // エラーダイアログはすでに_generateResponseFromAPI内で表示されている可能性がある
        // ここではメッセージのみ取得
        aiResponse = errorHandlingService.getErrorMessage(errorType);
      } else {
        // コンテキストがない場合はデフォルトメッセージ
        aiResponse = 'AIの応答取得中にエラーが発生しました。しばらくしてからもう一度お試しください。';
      }
    }
    
    // 応答を会話履歴に追加
    final aiMessage = Message(content: aiResponse, isUser: false);
    _conversationHistory.add(aiMessage);
    
    // 初回の気分選択と質問応答が完了したかどうかの判定
    if (!_isInitialExchangeComplete && _conversationHistory.length >= 2) {
      _isInitialExchangeComplete = true;
    }
    
    return aiResponse;
  }

  // 会話を開始する
  Future<String> startConversation(String initialReflection, String mood, {BuildContext? context}) async {
    _conversationHistory.clear();
    _messageCount = 0; // Reset count
    _isInitialExchangeComplete = false;
    _currentMood = mood;
    
    // ユーザーが最初の振り返りを入力した場合、それを最初のユーザーメッセージとして追加
    if (initialReflection.isNotEmpty) {
      final userMessage = Message(content: initialReflection, isUser: true);
      _conversationHistory.add(userMessage);
      _messageCount = 1; // First user message
    }
    
    // AIの最初の応答を生成。BuildContextを渡してエラーハンドリングを改善
    return await generateAndAddAIResponse(
      initialContextOverride: initialReflection,
      context: context,
    );
  }
  
  // GPT-4oにメッセージを送信して応答を取得する内部メソッド
  Future<String> _generateResponseFromAPI(String userInput, {BuildContext? context}) async {
    // デバッグ用に強制的にモック応答を返す場合はここをtrueにする
    bool useDebugMockResponse = false;
    if (useDebugMockResponse && kDebugMode) {
      return _getMockResponse(_currentMood, _messageCount);
    }

    
    // タイムアウト設定
    const timeoutDuration = Duration(seconds: 30);

    try {
      // タイムアウト付きのAPIリクエスト
      final response = await http.post(
        Uri.parse(_chatCompletionsBaseUrl),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'model': 'gpt-4o',
          'messages': _buildMessages(userInput),
          'max_tokens': 200, 
          'temperature': 0.7,
        }),
      ).timeout(timeoutDuration, onTimeout: () {
        // タイムアウトの場合
        throw TimeoutException('応答の取得がタイムアウトしました。ネットワーク環境を確認してください。');
      });

      if (response.statusCode == 200) {
        try {
          final data = jsonDecode(response.body);
          return data['choices'][0]['message']['content'];
        } catch (e) {
          throw Exception('レスポンスの解析に失敗しました。');
        }
      } else {
        // ステータスコードに基づくエラータイプの判定
        final errorHandlingService = ErrorHandlingService();
        final errorType = errorHandlingService.getErrorTypeFromStatusCode(response.statusCode);
        
        throw Exception('${errorHandlingService.getErrorMessage(errorType)} (ステータスコード: ${response.statusCode})');
      }
    } on TimeoutException catch (e) {
      if (context != null) {
        ErrorHandlingService().showErrorDialog(
          context, 
          ErrorType.timeout,
          onRetry: () async {
            // 再試行ロジックを実装する場所
          },
        );
      }
      return '応答の取得に時間がかかっています。ネットワーク環境を確認して、もう一度お試しください。';
    } on http.ClientException catch (e) {
      if (context != null) {
        ErrorHandlingService().showErrorDialog(
          context, 
          ErrorType.network,
          onRetry: () async {
            // 再試行ロジックを実装する場所
          },
        );
      }
      return 'ネットワークに接続できません。インターネット接続を確認して、もう一度お試しください。';
    } catch (e) {
      if (kDebugMode && useDebugMockResponse) {
        return _getMockResponse(_currentMood, _messageCount);
      }
      
      if (context != null) {
        final errorHandlingService = ErrorHandlingService();
        final errorType = errorHandlingService.getErrorTypeFromException(e);
        errorHandlingService.showErrorDialog(
          context, 
          errorType,
          onRetry: () async {
            // 再試行ロジックを実装する場所
          },
        );
      }
      
      return 'エラーが発生しました。しばらくしてからもう一度お試しください。';
    }
  }

  // APIリクエスト用のメッセージ配列を構築
  List<Map<String, String>> _buildMessages(String contextForAPI) {
    final messages = <Map<String, String>>[];
    
    // システムプロンプトを追加
    messages.add({
      'role': 'system',
      'content': _buildSystemPrompt(),
    });
    
    // 会話履歴から最大10個前までのメッセージを追加（最新の入力は除く）
    final historyToInclude = _conversationHistory.length > 1 
        ? _getLastMessages(_conversationHistory.sublist(0, _conversationHistory.length - 1), 10)
        : [];
    
    for (final message in historyToInclude) {
      messages.add({
        'role': message.isUser ? 'user' : 'assistant',
        'content': message.content,
      });
    }
    
    // APIに渡すコンテキストとなるユーザー入力（または初回リフレクション）を追加
    // _messageCount は addUserMessage を呼び出した後の会話履歴の全長を指す。
    // startConversationから呼ばれた場合、initialReflectionが空ならaddUserMessageは呼ばれず、_messageCountは0。
    // initialReflectionが有ればaddUserMessageが呼ばれ、_messageCountは1。
    // 通常の会話フローでは、addUserMessageが呼ばれた直後なので、_conversationHistory.lastがユーザー入力。
    
    // 初回ターンかどうかを判断（システムプロンプト以外のメッセージがまだない、またはユーザーメッセージが1つだけ）
    final bool isFirstUserTurn = _conversationHistory.where((m) => m.isUser).length <= 1 && 
                                 (_conversationHistory.isEmpty || _conversationHistory.first.content == contextForAPI) ;
                                 //↑ startConversationでreflectionが空の場合、historyは空でcontextForAPIは空
                                 // reflectionが有る場合、history.first.content == contextForAPI
                                 // 通常会話の場合、history.last.content == contextForAPI

    if (isFirstUserTurn) {
      // 初回メッセージ（気分選択直後）の場合は気分情報を含めたプロンプトを使用
      messages.add({
        'role': 'user',
        'content': _buildUserPrompt(contextForAPI, _currentMood), 
      });
    } else {
      // 2回目以降は通常のメッセージとして追加
      messages.add({
        'role': 'user',
        'content': contextForAPI, 
      });
    }
    
    return messages;
  }
  
  // システムプロンプトの構築（GPT-4o mini最適化版）
  String _buildSystemPrompt() {
    final characterId = _getSelectedCharacterId();
    final characterInfo = _getCharacterInfo(characterId);
    
    return '''
# ROLE
あなたは睡眠前の心の整理をサポートする${characterInfo['name']}です。

# TASK
就寝前のユーザーの感情や振り返りに対して、高い共感性で応答し、心を軽やかにするサポートをしてください。

# CONSTRAINTS
- 応答は必ず85文字以上120文字以内
- 7回程度の短い会話を想定
- ${characterInfo['speech_style']}
- 医療アドバイス、説教、過度な楽観主義は禁止

# RESPONSE_STRATEGY
## 共感技法（必須）
1. ミラーリング：ユーザーの言葉を反映
2. バリデーション：感情を正当化
3. アクティブリスニング：感情を言語化

## アプローチパターン（毎回異なる手法を選択）
- 共感的傾聴：感情を受け止める
- 心理的洞察：深い意味を提示
- 視点転換：別角度から提案
- 自己肯定：強みを認める
- 具体的質問：穏やかな探求
- マインドフルネス：今に意識を向ける
- 小さな喜び：日常の幸せに注目
- 自己受容：完璧でなくても自分を許す
- 感謝の視点：感謝に目を向ける
- 成長視点：学びや成長を見出す
- 未来志向：明日への希望
- 身体感覚：リラックス促進

## 睡眠促進要素（会話終盤）
- 深い呼吸の提案
- 穏やかな言葉選び
- 身体の緩和
- 心地よいイメージ

# OUTPUT_FORMAT
[共感表現] + [洞察・提案] + [自然な質問] の構成で、120文字以内で応答してください。
'''
  }

  // ユーザープロンプトの構築（GPT-4o mini最適化版）
  String _buildUserPrompt(String userInput, String mood) {
    final moodMap = {
      '喜': '喜び・嬉しさ',
      '怒': '怒り・イライラ', 
      '哀': '悲しみ・寂しさ',
      '楽': '楽しさ・充実感',
      '疲': '疲労・消耗感',
      '焦': '焦り・不安'
    };
    
    final moodDescription = moodMap[mood] ?? '複雑な感情';

    return '''
# USER_INPUT
気分: $moodDescription
振り返り: "$userInput"

# INSTRUCTION
1. "$moodDescription"の感情に具体的に共感
2. 振り返り内容の意味や価値を認める
3. 自然な質問で会話を促進
4. 120文字以内で応答

上記の制約とアプローチパターンに従って応答してください。
''';
  }

  // 選択されたキャラクターIDを取得
  int _getSelectedCharacterId() {
    try {
      // 外部から設定された場合はそれを使用
      if (_selectedCharacterId != null) {
        return _selectedCharacterId!;
      }
      
      // デフォルト値を返す
      return 0; // 左上の犬アイコン
    } catch (e) {
      return 0;
    }
  }
  
  // 選択されたキャラクターIDを設定
  int? _selectedCharacterId;
  void setSelectedCharacterId(int characterId) {
    _selectedCharacterId = characterId;
  }
  
  // キャラクター情報を取得
  Map<String, String> _getCharacterInfo(int characterId) {
    // Characterクラスからキャラクター情報を取得
    final character = Character.getCharacterById(characterId);
    
    return {
      'name': character.name,
      'speech_style': '${character.personality}な性格で話してください。'
    };
  }

  // 会話履歴を要約する
  Future<String> summarizeConversation() async {
    if (_conversationHistory.isEmpty) {
      return "会話履歴がありません。";
    }

    // デバッグ用に強制的にモック応答を返す場合はここをtrueにする
    bool useDebugMockSummary = false;
    if (useDebugMockSummary && kDebugMode) {
      return "（モック）ユーザーは${_currentMood}な気分で、いくつかのやり取りをしました。";
    }

    final List<Map<String, String>> messagesForSummary = [];

    // 要約用のシステムプロンプト
    messagesForSummary.add({
      'role': 'system',
      'content': '''あなたはユーザーの心理カウンセラーです。以下の会話を元に、二部構成のまとめを作成してください。

このまとめは、ユーザーが後で振り返る際に参考になるよう、以下の2つのパートに分けて作成してください：

パート１：【ユーザーの振り返り】
- ユーザーが話した内容や悩み、感情を簡潔にまとめてください。
- 「ユーザーさんは、〜について悩んでいました」のような形式で、第三者的な視点でまとめてください。
- 事実と感情に焦点を当て、ユーザーの言葉を要約してください。

パート２：【アドバイス】
- ユーザーに対する実用的なアドバイスを記録してください。
- 具体的な行動提案や実践可能なヒントを含めてください。
- 前向きな視点や小さな成功体験を強調するメッセージを含めてください。

全体で100文字から150文字程度でまとめてください。各パートは明確に区別し、読みやすく、実用的な内容にしてください。医療的なアドバイスや診断は避け、ユーザーの自己成長や心の健康をサポートする内容に焦点を当ててください。''',
    });

    // 全ての会話履歴を要約のコンテキストとして追加
    for (final message in _conversationHistory) {
      messagesForSummary.add({
        'role': message.isUser ? 'user' : 'assistant',
        'content': message.content,
      });
    }

    try {
      final response = await http.post(
        Uri.parse(_summarizeBaseUrl), // Use the new backend URL for summarization
        headers: {
          'Content-Type': 'application/json',
          // Authorization header is removed; backend will handle API key
        },
        body: jsonEncode({
          'model': 'gpt-4o', // Backend might override or use this
          'messages': messagesForSummary,
          'max_tokens': 100, 
          'temperature': 0.5,
          // Potentially pass other relevant info to backend if needed
          // e.g., 'userId': 'some_user_id', 'mood': _currentMood
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['choices'] != null && data['choices'].isNotEmpty) {
          return data['choices'][0]['message']['content'].trim();
        } else {
          throw Exception('Failed to parse summary from API response: "choices" field is missing or empty.');
        }
      } else {
        throw Exception('Failed to generate summary from backend: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      if (kDebugMode && useDebugMockSummary) { // Fallback to mock only if debug mock is globally enabled
         return "（モック）ユーザーは${_currentMood}な気分で、いくつかのやり取りをしました。";
      }
      // Consider a more user-friendly error message for production
      throw Exception('会話の要約中にエラーが発生しました。しばらくしてからもう一度お試しください。');
    }
  }

  // デバッグ用のモック応答（APIキーがない場合や開発時に使用）
  String _getMockResponse(String mood, int messageCount) {
    // 会話の回数に応じて異なる応答を返す
    if (messageCount == 1) {
      // 初回メッセージの応答
      switch (mood) {
case '喜':
          return '今日の喜びを言葉にしてくれてありがとう。その小さな幸せを感じられる心は、あなたの大切な宝物です。もう少し、その嬉しかった瞬間について教えてもらえますか？';
        case '怒':
          return '怒りの感情を正直に表現してくれたことに感謝します。その感情は、あなたの大切な価値観や境界線を教えてくれるものかもしれません。どんなことが特に気になりましたか？';
        case '哀':
          return '悲しい気持ちを言葉にするのは勇気のいることです。その感情もあなたの一部として、ただそこにあることを認めてあげてください。今、一番心に引っかかっていることはなんですか？';
        case '楽':
          return '楽しい時間を過ごせたことが伝わってきます。そういった瞬間を大切にできるあなたの感性は素晴らしいですね。その楽しい経験から、どんな発見がありましたか？';
        case '疲':
          return 'お疲れさまでした。今日一日、あなたはよく頑張りました。疲れを感じるということは、何かに真剣に向き合った証でもあります。今日のどんな部分が特に疲れましたか？';
        case '焦':
          return '焦りを感じていることを共有してくれてありがとう。その感情は、あなたが大切にしていることへの思いの表れかもしれませんね。どんなことに対して焦りを感じていますか？';
        default:
          return '今日の気持ちを共有してくれてありがとう。一日の終わりに自分の感情と向き合うことは、とても大切なことです。今日はどんな出来事が印象に残っていますか？';
      }
    } else if (messageCount == 2) {
      // 2回目のメッセージの応答（深掘りの質問）
      return 'なるほど、そう感じたのですね。それについてもう少し考えてみると、何か気づくことはありますか？あなたにとって、それはどんな意味を持っていますか？';
    } else if (messageCount == 3) {
      // 3回目のメッセージの応答（深堀りと心の整理を促す）
      return 'そういう捕らえ方ができるんですね。とても興味深い視点です。その経験から学んだことを少しだけ深呼吸しながら考えてみましょう。心に残っていることは何ですか？';
    } else if (messageCount == 4) {
      // 4回目のメッセージの応答（まとめと睡眠を促すアドバイス）
      return '今日の振り返りを通して、色々な気づきがあったようですね。お話を聞かせてくれてありがとう。床に入る前に、腕や足の緩和を感じながら、ゆっくりと深呼吸をしてみませんか。心も体も穏やかになりますよ。';
    } else {
      // 5回目以降のメッセージの応答（睡眠に向けた穏やかな終結）
      return 'この会話を通して、あなたの心が少し穏やかになったなら嬉しいです。これから眠りにつく準備をしましょう。穏やかな波の音や、優しい月明かりの下で、あなたの体が少しずつ重くなっていくのを感じてください。おやすみなさい。';
    }
  }
}
