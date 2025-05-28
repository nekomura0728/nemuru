import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:nemuru/theme/app_theme.dart';
import 'package:provider/provider.dart';
import 'package:nemuru/services/subscription_service.dart';
import 'package:nemuru/services/chat_log_service.dart';
import 'package:nemuru/services/preferences_service.dart';
import 'package:nemuru/screens/ai_response_screen.dart'; // 星空背景と流れ星のペインターをインポート
import 'dart:math';

class CheckInScreen extends StatefulWidget {
  const CheckInScreen({Key? key}) : super(key: key);

  @override
  State<CheckInScreen> createState() => _CheckInScreenState();
}

class _CheckInScreenState extends State<CheckInScreen> with SingleTickerProviderStateMixin {
  final TextEditingController _textController = TextEditingController();
  String? _selectedMood;
  String? _moodMessage;
  // 気分アイコンのマッピング
  // アイコンはカスタム画像を使用するように変更
  final Map<String, int> _moodIconIds = {
    '喜': 13, // 喜びアイコンは13.png
    '怒': 14, // 怒りアイコンは14.png
    '哀': 15, // 哀しみアイコンは15.png
    '楽': 16, // 楽しさアイコンは16.png
    '疲': 17, // 疲れアイコンは17.png
    '焦': 18, // 焦りアイコンは18.png
  };
  
  final Map<String, Color> _moodColors = {
    '喜': AppTheme.joyColor,
    '怒': AppTheme.angerColor,
    '哀': AppTheme.sadnessColor,
    '楽': AppTheme.pleasureColor,
    '疲': AppTheme.tiredColor,
    '焦': AppTheme.anxietyColor,
  };
  
  // 流れ星アニメーション用のコントローラー
  late AnimationController _shootingStarController;
  
