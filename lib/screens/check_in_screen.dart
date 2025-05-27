import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:nemuru/theme/app_theme.dart';
import 'package:provider/provider.dart';
import 'package:nemuru/services/subscription_service.dart';
import 'package:nemuru/services/chat_log_service.dart';
import 'package:nemuru/services/preferences_service.dart';

class CheckInScreen extends StatefulWidget {
  const CheckInScreen({Key? key}) : super(key: key);

  @override
  State<CheckInScreen> createState() => _CheckInScreenState();
}

class _CheckInScreenState extends State<CheckInScreen> {
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

  @override
  void dispose() {
    _textController.dispose();
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
        title: Text(
          'NEMURU',
          style: AppTheme.handwrittenStyle.copyWith(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => Navigator.of(context).pushNamed('/settings'),
          ),
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () => Navigator.of(context).pushNamed('/log'),
          ),
        ],
      ),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Date display
                Center(
                  child: Text(
                    formattedDate,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: AppTheme.secondaryTextColor,
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                
                // Mood selection title
                Center(
                  child: Text(
                    '今日の気分は？',
                    style: AppTheme.handwrittenStyle.copyWith(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                
                // Mood selection
                _buildMoodSelection(),
                const SizedBox(height: 32),
                
                // Text input
                TextField(
                  controller: _textController,
                  maxLines: 5,
                  maxLength: 300,
                  decoration: InputDecoration(
                    hintText: '今日あったこと、感じたことを自由にお聞かせください…',
                    hintStyle: TextStyle(
                      color: AppTheme.secondaryTextColor.withOpacity(0.7),
                    ),
                    filled: true,
                    fillColor: Theme.of(context).cardColor,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(
                        color: AppTheme.primaryColor.withOpacity(0.5),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                
                // Submit button
                const SizedBox(height: 32),
                ElevatedButton(
                  onPressed: _submitCheckIn,
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 56),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(28),
                    ),
                  ),
                  child: const Text('送信'),
                ),
                
                // 過去のログを見るボタン
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  icon: const Icon(Icons.history),
                  label: const Text('これまでの心の軌跡を見る'),
                  onPressed: () => Navigator.of(context).pushNamed('/log'),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 56),
                    side: BorderSide(color: AppTheme.primaryColor),
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
    return GridView.builder(
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
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            decoration: BoxDecoration(
              color: isSelected 
                  ? color?.withOpacity(0.2) 
                  : Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isSelected 
                    ? color ?? AppTheme.primaryColor 
                    : AppTheme.primaryColor.withOpacity(0.3),
                width: isSelected ? 2 : 1,
              ),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: (color ?? AppTheme.primaryColor).withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
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
                      : AppTheme.secondaryTextColor,
                ),
                const SizedBox(height: 8),
                Text(
                  mood,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    color: isSelected 
                        ? color 
                        : AppTheme.secondaryTextColor,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
