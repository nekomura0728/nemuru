import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:nemuru/services/chat_log_service.dart';
import 'package:nemuru/services/preferences_service.dart';
import 'package:nemuru/models/chat_log.dart';
import 'package:nemuru/models/message.dart';

/// スクリーンショット撮影用のヘルパークラス
/// デバッグビルドでのみ使用可能
class ScreenshotHelper {
  static Future<void> setupSampleData(BuildContext context) async {
    final chatLogService = Provider.of<ChatLogService>(context, listen: false);
    final preferencesService = Provider.of<PreferencesService>(context, listen: false);
    
    // サンプルデータをクリア
    await chatLogService.clearAllLogs();
    
    // キャラクターを設定（犬）
    await preferencesService.setSelectedCharacterId(1);
    
    // サンプルのチャットログを作成
    final now = DateTime.now();
    
    // 1. 今日の記録（喜び）
    final log1 = ChatLog(
      id: 'sample1',
      deviceId: 'screenshot-device',
      mood: '喜',
      reflection: '新しいプロジェクトが始まって、少し緊張したけど、チームのみんなが優しくて安心しました。明日も頑張れそうです。',
      characterId: 1,
      createdAt: now,
      messages: [
        Message(
          role: 'user',
          content: '新しいプロジェクトが始まって、少し緊張したけど、チームのみんなが優しくて安心しました。明日も頑張れそうです。',
          timestamp: now,
        ),
        Message(
          role: 'assistant',
          content: '新しい挑戦にワクワクドキドキだね！優しいチームメンバーに恵まれて本当によかった。きっと素敵なプロジェクトになるよ。今夜はゆっくり休んで、明日も一緒に頑張ろう！',
          timestamp: now.add(Duration(seconds: 2)),
        ),
        Message(
          role: 'user',
          content: 'ありがとう。少し不安だったけど、話を聞いてもらえて楽になりました。',
          timestamp: now.add(Duration(seconds: 5)),
        ),
        Message(
          role: 'assistant',
          content: '不安な気持ちを共有してくれてありがとう。新しいことを始めるときは誰でもドキドキするものだよ。でも、君なら大丈夫！おやすみなさい、いい夢を見てね。',
          timestamp: now.add(Duration(seconds: 7)),
        ),
      ],
    );
    
    // 2. 昨日の記録（疲）
    final log2 = ChatLog(
      id: 'sample2',
      deviceId: 'screenshot-device',
      mood: '疲',
      reflection: '今日は会議が続いて疲れました。でも、プロジェクトの方向性が見えてきて、やりがいも感じています。',
      characterId: 1,
      createdAt: now.subtract(Duration(days: 1)),
      messages: [
        Message(
          role: 'user',
          content: '今日は会議が続いて疲れました。でも、プロジェクトの方向性が見えてきて、やりがいも感じています。',
          timestamp: now.subtract(Duration(days: 1)),
        ),
        Message(
          role: 'assistant',
          content: '長い会議お疲れさま！疲れの中にもやりがいを見つけられる君は素晴らしいね。今夜はゆっくりお風呂に浸かって、心と体を癒してあげて。',
          timestamp: now.subtract(Duration(days: 1)).add(Duration(seconds: 2)),
        ),
      ],
    );
    
    // 3. 2日前の記録（楽）
    final log3 = ChatLog(
      id: 'sample3',
      deviceId: 'screenshot-device',
      mood: '楽',
      reflection: '週末は友達と久しぶりに会えて楽しかった。美味しいものを食べて、たくさん笑いました。',
      characterId: 1,
      createdAt: now.subtract(Duration(days: 2)),
      messages: [
        Message(
          role: 'user',
          content: '週末は友達と久しぶりに会えて楽しかった。美味しいものを食べて、たくさん笑いました。',
          timestamp: now.subtract(Duration(days: 2)),
        ),
        Message(
          role: 'assistant',
          content: '友達との楽しい時間、最高だね！美味しいものと笑顔は心の栄養だよ。その幸せな気持ちを胸に、ぐっすり眠ろう。きっと楽しい夢が見られるよ！',
          timestamp: now.subtract(Duration(days: 2)).add(Duration(seconds: 2)),
        ),
      ],
    );
    
    // データを保存
    await chatLogService.saveLog(log1);
    await chatLogService.saveLog(log2);
    await chatLogService.saveLog(log3);
  }
  
  /// スクリーンショット撮影モードの設定
  static void configureForScreenshots(BuildContext context) {
    final preferencesService = Provider.of<PreferencesService>(context, listen: false);
    
    // 理想的な設定
    preferencesService.setDarkMode(false); // ライトモードで撮影
    preferencesService.setSelectedCharacterId(1); // 犬のキャラクター
    
    // 通知は23:00に設定（夜の使用を想定）
    preferencesService.setNotificationTime(TimeOfDay(hour: 23, minute: 0));
  }
}