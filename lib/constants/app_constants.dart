/// アプリケーション全体の定数を管理するクラス
class AppConstants {
  // プライベートコンストラクタ（インスタンス化を防ぐ）
  AppConstants._();

  // ========== アプリ情報 ==========
  /// アプリ名
  static const String appName = 'ねむる';
  
  /// アプリの英語名
  static const String appNameEn = 'nemuru';
  
  /// Bundle ID
  static const String bundleId = 'com.nemuruapp.nemuru';

  // ========== サブスクリプション制限 ==========
  /// 無料プランの1日の会話制限
  static const int freeConversationLimit = 2;
  
  /// プレミアムプランの1日の会話制限
  static const int premiumConversationLimit = 3;
  
  /// 無料プランの1回の会話でのターン数制限
  static const int freeConversationTurns = 5;
  
  /// プレミアムプランの1回の会話でのターン数制限
  static const int premiumConversationTurns = 20;
  
  /// 無料プランで利用可能なキャラクター数
  static const int freeCharacterLimit = 4;
  
  /// 無料プランで閲覧可能なログの日数
  static const int freeLogDaysLimit = 3;

  // ========== 価格情報 ==========
  /// 月額プレミアムプラン価格（円）
  static const int monthlyPremiumPrice = 500;
  
  /// 年額プレミアムプラン価格（円）
  static const int yearlyPremiumPrice = 5000;
  
  /// 月額プレミアムプラン商品ID
  static const String monthlyPremiumProductId = 'nemuru_premium_monthly';
  
  /// 年額プレミアムプラン商品ID
  static const String yearlyPremiumProductId = 'nemuru_premium_yearly';

  // ========== キャラクター関連 ==========
  /// 総キャラクター数
  static const int totalCharacterCount = 12;
  
  /// デフォルトキャラクターID
  static const int defaultCharacterId = 0;
  
  /// 気分アイコンの開始ID
  static const int moodIconStartId = 13;
  
  /// 気分の種類
  static const List<String> moodTypes = ['喜', '怒', '哀', '楽', '疲', '焦'];

  // ========== ローカルストレージキー ==========
  /// チャットログ保存キー
  static const String chatLogsKey = 'chat_logs';
  
  /// プレミアム状態保存キー
  static const String isPremiumKey = 'is_premium';
  
  /// 選択キャラクターID保存キー
  static const String selectedCharacterIdKey = 'selected_character_id';
  
  /// ダークモード設定保存キー
  static const String isDarkModeKey = 'is_dark_mode';
  
  /// オンボーディング完了フラグ保存キー
  static const String onboardingCompletedKey = 'onboarding_completed';
  
  /// 今日の会話回数保存キー
  static const String todayConversationCountKey = 'today_conversation_count';
  
  /// 月間会話回数保存キー
  static const String monthlyConversationCountKey = 'monthly_conversation_count';
  
  /// 最後の会話日付保存キー
  static const String lastConversationDateKey = 'last_conversation_date';
  
  /// 最後の月間リセット日付保存キー
  static const String lastMonthlyResetDateKey = 'last_monthly_reset_date';
  
  /// フォントスケール保存キー
  static const String fontScaleKey = 'font_scale';

  // ========== URL関連 ==========
  /// プライバシーポリシーURL
  static const String privacyPolicyUrl = 'https://nekomura0728.github.io/nemuru/privacy-policy/';
  
  /// 利用規約URL（必要に応じて）
  static const String termsOfServiceUrl = 'https://nekomura0728.github.io/nemuru/terms-of-service.html';

  // ========== 通知関連 ==========
  /// デフォルト通知時刻（23:00）
  static const int defaultNotificationHour = 23;
  static const int defaultNotificationMinute = 0;
  
  /// 通知チャンネルID
  static const String notificationChannelId = 'nemuru_daily_reminder';
  
  /// 通知チャンネル名
  static const String notificationChannelName = 'ねむる 日次リマインダー';

  // ========== 会話関連 ==========
  /// システムプロンプトの最大文字数制限
  static const int maxSystemPromptLength = 2000;
  
  /// ユーザー入力の最大文字数制限
  static const int maxUserInputLength = 300;
  
  /// 会話要約の推奨文字数範囲
  static const int summaryMinLength = 50;
  static const int summaryMaxLength = 100;
  
  /// AI応答の推奨文字数範囲
  static const int aiResponseMinLength = 80;
  static const int aiResponseMaxLength = 120;

  // ========== デバッグ・開発関連 ==========
  /// デバッグモードでのモック応答使用フラグ
  static const bool useDebugMockResponses = false;
  
  /// ログ出力レベル
  static const String logLevel = 'INFO';

  // ========== アクセシビリティ関連 ==========
  /// フォントスケールの最小値
  static const double minFontScale = 0.8;
  
  /// フォントスケールの最大値
  static const double maxFontScale = 1.5;
  
