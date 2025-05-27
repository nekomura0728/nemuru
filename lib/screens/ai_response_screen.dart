import 'package:flutter/material.dart';
import 'package:nemuru/theme/app_theme.dart';
import 'package:nemuru/services/gpt_service.dart';
import 'package:provider/provider.dart';
import 'package:nemuru/services/preferences_service.dart';
import 'package:nemuru/models/message.dart';
import 'package:nemuru/services/chat_log_service.dart';
import 'package:nemuru/services/subscription_service.dart';
import 'package:nemuru/widgets/character_image_painter.dart';
import 'package:nemuru/models/chat_log.dart'; // ChatLogモデルをインポート
import 'package:nemuru/models/character.dart';

// チャットの進行状況を示すEnum
enum ChatPhase {
  moodSelection, // 気分選択中
  chatting,      // 会話中
  ended,         // 会話終了
}

class AIResponseScreen extends StatefulWidget {
  final ChatLog? chatLog; // Existing log to display/continue
  final int? characterId; // For new chats (if chatLog is null)
  final String? mood; // For new chats (if chatLog is null)
  final String? initialReflection; // For new chats (if chatLog is null, from check-in or similar)

  const AIResponseScreen({
    super.key,
    this.chatLog,
    this.characterId,
    this.mood,
    this.initialReflection,
  });

  @override
  State<AIResponseScreen> createState() => _AIResponseScreenState();
}

class _AIResponseScreenState extends State<AIResponseScreen> with SingleTickerProviderStateMixin {
  bool _isLoading = true;
  bool _isSending = false;
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  late AnimationController _animationController;
  late Animation<double> _fadeInAnimation;
  
  // GPTサービスのインスタンス
  final GPTService _gptService = GPTService();
  late ChatLogService _chatLogService; // ChatLogServiceのインスタンス

  // UIと状態管理のための変数
  ChatPhase _currentPhase = ChatPhase.chatting; // 最初からチャットフェーズに設定
  String? _selectedMood; // ユーザーが選択した気分
  String? _currentLogId; // 現在のチャットログID
  String? _initialReflection; // チェックイン画面からの振り返りテキスト

  // 気分の選択肢 (実際のアプリでは外部から取得または定数として定義)
  final List<Map<String, dynamic>> _moods = [
    {'label': '喜', 'value': '喜', 'color': AppTheme.joyColor},
    {'label': '怒', 'value': '怒', 'color': AppTheme.angerColor},
    {'label': '哀', 'value': '哀', 'color': AppTheme.sadnessColor},
    {'label': '楽', 'value': '楽', 'color': AppTheme.pleasureColor},
    {'label': '疲', 'value': '疲', 'color': AppTheme.tiredColor},
    {'label': '焦', 'value': '焦', 'color': AppTheme.anxietyColor},
  ];
  
  // 会話の終了フラグ (手動終了または自動終了を管理)
  bool _isConversationOver = false; // 手動終了用のフラグ
  
  // 会話が終了条件を満たしているかチェック
  bool get _shouldEndConversation {
    final subscriptionService = Provider.of<SubscriptionService>(context, listen: false);
    // プレミアムユーザーは送信30回まで、無料ユーザーは送信7回まで
    final maxTurns = subscriptionService.isPremium
        ? SubscriptionService.premiumConversationTurns
        : SubscriptionService.freeConversationTurns;
    return _gptService.messageCount >= maxTurns;
  }
  
