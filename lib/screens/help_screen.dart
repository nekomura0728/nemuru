import 'package:flutter/material.dart';
import 'package:nemuru/theme/app_theme.dart';

class HelpScreen extends StatefulWidget {
  const HelpScreen({Key? key}) : super(key: key);

  @override
  State<HelpScreen> createState() => _HelpScreenState();
}

class _HelpScreenState extends State<HelpScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = isDarkMode ? AppTheme.darkPrimaryColor : AppTheme.primaryColor;
    
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'ヘルプ',
          style: AppTheme.handwrittenStyle.copyWith(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).brightness == Brightness.dark 
                ? Colors.white 
                : AppTheme.primaryColor,
          ),
        ),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded),
          tooltip: '戻る',
          onPressed: () => Navigator.of(context).pop(),
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: primaryColor,
          unselectedLabelColor: isDarkMode ? Colors.white70 : Colors.grey[600],
          indicatorColor: primaryColor,
          tabs: const [
            Tab(text: '使い方ガイド'),
            Tab(text: 'よくある質問'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildGuideTab(),
          _buildFaqTab(),
        ],
      ),
    );
  }

  Widget _buildGuideTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('Nemuruの基本的な使い方'),
          const SizedBox(height: 16),
          
          _buildGuideStep(
            icon: Icons.sentiment_satisfied_alt,
            title: '1. 今日の気分を選択',
            description: 'まずは今日の気分を選んでください。気分に合わせて会話が調整されます。',
          ),
          
          _buildGuideStep(
            icon: Icons.edit_note,
            title: '2. 一日を振り返る',
            description: '今日起きた出来事や感じたことを自由に入力してください。どんな些細なことでも大丈夫です。',
          ),
          
          _buildGuideStep(
            icon: Icons.chat_bubble_outline,
            title: '3. キャラクターと対話',
            description: '選んだキャラクターがあなたの気持ちに寄り添い、心安らぐ会話をお手伝いします。',
          ),
          
          _buildGuideStep(
            icon: Icons.book_outlined,
            title: '4. 振り返りの記録',
            description: '会話の内容は自動で記録され、過去の心の軌跡として振り返ることができます。',
          ),
          
          const SizedBox(height: 24),
          _buildSectionTitle('各画面の説明'),
          const SizedBox(height: 16),
          
          _buildFeatureCard(
            icon: Icons.home_outlined,
            title: 'ホーム画面',
            description: '気分を選択し、一日の振り返りを入力する画面です。ここから会話を始めることができます。',
          ),
          
          _buildFeatureCard(
            icon: Icons.chat_bubble_outline,
            title: '対話画面',
            description: 'キャラクターとの会話を行う画面です。メッセージを入力して送信すると、キャラクターが応答します。',
          ),
          
          _buildFeatureCard(
            icon: Icons.history,
            title: '心の軌跡',
            description: '過去の会話記録を閲覧できる画面です。日付ごとに会話が整理されています。',
          ),
          
          _buildFeatureCard(
            icon: Icons.settings_outlined,
            title: '設定',
            description: 'アプリの各種設定を変更できる画面です。テーマの切り替えやフォントサイズの調整などができます。',
          ),
        ],
      ),
    );
  }

  Widget _buildFaqTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('よくある質問'),
          const SizedBox(height: 16),
          
          _buildFaqItem(
            question: '無料版と有料版の違いは何ですか？',
            answer: '無料版では1日に2回までの会話が可能です。有料版（プレミアムプラン）では実質無制限の会話が可能になります。また、有料版では会話の履歴を長期間保存することができます。',
          ),
          
          _buildFaqItem(
            question: '会話の履歴はどこで確認できますか？',
            answer: 'ホーム画面右上の「履歴」アイコンをタップすると、過去の会話履歴を確認できます。日付ごとに整理されており、タップすると詳細を見ることができます。',
          ),
          
          _buildFaqItem(
            question: '会話の途中で終了してしまった場合はどうなりますか？',
            answer: '会話は自動的に保存されるため、アプリを再起動しても続きから再開できます。ただし、メッセージ送信前に終了した場合は、そのメッセージは保存されません。',
          ),
          
          _buildFaqItem(
            question: 'キャラクターを変更することはできますか？',
            answer: '現在のバージョンでは、初回設定時に選んだキャラクターを使用します。将来のアップデートでキャラクター変更機能を追加する予定です。',
          ),
          
          _buildFaqItem(
            question: 'ダークモードに切り替えるにはどうすればいいですか？',
            answer: '設定画面から「ダークモード」を選択することで、ダークモードに切り替えることができます。また、端末の設定に合わせて自動的に切り替えることもできます。',
          ),
          
          _buildFaqItem(
            question: 'フォントサイズを変更するにはどうすればいいですか？',
            answer: '設定画面から「フォントサイズ」を選択し、5段階のサイズから選ぶことができます。アプリ全体のフォントサイズが変更されます。',
          ),
          
          _buildFaqItem(
            question: 'アプリの通知設定はどこで変更できますか？',
            answer: '設定画面から「通知設定」を選択することで、通知のオン/オフや時間帯の設定ができます。就寝前の振り返りリマインダーなどを設定できます。',
          ),
          
          _buildFaqItem(
            question: 'サブスクリプションはいつでもキャンセルできますか？',
            answer: 'はい、いつでもキャンセル可能です。App StoreまたはGoogle Playのサブスクリプション管理画面からキャンセルできます。キャンセル後も、期間終了まではプレミアム機能を利用できます。',
          ),
          
          _buildFaqItem(
            question: 'プライバシーは守られますか？',
            answer: 'はい、あなたの会話内容はプライバシーポリシーに基づいて厳重に保護されています。詳細は設定画面の「プライバシーポリシー」をご覧ください。',
          ),
          
          _buildFaqItem(
            question: '不具合や要望はどこで報告できますか？',
            answer: '設定画面の「お問い合わせ」から、不具合の報告や機能の要望を送信することができます。ご意見・ご要望はアプリの改善に役立てさせていただきます。',
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return Text(
      title,
      style: TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.bold,
        color: isDarkMode ? AppTheme.darkPrimaryColor : AppTheme.primaryColor,
      ),
    );
  }

  Widget _buildGuideStep({
    required IconData icon,
    required String title,
    required String description,
  }) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = isDarkMode ? AppTheme.darkPrimaryColor : AppTheme.primaryColor;
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 20.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: primaryColor.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: primaryColor,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isDarkMode ? AppTheme.darkTextColor : AppTheme.textColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 16,
                    color: isDarkMode ? AppTheme.darkSecondaryTextColor : AppTheme.secondaryTextColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureCard({
    required IconData icon,
    required String title,
    required String description,
  }) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDarkMode ? AppTheme.darkCardColor : Colors.white;
    final primaryColor = isDarkMode ? AppTheme.darkPrimaryColor : AppTheme.primaryColor;
    
    return Card(
      margin: const EdgeInsets.only(bottom: 16.0),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      color: cardColor,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              icon,
              color: primaryColor,
              size: 24,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isDarkMode ? AppTheme.darkTextColor : AppTheme.textColor,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 16,
                      color: isDarkMode ? AppTheme.darkSecondaryTextColor : AppTheme.secondaryTextColor,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFaqItem({
    required String question,
    required String answer,
  }) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDarkMode ? AppTheme.darkCardColor : Colors.white;
    
    return Card(
      margin: const EdgeInsets.only(bottom: 16.0),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      color: cardColor,
      child: ExpansionTile(
        title: Text(
          question,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: isDarkMode ? AppTheme.darkTextColor : AppTheme.textColor,
          ),
        ),
        iconColor: isDarkMode ? AppTheme.darkPrimaryColor : AppTheme.primaryColor,
        collapsedIconColor: isDarkMode ? Colors.white70 : Colors.grey[600],
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Text(
              answer,
              style: TextStyle(
                fontSize: 15,
                color: isDarkMode ? AppTheme.darkSecondaryTextColor : AppTheme.secondaryTextColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
