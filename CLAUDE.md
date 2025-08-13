# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Nemuru is a Flutter-based sleep and mood tracking app with AI-powered responses. It features daily mood check-ins, personalized AI conversations via GPT-4o mini, and a subscription-based model.

## Development Commands

```bash
# Flutter commands
flutter pub get          # Install dependencies
flutter analyze         # Run static analysis and linting
flutter test            # Run all tests
flutter test test/widget_test.dart  # Run specific test file
flutter build ios       # Build for iOS
flutter build apk       # Build for Android
flutter run             # Run in development mode

# Git自動コミット設定
git add . && git commit -m "自動保存: $(date '+%Y-%m-%d %H:%M:%S')" # 自動保存用

# 推奨開発フロー
flutter analyze         # 静的解析 (必須)
flutter test            # テスト実行後
git add . && git commit -m "feat: 機能追加/修正内容" && git push  # 自動プッシュ

# Supabase local development
supabase start          # Start local Supabase instance
supabase functions serve chat-completion  # Serve edge functions locally
supabase stop           # Stop local Supabase

# iOS App Store リリース手順
# バージョンアップしてビルド・アップロード
# 1. pubspec.yamlのversion（+の後のビルド番号）を上げる
# 2. 以下のコマンドでビルド
flutter clean
flutter pub get
flutter build ipa
# 3. Xcodeでアップロード
open ios/Runner.xcworkspace
# Xcode内で: Product → Archive → Distribute App → App Store Connect → Upload
```

## Architecture Overview

### Layer Structure
- **Models** (`/lib/models/`): Data structures for Character, ChatLog, Message, UserProfile
- **Services** (`/lib/services/`): Business logic layer with singleton services
- **Screens** (`/lib/screens/`): UI presentation layer
- **Widgets** (`/lib/widgets/`): Reusable UI components

### State Management
- Provider pattern with ChangeNotifier for reactive updates
- Services injected at app root via MultiProvider
- Persistent state via SharedPreferences (local) and Supabase (remote)

### Key Services
- **GPTService**: Manages AI conversations with GPT-4o mini, character selection, optimized prompts, and personalization
- **ChatLogService**: CRUD operations for chat history with local persistence and user profile analysis
- **SubscriptionService**: Handles Free/Premium tiers with usage limits (Free: 2 chats/day, Premium: 3 chats/day)
- **PreferencesService**: Local settings storage including dark mode, character selection, font size
- **NotificationService**: Daily reminder notifications at 23:00
- **CharacterImageWidget**: Optimized character image display with proper state management

### Navigation
- Named routes with `onGenerateRoute` for parameter passing
- Main screens: CheckInScreen, LogScreen, SettingsScreen, HelpScreen
- Modal dialogs for upgrades and errors via ErrorHandlingService

### Backend Integration
- Supabase for data persistence and edge functions
- Edge function at `/chat-completion` proxies OpenAI GPT-4o mini API
- Structured prompts optimized for GPT-4o mini performance
- 12 conversation approach patterns with empathy techniques
- Device-based identification using UUID (no user accounts)
- CORS-enabled for web compatibility

### Subscription Model
- **Free Tier**: 2 conversations/day, 4 characters, 3-day log history
- **Premium Tier**: 3 conversations/day, all characters, unlimited history
- Usage tracking resets daily at midnight

### Testing & Quality
- Standard Flutter lints via analysis_options.yaml
- Widget tests in `/test/` directory
- Run `flutter analyze` before committing
- Code quality improvements: removed debug prints, unused imports
- Optimized character image rendering with CharacterImageWidget

### AI機能の最適化
- **Model**: GPT-4o mini for cost-effective and fast responses
- **Structured Prompts**: Organized with ROLE, TASK, CONSTRAINTS sections
- **Empathy Techniques**: Mirroring, Validation, Active Listening
- **Response Patterns**: 12 different approach patterns for varied conversations
- **Sleep Enhancement**: Breathing exercises, relaxation techniques included
- **Character Consistency**: 12 distinct characters with proper image-name matching

## 最新の改善点

### GitHub Actions CI/CD実装（2025年6月26日実装）
- **SSL問題解決**: 企業環境のビルドエラーをGitHub Actionsで回避
- **自動化パイプライン**: Flutter CI/CD・セキュリティスキャン・リリース自動化
- **品質向上**: 静的解析167件→151件、print文16件→0件に改善
- **セキュリティ強化**: 課金システムバイパス脆弱性を完全修正
- **非同期安定化**: クラッシュリスク軽減（15箇所→12箇所）

