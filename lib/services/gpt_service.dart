import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:nemuru/models/character.dart';
import 'package:nemuru/models/message.dart';
import 'package:nemuru/models/user_profile.dart';
import 'package:nemuru/services/error_handling_service.dart';

class GPTService {
  // バックエンドAPIのエンドポイント（Supabase Edge Functions）
  static const String _chatCompletionsBaseUrl = 'https://ldellkrfbgzrheisjret.supabase.co/functions/v1/chat-completion';
  static const String _summarizeBaseUrl = 'https://ldellkrfbgzrheisjret.supabase.co/functions/v1/chat-completion'; // 同じエンドポイントを使用

  // 会話履歴を保持
  final List<Message> _conversationHistory = [];
  int _messageCount = 0; // 実際の会話カウント（初回の気分選択と質問応答を除く）
  bool _isInitialExchangeComplete = false; // 初回の気分選択と質問応答が完了したか
  String _currentMood = '';
  UserProfile? _userProfile; // ユーザープロファイル
  
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

  // ユーザープロファイルを設定
  void setUserProfile(UserProfile profile) {
    _userProfile = profile;
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
      // エラータイプに基づいたメッセージを表示
      if (context != null && context.mounted) {
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
    // デバッグ用モック応答（必要時にコメントアウトを解除）
    // if (kDebugMode) {
    //   return _getMockResponse(_currentMood, _messageCount);
    // }

    
    // タイムアウト設定
    const timeoutDuration = Duration(seconds: 30);

    try {
      // タイムアウト付きのAPIリクエスト
      final response = await http.post(
        Uri.parse(_chatCompletionsBaseUrl),
        headers: {
          'Content-Type': 'application/json',
          // Firebase Functionsでは認証ヘッダー不要（Functions内でAPIキー処理）
        },
        body: jsonEncode({
          'model': 'gpt-4o-mini', // Firebase Functions用にgpt-4o-miniに変更
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
    } on TimeoutException {
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
    } on http.ClientException {
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
      // デバッグ用モック応答（必要時にコメントアウトを解除）
      // if (kDebugMode) {
      //   return _getMockResponse(_currentMood, _messageCount);
      // }
      
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
    
    final characterName = characterInfo['name'] ?? 'キャラクター';
    final speechStyle = characterInfo['speech_style'] ?? '優しい語調';
    final empathyStyle = characterInfo['empathy_style'] ?? '';
    final questionStyle = characterInfo['question_style'] ?? '';
    final adviceStyle = characterInfo['advice_style'] ?? '';
    final specialty = characterInfo['specialty'] ?? '';
    
    // パーソナライゼーション情報を追加
    final personalizationContext = _userProfile?.getPersonalizationContext() ?? '';
    
    return '''
# ROLE
あなたは睡眠前の心の整理をサポートする${characterName}です。

# CHARACTER_PROFILE
- 性格: $speechStyle
- 得意分野: $specialty
- 共感スタイル: $empathyStyle
- 質問スタイル: $questionStyle  
- アドバイススタイル: $adviceStyle

# USER_CONTEXT
$personalizationContext

# TASK
就寝前のユーザーの感情や振り返りに対して、あなたの特性を活かした共感性で応答し、心を軽やかにするサポートをしてください。

# CONSTRAINTS
- 応答は必ず80文字以上120文字以内（自然な会話を優先）
- 5回程度の短い会話を想定
- CHARACTER_PROFILEの特性を活かした応答をする
- 医療アドバイス、説教、過度な楽観主義は禁止
- USER_CONTEXTの情報を参考に、適切な口調と親しみやすさで対応
- あなたの得意分野を活かして相手の話を引き出す

# RESPONSE_STRATEGY
## 共感技法（必須）
1. ミラーリング：ユーザーの言葉を反映
2. バリデーション：感情を正当化
3. アクティブリスニング：感情を言語化

## アプローチパターン（会話の流れに応じて自然に選択）
### 会話初期（1-3往復）
- 共感的傾聴：「そうだったんですね」「それはつらかったでしょうね」
- 感情の言語化：「○○という気持ちなんですね」
- 具体的質問：「どんなことがあったんですか？」

### 会話中期（3-4往復）
- 心理的洞察：「もしかして○○かもしれませんね」
- 視点転換：「でも、それって○○ってことでもありますよね」
- 自己肯定：「○○したあなたはすごいですよ」

### 会話終盤（4-5往復）
- マインドフルネス：「今夜はゆっくり休んでくださいね」
- 身体感覚：「深呼吸して、身体の力を抜いてみましょう」
- 明日への希望：「明日はきっといい日になりますよ」

## 睡眠促進要素（会話終盤）
- 深い呼吸の提案
- 穏やかな言葉選び
- 身体の緩和
- 心地よいイメージ

# OUTPUT_FORMAT
- 会話の流れを重視し、自然な応答を心がける
- 必ずしも質問で終わらなくてよい（共感や肯定で終わることもOK）
- 120文字以内で、温かみのある言葉で応答
''';
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

    // 会話の流れに応じた指示を追加
    String conversationPhaseInstruction = '';
    if (_messageCount <= 2) {
      conversationPhaseInstruction = '''

# CONVERSATION_PHASE: 会話初期
- まずは共感を示し、安心できる空間を作る
- ユーザーの話をもっと聞きたいという姿勢を示す''';
    } else if (_messageCount <= 3) {
      conversationPhaseInstruction = '''

# CONVERSATION_PHASE: 会話中期
- より深い理解を示し、新しい視点を提供
- ユーザーが自分で気づきを得られるようサポート''';
    } else {
      conversationPhaseInstruction = '''

# CONVERSATION_PHASE: 会話終盤
- リラックスと眠りに向けた準備を促す
- 今日の振り返りを肯定的にまとめる''';
    }

    return '''
# USER_INPUT
気分: $moodDescription
振り返り: "$userInput"
$conversationPhaseInstruction

# INSTRUCTION
1. "$moodDescription"の感情に寄り添う
2. ユーザーの言葉を丁寧に受け止める
3. 会話の流れに応じた自然な応答
4. 120文字以内で、温かみのある言葉で

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
      'speech_style': character.personality,
      'empathy_style': character.empathyStyle,
      'question_style': character.questionStyle,
      'advice_style': character.adviceStyle,
      'specialty': character.specialty,
    };
  }

  // 会話履歴を要約する
  Future<String> summarizeConversation() async {
    if (_conversationHistory.isEmpty) {
      return "会話履歴がありません。";
    }

    // デバッグ用モック応答（必要時にコメントアウトを解除）
    // if (kDebugMode) {
    //   final responses = ["今日の出来事や感情について話し、穏やかな気持ちで眠りにつけるよう励まされた"];
    //   return responses[0];
    // }

    final List<Map<String, String>> messagesForSummary = [];

    // 要約用のシステムプロンプト
    messagesForSummary.add({
      'role': 'system',
      'content': '''以下の会話を50〜100文字程度で簡潔に要約してください。

要約のルール：
- アドバイスは不要です
- 何について話したかの概要のみをまとめてください
- 「〜について話した」「〜を相談した」というシンプルな形式で
- 【】や見出しは使わないでください

例：
「仕事のストレスについて相談し、リラックス方法を教えてもらった」
「今日の嬉しい出来事を共有し、その気持ちを大切にするよう励まされた」
「疲れを感じていることを話し、休息の大切さについて話し合った」''',
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
          'model': 'gpt-4o-mini', // Firebase Functions用にgpt-4o-miniに変更
          'messages': messagesForSummary,
          'max_tokens': 150, 
          'temperature': 0.5,
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
      // デバッグ用モック応答（必要時にコメントアウトを解除）
      // if (kDebugMode) {
      //   return "（モック）ユーザーは${_currentMood}な気分で、いくつかのやり取りをしました。";
      // }
      // Consider a more user-friendly error message for production
      throw Exception('会話の要約中にエラーが発生しました。しばらくしてからもう一度お試しください。');
    }
  }

  // デバッグ用のモック応答（APIキーがない場合や開発時に使用）
}
