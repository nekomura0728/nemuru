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
  final Map<String, IconData> _moodIcons = {
    '喜': Icons.sentiment_very_satisfied_rounded,
    '怒': Icons.sentiment_very_dissatisfied_rounded,
    '哀': Icons.sentiment_dissatisfied_rounded,
    '楽': Icons.sentiment_satisfied_alt_rounded,
    '疲': Icons.bedtime_rounded,
    '焦': Icons.running_with_errors_rounded,
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
    
    // デバッグ用に値を表示
    print('Debug - Creating log and sending to AI response screen: characterId=$characterId, mood=$mood, reflection=$reflection');

    // ChatLogを先に作成
    final newLog = await chatLogService.createLog(
      mood: mood,
      reflection: reflection.isNotEmpty ? reflection : null, // 空の場合はnullを渡す
      characterId: characterId,
    );
    
    // AIResponseScreenにChatLogオブジェクトを渡して遷移
    Navigator.of(context).pushNamed(
      '/ai-response',
      arguments: {
        'chatLog': newLog, // 作成したログを渡す
        // characterId, mood, initialReflection は newLog に含まれるため、個別には不要
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
              // メインコンテンツ
              SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Date display with night theme
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
                  decoration: BoxDecoration(
                    color: Theme.of(context).brightness == Brightness.dark 
                        ? AppTheme.darkPrimaryColor.withOpacity(0.15) 
                        : AppTheme.primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.nightlight_round,
                        size: 20,
                        color: Theme.of(context).brightness == Brightness.dark 
                            ? AppTheme.darkSecondaryTextColor 
                            : AppTheme.secondaryTextColor,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        formattedDate,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: Theme.of(context).brightness == Brightness.dark 
                              ? AppTheme.darkSecondaryTextColor 
                              : AppTheme.secondaryTextColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 40),
                
                // Mood selection title with stars
                Center(
                  child: Column(
                    children: [
                      Text(
                        '今夕の気持ちを教えてください',
                        style: AppTheme.handwrittenStyle.copyWith(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).brightness == Brightness.dark 
                              ? AppTheme.darkPrimaryColor 
                              : AppTheme.primaryColor,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '眼を閉じて、心の声に耳を澄ませてみましょう',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).brightness == Brightness.dark 
                              ? AppTheme.darkSecondaryTextColor 
                              : AppTheme.secondaryTextColor,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                
                // Mood selection
                _buildMoodSelection(),
                const SizedBox(height: 32),
                
                // Text input with night theme
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.black.withOpacity(0.2)
                            : Colors.grey.withOpacity(0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
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
                            ? AppTheme.darkSecondaryTextColor.withOpacity(0.7)
                            : AppTheme.secondaryTextColor.withOpacity(0.7),
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
                              ? AppTheme.darkPrimaryColor.withOpacity(0.5)
                              : AppTheme.primaryColor.withOpacity(0.5),
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(
                          color: Theme.of(context).brightness == Brightness.dark
                              ? AppTheme.darkPrimaryColor.withOpacity(0.3)
                              : AppTheme.primaryColor.withOpacity(0.3),
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
                const SizedBox(height: 40),
                
                // Submit button with night theme
                ElevatedButton.icon(
                  onPressed: _submitCheckIn,
                  icon: Icon(
                    Icons.send_rounded,
                    color: Colors.white,
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).brightness == Brightness.dark
                        ? AppTheme.darkPrimaryColor
                        : AppTheme.primaryColor,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 56),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(28),
                    ),
                    elevation: 4,
                    shadowColor: Theme.of(context).brightness == Brightness.dark
                        ? AppTheme.darkPrimaryColor.withOpacity(0.5)
                        : AppTheme.primaryColor.withOpacity(0.5),
                  ),
                  label: const Text('心を届ける', style: TextStyle(fontSize: 16)),
                ),
                
                // 過去のログを見るボタン
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  icon: Icon(
                    Icons.auto_stories_rounded,
                    color: Theme.of(context).brightness == Brightness.dark
                        ? AppTheme.darkAccentColor
                        : AppTheme.accentColor,
                  ),
                  label: const Text('これまでの心の軌跡を振り返る'),
                  onPressed: () => Navigator.of(context).pushNamed('/log'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Theme.of(context).brightness == Brightness.dark
                        ? AppTheme.darkAccentColor
                        : AppTheme.accentColor,
                    minimumSize: const Size(double.infinity, 56),
                    side: BorderSide(
                      color: Theme.of(context).brightness == Brightness.dark
                          ? AppTheme.darkAccentColor
                          : AppTheme.accentColor,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(28),
                    ),
                  ),
                ),
              ],
            ),
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
            ? AppTheme.darkBackgroundColor.withOpacity(0.3) 
            : AppTheme.backgroundColor.withOpacity(0.3),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDarkMode 
              ? AppTheme.darkPrimaryColor.withOpacity(0.1) 
              : AppTheme.primaryColor.withOpacity(0.1),
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
        itemCount: _moodIcons.length,
        itemBuilder: (context, index) {
          final mood = _moodIcons.keys.elementAt(index);
          final icon = _moodIcons[mood];
          final color = _moodColors[mood];
          final isSelected = _selectedMood == mood;
          
          return GestureDetector(
            onTap: () {
              setState(() {
                _selectedMood = mood;
              });
              // タップ時に軽いフィードバックを表示
              ScaffoldMessenger.of(context).clearSnackBars();
              if (isSelected) return; // 既に選択されている場合は何もしない
              
              final moodMessages = {
                '喜': '嬉しい気持ちを選びました。今日の幸せな瞬間を教えてください。',
                '怒': '怒りの気持ちを選びました。何があなたを苦しめているのでしょうか。',
                '哀': '悲しい気持ちを選びました。その悲しみを共有してみませんか。',
                '楽': '心地よい気持ちを選びました。何があなたに安らぎを与えていますか。',
                '疲': '疲れた気持ちを選びました。今日は大変な一日だったのですね。',
                '焼': '不安な気持ちを選びました。あなたの心配事を聞かせてください。',
              };
              
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(moodMessages[mood] ?? '気持ちを選びました'),
                  duration: const Duration(seconds: 2),
                  behavior: SnackBarBehavior.floating,
                  backgroundColor: isDarkMode 
                      ? AppTheme.darkCardColor 
                      : AppTheme.primaryColor.withOpacity(0.9),
                ),
              );
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              decoration: BoxDecoration(
                color: isSelected 
                    ? (isDarkMode 
                        ? color?.withOpacity(0.3) 
                        : color?.withOpacity(0.2))
                    : cardColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isSelected 
                      ? color ?? (isDarkMode ? AppTheme.darkPrimaryColor : AppTheme.primaryColor)
                      : (isDarkMode 
                          ? AppTheme.darkPrimaryColor.withOpacity(0.2) 
                          : AppTheme.primaryColor.withOpacity(0.2)),
                  width: isSelected ? 2 : 1,
                ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: (color ?? (isDarkMode ? AppTheme.darkPrimaryColor : AppTheme.primaryColor)).withOpacity(isDarkMode ? 0.4 : 0.3),
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
                  Icon(
                    icon,
                    size: 36,
                    color: isSelected 
                        ? color 
                        : secondaryTextColor,
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
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