### P0/P1セキュリティ・品質修正（2025年6月26日実装）
- **課金セキュリティ**: モック検証バイパスを削除、適切なサーバーサイド検証実装
- **API設定管理**: ApiConstants.dartで環境別設定を統一管理
- **デバッグ情報漏洩防止**: 全print文を削除、本番環境での情報漏洩を完全防止
- **非同期コンテキスト修正**: mounted checkでクラッシュリスクを軽減

### 振り返り機能の刷新（2025年6月14日実装）
- **概要表示のみに変更**: 従来の「内容+アドバイス」構成から簡潔な概要（50-100文字）に変更
- **全会話ログ保存**: ChatLogモデルにfullConversationフィールドを追加
- **詳細表示機能**: chat_log_detail_screen.dartに「会話の詳細を見る」ボタンを追加
- **チャットバブル形式**: 全会話をユーザー/AI別に見やすく表示
- **GPTプロンプト最適化**: 要約生成を概要専用プロンプトに変更

### 軽量パーソナライゼーション機能（2025年6月14日実装）
- **UserProfileクラス**: 気分傾向、よく話すトピック、関係性レベルを分析
- **軽量設計**: APIコスト最小限（2-3行の簡潔な情報のみプロンプトに追加）
- **傾向分析**: 過去ログから最頻気分、キーワード抽出、関係性レベル判定
- **口調調整**: 関係性（初回→慣れてきた→親しい）に応じた自然な会話
- **リアルタイム分析**: ChatLogServiceで動的にユーザープロファイルを生成

### データモデル拡張
```dart
// ChatLogモデルの追加フィールド
final List<Message>? fullConversation; // 会話の全ログ

// 新規UserProfileモデル
class UserProfile {
  final String frequentMood;        // 最頻気分
  final List<String> commonTopics;  // よく話すトピック
  final int conversationCount;      // 総会話回数
  final String relationshipLevel;   // 関係性レベル
}
```

### 技術実装詳細
- **ChatLogService.analyzeUserProfile()**: ユーザー傾向を軽量分析
- **GPTService.setUserProfile()**: パーソナライゼーション情報をプロンプトに統合
- **キーワード抽出**: 「仕事」「疲れ」「友達」など11カテゴリのトピック分析
- **関係性判定**: 会話回数に基づく段階的な親しみやすさ調整

### UI/UX改善
- 気持ち選択時の説明文を入力欄上に移動、見やすいデザインに変更
- 気持ちアイコンサイズを拡大（50px → 70px）
- 選択時の不要な円装飾を削除
- オンボーディングボタン色を統一（水色）
- キャラクター名とアイコンの不一致を全修正

### 技術的改善
- CharacterImageWidgetでキャラクター画像の白表示問題を解決
- GPT-4o mini用にプロンプトを構造化・最適化
- コード品質向上（デバッグprint削除、未使用import削除）
- 完全ローカル保存への移行完了（Supabaseデータベース不使用）

## Android リリース進捗（2025年6月5日完了）

### ✅ 完了済み項目

#### ビルド・署名設定
- **AAB ファイル生成**: `/Users/s.maemura/nemuru/build/app/outputs/bundle/release/app-release.aab` (53MB)
- **キーストア作成**: `nemuru-upload-key.jks` で署名設定完了
- **Netskope SSL証明書問題**: 解決済み（企業環境での gradle 設定対応）
- **Core Library Desugaring**: flutter_local_notifications v17.2.3 対応完了
- **API レベル35対応**: Flutter 3.32.0でGoogle Play要件（レベル34）を上回る対応済み

#### Google Play Console 設定
- **アプリ登録**: `com.nemuruapp.nemuru` として登録完了
- **プライバシーポリシー**: https://nekomura0728.github.io/nemuru/privacy-policy/ で公開済み
- **データ安全性**: 購入履歴、パフォーマンスデータ、ユーザー作成コンテンツ、デバイスID の設定完了
- **健康関連機能**: 睡眠管理、ストレス管理・リラクゼーション機能として申告済み
- **金融取引機能**: 「金融取引機能なし」として申告済み
- **ストア掲載情報**: デフォルト設定完了

#### テスト設定
- **内部テスト**: リリース 1.0.0 (内部テスト版) 公開済み（6月5日 12:55）
- **テスター招待**: 2名のテスターを招待済み、テストリンク生成完了
- **対応デバイス**: 20,424台のAndroidデバイス
- **ライセンステスト**: RESPOND_NORMALLY で設定済み