  // 現在のユーザー送信回数を取得
  int get _currentConversationCount => _gptService.messageCount;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fadeInAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeIn,
    ));
    
    // ChatLogServiceを取得
    _chatLogService = Provider.of<ChatLogService>(context, listen: false);
    
    // 選択されたキャラクターIDを設定
    final prefsService = Provider.of<PreferencesService>(context, listen: false);
    final selectedCharacterId = prefsService.selectedCharacterId;
    print('AIResponseScreen: 選択されたキャラクターID: $selectedCharacterId');
    _gptService.setSelectedCharacterId(selectedCharacterId);
    
    // Initialize based on constructor parameters
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.chatLog != null) {
        final log = widget.chatLog!;
        if (log.summary != null) {
          // This log is already completed and summarized. 
          // AIResponseScreen is for active chats. Display an error or navigate away.
          print("Error: Attempted to open an already summarized chat log in AIResponseScreen.");
          if (mounted) {
            setState(() => _isLoading = false);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('このチャットは既に終了し、まとめられています。')),
            );
            // Optionally, navigate back or to a log viewer screen
            // Navigator.of(context).pop(); 
          }
          return;
        }

        // Log exists but not summarized yet (e.g., from check-in, or interrupted)
        _currentLogId = log.id;
        _selectedMood = log.mood;
        _initialReflection = log.reflection;
        _gptService.setSelectedCharacterId(log.characterId);
        // _gptService.conversationHistory will be populated by _startChatSession or user interaction
        _startChatSession(); // Start or resume chat for this log ID

      } else {
        // Brand new chat, no pre-existing log object
        if (widget.characterId == null || widget.mood == null) {
          print("Error: Missing characterId or mood for new chat. characterId: ${widget.characterId}, mood: ${widget.mood}");
          if (mounted) {
            setState(() => _isLoading = false);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('チャットを開始できませんでした。キャラクターまたは気分が選択されていません。')),
            );
            // デバッグ用に引数を表示
            print("Debug - Arguments received: ${widget.characterId}, ${widget.mood}, ${widget.initialReflection}");
          }
          return;
        }
        _selectedMood = widget.mood!;
        _initialReflection = widget.initialReflection;
        _gptService.setSelectedCharacterId(widget.characterId!);
        // _currentLogId is null here, _startChatSession will create a new log.
        _startChatSession();
      }
    });
  }


  @override
  void dispose() {
    _animationController.dispose();
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  // このメソッドは新しいフローでは不要なので削除 (またはコメントアウト)
  // Future<void> _getAIResponse() async { ... }

  // 会話セッションを開始する前に会話制限をチェック
  Future<bool> _checkConversationLimits() async {
    final subscriptionService = Provider.of<SubscriptionService>(context, listen: false);
    
    // 会話回数制限のチェック
    if (subscriptionService.hasReachedFreeLimit || subscriptionService.hasReachedPremiumLimit) {
      // 制限に達している場合、ダイアログを表示
      if (mounted) {
        final isPremium = subscriptionService.isPremium;
        final limit = isPremium 
            ? SubscriptionService.premiumConversationLimit 
            : SubscriptionService.freeConversationLimit;
            
        await showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            title: const Text('会話制限に達しました'),
            content: isPremium
                ? Text('プレミアムプランの1日の会話制限($limit回)に達しました。明日また会話できます。')
                : Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('無料プランの1日の会話制限($limit回)に達しました。'),
                      const SizedBox(height: 16),
                      const Text('プレミアムにアップグレードすると、1日3回まで会話できます。'),
                    ],
                  ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('閉じる'),
              ),
              if (!isPremium)
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    // 設定画面に遷移してプレミアム案内を表示
                    Navigator.of(context).pushReplacementNamed('/settings');
                  },
                  child: const Text('プレミアムにアップグレード'),
                ),
            ],
          ),
        );
        
        // 制限に達している場合は前の画面に戻る
        Navigator.of(context).pop();
        return false;
      }
    }
    
    // 制限に達していない場合はtrueを返す
    return true;
  }

  // 会話セッションを開始する
  Future<void> _startChatSession() async {
    if (_selectedMood == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('気分が選択されていません。')),
      );
      return;
    }
    
    // 会話制限をチェック（既存の会話の場合はスキップ）
    if (_currentLogId == null) {
      final canStartConversation = await _checkConversationLimits();
      if (!canStartConversation) return;
      
      // 注意: 会話カウンターはここでは増やさない
      // createLogメソッド内で既に増加されるため
    }

    setState(() {
      _isLoading = true; // AIの初回応答を待つ間ローディング表示
    });

    final reflectionText = _initialReflection ?? '';
    final prefsService = Provider.of<PreferencesService>(context, listen: false);

    try {
      // チェックイン画面からの遷移の場合、ChatLogはすでに作成済み
      if (_currentLogId == null) {
        try {
          // 何らかの理由でLogIDがない場合は新規作成
          final newLog = await _chatLogService.createLog(
            mood: _selectedMood!,
            reflection: reflectionText.isNotEmpty ? reflectionText : null,
            characterId: prefsService.selectedCharacterId,
          );
          _currentLogId = newLog.id;
        } catch (e) {
          // 会話制限に達した場合などのエラー処理
          if (mounted) {
            setState(() {
              _isLoading = false;
            });
            
            // プレミアムかどうかを確認
            final subscriptionService = Provider.of<SubscriptionService>(context, listen: false);
            final isPremium = subscriptionService.isPremium;
            final limit = isPremium 
                ? SubscriptionService.premiumConversationLimit 
                : SubscriptionService.freeConversationLimit;
            
            // エラーメッセージを表示
            await showDialog(
              context: context,
              barrierDismissible: false,
              builder: (context) => AlertDialog(
                title: const Text('会話制限に達しました'),
                content: isPremium
                    ? Text('プレミアムプランの1日の会話制限($limit回)に達しました。明日また会話できます。')
                    : Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('無料プランの1日の会話制限($limit回)に達しました。'),
                          const SizedBox(height: 16),
                          const Text('プレミアムにアップグレードすると、1日う3回まで会話できます。'),
                        ],
                      ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('閉じる'),
                  ),
                  if (!isPremium)
                    ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                        // 設定画面に遷移してプレミアム案内を表示
                        Navigator.of(context).pushReplacementNamed('/settings');
                      },
                      child: const Text('プレミアムにアップグレード'),
                    ),
                ],
              ),
            );
            
            // 制限に達している場合は前の画面に戻る
            Navigator.of(context).pop();
            return; // 処理を中断
          }
          return; // 処理を中断
        }
      }

      // GPTServiceのstartConversationを呼び出す
      await _gptService.startConversation(reflectionText, _selectedMood!);

      // 会話の内容は最終的にsummarizeConversationメソッドで要約され、
      // updateLogSummaryメソッドで保存されるので、個々のメッセージを保存する必要はありません。

      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        _animationController.forward(); // アニメーション再開/開始
        _scrollToBottom();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('会話の開始に失敗しました: ${e.toString()}')),
        );
      }
    }
  }
  
  // メッセージを送信
  Future<void> _sendMessage() async {
    final text = _textController.text.trim();
    if (text.isEmpty) return;
    
    // メッセージ送信中は重複送信を防止
    if (_isSending) return;
    
    // 会話ターン数の制限をチェック
    final subscriptionService = Provider.of<SubscriptionService>(context, listen: false);
    final maxTurns = subscriptionService.isPremium
        ? SubscriptionService.premiumConversationTurns
        : SubscriptionService.freeConversationTurns;
    
    // 残り送信回数に応じた警告を表示
    final remainingTurns = maxTurns - _currentConversationCount;
    if (remainingTurns == 2) { // 次が最後から2番目のメッセージの場合 (例: 5/7送信済みで次が6回目)
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('次のメッセージを送信すると、残りの送信回数は1回となります。'),
          duration: Duration(seconds: 3),
          backgroundColor: Colors.orange,
        ),
      );
    } else if (remainingTurns == 1) { // 次が最後のメッセージの場合 (例: 6/7送信済みで次が7回目)
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('次のメッセージが最後の送信となります。'),
          duration: Duration(seconds: 3),
          backgroundColor: Colors.orange,
        ),
      );
    }
    
    // 最後のメッセージかどうかチェック
    final bool isLastMessage = _currentConversationCount == maxTurns - 1;
    
    setState(() {
      _isSending = true;
    });
    
    final String currentInputText = text;

    // 1. ユーザーメッセージをGPTServiceの履歴に追加
    _gptService.addUserMessage(currentInputText);

    // 2. UIを更新してユーザーメッセージを即時表示 & テキストコントローラーをクリア
    _textController.clear();
    if (mounted) {
      setState(() {});
      _scrollToBottom();
    }
    
    // 3. AIの応答を生成・取得
    try {
      await _gptService.generateAndAddAIResponse();
      
      // 4. UIを更新してAIメッセージを表示
      if (mounted) {
        setState(() {}); 
        _scrollToBottom();
      }

      // 5. 最後のメッセージだった場合、制限に達したことを通知して会話を終了
      if (isLastMessage && _currentLogId != null) {
        // 少し間を空けてからダイアログを表示
        await Future.delayed(const Duration(milliseconds: 1000));
        
        // 制限に達したことをユーザーに通知
        if (mounted) {
          await showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) => AlertDialog(
              title: const Text('送信回数の制限に達しました'),
              content: subscriptionService.isPremium
                  ? const Text('プレミアムプランの送信回数制限（30回）に達しました。会話をまとめます。')
                  : const Text('無料プランの送信回数制限（7回）に達しました。プレミアムプランにアップグレードすると、30回まで送信可能になります。'),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    // 会話をまとめる
                    _endConversation();
                  },
                  child: const Text('会話をまとめる'),
                ),
                if (!subscriptionService.isPremium)
                  ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      // 設定画面に遷移してプレミアム案内を表示
                      Navigator.of(context).pushReplacementNamed('/settings');
                    },
                    child: const Text('プレミアムにアップグレード'),
                  ),
              ],
            ),
          );
        }
      }
    } catch (e) {
      // エラー処理
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('メッセージの送信に失敗しました')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSending = false;
        });
      }
    }
  }
  
  // スクロールを一番下に移動
  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  // 気分選択UIは削除しました

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'AIと会話中',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(40.0),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Consumer<SubscriptionService>(
              builder: (context, subscriptionService, _) {
                final isPremium = subscriptionService.isPremium;
                final maxTurns = isPremium
                    ? SubscriptionService.premiumConversationTurns
                    : SubscriptionService.freeConversationTurns;
                final maxConversations = isPremium
                    ? SubscriptionService.premiumConversationLimit
                    : SubscriptionService.freeConversationLimit;
                
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '送信回数: $_currentConversationCount/$maxTurns',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppTheme.secondaryTextColor,
                            fontWeight: _currentConversationCount > maxTurns * 0.7 ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                        Text(
                          '今日の会話: ${subscriptionService.todayConversationCount}/$maxConversations',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppTheme.secondaryTextColor,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    // ターン数のプログレスバー
                    LinearProgressIndicator(
                      value: _currentConversationCount / maxTurns,
                      backgroundColor: Colors.grey[300],
                      valueColor: AlwaysStoppedAnimation<Color>(
                        _currentConversationCount > maxTurns * 0.8
                            ? Colors.red
                            : _currentConversationCount > maxTurns * 0.5
                                ? Colors.orange
                                : AppTheme.primaryColor,
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
        actions: [],
      ),
      body: Column(
        children: [
          if (_isLoading) // ローディング表示
            // Loading animation
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(
                    width: 60,
                    height: 60,
                    child: CircularProgressIndicator(
                      strokeWidth: 3,
                      valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(_currentPhase == ChatPhase.ended ? '会話をまとめています...' : 'メッセージを考えています...'),
                ],
              ),
            )
          else
            // チャット画面
            Expanded(
              child: FadeTransition(
                opacity: _fadeInAnimation,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: _buildChatList(),
                ),
              ),
            ),
            
          // 入力フィールドと会話終了メッセージ
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: (_isConversationOver || _shouldEndConversation) 
                ? _buildConversationEndedMessage() 
                : _buildInputField(),
          ),
            
          // 会話終了時のボタン (7ターン経過後または手動終了時)
          if (_isConversationOver || _shouldEndConversation)
            Padding(
              padding: const EdgeInsets.only(bottom: 16.0),
              child: Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.of(context).pushReplacementNamed('/log'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(28),
                        ),
                      ),
                      child: const Text('記録を見る'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pushReplacementNamed('/check-in'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        side: BorderSide(color: AppTheme.primaryColor),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(28),
                        ),
                      ),
                      child: const Text('閉じる'),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
  
  // チャットリストを構築
  Widget _buildChatList() {
    final messages = _gptService.conversationHistory;
    
    if (messages.isEmpty) {
      return const Center(
        child: Text('メッセージがありません'),
      );
    }
    
    return ListView.builder(
      controller: _scrollController,
      itemCount: messages.length,
      itemBuilder: (context, index) {
        final message = messages[index];
        return _buildMessageBubble(message);
      },
    );
  }
  
  // メッセージバブルを構築
  Widget _buildMessageBubble(Message message) {
    final isUser = message.isUser;
    final preferencesService = Provider.of<PreferencesService>(context, listen: false);
    final selectedCharacterId = preferencesService.selectedCharacterId;
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser) ...[
            // 選択したキャラクターアイコンを表示
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: ClipOval(
                child: CustomPaint(
                  painter: CharacterImagePainter(
                    imagePath: 'assets/images/chara1.png',
                    characterId: selectedCharacterId,
                  ),
                  size: const Size(40, 40),
                ),
              ),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isUser 
                    ? AppTheme.primaryColor.withOpacity(0.1)
                    : AppTheme.accentColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20).copyWith(
                  bottomLeft: isUser ? const Radius.circular(20) : const Radius.circular(0),
                  bottomRight: isUser ? const Radius.circular(0) : const Radius.circular(20),
                ),
              ),
              child: Text(
                message.content,
                style: isUser
                    ? Theme.of(context).textTheme.bodyMedium
                    : AppTheme.handwrittenStyle.copyWith(
                        fontSize: 16,
                        height: 1.5,
                      ),
              ),
            ),
          ),
          if (isUser) ...[  
            const SizedBox(width: 8),
            CircleAvatar(
              backgroundColor: AppTheme.primaryColor.withOpacity(0.2),
              child: Icon(
                Icons.person,
                color: AppTheme.primaryColor,
                size: 20,
              ),
            ),
          ],
        ],
      ),
    );
  }
  
  // 入力フィールドを構築
  Widget _buildConversationEndedMessage() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 8.0),
      child: Text(
        '''AIとの会話は終了しました。お疲れ様でした。
下のボタンからログを確認したり、ホームに戻ったりできます。''',
        textAlign: TextAlign.center,
        style: TextStyle(color: AppTheme.secondaryTextColor, fontSize: 15),
      ),
    );
  }

  // 会話を終了するメソッド
  Future<void> _endConversation() async {
    setState(() {
      _isLoading = true;
      _currentPhase = ChatPhase.ended;
    });

    try {
      // 会話の要約を生成
      final summary = await _gptService.summarizeConversation();
      
      // ログに要約を保存
      if (_currentLogId != null) {
        await _chatLogService.updateLogSummary(_currentLogId!, summary);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('会話が終了し、内容が記録されました。')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('会話の記録に失敗しました: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _isConversationOver = true; // 会話終了フラグをセット
        });
      }
    }
  }

  Widget _buildInputField() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _textController,
                decoration: InputDecoration(
                  hintText: 'メッセージを入力...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide(color: AppTheme.primaryColor.withOpacity(0.5)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide(color: AppTheme.primaryColor.withOpacity(0.5)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide(color: AppTheme.primaryColor),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  filled: true,
                  fillColor: Theme.of(context).cardColor,
                ),
                maxLines: 1,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => _sendMessage(),
                enabled: !_isSending && !_isConversationOver && !_shouldEndConversation,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              decoration: BoxDecoration(
                color: AppTheme.primaryColor,
                shape: BoxShape.circle,
              ),
              child: IconButton(
                icon: _isSending
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Icon(Icons.send, color: Colors.white),
                onPressed: _isSending || _isConversationOver ? null : _sendMessage,
              ),
            ),
          ],
        ),
        
        // 会話を終了するボタン
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            icon: const Icon(Icons.check_circle_outline),
            label: const Text('会話を終了する'),
            onPressed: _isSending || _isConversationOver ? null : _endConversation,
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 12),
              side: BorderSide(color: AppTheme.primaryColor),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(28),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
