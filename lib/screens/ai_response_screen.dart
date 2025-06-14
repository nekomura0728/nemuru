import 'package:flutter/material.dart';
import 'package:nemuru/theme/app_theme.dart';
import 'package:nemuru/services/gpt_service.dart';
import 'package:provider/provider.dart';
import 'package:nemuru/services/preferences_service.dart';
import 'package:nemuru/services/subscription_service.dart';
import 'package:nemuru/services/chat_log_service.dart';
import 'package:nemuru/widgets/character_image_widget.dart';
import 'package:nemuru/models/message.dart';
import 'package:nemuru/models/chat_log.dart';
import 'dart:math';
import 'dart:async';

// 星のデータを保持するクラス
class Star {
  final double x; // 画面上のx座標（0.0〜1.0）
  final double y; // 画面上のy座標（0.0〜1.0）
  final double size; // 星のサイズ
  final double opacity; // 星の透明度

  Star(
      {required this.x,
      required this.y,
      required this.size,
      required this.opacity});
}

// 星空の背景を描画するためのカスタムペインター
class StarSkyPainter extends CustomPainter {
  final bool isDarkMode;
  // 静的なリストで星を保持することで、再描画時に星の位置が変わらないようにする
  static final List<Star> _darkModeStars = [];
  static final List<Star> _lightModeStars = [];
  static final Random _random = Random();

  StarSkyPainter({required this.isDarkMode}) {
    // 初回のみ星を生成
    if (isDarkMode && _darkModeStars.isEmpty) {
      _generateStars(_darkModeStars, 100); // ダークモードでは100個の星
    } else if (!isDarkMode && _lightModeStars.isEmpty) {
      _generateStars(_lightModeStars, 30); // ライトモードでは30個の星
    }
  }

  // 星を生成するヘルパーメソッド
  void _generateStars(List<Star> starList, int count) {
    for (int i = 0; i < count; i++) {
      starList.add(Star(
        x: _random.nextDouble(),
        y: _random.nextDouble(),
        size: _random.nextDouble() * 2 + 0.5, // 0.5〜2.5のサイズ
        opacity: _random.nextDouble() * 0.7 + 0.3, // 0.3〜1.0の透明度
      ));
    }
  }