#### 課金システム設定
- **月額プラン**: `nemuru_premium_monthly` - 500円/月 設定完了
- **年額プラン**: `nemuru_premium_yearly` - 5000円/年 設定完了
- **価格設定**: 日本市場のみで配信設定

### ⏳ 次のステップ
1. **課金機能テスト**: 内部テスターによる購入フローのテスト実行
2. **クローズドテスト**: 外部ユーザー向けテスト（12名以上、14日間以上）
3. **製品版リリース**: 審査通過後の一般公開

### 🔧 技術的な重要設定

#### SSL証明書対応（Netskope環境）
```properties
# android/gradle.properties
org.gradle.jvmargs=-Xmx4096m -Dfile.encoding=UTF-8 -Dtrust_all_cert=true
android.javaCompile.suppressSourceTargetDeprecationWarning=true
```

#### 署名設定
```kotlin
// android/app/build.gradle.kts
signingConfigs {
    create("release") {
        keyAlias = "nemuru"
        keyPassword = "nemurupass"
        storeFile = file("../nemuru-upload-key.jks")
        storePassword = "nemurupass"
    }
}
```

#### ビルドコマンド
```bash
# 最終的に成功したビルドコマンド
flutter build appbundle --release
# 出力: /Users/s.maemura/nemuru/build/app/outputs/bundle/release/app-release.aab
```

## Gemini CLI 連携ガイド

### 目的
ユーザーが **「Geminiと相談しながら進めて」** （または同義語）と指示した場合、Claude は以降のタスクを **Gemini CLI** と協調しながら進める。
Gemini から得た回答はそのまま提示し、Claude 自身の解説・統合も付け加えることで、両エージェントの知見を融合する。

**Gemini CLI 呼び出し**
```bash 
gemini -p "$PROMPT"
```

**Gemini Websearch 呼び出し**
```bash
gemini -p "WebSearch: ..."
```

## SuperClaude開発設定

### Git自動保存設定
- **自動コミット**: 作業後は自動でgit commit実行
- **プッシュ戦略**: 機能完了時のみpush（作業中は頻繁なローカルコミット）
- **ブランチ戦略**: feature/fix-security → main へのPRワークフロー

### 優先開発順序
1. **P0 (緊急)**: セキュリティ修正 → 自動コミット
2. **P1 (高)**: 静的解析エラー修正 → 自動コミット  
3. **P2 (中)**: パフォーマンス最適化 → 自動コミット
4. **P3 (低)**: アーキテクチャ改善 → 機能PR

### Claude Code作業パターン
- 修正完了 → `flutter analyze` → 自動git commit
- テスト完了 → `flutter test` → 自動git commit
- 機能完了 → 手動PR作成・レビュー

## 開発継続ガイド

### 重要な実装済み機能
1. **振り返り機能**: 概要表示+詳細展開式（ChatLog.fullConversation使用）
2. **パーソナライゼーション**: 軽量ユーザープロファイル分析（UserProfile使用）
3. **完全ローカル保存**: SharedPreferencesによる高速・低コスト運用
4. **課金システム**: Free/Premium階層、使用制限管理

### 次の開発候補
- **通知機能強化**: よりパーソナライズされた通知タイミング
- **キャラクター追加**: 新しい個性とキャラクター画像
- **データ分析**: ユーザー行動パターンのさらなる活用
- **多言語対応**: 英語版の展開準備

### 開発時の注意事項
- APIコスト最小化を常に意識（GPT-4o mini使用、プロンプト最適化）
- ローカル保存前提のデータ設計を維持
- プライバシーファーストの開発方針を継続

## リリース進行状況（2025年7月18日更新）

### Android版リリース状況
- **✅ 完了済み**: AABファイル生成、Google Play Console設定、内部テスト公開
- **🔄 進行中**: 内部テスト実施中（課金機能テストを含む）
- **📋 次のステップ**: クローズドテスト（12名以上、14日間）→ 製品版リリース

### iOS版リリース状況（2025年7月18日）
- **✅ 完了済み**: 
  - Apple Developer アカウント取得
  - Xcode署名設定・プロビジョニングプロファイル設定
  - App Store Connect アプリ登録
  - TestFlight設定とベータテスト
  - ビルド20を審査提出（2025年7月15日）→ 審査却下
  - **審査却下対応完了（2025年7月18日）**:
    - 利用規約ページ作成・公開
    - サポートページ作成・公開
    - App Store Connect メタデータ更新
    - バージョン 1.0.16+25 ビルド完了
