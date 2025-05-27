import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:nemuru/services/preferences_service.dart';
import 'package:nemuru/services/notification_service.dart';
import 'package:nemuru/theme/app_theme.dart';
import 'package:nemuru/models/character.dart';
import 'package:nemuru/widgets/character_image_painter.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({Key? key}) : super(key: key);

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentPage < 2) { // ページ数を3ページに変更
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _completeOnboarding() async {
    final preferencesService = Provider.of<PreferencesService>(context, listen: false);
    await preferencesService.setOnboardingCompleted(true);
    
    if (mounted) {
      Navigator.of(context).pushReplacementNamed('/check-in');
    }
  }

  // 通知許可メソッドは削除

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView(
                controller: _pageController,
                onPageChanged: (int page) {
                  setState(() {
                    _currentPage = page;
                  });
                },
                children: [
                  _buildWelcomePage(),
                  _buildTutorialPage(), // チュートリアルページ
                  _buildCharacterSelectionPage(), // キャラクター選択ページ
                ],
              ),
            ),
            _buildPageIndicator(),
            _buildBottomButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildWelcomePage() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 40),
          Text(
            'NEMURUへようこそ',
            style: AppTheme.handwrittenStyle.copyWith(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).brightness == Brightness.dark ? AppTheme.darkPrimaryColor : AppTheme.primaryColor,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 40),
          Container(
            width: 200,
            height: 200,
            decoration: BoxDecoration(
              color: Theme.of(context).brightness == Brightness.dark 
                  ? AppTheme.darkPrimaryColor.withOpacity(0.2) 
                  : AppTheme.primaryColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Icon(
                  Icons.nightlight_round,
                  size: 100,
                  color: Theme.of(context).brightness == Brightness.dark 
                      ? AppTheme.darkPrimaryColor 
                      : AppTheme.primaryColor,
                ),
                Positioned(
                  right: 50,
                  top: 50,
                  child: Icon(
                    Icons.star,
                    size: 30,
                    color: Theme.of(context).brightness == Brightness.dark 
                        ? Colors.amber.withOpacity(0.7) 
                        : Colors.amber,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 40),
          Text(
            '眠れない夜に、あなたの心に寄り添います。',
            style: Theme.of(context).textTheme.bodyLarge,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            'NEMURUは眠りにつく前のひとときに、一日を振り返り心を落ち着けるお手伝いをするアプリです。',
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            '毎晩、あなた自身のためのひとときを。',
            style: AppTheme.handwrittenStyle.copyWith(
              fontSize: 20,
              color: Theme.of(context).brightness == Brightness.dark 
                  ? AppTheme.darkAccentColor 
                  : AppTheme.accentColor,
            ),
            textAlign: TextAlign.center,
          ),
          const Spacer(),
        ],
      ),
    );
  }

  Widget _buildTutorialPage() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 20),
          Text(
            'NEMURUの使い方',
            style: AppTheme.handwrittenStyle.copyWith(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).brightness == Brightness.dark ? AppTheme.darkPrimaryColor : AppTheme.primaryColor,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 40),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  _buildTutorialStep(
                    icon: Icons.sentiment_satisfied_alt,
                    title: '1. 今日の気分を選択',
                    description: 'まずは今日の気分を5段階から選んでください。\n気分に合わせて会話が調整されます。',
                  ),
                  const SizedBox(height: 24),
                  _buildTutorialStep(
                    icon: Icons.edit_note,
                    title: '2. 一日を振り返る',
                    description: '今日起きた出来事や感じたことを\n自由に入力してください。どんな些細なことでも大丈夫です。',
                  ),
                  const SizedBox(height: 24),
                  _buildTutorialStep(
                    icon: Icons.chat_bubble_outline,
                    title: '3. キャラクターと対話',
                    description: '選んだキャラクターがあなたの気持ちに寄り添い、\n心安らぐ会話をお手伝いします。',
                  ),
                  const SizedBox(height: 24),
                  _buildTutorialStep(
                    icon: Icons.book_outlined,
                    title: '4. 振り返りの記録',
                    description: '会話の内容は自動で記録され、\n過去の心の軌跡として振り返ることができます。',
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTutorialStep({
    required IconData icon,
    required String title,
    required String description,
  }) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = isDarkMode ? AppTheme.darkPrimaryColor : AppTheme.primaryColor;
    final cardColor = isDarkMode ? AppTheme.darkCardColor : AppTheme.cardColor;
    
    return Card(
      elevation: 2,
      color: cardColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Row(
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: primaryColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 30,
                color: primaryColor,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: primaryColor,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    description,
                    style: Theme.of(context).textTheme.bodyMedium,
                    textAlign: TextAlign.left,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // キャラクター選択ページを構築
  Widget _buildCharacterSelectionPage() {
    // 無料版で利用可能なキャラクターを取得
    final freeCharacters = Character.getFreeCharacters();
    final preferencesService = Provider.of<PreferencesService>(context, listen: false);
    
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 20),
          Text(
            'キャラクター選択',
            style: AppTheme.handwrittenStyle.copyWith(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).brightness == Brightness.dark ? AppTheme.darkPrimaryColor : AppTheme.primaryColor,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          Text(
            'あなたの眠れない夜に寄り添う相手を選んでください',
            style: Theme.of(context).textTheme.bodyLarge,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 30),
          Expanded(
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 0.8,
              ),
              itemCount: freeCharacters.length,
              itemBuilder: (context, index) {
                final character = freeCharacters[index];
                return _buildCharacterCard(character, preferencesService);
              },
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'プレミアムプランでは全て12種類のキャラクターが利用可能です',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
  
  // キャラクターカードを構築
  Widget _buildCharacterCard(Character character, PreferencesService preferencesService) {
    final isSelected = preferencesService.selectedCharacterId == character.id;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = isDarkMode ? AppTheme.darkPrimaryColor : AppTheme.primaryColor;
    final textColor = isDarkMode ? AppTheme.darkTextColor : AppTheme.textColor;
    final cardColor = isDarkMode ? AppTheme.darkCardColor : AppTheme.cardColor;
    
    return GestureDetector(
      onTap: () async {
        await preferencesService.saveSelectedCharacterId(character.id);
        setState(() {}); // UIを更新
      },
      child: Card(
        elevation: isSelected ? 4 : 1,
        color: cardColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: isSelected ? primaryColor : Colors.transparent,
            width: 2,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // キャラクターアイコン
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: primaryColor.withOpacity(0.2),
                  shape: BoxShape.circle,
                  boxShadow: isSelected ? [
                    BoxShadow(
                      color: primaryColor.withOpacity(0.3),
                      blurRadius: 10,
                      spreadRadius: 2,
                    )
                  ] : [],
                ),
                child: ClipOval(
                  child: CustomPaint(
                    painter: CharacterImagePainter(
                      imagePath: character.imagePath,
                      characterId: character.id,
                    ),
                    size: const Size(80, 80),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              // キャラクター名
              Text(
                character.name,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected ? primaryColor : textColor,
                ),
              ),
              const SizedBox(height: 8),
              // キャラクターの性格
              Text(
                character.personality,
                style: TextStyle(
                  fontSize: 12,
                  color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  // 通知設定ページは削除

  Widget _buildPageIndicator() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = isDarkMode ? AppTheme.darkPrimaryColor : AppTheme.primaryColor;
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(
          3, // 3ページに変更
          (index) => AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            width: _currentPage == index ? 20 : 10,
            height: 10,
            margin: const EdgeInsets.symmetric(horizontal: 4),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(5),
              color: _currentPage == index
                  ? primaryColor
                  : primaryColor.withOpacity(0.3),
              boxShadow: _currentPage == index ? [
                BoxShadow(
                  color: primaryColor.withOpacity(0.3),
                  blurRadius: 5,
                  spreadRadius: 1,
                )
              ] : [],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBottomButtons() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = isDarkMode ? AppTheme.darkPrimaryColor : AppTheme.primaryColor;
    final accentColor = isDarkMode ? AppTheme.darkAccentColor : AppTheme.accentColor;
    
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        children: [
          if (_currentPage < 2) // 最初と2番目のページでは次へボタンを表示
            ElevatedButton(
              onPressed: _nextPage,
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 56),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(28),
                ),
                elevation: 4,
                shadowColor: primaryColor.withOpacity(0.5),
              ),
              child: const Text('次へ', style: TextStyle(fontSize: 16)),
            ),
          if (_currentPage == 2) // 最後のページでは開始ボタンを表示
            ElevatedButton(
              onPressed: _completeOnboarding,
              style: ElevatedButton.styleFrom(
                backgroundColor: accentColor,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 56),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(28),
                ),
                elevation: 4,
                shadowColor: accentColor.withOpacity(0.5),
              ),
              child: const Text('眼を閉じて、心を開いて', style: TextStyle(fontSize: 16)),
            ),
        ],
      ),
    );
  }
}
