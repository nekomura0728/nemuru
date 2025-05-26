import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:nemuru/models/chat_log.dart';
import 'package:nemuru/theme/app_theme.dart'; // AppTheme for consistent styling

class ChatLogDetailScreen extends StatelessWidget {
  final ChatLog chatLog;

  const ChatLogDetailScreen({super.key, required this.chatLog});

  @override
  Widget build(BuildContext context) {
    final String formattedDate = DateFormat('yyyy年MM月dd日 HH:mm').format(chatLog.date);
    final String moodDisplay = "気分: ${chatLog.mood}";
    final String reflectionDisplay = chatLog.reflection?.isNotEmpty == true
        ? "今日の振り返り:\n${chatLog.reflection}"
        : "今日の振り返りはありませんでした。";
    final String summaryDisplay = chatLog.summary?.isNotEmpty == true
        ? "会話のまとめ:\n${chatLog.summary}"
        : "会話の概要はありません。";

    return Scaffold(
      appBar: AppBar(
        title: Text(DateFormat('yyyy/MM/dd').format(chatLog.date)), // タイトルにも日付
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              formattedDate,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppTheme.secondaryTextColor,
                  ),
            ),
            const SizedBox(height: 12),
            Text(
              moodDisplay,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    // Optionally, color code based on mood if desired
                  ),
            ),
            const SizedBox(height: 20),
            _buildSectionTitle(context, '今日の出来事・感じたこと'),
            const SizedBox(height: 8),
            Text(
              chatLog.reflection ?? '記録されていません。',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(height: 1.5),
            ),
            const SizedBox(height: 24),
            _buildSectionTitle(context, 'AIとの会話のまとめ'),
            const SizedBox(height: 8),
            Text(
              chatLog.summary ?? '記録されていません。',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(height: 1.5),
            ),
            const SizedBox(height: 24),
            // Add more details or actions if needed
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w600,
            color: AppTheme.primaryColor, // Or your preferred title color
          ),
    );
  }
}