  @override
  void initState() {
    super.initState();
    
    // 流れ星アニメーションの設定
    _shootingStarController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10), // 10秒間のアニメーション
    );
    
    // アニメーションを繰り返し再生
    _shootingStarController.repeat();
  }

  @override
  void dispose() {
    _textController.dispose();
    _shootingStarController.dispose(); // アニメーションコントローラーのクリーンアップ
    super.dispose();
  }

  Future<void> _submitCheckIn() async {
    // サブスクリプションサービスを取得
    final subscriptionService = Provider.of<SubscriptionService>(context, listen: false);
    final chatLogService = Provider.of<ChatLogService>(context, listen: false);
    final preferencesService = Provider.of<PreferencesService>(context, listen: false);
    
    // 入力チェック
    if (_selectedMood == null || _textController.text.trim().isEmpty) {
      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('気分と今日の振り返りを入力してください'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    
    // 制限チェック
    if (subscriptionService.isPremium) {
      if (subscriptionService.hasReachedPremiumLimit) {
        _showPremiumUsageLimitDialog();
        return;
      }
    } else { // 無料プランユーザー
      if (subscriptionService.hasReachedFreeLimit) {
        _showFreeUsageLimitDialog();
        return;
      }
    }

    // チャットログを作成
    final characterId = preferencesService.selectedCharacterId;
    final reflection = _textController.text.trim();
    final mood = _selectedMood!;
    

    // ChatLogを先に作成
    final newLog = await chatLogService.createLog(
      mood: mood,
      reflection: reflection.isNotEmpty ? reflection : null, // 空の場合はnullを渡す
      characterId: characterId,
    );
    
    // AIレスポンススクリーンにChatLogオブジェクトを渡して遷移
    // 必ず遷移するように、pushReplacementNamedを使用
    Navigator.of(context).pushReplacementNamed(
      '/ai-response',
      arguments: {
        'chatLog': newLog, // 作成したログを渡す
        'characterId': characterId,
        'mood': mood,
        'reflection': reflection,
      },
    );

    // Reset input fields after successful submission
    if (mounted) {
      setState(() {
        _textController.clear();
        _selectedMood = null;
      });
    }
  }

  // プレミアムプランの制限に達した場合のダイアログ
  void _showPremiumUsageLimitDialog() {
    final limit = SubscriptionService.premiumConversationLimit;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('会話回数の上限に達しました'),
        content: Text('プレミアムプランの1日の会話制限($limit回)に達しました。会話回数は毎日午前0時にリセットされます。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('閉じる'),
          ),
        ],
      ),
    );
  }

  // 無料プランの制限に達した場合のダイアログ
  void _showFreeUsageLimitDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('会話回数の上限に達しました'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('無料プランでは1日に2回までのAI会話が可能です。会話回数は毎日午前0時にリセットされます。'),
            const SizedBox(height: 16),
            const Text('プレミアムプランにアップグレードすると、実質無制限の会話をお楽しみいただけます。'),
            const SizedBox(height: 8),
            Text(
              'プレミアムプラン: 月額 ¥480 (税込)',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: AppTheme.accentColor,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('キャンセル'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pushNamed('/settings');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.accentColor,
            ),
            child: const Text('プレミアムにアップグレード'),
          ),
        ],
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    );
  }
  
  @override
  Widget build(BuildContext context) {
    // サブスクリプションサービスを取得
    final subscriptionService = Provider.of<SubscriptionService>(context);
    
    // Get current date in Japanese format
    final now = DateTime.now();
    final dateFormat = DateFormat.yMMMMd('ja');
    final formattedDate = dateFormat.format(now);

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Icon(
              Icons.nightlight_round,
              size: 24,
              color: Theme.of(context).brightness == Brightness.dark 
                  ? AppTheme.darkPrimaryColor 
                  : AppTheme.primaryColor,
            ),
            const SizedBox(width: 8),
            Text(
              'NEMURU',
              style: AppTheme.handwrittenStyle.copyWith(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).brightness == Brightness.dark 
                    ? AppTheme.darkPrimaryColor 
                    : AppTheme.primaryColor,
              ),
            ),
          ],
        ),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => Navigator.of(context).pushNamed('/settings'),
            tooltip: '設定',
          ),
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () => Navigator.of(context).pushNamed('/log'),
            tooltip: '過去の記録',
          ),
        ],
      ),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: Container(
          decoration: BoxDecoration(
            // 天空の背景グラデーション
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: Theme.of(context).brightness == Brightness.dark
                  ? [
                      const Color(0xFF0D1B2A),  // 深い紫がかった青
                      const Color(0xFF1B263B),  // 深い青
                    ]
                  : [
                      const Color(0xFFE6F2FF),  // 薄い青
                      const Color(0xFFF5F5F5),  // 白に近い色
                    ],
            ),
          ),
          child: Stack(
            children: [
              // 星空背景
              Positioned.fill(
                child: CustomPaint(
                  painter: StarSkyPainter(
                    isDarkMode: Theme.of(context).brightness == Brightness.dark,
                  ),
                ),
              ),
              // 流れ星アニメーション
              Positioned.fill(
                child: AnimatedBuilder(
                  animation: _shootingStarController,
                  builder: (context, child) {
                    return CustomPaint(
                      painter: ShootingStarPainter(
                        isDarkMode: Theme.of(context).brightness == Brightness.dark,
                        animationValue: _shootingStarController.value,
                      ),
                    );
                  },
                ),
              ),
              // 全体レイアウトを変更してボタンを下部に配置
              Column(
                children: [
                  // メインコンテンツ部分（スクロール可能）
                  Expanded(
                    child: SingleChildScrollView(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                      _buildMoodSelection(),
                      const SizedBox(height: 16),
                      // 気持ちの説明文を表示
                      if (_moodMessage != null)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          margin: const EdgeInsets.only(bottom: 16),
                          decoration: BoxDecoration(
                            color: Theme.of(context).brightness == Brightness.dark
                                ? AppTheme.darkPrimaryColor.withValues(alpha: 0.15)
                                : AppTheme.primaryColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Theme.of(context).brightness == Brightness.dark
                                  ? AppTheme.darkPrimaryColor.withValues(alpha: 0.3)
                                  : AppTheme.primaryColor.withValues(alpha: 0.3),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.lightbulb_outline,
                                color: Theme.of(context).brightness == Brightness.dark
                                    ? AppTheme.darkPrimaryColor
                                    : AppTheme.primaryColor,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _moodMessage!,
                                  style: TextStyle(
                                    color: Theme.of(context).brightness == Brightness.dark
                                        ? AppTheme.darkTextColor
                                        : AppTheme.textColor,
                                    fontSize: 14,
                                    height: 1.4,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      // TextField Container
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Theme.of(context).brightness == Brightness.dark
                              ? AppTheme.darkCardColor.withValues(alpha: 0.8)
                              : Theme.of(context).cardColor.withValues(alpha: 0.9),
                          borderRadius: BorderRadius.circular(18),
                          boxShadow: [
                            BoxShadow(
                              color: Theme.of(context).brightness == Brightness.dark
                                  ? Colors.black.withValues(alpha: 0.25)
                                  : Colors.grey.withValues(alpha: 0.15),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: TextField(
                    controller: _textController,
                    maxLines: 5,
                    maxLength: 300,
                    style: Theme.of(context).textTheme.bodyLarge,
                    decoration: InputDecoration(
                      hintText: '今夕の出来事や、心に浮かんだ思いを、ありのままに…',
                      hintStyle: TextStyle(
                        color: Theme.of(context).brightness == Brightness.dark
                            ? AppTheme.darkSecondaryTextColor.withValues(alpha: 0.7)
                            : AppTheme.secondaryTextColor.withValues(alpha: 0.7),
                        fontStyle: FontStyle.italic,
                      ),
                      filled: true,
                      fillColor: Theme.of(context).brightness == Brightness.dark
                          ? AppTheme.darkCardColor
                          : Theme.of(context).cardColor,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(
                          color: Theme.of(context).brightness == Brightness.dark
                              ? AppTheme.darkPrimaryColor.withValues(alpha: 0.5)
                              : AppTheme.primaryColor.withValues(alpha: 0.5),
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(
                          color: Theme.of(context).brightness == Brightness.dark
                              ? AppTheme.darkPrimaryColor.withValues(alpha: 0.3)
                              : AppTheme.primaryColor.withValues(alpha: 0.3),
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(
                          color: Theme.of(context).brightness == Brightness.dark
                              ? AppTheme.darkPrimaryColor
                              : AppTheme.primaryColor,
                          width: 2,
                        ),
                      ),
                      contentPadding: const EdgeInsets.all(16),
                    ),
                  ),
                ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  
                  // ボタン部分を下部に配置
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Submit button with night theme
                        ElevatedButton.icon(
                          onPressed: _submitCheckIn,
                          icon: const Icon(Icons.send_rounded), // color will be taken from foregroundColor
                          label: Text('心を届ける', style: Theme.of(context).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.bold)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Theme.of(context).brightness == Brightness.dark
                                ? AppTheme.darkPrimaryColor
                                : AppTheme.primaryColor,
                            foregroundColor: Colors.white, // Sets icon and text color
                            minimumSize: const Size(double.infinity, 56),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(28),
                            ),
                            elevation: 5, // Standard elevation
                            shadowColor: Theme.of(context).brightness == Brightness.dark
                                ? Colors.black.withValues(alpha: 0.3)
                                : Colors.black.withValues(alpha: 0.2),
                          ),
                        ),
                        
                        // 過去のログを見るボタン
                        const SizedBox(height: 16),
                        OutlinedButton.icon(
                          icon: const Icon(Icons.auto_stories_rounded),
                          label: const Text('これまでの心の軌跡を振り返る'),
                          onPressed: () => Navigator.of(context).pushNamed('/log'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Theme.of(context).brightness == Brightness.dark
                                ? AppTheme.darkAccentColor
                                : AppTheme.accentColor, // Sets icon and text color
                            minimumSize: const Size(double.infinity, 56),
                            side: BorderSide(
                              color: Theme.of(context).brightness == Brightness.dark
                                  ? AppTheme.darkAccentColor
                                  : AppTheme.accentColor,
                              width: 1.5, // Slightly thicker border
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(28),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMoodSelection() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDarkMode ? AppTheme.darkCardColor : Theme.of(context).cardColor;
    final secondaryTextColor = isDarkMode ? AppTheme.darkSecondaryTextColor : AppTheme.secondaryTextColor;
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDarkMode 
            ? AppTheme.darkBackgroundColor.withValues(alpha: 0.3) 
            : AppTheme.backgroundColor.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDarkMode 
              ? AppTheme.darkPrimaryColor.withValues(alpha: 0.1) 
              : AppTheme.primaryColor.withValues(alpha: 0.1),
          width: 1,
        ),
      ),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          childAspectRatio: 1.2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
        ),
        itemCount: _moodIconIds.length,
        itemBuilder: (context, index) {
          final mood = _moodIconIds.keys.elementAt(index);
          final iconId = _moodIconIds[mood];
          final color = _moodColors[mood];
          final isSelected = _selectedMood == mood;
          
          return GestureDetector(
            onTap: () {
              final moodMessages = {
                '喜': '嬉しい気持ちを選びました。今日の幸せな瞬間を教えてください。',
                '怒': '怒りの気持ちを選びました。何があなたを苦しめているのでしょうか。',
                '哀': '悲しい気持ちを選びました。その悲しみを共有してみませんか。',
                '楽': '心地よい気持ちを選びました。何があなたに安らぎを与えていますか。',
                '疲': '疲れた気持ちを選びました。今日は大変な一日だったのですね。',
                '焦': '不安な気持ちを選びました。あなたの心配事を聞かせてください。',
              };
              
              setState(() {
                _selectedMood = mood;
                _moodMessage = moodMessages[mood];
              });
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              decoration: BoxDecoration(
                color: isSelected 
                    ? (isDarkMode 
                        ? color?.withValues(alpha: 0.3) 
                        : color?.withValues(alpha: 0.2))
                    : cardColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isSelected 
                      ? color ?? (isDarkMode ? AppTheme.darkPrimaryColor : AppTheme.primaryColor)
                      : (isDarkMode 
                          ? AppTheme.darkPrimaryColor.withValues(alpha: 0.2) 
                          : AppTheme.primaryColor.withValues(alpha: 0.2)),
                  width: isSelected ? 2 : 1,
                ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: (color ?? (isDarkMode ? AppTheme.darkPrimaryColor : AppTheme.primaryColor)).withValues(alpha: isDarkMode ? 0.4 : 0.3),
                          blurRadius: 10,
                          spreadRadius: 1,
                          offset: const Offset(0, 3),
                        ),
                      ]
                    : null,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // カスタム画像アイコンを表示 - 元の画像をそのまま表示
                  Image.asset(
                    'assets/images/$iconId.png',
                    width: 70,
                    height: 70,
                    // 色の適用を削除して元の画像をそのまま表示
                  ),
                  const SizedBox(height: 8),
                  Text(
                    mood,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      color: isSelected 
                          ? color 
                          : secondaryTextColor,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
