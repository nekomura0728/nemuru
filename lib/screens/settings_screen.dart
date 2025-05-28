import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:nemuru/services/preferences_service.dart';
import 'package:nemuru/services/subscription_service.dart';
import 'package:nemuru/services/purchase_service.dart';
import 'package:nemuru/services/accessibility_service.dart';
import 'package:flutter/foundation.dart'; // kDebugModeのため
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

import 'package:nemuru/theme/app_theme.dart';
import 'package:nemuru/models/character.dart';
import 'package:nemuru/widgets/character_image_widget.dart';
import 'package:nemuru/constants/app_constants.dart';
import 'package:nemuru/screens/policy_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  // アプリバージョン情報
  String _appVersion = '';
  bool _isLoading = true;
  
  @override
  void initState() {
    super.initState();
    _loadAppVersion();
  }
  
  // アプリバージョン情報を取得
  Future<void> _loadAppVersion() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      setState(() {
        _appVersion = '${packageInfo.version} (${packageInfo.buildNumber})';
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _appVersion = '1.0.0';
        _isLoading = false;
      });
    }
  }
  
  @override
  void dispose() {
    super.dispose();
  }


  @override
  Widget build(BuildContext context) {
    final preferencesService = Provider.of<PreferencesService>(context);
    
    return Scaffold(
      appBar: AppBar(
        title: Text(
          '設定',
          style: Theme.of(context).textTheme.titleLarge,
        ),
      ),
      body: ListView(
        children: [
          // 通知設定は実装されていないため削除
          
          // Theme settings
          _buildSectionHeader(context, 'テーマ設定'),
          ListTile(
            title: const Text('ダークモード'),
            trailing: Switch(
              value: preferencesService.isDarkMode,
              onChanged: (value) async {
                await preferencesService.setIsDarkMode(value);
              },
              activeColor: AppTheme.primaryColor,
            ),
          ),
          const Divider(),
          
          // アクセシビリティ設定
          _buildSectionHeader(context, 'アクセシビリティ設定'),
          _buildFontSizeSelector(context),
          const Divider(),
          
          // キャラクター設定
          _buildSectionHeader(context, 'キャラクター設定'),
          _buildCharacterSelector(context, preferencesService),
          const Divider(),
          
          // Subscription
          _buildSectionHeader(context, 'アカウント・プラン'),
          _buildSubscriptionCard(context),
          const Divider(),
          
          // About
          _buildSectionHeader(context, '情報'),
          ListTile(
            title: const Text('ヘルプとよくある質問'),
            leading: const Icon(Icons.help_outline),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              Navigator.of(context).pushNamed('/help');
            },
          ),
          ListTile(
            title: const Text('プライバシーポリシー'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              if (AppConstants.useExternalUrls) {
                _launchURL(AppConstants.privacyPolicyUrl);
              } else {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => PolicyScreen.privacyPolicy(),
                  ),
                );
              }
            },
          ),
          ListTile(
            title: const Text('利用規約'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              if (AppConstants.useExternalUrls) {
                _launchURL(AppConstants.termsOfServiceUrl);
              } else {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => PolicyScreen.termsOfService(),
                  ),
                );
              }
            },
          ),
          ListTile(
            title: const Text('バージョン'),
            subtitle: Text(_isLoading ? '読み込み中...' : _appVersion),
            enabled: false,
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              AppConstants.aiDisclaimer,
              style: TextStyle(
                fontSize: 12,
                color: AppTheme.secondaryTextColor,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
  
  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: AppTheme.primaryColor,
        ),
      ),
    );
  }

  Widget _buildFontSizeSelector(BuildContext context) {
    final accessibilityService = Provider.of<AccessibilityService>(context);
    
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'フォントサイズ',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 16),
          Text(
            'プレビュー: このテキストでフォントサイズを確認できます',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            children: AccessibilityService.fontScaleOptions.map((option) {
              final isSelected = accessibilityService.fontScaleFactor == option.scale;
              return ChoiceChip(
                label: Text(option.label),
                selected: isSelected,
                onSelected: (selected) {
                  if (selected) {
                    accessibilityService.setFontScaleFactor(option.scale);
                  }
                },
                selectedColor: AppTheme.primaryColor.withValues(alpha: 0.3),
                backgroundColor: Colors.grey[200],
                labelStyle: TextStyle(
                  color: isSelected ? AppTheme.primaryColor : Colors.black87,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
  
  Widget _buildSubscriptionCard(BuildContext context) {
    // プレファレンスからプレミアムフラグを取得
    final preferencesService = Provider.of<PreferencesService>(context);
    final subscriptionService = Provider.of<SubscriptionService>(context);
    final purchaseService = Provider.of<PurchaseService>(context);
    final bool isPremium = preferencesService.isPremium;
    final bool isPurchasePending = purchaseService.isPurchasePending;
    
    return Card(
      margin: const EdgeInsets.all(16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  isPremium ? Icons.workspace_premium : Icons.star_border,
                  color: isPremium ? AppTheme.accentColor : AppTheme.primaryColor,
                  size: 24,
                ),
                const SizedBox(width: 8),
                Text(
                  isPremium ? 'プレミアムプラン' : '無料プラン',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: isPremium ? AppTheme.accentColor : AppTheme.primaryColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildPlanFeature('1日1回の振り返り', true),
            _buildPlanFeature('7日間のログ保存', true),
            _buildPlanFeature('無制限のログ閲覧', isPremium),
            _buildPlanFeature('全てのキャラクターが利用可能', isPremium),
            _buildPlanFeature('応答テーマの選択', isPremium),
            const SizedBox(height: 16),
            if (!isPremium)
              ElevatedButton(
                onPressed: isPurchasePending ? null : () {
                  _showSubscriptionDialog(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.accentColor,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 48),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                  disabledBackgroundColor: Colors.grey,
                ),
                child: isPurchasePending
                  ? Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)),
                        const SizedBox(width: 8),
                        const Text('処理中...'),
                      ],
                    )
                  : const Text('プレミアムにアップグレード'),
              ),
            if (isPremium)
              Column(
                children: [
                  OutlinedButton(
                    onPressed: () {
                      // 購入履歴を復元
                      purchaseService.restorePurchases();
                    },
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 48),
                      side: BorderSide(color: AppTheme.accentColor),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                    ),
                    child: const Text('購入履歴を復元'),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'プレミアムプランは現在有効です',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppTheme.accentColor,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            // エラーメッセージがあれば表示 (デバッグモードでは表示しない)
            if (purchaseService.errorMessage != null && 
                purchaseService.errorMessage!.isNotEmpty && 
                !kDebugMode)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text(
                  purchaseService.errorMessage!,
                  style: const TextStyle(
                    color: Colors.red,
                    fontSize: 12,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildPlanFeature(String feature, bool isIncluded) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(
            isIncluded ? Icons.check_circle_outline : Icons.remove_circle_outline,
            color: isIncluded ? Colors.green : Colors.grey,
            size: 20,
          ),
          const SizedBox(width: 8),
          Text(
            feature,
            style: TextStyle(
              color: isIncluded ? null : Colors.grey,
            ),
          ),
        ],
      ),
    );
  }
  
  void _showSubscriptionDialog(BuildContext context) {
    // 購入サービスを取得
    final purchaseService = Provider.of<PurchaseService>(context, listen: false);
    final products = purchaseService.products;
    final bool isReleaseMode = const bool.fromEnvironment('dart.vm.product');

    // リリースモードで利用可能な商品がない場合のみメッセージ表示して早期リターン
    if (products.isEmpty && isReleaseMode) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('現在、購入可能な商品がありません。後ほどお試しください。')),
      );
      return;
    }

    // 月額プランと年額プランを安全に取得
    ProductDetails? monthlyProduct;
    try {
      monthlyProduct = products.firstWhere((p) => p.id.contains('monthly'));
    } catch (e) {
      monthlyProduct = null; // 見つからない場合はnull
    }

    ProductDetails? yearlyProduct;
    if (products.isNotEmpty) { // productsが空でない場合のみ年額プランを検索
      try {
        yearlyProduct = products.firstWhere((p) => p.id.contains('yearly'));
      } catch (e) {
        yearlyProduct = null; // 見つからない場合はnull
      }
    }
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('プレミアムプラン'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 実際の商品情報があれば表示、なければデバッグ用プレースホルダ
            if (monthlyProduct != null) 
              Text(
                '月額 ${monthlyProduct.price}',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              )
            else if (!isReleaseMode) // デバッグモードで月額商品がない場合
              const Text(
                '月額プラン (デバッグ用)',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            
            if (yearlyProduct != null) ...[
              const SizedBox(height: 8),
              Text(
                '年額 ${yearlyProduct.price} (お得なプラン)',
                style: const TextStyle(fontSize: 16),
              ),
            ] else if (!isReleaseMode && monthlyProduct == null) ...[ // デバッグモードで年額商品もなく、月額もなかった場合
              const SizedBox(height: 8),
              const Text(
                '年額プラン (デバッグ用)',
                style: TextStyle(fontSize: 16),
              ),
            ],
            const SizedBox(height: 16),
            const Text('プレミアム特典:'),
            const SizedBox(height: 8),
            _buildPlanFeature('無制限のログ閲覧', true),
            _buildPlanFeature('全てのキャラクターが利用可能', true),
            _buildPlanFeature('応答テーマの選択', true),
            _buildPlanFeature('一日に複数回の会話', true),
            const SizedBox(height: 16),
            const Text(
              '※ サブスクリプションは自動更新されます。解約はいつでも可能です。',
              style: TextStyle(fontSize: 12, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('キャンセル'),
          ),
          // 年額プラン購入ボタン (商品があるかデバッグモードの場合に表示)
          if (yearlyProduct != null || (!isReleaseMode && (monthlyProduct == null || products.isEmpty))) // デバッグで商品がない場合も年額モックボタンを表示
            ElevatedButton(
              onPressed: () async {
                Navigator.of(context).pop();
                if (yearlyProduct != null) {
                  await purchaseService.purchaseProduct(yearlyProduct);
                } else if (!isReleaseMode) { // デバッグモードで年額商品がない場合、モック購入
                  final subscriptionService = Provider.of<SubscriptionService>(context, listen: false);
                  await subscriptionService.setPremium(true); 
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('デバッグモード: 年額プラン(仮)にアップグレードしました！')),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.accentColor,
              ),
              child: Text(yearlyProduct != null ? '年額プランを購入' : '年額プランを試す (デバッグ)'),
            ),

          // 月額プラン購入ボタン (商品があるかデバッグモードの場合に表示)
          if (monthlyProduct != null || !isReleaseMode)
            ElevatedButton(
              onPressed: () async {
                Navigator.of(context).pop();
                // デバッグモードまたは月額商品がない場合はモック購入を使用
                if (!isReleaseMode || monthlyProduct == null) {
                  final subscriptionService = Provider.of<SubscriptionService>(context, listen: false);
                  await subscriptionService.setPremium(true);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('デバッグモード: 月額プラン(仮)にアップグレードしました！')),
                  );
                } else if (monthlyProduct != null) {
                  // 実際の購入処理 (monthlyProductがnullでないことを保証)
                  await purchaseService.purchaseProduct(monthlyProduct);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.accentColor,
              ),
              child: Text(monthlyProduct != null ? '月額プランを購入' : '月額プランを試す (デバッグ)'),
            ),
        ],
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    );
  }
  
  void _showComingSoonDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('お知らせ'),
        content: Text(message),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    );
  }
  
  // URLを開くメソッド
  Future<void> _launchURL(String url) async {
    final Uri uri = Uri.parse(url);
    try {
      if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
        throw Exception('Could not launch $url');
      }
    } catch (e) {
      _showComingSoonDialog(context, 'URLを開けませんでした: $url');
    }
  }
  
  // キャラクター選択メソッド
  Widget _buildCharacterSelector(BuildContext context, PreferencesService preferencesService) {
    final selectedCharacterId = preferencesService.selectedCharacterId;
    final selectedCharacter = Character.getCharacterById(selectedCharacterId);
    
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'キャラクター',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              // キャラクターアイコン
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: ClipOval(
                  child: CharacterImageWidget(
                    characterId: selectedCharacterId,
                    width: 60,
                    height: 60,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              // キャラクター情報
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      selectedCharacter.name,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      selectedCharacter.personality,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              _showCharacterSelectionDialog(context, preferencesService);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('キャラクターを変更'),
          ),
        ],
      ),
    );
  }
  
  // キャラクター選択ダイアログ
  void _showCharacterSelectionDialog(BuildContext context, PreferencesService preferencesService) {
    // 全てのキャラクターを表示し、無料プランでは一部をロック表示
    final characters = Character.getAllCharacters();
    final selectedCharacterId = preferencesService.selectedCharacterId;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('キャラクター選択'),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (!preferencesService.isPremium)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16.0),
                  child: Text(
                    'プレミアムプランでは全てのキャラクターが利用可能になります',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              Expanded(
                child: GridView.builder(
                  shrinkWrap: true,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 0.8,
                  ),
                  itemCount: characters.length,
                  itemBuilder: (context, index) {
                    final character = characters[index];
                    final isSelected = character.id == selectedCharacterId;
                    
                    // キャラクターが無料プランで利用可能かどうか
                    final bool isAvailable = character.isFreeVersion || preferencesService.isPremium;
                    
                    return GestureDetector(
                      onTap: () async {
                        if (isAvailable) {
                          // 利用可能なキャラクターを選択
                          await preferencesService.saveSelectedCharacterId(character.id);
                          Navigator.of(context).pop();
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('「${character.name}」を選択しました')),
                          );
                        } else {
                          // プレミアムプランの案内を表示
                          Navigator.of(context).pop();
                          _showSubscriptionDialog(context);
                        }
                      },
                      child: Stack(
                        children: [
                          Card(
                            elevation: isSelected ? 4 : 1,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: BorderSide(
                                color: isSelected ? AppTheme.primaryColor : Colors.transparent,
                                width: 2,
                              ),
                            ),
                            // ロックされたキャラクターはグレーアウト表示
                            color: isAvailable ? null : Colors.grey[200],
                            child: Container(
                              width: double.infinity,
                              height: double.infinity,
                              padding: const EdgeInsets.all(8.0),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  // キャラクターアイコン
                                  Container(
                                    width: 50,
                                    height: 50,
                                    decoration: BoxDecoration(
                                      color: AppTheme.primaryColor.withValues(alpha: 0.1),
                                      shape: BoxShape.circle,
                                    ),
                                    child: ClipOval(
                                      child: CharacterImageWidget(
                                        characterId: character.id,
                                        width: 50,
                                        height: 50,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  // キャラクター名
                                  Text(
                                    character.name,
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                      color: isSelected ? AppTheme.primaryColor : Colors.black87,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: 4),
                                  // キャラクターの性格
                                  Expanded(
                                    child: Text(
                                      character.personality,
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: Colors.grey[600],
                                      ),
                                      textAlign: TextAlign.center,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          // プレミアム限定キャラクターにはロックアイコンを表示
                          if (!isAvailable)
                            Positioned(
                              top: 8,
                              right: 8,
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: AppTheme.accentColor.withValues(alpha: 0.9),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.lock,
                                  color: Colors.white,
                                  size: 16,
                                ),
                              ),
                            ),
                          // プレミアム限定キャラクターには「プレミアム」バッジを表示
                          if (!isAvailable)
                            Positioned(
                              bottom: 8,
                              right: 8,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppTheme.accentColor,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Text(
                                  'プレミアム',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 8,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('キャンセル'),
          ),
          if (!preferencesService.isPremium)
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _showSubscriptionDialog(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.accentColor,
              ),
              child: const Text('プレミアムにアップグレード'),
            ),
        ],
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    );
  }
}
