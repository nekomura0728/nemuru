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

# Supabase local development
supabase start          # Start local Supabase instance
supabase functions serve chat-completion  # Serve edge functions locally
supabase stop           # Stop local Supabase
```

## Architecture Overview

### Layer Structure
- **Models** (`/lib/models/`): Data structures for Character, ChatLog, Message
- **Services** (`/lib/services/`): Business logic layer with singleton services
- **Screens** (`/lib/screens/`): UI presentation layer
- **Widgets** (`/lib/widgets/`): Reusable UI components

### State Management
- Provider pattern with ChangeNotifier for reactive updates
- Services injected at app root via MultiProvider
- Persistent state via SharedPreferences (local) and Supabase (remote)

### Key Services
- **GPTService**: Manages AI conversations with GPT-4o mini, character selection, and optimized prompts
- **ChatLogService**: CRUD operations for chat history with Supabase persistence
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