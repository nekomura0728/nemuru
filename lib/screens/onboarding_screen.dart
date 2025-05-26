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
    if (_currentPage < 1) { // ページ数を2ページに変更
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
              color: AppTheme.primaryColor,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 40),
          Container(
            width: 200,
            height: 200,
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.nightlight_round,
              size: 100,
              color: AppTheme.primaryColor,
            ),
          ),
          const SizedBox(height: 40),
          Text(
            'NEMURUは、眠りにつく前に一日を振り返り、心を落ち着けるお手伝いをします。',
            style: Theme.of(context).textTheme.bodyLarge,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            '毎晩、あなた自身のためのひとときを。',
            style: AppTheme.handwrittenStyle.copyWith(
              fontSize: 20,
              color: AppTheme.accentColor,
            ),
            textAlign: TextAlign.center,
          ),
          const Spacer(),
        ],
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
              color: AppTheme.primaryColor,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          Text(
            'あなたと会話するキャラクターを選んでください',
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
    
    return GestureDetector(
      onTap: () async {
        await preferencesService.saveSelectedCharacterId(character.id);
        setState(() {}); // UIを更新
      },
      child: Card(
        elevation: isSelected ? 4 : 1,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: isSelected ? AppTheme.primaryColor : Colors.transparent,
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
                  color: AppTheme.primaryColor.withOpacity(0.1),
                  shape: BoxShape.circle,
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
                  color: isSelected ? AppTheme.primaryColor : Colors.black87,
                ),
              ),
              const SizedBox(height: 8),
              // キャラクターの性格
              Text(
                character.personality,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
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
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(
          2, // 2ページに変更
          (index) => Container(
            width: 10,
            height: 10,
            margin: const EdgeInsets.symmetric(horizontal: 4),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _currentPage == index
                  ? AppTheme.primaryColor
                  : AppTheme.primaryColor.withOpacity(0.3),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBottomButtons() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        children: [
          if (_currentPage == 0) // 最初のページでは次へボタンを表示
            ElevatedButton(
              onPressed: _nextPage,
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 56),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(28),
                ),
              ),
              child: const Text('次へ'),
            ),
          if (_currentPage == 1) // 最後のページでは開始ボタンを表示
            ElevatedButton(
              onPressed: _completeOnboarding,
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 56),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(28),
                ),
              ),
              child: const Text('開始する'),
            ),
        ],
      ),
    );
  }
}