- **🔄 進行中**: 再審査申請準備完了（2025年7月18日）
- **📋 審査通過後のタスク**:
  1. アプリを公開（手動または自動）
  2. 実際の購入テスト実施

### 共通準備済み項目
- Bundle ID統一: `com.nemuruapp.nemuru` (Android/iOS共通)
- アプリ名: 「ねむる」
- 課金プラン: 月額500円、年額5000円
- プライバシーポリシー: https://nekomura0728.github.io/nemuru/privacy-policy/
- ストア掲載情報完備（Android/iOS版）

### 今後の重要タスク
#### 短期（審査・テスト完了後すぐ）
- [ ] iOS署名証明書・プロビジョニングプロファイル設定
- [ ] App Store Connect アプリ登録
- [ ] iOS TestFlight 設定
- [ ] Android クローズドテスト移行
- [ ] 両プラットフォームでの課金機能最終テスト

#### 中期（リリース後）
- [ ] ユーザーフィードバック収集・分析
- [ ] パフォーマンス監視とクラッシュ対応
- [ ] アップデート版リリース計画
- [ ] マーケティング戦略実行

#### 長期（機能拡張）
- [ ] 通知機能のパーソナライゼーション強化
- [ ] 新キャラクター追加（音声対応検討）
- [ ] 睡眠データ分析機能の高度化
- [ ] 多言語対応（英語版）
- [ ] ウェアラブルデバイス連携検討

## iOS購入検証システム実装（2025年7月15日）

### Supabase Edge Function設定
- **プロジェクト**: `ldellkrfbgzrheisjret.supabase.co`
- **関数**: `verify-purchase` - iOS/Android購入検証
- **APIキー**: 正しいAnon Keyに更新（ビルド20）

### 購入検証の問題と解決
1. **HTTP 401エラー**: APIキーが古い→最新のキーに更新
2. **Apple Receipt 21002エラー**: TestFlight環境の制限
   - レシートフォーマットの問題
   - 一時的に21002エラーを許可（TestFlight環境のみ）
   - 本番リリース後は厳密な検証に戻す必要あり

### 環境変数設定
```bash
supabase secrets set APPLE_SHARED_SECRET=<App Store Connect共有シークレット> --project-ref ldellkrfbgzrheisjret
```

### Edge Function修正内容
- サンドボックスURL固定（TestFlight用）
- レシートのBase64エンコード自動処理
- 21002エラーの一時的許可
- 詳細ログ追加

## App Store審査対応履歴

### 初回審査却下（2025年7月17日）
**却下理由：**
1. **Guideline 2.1**: インアプリ購入商品が審査に未提出
2. **Guideline 3.1.2**: 利用規約（EULA）リンクの不足

### 第1回対応（2025年7月18日）
- 利用規約・サポートページ作成
- App Store Connect設定更新  
- 購入機能デバッグ強化
- バージョン 1.0.16+24 → 1.0.16+25

### 第2回審査却下（2025年7月XX日）
**却下理由：**
- **Guideline 3.1.2**: アプリ内にプライバシーポリシーと利用規約への機能的なリンクが不足

### 第2回対応（2025年7月21日）
**アプリ内リンク追加完了：**
- ✅ **設定画面のサブスクリプション購入ダイアログ**にリンク追加
- ✅ **AI応答画面の会話制限ダイアログ**（無料プランのみ）にリンク追加  
- ✅ **AI応答画面の送信回数制限ダイアログ**（無料プランのみ）にリンク追加
- ✅ **チェックイン画面の会話制限ダイアログ**（無料プランのみ）にリンク追加

**サブスクリプション情報明確化：**
- ✅ タイトル：「ねむるプレミアム - 自動更新サブスクリプション」
- ✅ 価格・期間：「月額プラン ¥500 / 月」「年額プラン ¥5,000 / 年」  
- ✅ 自動更新の明記

**URL設定完了：**
- ✅ 利用規約: https://nekomura0728.github.io/nemuru/terms-of-service.html
- ✅ プライバシーポリシー: https://nekomura0728.github.io/nemuru/privacy-policy/
- ✅ サポートページ: https://nekomura0728.github.io/nemuru/support.html
- ✅ `useExternalUrls = true` に設定（外部ブラウザでリンク開く）

