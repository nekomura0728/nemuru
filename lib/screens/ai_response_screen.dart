import 'package:flutter/material.dart';
import 'package:nemuru/theme/app_theme.dart';
import 'package:nemuru/services/gpt_service.dart';
import 'package:provider/provider.dart';
import 'package:nemuru/services/preferences_service.dart';
import 'package:nemuru/services/subscription_service.dart';
import 'package:nemuru/services/chat_log_service.dart';
import 'package:nemuru/widgets/character_image_widget.dart';
import 'package:nemuru/widgets/star_sky_background.dart';
import 'package:nemuru/widgets/chat_message_bubble.dart';
import 'package:nemuru/models/message.dart';
import 'package:nemuru/models/chat_log.dart';
import 'package:nemuru/constants/ui_constants.dart';
import 'package:nemuru/constants/app_constants.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:math';
import 'dart:async';

// Star and StarSkyPainter classes moved to lib/widgets/star_sky_background.dart

// ShootingStar and ShootingStarPainter classes moved to lib/widgets/star_sky_background.dart

// チャットの進行状況を示すEnum
enum ChatPhase {
  moodSelection, // 気分選択中
  chatting, // 会話中
  ended, // 会話終了
}

class AIResponseScreen extends StatefulWidget {
  final ChatLog? chatLog; // Existing log to display/continue
  final int? characterId; // For new chats (if chatLog is null)
  final String? mood; // For new chats (if chatLog is null)
  final String?
      initialReflection; // For new chats (if chatLog is null, from check-in or similar)

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

class _AIResponseScreenState extends State<AIResponseScreen>
    with SingleTickerProviderStateMixin {
  bool _isLoading = true;
  bool _isSending = false;
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  late AnimationController _animationController;
  late Animation<double> _fadeInAnimation;
  
  // 星のリストをインスタンス変数として保持
  late final List<Star> _stars;

  // GPTサービスのインスタンス
  final GPTService _gptService = GPTService();
  late ChatLogService _chatLogService; // ChatLogServiceのインスタンス

  // UIと状態管理のための変数
  ChatPhase _currentPhase = ChatPhase.chatting; // 最初からチャットフェーズに設定
  String? _selectedMood; // ユーザーが選択した気分
  String? _currentLogId; // 現在のチャットログID
  String? _initialReflection; // チェックイン画面からの振り返りテキスト


  // 会話の終了フラグ (手動終了または自動終了を管理)
  bool _isConversationOver = false; // 手動終了用のフラグ

  // 会話が終了条件を満たしているかチェック
  bool get _shouldEndConversation {
    if (!mounted) return false;
    
    try {
      final subscriptionService =
          Provider.of<SubscriptionService>(context, listen: false);
      // プレミアムユーザーは送信30回まで、無料ユーザーは送信7回まで
      final maxTurns = subscriptionService.isPremium
          ? SubscriptionService.premiumConversationTurns
          : SubscriptionService.freeConversationTurns;
      return _gptService.messageCount >= maxTurns;
    } catch (e) {
      // Provider not available, assume free tier limits
      return _gptService.messageCount >= SubscriptionService.freeConversationTurns;
    }
  }

  // 現在のユーザー送信回数を取得
  int get _currentConversationCount => _gptService.messageCount;
  
  // 星を生成するメソッド（一度だけ実行）
  void _generateStars() {
    final random = Random();
    final starCount = UIConstants.darkModeStarCount;
    _stars = List.generate(starCount, (index) {
      return Star(
        x: random.nextDouble(),
        y: random.nextDouble(),
        size: random.nextDouble() * (UIConstants.starMaxSize - UIConstants.starMinSize) + UIConstants.starMinSize,
        opacity: random.nextDouble() * (UIConstants.starMaxOpacity - UIConstants.starMinOpacity) + UIConstants.starMinOpacity,
      );
    });
  }

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
    
    // 星を生成（画面初回表示時のみ）
    _generateStars();

    // ChatLogServiceを取得
    _chatLogService = Provider.of<ChatLogService>(context, listen: false);

    // 選択されたキャラクターIDを設定
    final prefsService =
        Provider.of<PreferencesService>(context, listen: false);
    final selectedCharacterId = prefsService.selectedCharacterId;
    _gptService.setSelectedCharacterId(selectedCharacterId);

    // Initialize based on constructor parameters
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.chatLog != null) {
        final log = widget.chatLog!;
        if (log.summary != null) {
          // This log is already completed and summarized.
          // AIResponseScreen is for active chats. Display an error or navigate away.
          if (mounted) {
            setState(() => _isLoading = false);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(AppConstants.chatAlreadyCompletedMessage)),
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
        
        // ユーザープロファイルを設定
        final userProfile = _chatLogService.analyzeUserProfile();
        _gptService.setUserProfile(userProfile);
        
        // _gptService.conversationHistory will be populated by _startChatSession or user interaction
        _startChatSession(); // Start or resume chat for this log ID
      } else {
        // Brand new chat, no pre-existing log object
        if (widget.characterId == null || widget.mood == null) {
          if (mounted) {
            setState(() => _isLoading = false);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                  content: Text('チャットを開始できませんでした。キャラクターまたは気分が選択されていません。')),
            );
          }
          return;
        }
        _selectedMood = widget.mood!;
        _initialReflection = widget.initialReflection;
        _gptService.setSelectedCharacterId(widget.characterId!);
        
