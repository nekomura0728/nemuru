import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import 'package:nemuru/theme/app_theme.dart';
import 'package:provider/provider.dart';
import 'package:nemuru/services/subscription_service.dart';
import 'package:nemuru/services/chat_log_service.dart';
import 'package:nemuru/models/chat_log.dart';
import 'package:nemuru/models/message.dart';

class LogScreen extends StatefulWidget {
  const LogScreen({Key? key}) : super(key: key);

  @override
  State<LogScreen> createState() => _LogScreenState();
}

class _LogScreenState extends State<LogScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  CalendarFormat _calendarFormat = CalendarFormat.month;
  
  // チャットログデータ
  Map<DateTime, List<Map<String, dynamic>>> _events = {};
  ValueNotifier<List<Map<String, dynamic>>> _selectedEvents = ValueNotifier([]);

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _selectedDay = _focusedDay;
    _updateSelectedEvents(); // Initialize selected events
    
    // チャットログサービスからデータを取得
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // _generateMockData(); // Comment out or remove mock data generation
      _loadLogs();
    });
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    _selectedEvents.dispose();
    super.dispose();
  }

  Future<void> _loadLogs() async {
    final chatLogService = Provider.of<ChatLogService>(context, listen: false);
    final List<ChatLog> allLogs = await chatLogService.getAllLogs();

    final Map<DateTime, List<Map<String, dynamic>>> newEvents = {};
    for (final log in allLogs) {
      final date = DateTime(log.date.year, log.date.month, log.date.day);
      // ChatLogにはmessagesプロパティがないため、summaryを使用
      final event = {
        'mood': log.mood,
        'userInput': log.reflection, // Use reflection from ChatLog
        'aiResponse': log.summary ?? '', // Use summary from ChatLog
        'timestamp': log.date, // Use date from ChatLog for the entry's primary timestamp
        // You might want to include characterId or other relevant fields if needed by _buildEventCard
        'characterId': log.characterId,
      };
      if (newEvents[date] == null) {
        newEvents[date] = [];
      }
      newEvents[date]!.add(event);
    }

    if (mounted) {
      setState(() {
        _events = newEvents;
      });
      _updateSelectedEvents();
    }
  }
  
  void _generateMockData() {
    final now = DateTime.now();
    final moods = ['喜', '怒', '哀', '楽', '疲', '焦'];
    final responses = [
      '今日も嬉しいことがあったんですね。その喜びを感じられることは素晴らしいことです。明日もまた、小さな幸せに気づける一日になりますように。',
      '怒りを感じることも大切な感情表現です。その気持ちをちゃんと認めてくれたことが素晴らしいです。少しずつ、心が落ち着いていきますように。',
      '悲しい気持ちを言葉にするのは勇気がいることです。その気持ちに正直になれたあなたは強いです。明日は少し心が軽くなっていますように。',
      '楽しい時間を過ごせたことが伝わってきます。その気持ちを大切にしてくださいね。明日もまた、心地よい時間が訪れますように。',
      'お疲れさまでした。今日一日、あなたはよく頑張りました。心地よい眠りにつけて、明日は少し楽になっていますように。',
      '焦りを感じることは、大切なことへの思いの表れかもしれません。その気持ちを認めてくれてありがとう。少しずつ、心が落ち着いていきますように。',
    ];
    
    final userInputs = [
      '今日は友達と久しぶりに会えて嬉しかった。',
      '仕事でミスをしてしまい、イライラした一日だった。',
      '大切にしていたものをなくしてしまって、悲しい。',
      '休日を満喫できて楽しかった。',
      '仕事が忙しくて、疲れた一日だった。',
      '締め切りが近づいていて、焦っている。',
    ];
    
    // Generate data for the past 10 days
    for (int i = 0; i < 10; i++) {
      final date = DateTime(now.year, now.month, now.day - i);
      final normalizedDate = DateTime(date.year, date.month, date.day);
      
      // Skip some days to simulate non-consecutive entries
      if (i == 3 || i == 7) continue;
      
      final moodIndex = i % moods.length;
      _events[normalizedDate] = [
        {
          'mood': moods[moodIndex],
          'userInput': userInputs[moodIndex],
          'aiResponse': responses[moodIndex],
          'timestamp': date,
        }
      ];
    }
  }
  
  List<Map<String, dynamic>> _getEventsForDay(DateTime day) {
    final normalizedDate = DateTime(day.year, day.month, day.day);
    return _events[normalizedDate] ?? [];
  }

  void _updateSelectedEvents() {
    if (_selectedDay != null) {
      _selectedEvents.value = _getEventsForDay(_selectedDay!);
    }
  }
  
  // ログが閲覧可能かどうかチェック
  bool _isLogAvailable(DateTime date) {
    final subscriptionService = Provider.of<SubscriptionService>(context, listen: false);
    return subscriptionService.isLogAvailable(date);
  }
  
  @override
  Widget build(BuildContext context) {
    // サブスクリプションサービスを取得
    final subscriptionService = Provider.of<SubscriptionService>(context);
    
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded),
          onPressed: () {
            // ナビゲーションスタックが空の場合はホーム画面に遷移
            if (Navigator.of(context).canPop()) {
              Navigator.of(context).pop();
            } else {
              Navigator.of(context).pushReplacementNamed('/check-in');
            }
          },
        ),
        title: Text(
          '心の軌跡',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'カレンダー'),
            Tab(text: 'リスト'),
          ],
          labelColor: AppTheme.primaryColor,
          unselectedLabelColor: AppTheme.secondaryTextColor,
          indicatorColor: AppTheme.primaryColor,
        ),
        actions: [
          // 無料プランの場合はプレミアムアップグレードボタンを表示
          if (!subscriptionService.isPremium)
            IconButton(
              icon: Icon(
                Icons.workspace_premium,
                color: AppTheme.accentColor,
              ),
              onPressed: () => Navigator.of(context).pushNamed('/settings'),
              tooltip: 'プレミアムにアップグレード',
            ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildCalendarView(),
          _buildListView(),
        ],
      ),
    );
  }
  
  Widget _buildCalendarView() {
    return Column(
      children: [
        TableCalendar(
          firstDay: DateTime.utc(2023, 1, 1),
          lastDay: DateTime.utc(2030, 12, 31),
          focusedDay: _focusedDay,
          calendarFormat: _calendarFormat,
          selectedDayPredicate: (day) {
            return isSameDay(_selectedDay, day);
          },
          onDaySelected: (selectedDay, focusedDay) {
            if (!isSameDay(_selectedDay, selectedDay)) {
              setState(() {
                _selectedDay = selectedDay;
                _focusedDay = focusedDay;
              });
              _updateSelectedEvents();
            }
          },
          onFormatChanged: (format) {
            setState(() {
              _calendarFormat = format;
            });
          },
          onPageChanged: (focusedDay) {
            _focusedDay = focusedDay;
          },
          eventLoader: _getEventsForDay,
          calendarStyle: CalendarStyle(
            markersMaxCount: 1,
            markerDecoration: BoxDecoration(
              color: AppTheme.primaryColor,
              shape: BoxShape.circle,
            ),
            todayDecoration: BoxDecoration(
              color: AppTheme.primaryColor.withValues(alpha: 0.3),
              shape: BoxShape.circle,
            ),
            selectedDecoration: BoxDecoration(
              color: AppTheme.primaryColor,
              shape: BoxShape.circle,
            ),
          ),
          headerStyle: HeaderStyle(
            formatButtonVisible: true,
            titleCentered: true,
            formatButtonDecoration: BoxDecoration(
              color: AppTheme.primaryColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            formatButtonTextStyle: TextStyle(
              color: AppTheme.primaryColor,
            ),
          ),
          calendarBuilders: CalendarBuilders(
            defaultBuilder: (context, day, focusedDay) {
              final bool isAvailable = _isLogAvailable(day);
              final bool hasEvents = _getEventsForDay(day).isNotEmpty;

              if (!isAvailable && hasEvents) {
                return Center(
                  child: Container(
                    width: 40, // Consistent size with other cells
                    height: 40,
                    margin: const EdgeInsets.all(1.0), // Minimal margin
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: Colors.grey.withValues(alpha: 0.05),
                      shape: BoxShape.circle,
                    ),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Text(
                          '${day.day}',
                          style: TextStyle(color: Colors.grey[400]),
                        ),
                        Icon(Icons.lock_outline, size: 16, color: Colors.grey[400]),
                      ],
                    ),
                  ),
                );
              }
              return null; 
            },
          ),
        ),
        const Divider(),
        Expanded(
          child: _selectedDay != null
              ? _buildDayLogList()
              : const Center(
                  child: Text('日付を選択して記録を確認しましょう'),
                ),
        ),
      ],
    );
  }
  
  Widget _buildDayLogList() {
    if (_selectedDay == null) return SizedBox.shrink();

    return ValueListenableBuilder<List<Map<String, dynamic>>>(
      valueListenable: _selectedEvents,
      builder: (context, events, _) {
        final isAvailable = _isLogAvailable(_selectedDay!);

        if (!isAvailable && events.isNotEmpty) {
          return _buildPremiumUpgradeCardForLogs();
        }

        if (events.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                'この日の記録はありません。',
                style: TextStyle(color: AppTheme.secondaryTextColor),
              ),
            ),
          );
        }

        return ListView(
          padding: const EdgeInsets.all(8.0),
          children: events.map((event) => _buildEventCard(event)).toList(),
        );
      }
    );
  }
  
  Widget _buildListView() {
    if (_events.isEmpty) {
      return Center(
        child: Text(
          '記録がありません',
          style: TextStyle(color: AppTheme.secondaryTextColor),
        ),
      );
    }
    
    // Sort events by date (newest first)
    final sortedDates = _events.keys.toList()
      ..sort((a, b) => b.compareTo(a));
    
    return ListView.builder(
      itemCount: sortedDates.length,
      itemBuilder: (context, index) {
        final date = sortedDates[index];
        final events = _events[date]!;
        
        // 無料プランの制限をチェック
        final bool isAvailable = _isLogAvailable(date);
        
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Row(
                children: [
                  Text(
                    DateFormat.yMMMd('ja').format(date),
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: isAvailable ? AppTheme.primaryColor : Colors.grey[400],
                    ),
                  ),
                  const SizedBox(width: 8),
                  // 制限外の日付にはロックアイコンを表示
                  if (!isAvailable)
                    Icon(
                      Icons.lock,
                      size: 16,
                      color: Colors.grey[400],
                    ),
                ],
              ),
            ),
            ... (isAvailable
                ? events.map((event) => _buildEventCard(event)).toList()
                : [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                      child: Container(
                        padding: const EdgeInsets.all(12.0),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey[300]!),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.workspace_premium,
                              color: AppTheme.accentColor.withValues(alpha: 0.5),
                              size: 24,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                '過去のログを閲覧するにはプレミアムプランにアップグレードしてください',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ]
            ),
            if (index < sortedDates.length - 1)
              const Divider(height: 32),
          ],
        );
      },
    );
  }
  
  Widget _buildPremiumUpgradeCardForLogs() {
    return Card(
      margin: const EdgeInsets.all(16.0),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.lock_outline,
              size: 48,
              color: AppTheme.accentColor,
            ),
            const SizedBox(height: 16),
            Text(
              '過去のログの全閲覧はプレミアム特典です',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppTheme.textColor,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '無料プランでは直近3日間のログのみご覧いただけます。全ての心の軌跡を振り返るには、プレミアムプランへのアップグレードをご検討ください。',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppTheme.secondaryTextColor, fontSize: 14),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.accentColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30.0),
                ),
              ),
              onPressed: () {
                Navigator.of(context).pushNamed('/settings');
              },
              child: const Text('プレミアムプランを見る'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEventCard(Map<String, dynamic> event) {
    final String mood = event['mood'];
    final String userInput = event['userInput'];
    final String aiResponse = event['aiResponse'];
    final int characterId = event['characterId'] ?? 0;
    
    // Get mood color
    Color moodColor;
    switch (mood) {
      case '喜': // Joy
        moodColor = AppTheme.joyColor;
        break;
      case '怒': // Anger
        moodColor = AppTheme.angerColor;
        break;
      case '哀': // Sadness
        moodColor = AppTheme.sadnessColor;
        break;
      case '楽': // Pleasure
        moodColor = AppTheme.pleasureColor;
        break;
      case '疲': // Tired
        moodColor = AppTheme.tiredColor;
        break;
      case '焦': // Anxiety
        moodColor = AppTheme.anxietyColor;
        break;
      default:
        moodColor = AppTheme.primaryColor;
    }
    
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: () {
          // チャット履歴画面に遷移
          Navigator.of(context).pushNamed('/chat-history');
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: moodColor.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    mood,
                    style: TextStyle(
                      color: moodColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  DateFormat.yMMMd('ja').add_Hm().format(event['timestamp']),
                  style: TextStyle(
                    color: AppTheme.secondaryTextColor,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (userInput.isNotEmpty) ...[
              Text(
                userInput,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Theme.of(context).brightness == Brightness.dark 
                      ? Colors.white 
                      : AppTheme.textColor,
                ),
              ),
              const Divider(height: 24),
            ],
            if (aiResponse.isNotEmpty) ...[
              // まとめのテキストを処理してセクションタイトルのフォントサイズを調整
              _buildFormattedSummary(context, aiResponse),
            ],
          ],
        ),
      ),
      ),
    );
  }
  
  // まとめテキストをフォーマットして表示
  Widget _buildFormattedSummary(BuildContext context, String summary) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final lines = summary.split('\n');
    final List<Widget> widgets = [];
    
    for (final line in lines) {
      if (line.contains('【ユーザーの振り返り】') || line.contains('【アドバイス】')) {
        // セクションタイトルは小さいフォントで
        widgets.add(
          Text(
            line,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: isDarkMode ? Colors.white70 : AppTheme.secondaryTextColor,
              height: 1.5,
            ),
          ),
        );
      } else if (line.trim().isNotEmpty) {
        // 本文は通常サイズで白いフォント
        widgets.add(
          Text(
            line,
            style: AppTheme.handwrittenStyle.copyWith(
              fontSize: 16,
              height: 1.5,
              color: isDarkMode ? Colors.white : AppTheme.textColor,
            ),
          ),
        );
      }
      if (line.trim().isEmpty && widgets.isNotEmpty) {
        widgets.add(const SizedBox(height: 8));
      }
    }
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: widgets,
    );
  }
}
