import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:nemuru/constants/app_constants.dart';
import 'package:nemuru/theme/app_theme.dart';

/// プライバシーポリシーと利用規約を表示する画面
class PolicyScreen extends StatelessWidget {
  final String title;
  final String content;

  const PolicyScreen({
    Key? key,
    required this.title,
    required this.content,
  }) : super(key: key);

  /// プライバシーポリシー画面を表示するためのファクトリーコンストラクタ
  factory PolicyScreen.privacyPolicy() {
    return const PolicyScreen(
      title: 'プライバシーポリシー',
      content: AppConstants.privacyPolicyText,
    );
  }

  /// 利用規約画面を表示するためのファクトリーコンストラクタ
  factory PolicyScreen.termsOfService() {
    return const PolicyScreen(
      title: '利用規約',
      content: AppConstants.termsOfServiceText,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          title,
          style: Theme.of(context).textTheme.titleLarge,
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Markdown(
          data: content,
          styleSheet: MarkdownStyleSheet(
            h1: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppTheme.primaryColor,
            ),
            h2: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppTheme.primaryColor.withOpacity(0.8),
            ),
            p: const TextStyle(
              fontSize: 16,
              height: 1.5,
            ),
            listBullet: TextStyle(
              color: AppTheme.primaryColor,
            ),
          ),
        ),
      ),
    );
  }
}
