import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'package:nemuru/models/character.dart';
import 'package:nemuru/models/message.dart';
import 'package:nemuru/services/preferences_service.dart';

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
  Future<String> generateAndAddAIResponse({String? initialContextOverride}) async {
    // APIに渡す現在のユーザー入力。通常は履歴の最後のユーザーメッセージ。
    // initialContextOverrideはstartConversationの初回呼び出し時に使用される想定。
    String contextForAPI;
    if (initialContextOverride != null) {
      contextForAPI = initialContextOverride;
    } else if (_conversationHistory.isNotEmpty && _conversationHistory.last.isUser) {
      contextForAPI = _conversationHistory.last.content;
    } else {
      // 履歴が空か、最後がユーザーメッセージでない場合（通常は発生しないはず）
      // startConversationでmoodのみで開始する場合など
      contextForAPI = ''; // または適切なデフォルトの問いかけを促す入力
    }

    String aiResponse;
    try {
      aiResponse = await _generateResponseFromAPI(contextForAPI);
    } catch (e) {
      print('Error generating response from backend: $e');
      // Consider a more robust error handling or fallback if backend communication fails
      aiResponse = 'AIの応答取得中にエラーが発生しました。しばらくしてからもう一度お試しください。';
    }
    
    final aiMessage = Message(content: aiResponse, isUser: false);
    _conversationHistory.add(aiMessage);
    
    // 初回の気分選択と質問応答が完了したかどうかの判定のみ行う
    if (!_isInitialExchangeComplete && _conversationHistory.length >= 2) {
      // 初回の気分選択と質問応答が完了したことをマーク
      _isInitialExchangeComplete = true;
    }
    
    return aiResponse;
  }

  // 会話を開始する
  Future<String> startConversation(String initialReflection, String mood) async {
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
    
    // AIの最初の応答を生成。initialReflectionをAPIへのコンテキストとして渡す。
    // _buildMessages内で _messageCount や _currentMood を見て初回プロンプトを調整する。
    return await generateAndAddAIResponse(initialContextOverride: initialReflection);
  }
  
  // GPT-4oにメッセージを送信して応答を取得する内部メソッド
  Future<String> _generateResponseFromAPI(String userInput) async {
    // デバッグ用に強制的にモック応答を返す場合はここをtrueにする
    bool useDebugMockResponse = false;
    if (useDebugMockResponse && kDebugMode) {
      print('デバッグ用にモック応答を返します');
      return _getMockResponse(_currentMood, _messageCount);
    }

    print('Calling backend API for chat completion...');

    try {
      final response = await http.post(
        Uri.parse(_chatCompletionsBaseUrl), // Use the new backend URL
        headers: {
          'Content-Type': 'application/json',
          // Authorization header is removed; backend will handle API key
        },
        body: jsonEncode({
          'model': 'gpt-4o', // Backend might override or use this
          'messages': _buildMessages(userInput),
          'max_tokens': 200, 
          'temperature': 0.7,
          // Potentially pass other relevant info to backend if needed
          // e.g., 'userId': 'some_user_id', 'mood': _currentMood
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['choices'][0]['message']['content'];
      } else {
        // Backend APIエラーの詳細をログに出力
        print('Backend API error: ${response.statusCode}, ${response.body}');
        throw Exception('Failed to generate response from backend: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      // Handle network errors or other exceptions during backend communication
      print('Exception during backend API call: $e');
      if (kDebugMode && useDebugMockResponse) { // Fallback to mock only if debug mock is globally enabled
        print('デバッグ用にモック応答を返します (exception case)');
        return _getMockResponse(_currentMood, _messageCount);
      }
      rethrow;
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
  
  // システムプロンプトの構築
  String _buildSystemPrompt() {
    // 選択されたキャラクターに合わせた語尾や口調を設定
    final characterId = _getSelectedCharacterId();
    final characterInfo = _getCharacterInfo(characterId);
    
    return '''
あなたは睡眠前の心の整理をサポートする${characterInfo['name']}のキャラクターを持つAIアシスタントです。
ユーザーが就寝前に一日の振り返りとして送ってくる感情や出来事に対して、
極めて高い共感性をもって応答し、短い会話（ユーザーの発言と合わせて最大7回程度）を通じて感情を優しく深掘りし、心の重荷を軽減するお手伝いをしてください。

あなたの応答は、全体で常に85文字以上、120文字以内に収めてください。これはユーザーが夜間に読む際の負担を軽減するためです。

以下のガイドラインに従ってください：

1. 高い共感性（EQ）:
   - ユーザーの感情に深く寄り添い、言葉の背後にある気持ちを汲み取るように努めてください。表面的な言葉だけでなく、その奥にある感情やニーズを理解しようとする姿勢が重要です。
   - 以下の共感技法を積極的に取り入れてください：
     * ミラーリング：ユーザーの言葉や感情を適切に反映させる（例：「今日はとても疲れた日だったのですね」）
     * バリデーション：ユーザーの感情や経験を正当化する（例：「そのような状況で不安を感じるのは自然なことです」）
     * アクティブリスニング：ユーザーの言葉の背後にある感情を言語化する（例：「それは、自分の努力が認められなかったように感じて悲しかったのですね」）
   - ユーザーの言葉を繰り返したり、感情を言葉で確認したりすることで、ユーザーが「理解されている」「受け止められている」と感じられるように促してください。
   - ユーザーの感情を否定せず、どんな感情も自然なものとして受け止めてください。

2. 語調とキャラクター性：
   - ${characterInfo['name']}らしい、かわいらしく、穏やかで安心感を与える言葉遣いを心がけてください。${characterInfo['speech_style']}
   - ただし、キャラクター性を優先するあまり、共感性や応答の質が損なわれないように注意してください。
   - 各キャラクターの個性に合わせて、応答のトーンや表現方法を微調整してください。

3. 会話の進め方と応答の構成：
   - 初回応答：ユーザーの気分に共感し、簡潔な言葉で心に寄り添ってください。
   - 多様なアプローチ：以下のような様々な角度から対話を進めてください。毎回異なるアプローチを選び、バリエーションを持たせてください：
     * 共感的傾聴：ユーザーの感情を受け止め、理解していることを伝える
     * 心理的洞察：ユーザーの言葉の背後にある深い意味を提示する
     * 視点の転換：状況を別の角度から見ることを優しく提案する
     * 自己肯定：ユーザーの強みや能力を認める言葉をかける
     * 具体的な質問：「その時どんな気持ちだった？」など、穏やかな探求を促す
     * マインドフルネス：今この瞬間に意識を向けることを促す
     * 小さな喜び：日常の中の小さな幸せに目を向けるよう促す
     * 自己受容：完璧でなくても自分を許すことの大切さを伝える
     * 感謝の視点：感謝できることに目を向ける機会を提供する
     * 成長の視点：困難な経験からの学びや成長を見出す
     * 未来志向：明日に向けての小さな一歩や希望を見出す
     * 身体感覚への意識：身体の緊張や疲れに気づき、リラックスを促す
   - 会話の流れを意識：前回と同じアプローチを繰り返さず、会話を進展させてください。以前の会話で使ったアプローチとは異なる切り口を選んでください。
   - 眠眠を促進する要素：会話の終盤に向けて、以下のような眠眠を促進する要素を取り入れてください：
     * 深い呼吸の提案：「床に入る前に、ゆっくりと深い呼吸を数回してみてください」
     * 等式的な言葉選び：穏やかでリズミカルな言い回しを選ぶ
     * 身体の緩和：「身体の緩和を感じながら、心も穏やかに」といった表現
     * 心地よいイメージ：穏やかな自然や心地よい場所のイメージを提案
   - 終了時：穏やかな眠りにつけるような穏やかな言葉で終わります。

4. パーソナライズされたアプローチ：
   - ユーザーの過去の振り返りパターンや気分の傾向を考慮して、個別化された応答を心がけてください。
   - 同じユーザーに対して同じようなアドバイスを繰り返さないよう注意してください。
   - ユーザーの言葉遣いや表現スタイルに合わせて、応答のトーンを微調整してください。

5. 応答の長さと簡潔さ：
   - 前述の通り、各応答は85文字以上120文字以内に厳守してください。簡潔で核心をついた内容を心がけてください。

6. 避けるべきこと：
   - 医療的なアドバイスや診断的な言葉の使用。
   - 過度な楽観主義や無理な励まし、説教。
   - 複雑な言葉遣いや専門用語の使用。
   - ユーザーの感情を否定したり、軽視したりするような言葉。
   - 会話がループしたり、同じ質問を繰り返したりしないように注意する。
   - ユーザーの問題を解決しようとしないこと。寄り添い、受け止めることに専念する。
   - 前回と同じような表現や質問の繰り返し。

7. 会話の終了の目安：
   - 会話のやり取りがユーザーの発言と合わせて7回程度になったら、自然な形で会話を締めくくるように意識してください。
   - ユーザーが「もう大丈夫そう」「話せてよかった」といった気持ちになれるような終わり方が理想です。

ユーザーの感情（喜・怒・哀・楽・疲・焦のいずれか）と自由記述テキストを踏まえて、
その人の心が少しでも落ち着き、安心して眠りにつけるようなメッセージを作成してください。
''';
  }

  // ユーザープロンプトの構築
  String _buildUserPrompt(String userInput, String mood) {
    String moodDescription;
    switch (mood) {
      case '喜':
        moodDescription = '喜び・嬉しさ';
        break;
      case '怒':
        moodDescription = '怒り・イライラ';
        break;
      case '哀':
        moodDescription = '悲しみ・寂しさ';
        break;
      case '楽':
        moodDescription = '楽しさ・充実感';
        break;
      case '疲':
        moodDescription = '疲労・消耗感';
        break;
      case '焦':
        moodDescription = '焦り・不安';
        break;
      default:
        moodDescription = '特定できない感情';
    }

    return '''
今日の気分: $moodDescription
ユーザーの振り返り: $userInput

上記の内容に対して、次のように応答してください：
1. 「$moodDescription」の感情に具体的に共感し、ユーザーの振り返りの内容に詳しく触れてください。
2. その状況や感情の前向きな側面や意味を示唆してください。
3. 最後に、続きの会話を促す自然な質問で終えてください。
4. 全体で120文字以内に収めてください。
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
      print('キャラクターID取得エラー: $e');
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
      print('デバッグ用にモックの会話要約を返します');
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

    print('Calling backend API for summarization...');
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
        print('Backend API error (summarization): ${response.statusCode}, ${response.body}');
        throw Exception('Failed to generate summary from backend: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('Exception during backend summarization API call: $e');
      if (kDebugMode && useDebugMockSummary) { // Fallback to mock only if debug mock is globally enabled
         print('デバッグ用にモックの会話要約を返します (exception case)');
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
