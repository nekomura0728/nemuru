import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // For date formatting
import 'package:provider/provider.dart';
import 'package:nemuru/models/chat_log.dart';
import 'package:nemuru/services/chat_log_service.dart';
// import 'ai_response_screen.dart'; // AIResponseScreenへの直接遷移は変更
import 'chat_log_detail_screen.dart'; // 新しい詳細画面（後で作成）

class ChatHistoryScreen extends StatelessWidget {
  const ChatHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
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
        title: const Text('チャット履歴'),
      ),
      body: Consumer<ChatLogService>(
        builder: (context, chatLogService, child) {
          final logs = chatLogService.logs;

          if (logs.isEmpty) {
            return const Center(
              child: Text('チャット履歴はありません。'),
            );
          }

          // Sort logs by date, newest first
          logs.sort((a, b) => b.date.compareTo(a.date));

          return ListView.builder(
            itemCount: logs.length,
            itemBuilder: (context, index) {
              final log = logs[index];
              String formattedDate = DateFormat('yyyy/MM/dd').format(log.date); // 時刻は不要なら削除
              
              String reflectionText = log.reflection?.isNotEmpty == true ? "振り返り: ${log.reflection}" : "振り返りなし";
              String summaryText = log.summary?.isNotEmpty == true ? "会話のまとめ: ${log.summary}" : "概要なし";
              
              // reflectionとsummaryを結合して表示、長すぎる場合は省略
              String subtitleContent = reflectionText;
              if (log.summary?.isNotEmpty == true) {
                subtitleContent += "\n$summaryText";
              }
              if (subtitleContent.length > 80) { // 表示文字数制限
                  subtitleContent = "${subtitleContent.substring(0, 80)}...";
              }

              return ListTile(
                title: Text('$formattedDate - ${log.mood}'),
                subtitle: Text(subtitleContent, maxLines: 3, overflow: TextOverflow.ellipsis),
                trailing: const Icon(Icons.arrow_forward_ios),
                onTap: () {
                  if (log.summary != null) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ChatLogDetailScreen(chatLog: log),
                      ),
                    );
                  } else {
                    // もしsummaryがnullのログ（中断されたチャットなど）を再開させたい場合は
                    // AIResponseScreenに遷移するロジックをここに入れることも可能
                    // Navigator.push(
                    //   context,
                    //   MaterialPageRoute(
                    //     builder: (context) => AIResponseScreen(chatLog: log),
                    //   ),
                    // );
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('このチャットはまだ完了していません。AIとの会話画面から再開してください。')),
                    );
                  }
                },
              );
            },
          );
        },
      ),
    );
  }
}