**リンク修正：**
- ✅ support.html内のリンクを相対パスに修正
- ✅ terms-of-service.html内の無効リンクを修正（privacy-policy.html → privacy-policy/、index.html → support.html）

**技術的修正：**
- ✅ iOSビルド完了（41.1MB、署名済み）
- ✅ バージョン更新準備
- ✅ GitHub Pagesリンク修正とプッシュ完了

### App Store Connect設定チェックリスト
- [ ] **プライバシーポリシーURL**: `https://nekomura0728.github.io/nemuru/privacy-policy/`
- [ ] **サポートURL**: `https://nekomura0728.github.io/nemuru/support.html`（設定済み）
- [ ] **カスタムEULA設定** または **アプリ説明欄に利用規約リンク追加**
- [ ] **新しいビルドアップロード**（バージョン番号を上げる）

**第2回再審査での予想結果:** アプリ内の機能的なリンク要件を完全に満たしたため、承認の可能性が非常に高い

## GitHub Pages 運用ガイド

### URL構造とファイル対応（重要）

| URL | 実際のファイルパス | 用途 |
|-----|------------------|------|
| `https://nekomura0728.github.io/nemuru/support.html` | `docs/support.html` | App Store Connect サポートURL |
| `https://nekomura0728.github.io/nemuru/terms-of-service.html` | `docs/terms-of-service.html` | 利用規約 |
| `https://nekomura0728.github.io/nemuru/privacy-policy/` | `docs/privacy-policy/index.html` | プライバシーポリシー |

### URL構造ルール
- **`.html`で終わるURL** → 同名のHTMLファイル
- **`/`で終わるURL** → ディレクトリ内の`index.html`

### 404エラー時の対応手順
1. **必ず現状確認**: `ls -la docs/` でファイル存在を確認
2. **Git履歴確認**: `git log --oneline -- docs/` で過去の変更を確認
3. **ファイル検索**: `find docs -name "*.html" -type f` で実際のパス確認
4. **修正後**: 相対パスでリンク記述（例: `href="terms-of-service.html"`）

### 教訓（2025年7月21日）
- URLの`/`終わりを見てディレクトリと勘違いしない
- 404エラーでもGitHub Pages全体の問題ではない場合がある
- **変更前に必ず現在のファイル構造を確認**

## 最新の開発完了項目（2025年6月26日 ～ 2025年7月15日）

### Web互換性実装完了 ✅
- **Chrome実行対応**: Flutter WebでChromeブラウザでの動作テストが可能に
- **プラットフォーム分離**: Web/Mobile専用機能を適切に分離
- **Webスタブ作成**: 
  - `web_purchase_stub.dart` - 課金機能のモック実装
  - `web_notification_stub.dart` - 通知機能のモック実装  
  - `web_timezone_stub.dart` - タイムゾーン機能のモック実装
  - `web_platform_stub.dart` - プラットフォーム判定のモック実装
- **条件付きインポート**: `dart:io` vs `dart:html` の適切な使い分け実装

### キャラクター差別化システム完成 ✅
- **12キャラクター個性実装**: 各キャラクターの独自性格・共感スタイル・質問スタイル・アドバイススタイル・得意分野を詳細定義
- **GPT統合**: キャラクター特性をGPTプロンプトに組み込み、会話に反映
- **語尾変更なし**: アプリの真面目なテーマに配慮し、語尾変更ではなく対話スタイルで差別化

### 会話制限システム正確化 ✅
- **制限値調整**: フリープラン5ターン、プレミアムプラン20ターン
- **メッセージ統一**: 全画面でのプレミアム誘導文言を正確な数値に統一
  - ホーム画面制限ダイアログ
  - AI応答画面制限ダイアログ  
  - 設定画面プラン比較
  - ヘルプ画面FAQ
  - ストア掲載情報
- **会話フェーズ調整**: GPTプロンプトの会話想定を7回→5回に最適化

### コード品質大幅改善 ✅
- **101件 → 65件**: 静的解析問題を35.6%改善
- **警告レベル削減**: 未使用import削除、デッドコード特定
- **Web互換性確保**: プラットフォーム固有コードの安全な処理
- **非同期処理安定化**: mounted checkによるクラッシュリスク軽減

### 技術的成果
- **条件付きコンパイル**: Web/Mobile環境での適切なライブラリ選択システム
- **プラットフォーム抽象化**: 購入・通知・プラットフォーム検出の統一インターフェース
- **エラーハンドリング強化**: Web環境での適切なフォールバック処理