        // ユーザープロファイルを設定
        final userProfile = _chatLogService.analyzeUserProfile();
        _gptService.setUserProfile(userProfile);
        
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
    // Clear static shooting stars to prevent memory leaks (一時的にコメントアウト)
    // ShootingStarPainter.clearShootingStars();
    // Cancel any pending operations
    if (_isSending) {
      _isSending = false;
    }
    super.dispose();
  }

  // このメソッドは新しいフローでは不要なので削除 (またはコメントアウト)
  // Future<void> _getAIResponse() async { ... }

  // 会話セッションを開始する前に会話制限をチェック
  Future<bool> _checkConversationLimits() async {
    final subscriptionService =
        Provider.of<SubscriptionService>(context, listen: false);

    // 会話回数制限のチェック
    if (subscriptionService.hasReachedFreeLimit ||
        subscriptionService.hasReachedPremiumLimit) {
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
                      const SizedBox(height: 16),
                      // 利用規約とプライバシーポリシーへのリンク
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          InkWell(
                            onTap: () async {
                              final url = Uri.parse(AppConstants.termsOfServiceUrl);
                              if (await canLaunchUrl(url)) {
                                await launchUrl(url, mode: LaunchMode.externalApplication);
                              }
                            },
                            child: const Text(
                              '利用規約',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.blue,
                                decoration: TextDecoration.underline,
                              ),
                            ),
                          ),
                          const Text(' | ', style: TextStyle(fontSize: 12)),
                          InkWell(
                            onTap: () async {
                              final url = Uri.parse(AppConstants.privacyPolicyUrl);
                              if (await canLaunchUrl(url)) {
                                await launchUrl(url, mode: LaunchMode.externalApplication);
                              }
                            },
                            child: const Text(
                              'プライバシーポリシー',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.blue,
                                decoration: TextDecoration.underline,
                              ),
                            ),
                          ),
                        ],
                      ),
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
        if (mounted) {
          Navigator.of(context).pop();
        }
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
    final prefsService =
        Provider.of<PreferencesService>(context, listen: false);

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
            final subscriptionService =
                Provider.of<SubscriptionService>(context, listen: false);
            final isPremium = subscriptionService.isPremium;
            final limit = isPremium
                ? SubscriptionService.premiumConversationLimit
                : SubscriptionService.freeConversationLimit;

            // エラーメッセージを表示
            if (mounted) {
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
                          Text('無料プランでは1日$limit回まで会話でき、1回あたり5回やり取りできます。本日の会話制限に達しました。'),
                          const SizedBox(height: 16),
                          const Text('プレミアムプランでは1日3回まで会話でき、1回あたり20回までやり取りできます。'),
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
            }

            // 制限に達している場合は前の画面に戻る
            if (mounted) {
              Navigator.of(context).pop();
            }
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

    // Input validation and sanitization
    if (text.length > AppConstants.maxUserInputLength) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('メッセージは${AppConstants.maxUserInputLength}文字以内で入力してください')),
      );
      return;
    }

    // メッセージ送信中は重複送信を防止
    if (_isSending) return;

    // 会話ターン数の制限をチェック
    final subscriptionService =
        Provider.of<SubscriptionService>(context, listen: false);
    final maxTurns = subscriptionService.isPremium
        ? SubscriptionService.premiumConversationTurns
        : SubscriptionService.freeConversationTurns;

    // 残り送信回数に応じた警告を表示
    final remainingTurns = maxTurns - _currentConversationCount;
    if (remainingTurns == 2) {
      // 次が最後から2番目のメッセージの場合 (例: 5/7送信済みで次が6回目)
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('次のメッセージを送信すると、残りの送信回数は1回となります。'),
          duration: Duration(seconds: 3),
          backgroundColor: Colors.orange,
        ),
      );
    } else if (remainingTurns == 1) {
      // 次が最後のメッセージの場合 (例: 6/7送信済みで次が7回目)
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
                  : Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('無料プランの送信回数制限（7回）に達しました。プレミアムプランにアップグレードすると、30回まで送信可能になります。'),
                        const SizedBox(height: 16),
                        // 利用規約とプライバシーポリシーへのリンク
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            InkWell(
                              onTap: () async {
                                final url = Uri.parse(AppConstants.termsOfServiceUrl);
                                if (await canLaunchUrl(url)) {
                                  await launchUrl(url, mode: LaunchMode.externalApplication);
                                }
                              },
                              child: const Text(
                                '利用規約',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.blue,
                                  decoration: TextDecoration.underline,
                                ),
                              ),
                            ),
                            const Text(' | ', style: TextStyle(fontSize: 12)),
                            InkWell(
                              onTap: () async {
                                final url = Uri.parse(AppConstants.privacyPolicyUrl);
                                if (await canLaunchUrl(url)) {
                                  await launchUrl(url, mode: LaunchMode.externalApplication);
                                }
                              },
                              child: const Text(
                                'プライバシーポリシー',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.blue,
                                  decoration: TextDecoration.underline,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
              actions: [
                TextButton(
                  onPressed: () async {
                    Navigator.of(context).pop(); // ダイアログを閉じる
                    // 会話をまとめる
                    await _endConversation();
                    // まとめ生成後は現在の画面を閉じて前の画面に戻る
                    if (context.mounted) {
                      Navigator.of(context).pop(); // AI応答画面を閉じる
                    }
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
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('メッセージの送信に失敗しました')),
        );
      }
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
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.nightlight_round,
              size: 20,
              color: Theme.of(context).brightness == Brightness.dark
                  ? AppTheme.darkPrimaryColor
                  : AppTheme.primaryColor,
            ),
            const SizedBox(width: 8),
            Text(
              '心の対話',
              style: AppTheme.handwrittenStyle.copyWith(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.white
                    : AppTheme.primaryColor,
              ),
            ),
          ],
        ),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded),
          tooltip: '戻る',
          onPressed: () => _handleBackPressed(),
        ),
        // bottom: PreferredSize(
        //   preferredSize: const Size.fromHeight(50.0),
        //   child: Padding(
        //     padding:
        //         const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        //     child: ConversationProgressBar(
        //       currentConversationCount: _currentConversationCount,
        //     ),
        //   ),
        // ),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            tooltip: 'ヘルプ',
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('心の対話について'),
                  content: const Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('ここでは、あなたの心に寄り添う対話をお楽しみいただけます。'),
                      SizedBox(height: 8),
                      Text('・対話はいつでも終了できます'),
                      Text('・終了時には対話のまとめが保存されます'),
                      Text('・過去の対話は「心の軌跡」から確認できます'),
                    ],
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('閉じる'),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          // 夜空の背景グラデーション
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: Theme.of(context).brightness == Brightness.dark
                ? [
                    const Color(0xFF050A12), // より暗い黒に近い青
                    const Color(0xFF0A1525), // より暗い青
                  ]
                : [
                    const Color(0xFFD8E8FF), // より濃い青
                    const Color(0xFFEAEAEA), // より濃い灰色がかった白
                  ],
          ),
        ),
        child: Stack(
          children: [
            // 星の背景
            Positioned.fill(
              child: CustomPaint(
                painter: StarSkyPainter(
                  isDarkMode: Theme.of(context).brightness == Brightness.dark,
                  stars: Theme.of(context).brightness == Brightness.dark
                      ? _stars  // ダークモードでは全ての星を使用
                      : _stars.take(UIConstants.lightModeStarCount).toList(), // ライトモードでは指定数のみ
                ),
              ),
            ),
            // メインコンテンツ
            Column(
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
                            valueColor: AlwaysStoppedAnimation<Color>(
                                AppTheme.primaryColor),
                          ),
                        ),
                        const SizedBox(height: 24),
                        Text(_currentPhase == ChatPhase.ended
                            ? '会話をまとめています...'
                            : 'メッセージを考えています...'),
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
                  ), // Added comma after Expanded widget

                // 入力フィールドと会話終了メッセージ
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: (_isConversationOver || _shouldEndConversation)
                      ? _buildConversationEndedMessage()
                      : _buildInputField(),
                ), // Added comma after Padding for input field, removed misleading comment

                // 会話終了時のボタン (7ターン経過後または手動終了時)
                if (_isConversationOver || _shouldEndConversation)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16.0),
                    child: Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () => Navigator.of(context)
                                .pushReplacementNamed('/log'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Theme.of(context).brightness ==
                                      Brightness.dark
                                  ? Colors.white
                                  : AppTheme.primaryColor,
                              foregroundColor: Theme.of(context).brightness ==
                                      Brightness.dark
                                  ? AppTheme.primaryColor
                                  : Colors.white,
                              elevation: 2,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: const RoundedRectangleBorder(
                                borderRadius: BorderRadius.all(Radius.circular(28)),
                              ),
                            ),
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.history,
                                  size: 18,
                                ),
                                SizedBox(width: 8),
                                Text('対話記録を見る'),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.of(context)
                                .pushReplacementNamed('/check-in'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Theme.of(context).brightness ==
                                      Brightness.dark
                                  ? Colors.white70
                                  : AppTheme.primaryColor,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              side: BorderSide(
                                color: Theme.of(context).brightness ==
                                        Brightness.dark
                                    ? Colors.white70
                                    : AppTheme.primaryColor,
                              ),
                              backgroundColor: Theme.of(context).brightness ==
                                      Brightness.dark
                                  ? Colors.black26
                                  : Colors.white,
                              shape: const RoundedRectangleBorder(
                                borderRadius: BorderRadius.all(Radius.circular(28)),
                              ),
                            ),
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.home_outlined,
                                  size: 18,
                                ),
                                SizedBox(width: 8),
                                Text('ホームに戻る'),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            // Removed extra closing parenthesis that was here
          ],
        ),
      ), // Close Container
    ); // Close Scaffold
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
    final preferencesService =
        Provider.of<PreferencesService>(context, listen: false);
    final selectedCharacterId = preferencesService.selectedCharacterId;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return ChatMessageBubble(
      message: message,
      selectedCharacterId: selectedCharacterId,
      isDarkMode: isDarkMode,
    );
  }

  // 会話を終了する
  Future<void> _endConversation() async {
    setState(() {
      _isLoading = true;
      _currentPhase = ChatPhase.ended;
    });
    try {
      // 会話の要約を生成
      final summary = await _gptService.summarizeConversation();
      
      // 全会話履歴を取得
      final fullConversation = List<Message>.from(_gptService.conversationHistory);
      
      // ログに要約と全会話を保存
      if (_currentLogId != null) {
        await _chatLogService.updateLogSummary(
          _currentLogId!, 
          summary,
          fullConversation: fullConversation,
        );
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

  void _handleBackPressed() {
    // 会話が未保存の場合は保存確認ダイアログを表示
    if (_gptService.conversationHistory.isNotEmpty && !_isConversationOver) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('会話を終了しますか？'),
          content: const Text('現在の会話を保存して終了します。'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('キャンセル'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.of(context).pop(); // ダイアログを閉じる
                await _endConversation(); // 会話を保存
                if (context.mounted) {
                  Navigator.of(context).pop(); // 画面を閉じる
                }
              },
              child: const Text('会話を終了'),
            ),
          ],
        ),
      );
    } else {
      Navigator.of(context).pop();
    }
  }

  Widget _buildConversationEndedMessage() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = isDarkMode ? AppTheme.darkPrimaryColor : AppTheme.primaryColor;
    final secondaryTextColor = isDarkMode ? AppTheme.darkSecondaryTextColor : AppTheme.secondaryTextColor;
    
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20.0, horizontal: 16.0),
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      decoration: BoxDecoration(
        color: isDarkMode 
            ? AppTheme.darkBackgroundColor.withOpacity(0.3) 
            : AppTheme.backgroundColor.withOpacity(0.3),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: primaryColor.withOpacity(0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: isDarkMode 
                ? Colors.black.withOpacity(0.1) 
                : Colors.grey.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(
            Icons.nightlight_round,
            color: primaryColor.withOpacity(0.7),
            size: 32,
          ),
          const SizedBox(height: 12),
          Text(
            '心の対話が終了しました',
            style: AppTheme.handwrittenStyle.copyWith(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isDarkMode ? Colors.white : AppTheme.primaryColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '今日の振り返りが記録されました',
            style: TextStyle(
              fontSize: 14,
              color: secondaryTextColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputField() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = isDarkMode ? AppTheme.darkPrimaryColor : AppTheme.primaryColor;
    final secondaryTextColor = isDarkMode ? AppTheme.darkSecondaryTextColor : AppTheme.secondaryTextColor;
    
    return Column(
      children: [
        // 入力フィールドと送信ボタン
        Container(
          decoration: BoxDecoration(
            color: isDarkMode 
                ? AppTheme.darkBackgroundColor.withOpacity(0.2) 
                : AppTheme.backgroundColor.withOpacity(0.2),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(
              color: primaryColor.withOpacity(0.1),
              width: 1,
            ),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _textController,
                  decoration: InputDecoration(
                    hintText: '気持ちをありのままに...',
                    hintStyle: TextStyle(
                      color: secondaryTextColor.withOpacity(0.8),
                      fontStyle: FontStyle.italic,
                    ),
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    filled: false,
                  ),
                  style: Theme.of(context).textTheme.bodyMedium,
                  maxLines: 1,
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) => _sendMessage(),
                  enabled: !_isSending && !_isConversationOver && !_shouldEndConversation,
                ),
              ),
              const SizedBox(width: 4),
              Container(
                decoration: BoxDecoration(
                  color: primaryColor,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: primaryColor.withOpacity(0.3),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
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
                      : const Icon(Icons.send_rounded, color: Colors.white),
                  onPressed: _isSending || _isConversationOver ? null : _sendMessage,
                  tooltip: '送信',
                ),
              ),
            ],
          ),
        ),
        
        // 会話を終了するボタン
        const SizedBox(height: 16),
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: isDarkMode 
                    ? Colors.black.withOpacity(0.1) 
                    : Colors.grey.withOpacity(0.1),
                blurRadius: 2,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: OutlinedButton.icon(
            icon: Icon(
              Icons.nightlight_round,
              color: isDarkMode ? Colors.white : AppTheme.primaryColor,
              size: 18,
            ),
            label: const Text('対話を終了する'),
            style: OutlinedButton.styleFrom(
              foregroundColor: isDarkMode ? Colors.white : AppTheme.primaryColor,
              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
              side: BorderSide(
                color: (isDarkMode ? Colors.white : AppTheme.primaryColor).withOpacity(0.3),
              ),
              backgroundColor: isDarkMode 
                  ? Colors.black26 
                  : Colors.white,
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.all(Radius.circular(28)),
              ),
            ),
            onPressed: _isConversationOver ? null : () async {
              // 対話を終了する確認ダイアログ
              final result = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('対話を終了しますか？'),
                  content: const Text('今日の心の記録として保存されます。'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      child: const Text('続ける'),
                    ),
                    ElevatedButton(
                      onPressed: () => Navigator.of(context).pop(true),
                      child: const Text('終了する'),
                    ),
                  ],
                ),
              );
              
              if (result == true) {
                await _endConversation();
              }
            },
          ),
        ),
      ],
    );
  }
}