  @override
  void paint(Canvas canvas, Size size) {
    // 使用する星のリストを選択
    final stars = isDarkMode ? _darkModeStars : _lightModeStars;

    // 星を描画
    for (final star in stars) {
      final paint = Paint()
        ..color = isDarkMode
            ? Colors.white.withValues(alpha: star.opacity)
            : Colors.blueGrey.withValues(alpha: star.opacity * 0.7)
        ..style = PaintingStyle.fill;

      // 星の位置を計算
      final x = star.x * size.width;
      final y = star.y * size.height;

      // 星を描画（小さな円）
      canvas.drawCircle(Offset(x, y), star.size, paint);

      // 輝きを追加（より大きな透明な円）
      if (isDarkMode && star.size > 1.5) {
        final glowPaint = Paint()
          ..color = Colors.white.withValues(alpha: star.opacity * 0.3)
          ..style = PaintingStyle.fill;
        canvas.drawCircle(Offset(x, y), star.size * 2, glowPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// 流れ星の情報を保持するクラス
class ShootingStar {
  final double startX;
  final double startY;
  final double length;
  final double angle; // ラジアン単位
  final double speed;
  final double delay; // 0.0から1.0の遅延値

  ShootingStar({
    required this.startX,
    required this.startY,
    required this.length,
    required this.angle,
    required this.speed,
    required this.delay,
  });
}

// 流れ星を描画するカスタムペインター
class ShootingStarPainter extends CustomPainter {
  final bool isDarkMode;
  final double animationValue; // 0.0から1.0のアニメーション値

  // 静的な流れ星のリスト
  static final List<ShootingStar> _shootingStars = [];
  static final Random _random = Random();

  ShootingStarPainter(
      {required this.isDarkMode, required this.animationValue}) {
    // 初回のみ流れ星を生成
    if (_shootingStars.isEmpty) {
      _generateShootingStars();
    }
  }

  void _generateShootingStars() {
    // 5個の流れ星を生成
    for (int i = 0; i < 5; i++) {
      _shootingStars.add(ShootingStar(
        startX: _random.nextDouble(),
        startY: _random.nextDouble() * 0.5, // 画面上部に配置
        length: _random.nextDouble() * 0.1 + 0.05, // 長さは画面の5～15%
        angle: _random.nextDouble() * 0.5 + 0.7, // 約぀0.7～1.2ラジアン（右下方向）
        speed: _random.nextDouble() * 0.5 + 0.5, // 速度のバリエーション
        delay: _random.nextDouble(), // 倍率で遅延を設定
      ));
    }
  }

  @override
  void paint(Canvas canvas, Size size) {
    for (final star in _shootingStars) {
      // 遅延を考慮したアニメーション値を計算
      double effectiveAnimation = (animationValue - star.delay) * star.speed;

      // アニメーション値が0以下または1以上の場合は描画しない
      if (effectiveAnimation < 0 || effectiveAnimation > 1) continue;

      // 流れ星の位置を計算
      final startX = star.startX * size.width;
      final startY = star.startY * size.height;

      // 流れ星の終点を計算
      final endX = startX +
          cos(star.angle) * star.length * size.width * effectiveAnimation;
      final endY = startY +
          sin(star.angle) * star.length * size.height * effectiveAnimation;

      // 流れ星の尾の長さを計算
      final tailLength =
          star.length * size.width * 0.7 * (1 - effectiveAnimation * 0.5);

      // 流れ星の先頭を描画
      final headPaint = Paint()
        ..color = isDarkMode
            ? Colors.white.withValues(alpha: 0.9)
            : Colors.white.withValues(alpha: 0.8)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(Offset(endX, endY), 2.0, headPaint);

      // 流れ星の尾を描画
      final tailStart = Offset(endX - cos(star.angle) * tailLength,
          endY - sin(star.angle) * tailLength);
      final tailEnd = Offset(endX, endY);

      // グラデーションを使用して尾を描画
      final tailPaint = Paint()
        ..shader = LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [
            isDarkMode
                ? Colors.white.withValues(alpha: 0)
                : Colors.white.withValues(alpha: 0),
            isDarkMode
                ? Colors.white.withValues(alpha: 0.7)
                : Colors.white.withValues(alpha: 0.6),
          ],
        ).createShader(Rect.fromPoints(tailStart, tailEnd))
        ..strokeWidth = 1.5
        ..style = PaintingStyle.stroke;

      canvas.drawLine(tailStart, tailEnd, tailPaint);

      // 光のグロー効果
      final glowPaint = Paint()
        ..color = isDarkMode
            ? Colors.white.withValues(alpha: 0.2)
            : Colors.white.withValues(alpha: 0.15)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.0;
      canvas.drawLine(tailStart, tailEnd, glowPaint);
    }
  }

  @override
  bool shouldRepaint(covariant ShootingStarPainter oldDelegate) {
    return oldDelegate.animationValue != animationValue;
  }
}

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
    final subscriptionService =
        Provider.of<SubscriptionService>(context, listen: false);
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
                      const Text('プレミアムにアップグレードすると、1日30回まで会話できます。'),
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
                          const Text('プレミアムにアップグレードすると、1日30回まで会話できます。'),
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
                  : const Text(
                      '無料プランの送信回数制限（7回）に達しました。プレミアムプランにアップグレードすると、30回まで送信可能になります。'),
              actions: [
                TextButton(
                  onPressed: () async {
                    Navigator.of(context).pop(); // ダイアログを閉じる
                    // 会話をまとめる
                    await _endConversation();
                    // まとめ生成後は現在の画面を閉じて前の画面に戻る
                    if (mounted) {
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
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(50.0),
          child: Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Consumer<SubscriptionService>(
              builder: (context, subscriptionService, _) {
                final isDarkMode =
                    Theme.of(context).brightness == Brightness.dark;
                final isPremium = subscriptionService.isPremium;
                final maxTurns = isPremium
                    ? SubscriptionService.premiumConversationTurns
                    : SubscriptionService.freeConversationTurns;
                final maxConversations = isPremium
                    ? SubscriptionService.premiumConversationLimit
                    : SubscriptionService.freeConversationLimit;

                // 送信回数に基づく色の設定
                final progressColor = _currentConversationCount > maxTurns * 0.8
                    ? Colors.redAccent.withValues(alpha: isDarkMode ? 0.7 : 1.0)
                    : _currentConversationCount > maxTurns * 0.5
                        ? Colors.orangeAccent
                            .withValues(alpha: isDarkMode ? 0.8 : 1.0)
                        : (isDarkMode
                            ? AppTheme.darkPrimaryColor
                            : AppTheme.primaryColor);

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: isDarkMode
                            ? AppTheme.darkBackgroundColor.withValues(alpha: 0.3)
                            : AppTheme.backgroundColor.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isDarkMode
                              ? AppTheme.darkPrimaryColor.withValues(alpha: 0.1)
                              : AppTheme.primaryColor.withValues(alpha: 0.1),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.chat_bubble_outline,
                                size: 14,
                                color: isDarkMode
                                    ? AppTheme.darkSecondaryTextColor
                                    : AppTheme.secondaryTextColor,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '送信回数: $_currentConversationCount/$maxTurns',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: isDarkMode
                                      ? AppTheme.darkSecondaryTextColor
                                      : AppTheme.secondaryTextColor,
                                  fontWeight:
                                      _currentConversationCount > maxTurns * 0.7
                                          ? FontWeight.bold
                                          : FontWeight.normal,
                                ),
                              ),
                            ],
                          ),
                          Row(
                            children: [
                              Icon(
                                Icons.calendar_today_outlined,
                                size: 14,
                                color: isDarkMode
                                    ? AppTheme.darkSecondaryTextColor
                                    : AppTheme.secondaryTextColor,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '今日: ${subscriptionService.todayConversationCount}/$maxConversations',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: isDarkMode
                                      ? AppTheme.darkSecondaryTextColor
                                      : AppTheme.secondaryTextColor,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 6),
                    // ターン数のプログレスバー
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: _currentConversationCount / maxTurns,
                        backgroundColor:
                            isDarkMode ? Colors.grey[800] : Colors.grey[300],
                        valueColor:
                            AlwaysStoppedAnimation<Color>(progressColor),
                        minHeight: 5,
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            tooltip: 'ヘルプ',
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: Text('心の対話について'),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('ここでは、あなたの心に寄り添う対話をお楽しみいただけます。'),
                      const SizedBox(height: 8),
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
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(28),
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.history,
                                  size: 18,
                                ),
                                const SizedBox(width: 8),
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
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(28),
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.home_outlined,
                                  size: 18,
                                ),
                                const SizedBox(width: 8),
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
    final isUser = message.isUser;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final preferencesService =
        Provider.of<PreferencesService>(context, listen: false);
    final selectedCharacterId = preferencesService.selectedCharacterId;

    // テーマに応じた色の設定
    final primaryColor =
        isDarkMode ? AppTheme.darkPrimaryColor : AppTheme.primaryColor;
    final accentColor =
        isDarkMode ? AppTheme.darkAccentColor : AppTheme.accentColor;

    // ユーザー側の吹き出しの色を調整（星空背景に溶け込まないように透明度を上げ、色をより鮮やかに）
    final userBubbleColor = isDarkMode
        ? primaryColor.withValues(alpha: 0.7) // 透明度を大幅に上げる
        : primaryColor.withValues(alpha: 0.6); // 透明度を大幅に上げる

    // AI側の吹き出しの色も大幅に調整
    final aiBubbleColor = isDarkMode
        ? accentColor.withValues(alpha: 0.6)
        : accentColor.withValues(alpha: 0.5);

    final textColor = isDarkMode ? AppTheme.darkTextColor : AppTheme.textColor;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      child: Row(
        mainAxisAlignment:
            isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser) ...[
            // 選択したキャラクターアイコンを表示
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: isDarkMode
                    ? accentColor.withValues(alpha: 0.15)
                    : accentColor.withValues(alpha: 0.1),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: isDarkMode
                        ? Colors.black.withValues(alpha: 0.2)
                        : Colors.grey.withValues(alpha: 0.2),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: ClipOval(
                child: CharacterImageWidget(
                  characterId: selectedCharacterId,
                  width: 40,
                  height: 40,
                ),
              ),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isUser ? userBubbleColor : aiBubbleColor,
                borderRadius: BorderRadius.circular(20).copyWith(
                  bottomLeft: isUser
                      ? const Radius.circular(20)
                      : const Radius.circular(4),
                  bottomRight: isUser
                      ? const Radius.circular(4)
                      : const Radius.circular(20),
                ),
                boxShadow: [
                  BoxShadow(
                    color: isDarkMode
                        ? Colors.black.withValues(alpha: 0.1)
                        : Colors.grey.withValues(alpha: 0.1),
                    blurRadius: 2,
                    offset: const Offset(0, 1),
                  ),
                ],
                border: Border.all(
                  color: isUser
                      ? primaryColor.withValues(alpha: isDarkMode ? 0.2 : 0.1)
                      : accentColor.withValues(alpha: isDarkMode ? 0.2 : 0.1),
                  width: 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // メッセージ本文
                  Text(
                    message.content,
                    style: isUser
                        ? Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: textColor,
                              height: 1.5,
                            )
                        : AppTheme.handwrittenStyle.copyWith(
                            fontSize: 16,
                            height: 1.5,
                            color: isDarkMode
                                ? AppTheme.darkTextColor
                                : AppTheme.textColor,
                          ),
                  ),
                  // メッセージ送信時間を表示
                  const SizedBox(height: 4),
                  Align(
                    alignment:
                        isUser ? Alignment.centerRight : Alignment.centerLeft,
                    child: Text(
                      // 実際のアプリでは、message.timestampから時間をフォーマットして表示
                      '今',
                      style: TextStyle(
                        fontSize: 10,
                        color: isDarkMode
                            ? AppTheme.darkSecondaryTextColor.withValues(alpha: 0.7)
                            : AppTheme.secondaryTextColor.withValues(alpha: 0.7),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (isUser) ...[
            const SizedBox(width: 8),
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: isDarkMode
                    ? primaryColor.withValues(alpha: 0.2)
                    : primaryColor.withValues(alpha: 0.15),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: isDarkMode
                        ? Colors.black.withValues(alpha: 0.2)
                        : Colors.grey.withValues(alpha: 0.2),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Icon(
                Icons.person,
                color: isDarkMode ? primaryColor : primaryColor,
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
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final primaryColor =
        isDarkMode ? AppTheme.darkPrimaryColor : AppTheme.primaryColor;
    final secondaryTextColor = isDarkMode
        ? AppTheme.darkSecondaryTextColor
        : AppTheme.secondaryTextColor;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20.0, horizontal: 16.0),
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      decoration: BoxDecoration(
        color: isDarkMode
            ? AppTheme.darkBackgroundColor.withValues(alpha: 0.3)
            : AppTheme.backgroundColor.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: primaryColor.withValues(alpha: 0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: isDarkMode
                ? Colors.black.withValues(alpha: 0.1)
                : Colors.grey.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(
            Icons.nightlight_round,
            color: primaryColor.withValues(alpha: 0.7),
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
            '今日のあなたの心に、少しでも安らぎが訪れましたか。対話のまとめが保存されました。',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: secondaryTextColor,
              fontSize: 14,
              height: 1.5,
            ),
          ),
        ],
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

      // 会話の全ログを取得
      final fullConversation = _gptService.conversationHistory;

      // ログに要約と全会話を保存
      if (_currentLogId != null) {
        await _chatLogService.updateLogSummary(_currentLogId!, summary, fullConversation: fullConversation);
        if (mounted) {
          // まとめを表示するダイアログ
          await showDialog(
            context: context,
            barrierDismissible: false, // ダイアログ外タップで閉じないように
            builder: (context) => AlertDialog(
              title: const Text('今日の振り返り'),
              content: SingleChildScrollView(
                child: Text(
                  summary,
                  style: const TextStyle(fontSize: 14, height: 1.5),
                ),
              ),
              actions: [
                ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('確認'),
                ),
              ],
            ),
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

  // 戻るボタンが押された時の処理
  Future<void> _handleBackPressed() async {
    // 会話が2回以上あり、まだ終了していない場合はまとめを生成するか確認
    if (_gptService.conversationHistory.length >= 2 && !_isConversationOver && _currentLogId != null) {
      final shouldGenerateSummary = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          title: const Text('会話を終了しますか？'),
          content: const Text('途中ですが、これまでの会話をまとめて記録しますか？'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('まとめずに戻る'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('まとめて記録'),
            ),
          ],
        ),
      );

      if (shouldGenerateSummary == null) {
        // ダイアログがキャンセルされた場合は何もしない
        return;
      }

      if (shouldGenerateSummary == true) {
        await _endConversation();
      }
    }
    
    // 画面を閉じてホーム画面に戻る
    if (mounted) {
      Navigator.of(context).pushReplacementNamed('/check-in');
    }
  }

  Widget _buildInputField() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final primaryColor =
        isDarkMode ? AppTheme.darkPrimaryColor : AppTheme.primaryColor;
    final accentColor =
        isDarkMode ? AppTheme.darkAccentColor : AppTheme.accentColor;
    final cardColor =
        isDarkMode ? AppTheme.darkCardColor : Theme.of(context).cardColor;
    final secondaryTextColor = isDarkMode
        ? AppTheme.darkSecondaryTextColor
        : AppTheme.secondaryTextColor;

    return Column(
      children: [
        // 入力フィールドと送信ボタン
        Container(
          decoration: BoxDecoration(
            color: isDarkMode
                ? Colors.black.withValues(alpha: 0.8) // 背景を黒で不透明に
                : Colors.white.withValues(alpha: 0.9), // 背景を白で不透明に
            borderRadius: BorderRadius.circular(28),
            border: Border.all(
              color: primaryColor.withValues(alpha: 0.3), // 境界線をより目立つように
              width: 1.5, // 境界線を太く
            ),
            boxShadow: [
              BoxShadow(
                color: isDarkMode
                    ? Colors.black.withValues(alpha: 0.3)
                    : Colors.grey.withValues(alpha: 0.2),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
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
                      color: secondaryTextColor.withValues(alpha: 0.8),
                      fontStyle: FontStyle.italic,
                    ),
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    filled: false,
                  ),
                  style: Theme.of(context).textTheme.bodyMedium,
                  maxLines: 1,
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) => _sendMessage(),
                  enabled: !_isSending &&
                      !_isConversationOver &&
                      !_shouldEndConversation,
                ),
              ),
              const SizedBox(width: 4),
              Container(
                decoration: BoxDecoration(
                  color: primaryColor,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: primaryColor.withValues(alpha: 0.3),
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
                  onPressed:
                      _isSending || _isConversationOver ? null : _sendMessage,
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
                    ? Colors.black.withValues(alpha: 0.3)
                    : Colors.grey.withValues(alpha: 0.2),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: OutlinedButton.icon(
            icon: Icon(
              Icons.nightlight_round,
              color: isDarkMode ? Colors.white : AppTheme.primaryColor,
              size: 18,
            ),
            label: Text('対話を終了する'),
            onPressed:
                _isSending || _isConversationOver || _gptService.conversationHistory.length < 2 ? null : _endConversation,
            style: OutlinedButton.styleFrom(
              foregroundColor:
                  isDarkMode ? Colors.white : AppTheme.primaryColor,
              padding: const EdgeInsets.symmetric(vertical: 14),
              side: BorderSide(
                  color: isDarkMode ? Colors.white70 : AppTheme.primaryColor,
                  width: 1.5), // 境界線を太く
              backgroundColor: isDarkMode ? Colors.black.withValues(alpha: 0.9) : Colors.white.withValues(alpha: 0.95), // 背景を不透明に
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
