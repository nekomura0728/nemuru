import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:nemuru/models/chat_log.dart';
import 'package:nemuru/models/message.dart';
import 'package:nemuru/theme/app_theme.dart'; // AppTheme for consistent styling

class ChatLogDetailScreen extends StatefulWidget {
  final ChatLog chatLog;

  const ChatLogDetailScreen({super.key, required this.chatLog});

  @override
  State<ChatLogDetailScreen> createState() => _ChatLogDetailScreenState();
}

class _ChatLogDetailScreenState extends State<ChatLogDetailScreen> {
  bool _showFullConversation = false;

  @override
  Widget build(BuildContext context) {
    final String formattedDate = DateFormat('yyyy年MM月dd日 HH:mm').format(widget.chatLog.date);
    final String moodDisplay = "気分: ${widget.chatLog.mood}";
    final String reflectionDisplay = widget.chatLog.reflection?.isNotEmpty == true
        ? "今日の振り返り:\n${widget.chatLog.reflection}"
        : "今日の振り返りはありませんでした。";
    final String summaryDisplay = widget.chatLog.summary?.isNotEmpty == true
        ? "会話のまとめ:\n${widget.chatLog.summary}"
        : "会話の概要はありません。";

    return Scaffold(
      appBar: AppBar(
        title: Text(DateFormat('yyyy/MM/dd').format(widget.chatLog.date)), // タイトルにも日付
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
              widget.chatLog.reflection ?? '記録されていません。',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(height: 1.5),
            ),
            // データベースにadviceカラムが存在しないため、一時的にコメントアウト
            /*
            const SizedBox(height: 24),
            _buildSectionTitle(context, 'AIからのアドバイス'),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).brightness == Brightness.dark
                    ? AppTheme.darkCardColor.withValues(alpha: 0.8)
                    : AppTheme.cardColor.withValues(alpha: 0.9),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppTheme.accentColor.withValues(alpha: 0.3),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Text(
                'アドバイスが記録されていません。',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  height: 1.5,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
            */
            const SizedBox(height: 24),
            _buildSectionTitle(context, 'AIとの会話のまとめ'),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).brightness == Brightness.dark
                    ? AppTheme.darkCardColor.withValues(alpha: 0.8)
                    : AppTheme.cardColor.withValues(alpha: 0.9),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppTheme.accentColor.withValues(alpha: 0.3),
                  width: 1,
                ),
              ),
              child: Text(
                widget.chatLog.summary ?? '記録されていません。',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(height: 1.5),
              ),
            ),
            if (widget.chatLog.fullConversation != null && widget.chatLog.fullConversation!.isNotEmpty) ...[
              const SizedBox(height: 24),
              Center(
                child: ElevatedButton.icon(
                  onPressed: () {
                    setState(() {
                      _showFullConversation = !_showFullConversation;
                    });
                  },
                  icon: Icon(_showFullConversation ? Icons.expand_less : Icons.expand_more),
                  label: Text(_showFullConversation ? '会話の詳細を閉じる' : '会話の詳細を見る'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.accentColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  ),
                ),
              ),
            ],
            if (_showFullConversation && widget.chatLog.fullConversation != null) ...[
              const SizedBox(height: 24),
              _buildSectionTitle(context, '会話の詳細'),
              const SizedBox(height: 16),
              ...widget.chatLog.fullConversation!.map((message) => _buildMessageBubble(context, message)),
            ],
            const SizedBox(height: 24),
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

  Widget _buildMessageBubble(BuildContext context, Message message) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final userBubbleColor = isDarkMode ? AppTheme.darkPrimaryColor : AppTheme.primaryColor;
    final aiBubbleColor = isDarkMode ? AppTheme.darkCardColor : AppTheme.cardColor;
    
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: message.isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!message.isUser) ...[
            const CircleAvatar(
              radius: 16,
              backgroundColor: AppTheme.accentColor,
              child: Icon(Icons.smart_toy, size: 20, color: Colors.white),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: message.isUser ? userBubbleColor : aiBubbleColor,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 2,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    message.content,
                    style: TextStyle(
                      color: message.isUser 
                        ? Colors.white 
                        : (isDarkMode ? Colors.white : Colors.black87),
                      fontSize: 14,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    DateFormat('HH:mm').format(message.timestamp),
                    style: TextStyle(
                      color: message.isUser 
                        ? Colors.white70 
                        : (isDarkMode ? Colors.white54 : Colors.black54),
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (message.isUser) ...[
            const SizedBox(width: 8),
            const CircleAvatar(
              radius: 16,
              backgroundColor: AppTheme.primaryColor,
              child: Icon(Icons.person, size: 20, color: Colors.white),
            ),
          ],
        ],
      ),
    );
  }
}