  /// フォントスケールのデフォルト値
  static const double defaultFontScale = 1.0;
  
  /// フォントスケールの刻み幅
  static const double fontScaleStep = 0.1;

  // ========== バリデーション関連 ==========
  /// 最小パスワード長（将来的にアカウント機能を追加する場合）
  static const int minPasswordLength = 8;
  
  /// ユーザー名の最大長（将来的にアカウント機能を追加する場合）
  static const int maxUsernameLength = 20;

  // ========== エラーメッセージ ==========
  /// 気分未選択エラーメッセージ
  static const String moodNotSelectedError = '気分を選択してください';
  
  /// 会話制限到達メッセージ
  static const String conversationLimitReachedMessage = '会話回数の上限に達しました';
  
  /// 送信制限到達メッセージ
  static const String sendLimitReachedMessage = '送信回数の制限に達しました';
  
  /// キャラクター・気分未選択エラーメッセージ
  static const String characterMoodNotSelectedError = 'チャットを開始できませんでした。キャラクターまたは気分が選択されていません。';
  
  /// チャット終了済みメッセージ
  static const String chatAlreadyCompletedMessage = 'このチャットは既に終了し、まとめられています。';

  // ========== 成功メッセージ ==========
  /// 設定保存成功メッセージ
  static const String settingsSavedMessage = '設定を保存しました';
  
  /// プレミアム購入成功メッセージ
  static const String premiumPurchaseSuccessMessage = 'プレミアムプランにアップグレードしました';

  // ========== ダイアログタイトル ==========
  /// 会話制限ダイアログタイトル
  static const String conversationLimitDialogTitle = '会話回数の上限に達しました';
  
  /// 送信制限ダイアログタイトル
  static const String sendLimitDialogTitle = '送信回数の制限に達しました';
  
  /// エラーダイアログタイトル
  static const String errorDialogTitle = 'エラーが発生しました';
  
  /// 確認ダイアログタイトル
  static const String confirmDialogTitle = '確認';

  // ========== ボタンテキスト ==========
  /// 閉じるボタン
  static const String closeButtonText = '閉じる';
  
  /// キャンセルボタン
  static const String cancelButtonText = 'キャンセル';
  
  /// 確認ボタン
  static const String confirmButtonText = '確認';
  
  /// プレミアムアップグレードボタン
  static const String upgradeButtonText = 'プレミアムにアップグレード';
  
  /// 会話をまとめるボタン
  static const String summarizeConversationButtonText = '会話をまとめる';
  
  /// 心を届けるボタン
  static const String sendHeartButtonText = '心を届ける';

  // ========== 設定・ポリシー関連 ==========
  /// 外部URL使用フラグ
  static const bool useExternalUrls = true;
  
  /// AIに関する免責事項
  static const String aiDisclaimer = 'AIによる応答は参考情報であり、医療的なアドバイスではありません。深刻な悩みがある場合は専門家にご相談ください。';
  
  /// プライバシーポリシーテキスト（外部URL使用時は空）
  static const String privacyPolicyText = '';
  
  /// 利用規約テキスト（外部URL使用時は空）
  static const String termsOfServiceText = '''# ねむる アプリ利用規約

## 第1条（適用）
本規約は、ねむるアプリ（以下「本アプリ」）の利用に関して、ねむる運営者（以下「当社」）と利用者との間の権利義務関係を定めるものです。

## 第2条（利用登録）
本アプリはアカウント登録不要でご利用いただけます。デバイス識別子を使用してサービスを提供します。

## 第3条（禁止事項）
利用者は、本アプリの利用にあたり、以下の行為を禁止します：
- 本アプリの機能を不正に利用する行為
- 他の利用者に迷惑をかける行為
- 本アプリの運営を妨害する行為

## 第4条（プレミアムプラン）
### 4.1 サブスクリプション
- 月額プラン：500円（税込）/ 月
- 年額プラン：5,000円（税込）/ 年
- 自動更新されます

### 4.2 解約
- iTunes & App Store設定からいつでも解約可能
- 解約は次の更新日から有効
- 返金は原則行いません

### 4.3 機能
- 1日3回の会話（各20ターン）
- 全キャラクター利用可能
- 無制限ログ閲覧

## 第5条（免責事項）
- AIによる応答は参考情報であり、医療的助言ではありません
- 深刻な悩みは専門家にご相談ください
- サービスの中断・停止による損害は補償しません

## 第6条（プライバシー）
詳細は[プライバシーポリシー](${AppConstants.privacyPolicyUrl})をご確認ください。

## 第7条（規約の変更）
当社は本規約を随時変更することがあります。変更後の利用をもって同意したものとみなします。

## 第8条（準拠法・管轄裁判所）
本規約は日本法に準拠し、東京地方裁判所を専属的合意管轄とします。

---
**制定日：2025年7月16日**
**ねむる運営者**
''';
}