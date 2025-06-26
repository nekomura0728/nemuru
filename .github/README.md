# 🚀 GitHub Actions CI/CD Pipeline

このディレクトリには、Nemuru アプリの自動化されたCI/CDパイプラインが含まれています。

## 📋 ワークフロー概要

### 1. 🔄 Flutter CI/CD Pipeline (`flutter-ci.yml`)
**トリガー**: プッシュ・プルリクエスト  
**目的**: 継続的インテグレーションとデプロイメント

#### フェーズ:
- **📊 Static Analysis & Tests**: コード品質チェック・単体テスト実行
- **🤖 Build Android**: APK・AABファイルの生成
- **🍎 Build iOS**: iOSアプリのビルド  
- **🚀 Deploy**: メインブランチでの自動リリース
- **📊 Generate Report**: ビルド結果レポート生成

#### 成果物:
- Debug APK
- Release APK  
- Release AAB (Google Play用)
- iOS Build
- Coverage Report
- Build Report

### 2. 🔒 Security Scan (`security-scan.yml`)
**トリガー**: プッシュ・プルリクエスト・毎日定時実行  
**目的**: セキュリティ脆弱性の早期発見

#### チェック項目:
- 🚨 Print文の検出（情報漏洩防止）
- 🔐 ハードコードされたシークレットの検出
- 🌐 HTTP接続の検出（HTTPS推奨）
- 🧩 依存関係のセキュリティチェック

#### 成果物:
- Security Report
- Dependency Report
- PR自動コメント

### 3. 🏷️ Release Build (`release.yml`)
**トリガー**: タグプッシュ・手動実行  
**目的**: 正式リリース版の自動生成

#### フェーズ:
- **🏷️ Prepare Release**: バージョン管理・変更履歴生成
- **🤖 Build Android Release**: リリース用APK・AAB生成
- **🍎 Build iOS Release**: リリース用iOSビルド
- **🚀 Create GitHub Release**: GitHubリリース自動作成

#### 成果物:
- リリース用APK・AAB
- iOS App Store用ビルド
- リリースノート
- GitHub Release

## 🎯 使用方法

### 通常の開発フロー
1. **開発ブランチでプッシュ** → `flutter-ci.yml` が自動実行
2. **プルリクエスト作成** → CI/CDパイプライン + セキュリティスキャン実行
3. **メインブランチにマージ** → 自動デプロイメント実行

### リリースフロー
1. **リリースタグ作成**:
   ```bash
   git tag v1.0.9
   git push origin v1.0.9
   ```
2. **自動リリースビルド実行** → GitHub Releaseが自動作成

### 手動リリース
1. **GitHub Actions** → **Release Build** → **Run workflow**
2. **Release type選択** (patch/minor/major)
3. **手動実行**

## 📊 バッジ・ステータス

以下のバッジをREADME.mdに追加することを推奨:

```markdown
![Flutter CI](https://github.com/yourusername/nemuru/workflows/Flutter%20CI%2FCD%20Pipeline/badge.svg)
![Security Scan](https://github.com/yourusername/nemuru/workflows/Security%20Scan/badge.svg)
![Release](https://github.com/yourusername/nemuru/workflows/Release%20Build/badge.svg)
```

## 🔧 設定・カスタマイズ

### 環境変数
- `FLUTTER_VERSION`: 使用するFlutterバージョン（現在: 3.32.0）
- `JAVA_VERSION`: Javaバージョン（現在: 17）

### 追加設定が必要な項目
1. **コード署名** (iOS): Apple Developer証明書の設定
2. **Play Store Upload**: Google Play Console API設定
3. **Secrets管理**: GitHub Secretsでの機密情報管理

### カスタマイズポイント
- **テスト実行時間**: 大規模プロジェクト向けのタイムアウト調整
- **通知設定**: Slack・Discordなどへの結果通知
- **デプロイ先**: Firebase App Distribution等の追加

## 🚨 トラブルシューティング

### よくある問題
1. **ビルドエラー**: 依存関係の問題 → `flutter pub get`の確認
2. **テスト失敗**: テストファイルの修正が必要
3. **iOS署名エラー**: Apple Developer設定の確認

### デバッグ方法
1. **GitHub Actions** → **該当ワークフロー** → **ログ確認**
2. **Artifacts** → **ビルドレポート**でエラー詳細を確認
3. **Re-run failed jobs** でリトライ

## 📈 メトリクス・改善点

### 現在の改善点
- ✅ SSL証明書問題の回避
- ✅ 自動化によるビルド時間短縮
- ✅ セキュリティチェックの自動化
- ✅ リリース作業の自動化

### 今後の拡張案
- 🔄 自動テストカバレッジ向上
- 📱 実機テストの自動化
- 🚀 ステージング環境への自動デプロイ
- 📊 パフォーマンス監視の統合

---
🤖 Generated with [Claude Code](https://claude.ai/code)