import 'dart:async';
import 'dart:convert';
import 'dart:io' if (dart.library.html) 'package:nemuru/services/web_platform_stub.dart';
import 'package:flutter/foundation.dart';
import 'package:nemuru/services/preferences_service.dart';
import 'package:nemuru/services/subscription_service.dart';
import 'package:nemuru/constants/api_constants.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:http/http.dart' as http;

// Conditional imports for platform-specific plugins
import 'package:in_app_purchase/in_app_purchase.dart' 
    if (dart.library.html) 'package:nemuru/services/web_purchase_stub.dart';

/// In-App Purchaseを管理するサービス
class PurchaseService extends ChangeNotifier {
  final InAppPurchase _inAppPurchase = InAppPurchase.instance;
  final PreferencesService _preferencesService;
  final SubscriptionService _subscriptionService;
  StreamSubscription<List<PurchaseDetails>>? _subscription;
  
  // Web platform check
  bool get isWebPlatform => kIsWeb;
  
  // 商品ID
  static const String _monthlySubscriptionId = 'nemuru_premium_monthly';
  static const String _yearlySubscriptionId = 'nemuru_premium_yearly';
  
  // 商品リスト
  List<ProductDetails> _products = [];
  
  // 購入中フラグ
  bool _isPurchasePending = false;
  
  // エラーメッセージ
  String? _errorMessage;
  
  
  // ゲッター
  List<ProductDetails> get products => _products;
  bool get isPurchasePending => _isPurchasePending;
  String? get errorMessage => _errorMessage;
  // isAvailableはFuture<bool>を返すため、同期的に使用できません
  // 代わりにメソッドとして提供
  Future<bool> checkAvailability() => _inAppPurchase.isAvailable();
  
  PurchaseService(this._preferencesService, this._subscriptionService) {
    _initializePurchase();
  }
  
  /// In-App Purchaseの初期化
  Future<void> _initializePurchase() async {
    // Web プラットフォームでは購入機能を無効化
    if (isWebPlatform) {
      _errorMessage = 'ウェブ版では購入機能はご利用いただけません';
      notifyListeners();
      return;
    }
    
    // 利用可能かチェック
    final isAvailable = await _inAppPurchase.isAvailable();
    if (!isAvailable) {
      _errorMessage = 'In-App Purchaseが利用できません';
      notifyListeners();
      return;
    }
    
    // 購入リスナーを設定
    final purchaseUpdated = _inAppPurchase.purchaseStream;
    _subscription = purchaseUpdated.listen(
      _listenToPurchaseUpdated,
      onDone: () {
        _subscription?.cancel();
      },
      onError: (error) {
        _errorMessage = 'エラーが発生しました: $error';
        notifyListeners();
      }
    );
    
    // 商品情報をロード
    await _loadProducts();
  }
  
  /// 商品情報をロード
  Future<void> _loadProducts() async {
    try {
      final Set<String> productIds = <String>{
        _monthlySubscriptionId,
        _yearlySubscriptionId,
      };
      
      final ProductDetailsResponse response = 
          await _inAppPurchase.queryProductDetails(productIds);
      
      if (response.notFoundIDs.isNotEmpty) {
        _errorMessage = '一部の商品情報が見つかりませんでした: ${response.notFoundIDs.join(", ")}';
      }
      
      _products = response.productDetails;
      notifyListeners();
    } catch (e) {
      _errorMessage = '商品情報の取得に失敗しました: $e';
      notifyListeners();
    }
  }
  
  /// 購入処理
  Future<void> purchaseProduct(ProductDetails product) async {
    if (_isPurchasePending) return;
    
    // Web プラットフォームでは購入不可
    if (isWebPlatform) {
      _errorMessage = 'ウェブ版では購入機能はご利用いただけません';
      notifyListeners();
      return;
    }
    
    _isPurchasePending = true;
    _errorMessage = null;
    notifyListeners();
    
    try {
      // 購入フローを開始
      final PurchaseParam purchaseParam = PurchaseParam(
        productDetails: product,
        applicationUserName: null,
      );
      
      await _inAppPurchase.buyNonConsumable(purchaseParam: purchaseParam);
    } catch (e) {
      _errorMessage = '購入処理中にエラーが発生しました: $e';
      _isPurchasePending = false;
      notifyListeners();
    }
  }
  
  /// 購入状態の更新をリッスン
  void _listenToPurchaseUpdated(List<PurchaseDetails> purchaseDetailsList) async {
    for (final PurchaseDetails purchaseDetails in purchaseDetailsList) {
      if (purchaseDetails.status == PurchaseStatus.pending) {
        // 購入処理中
        _isPurchasePending = true;
      } else {
        if (purchaseDetails.status == PurchaseStatus.error) {
          // エラー発生
          final errorCode = purchaseDetails.error?.code;
          if (errorCode == 'BillingResponse.itemAlreadyOwned') {
            // 既に所有している場合は成功として処理
            debugPrint('アイテムは既に所有されています - プレミアム状態に設定');
            await _subscriptionService.setPremiumStatus(true);
            _isPurchasePending = false;
            _errorMessage = null;
          } else {
            _errorMessage = '購入エラー: ${purchaseDetails.error?.message}';
            _isPurchasePending = false;
          }
        } else if (purchaseDetails.status == PurchaseStatus.purchased ||
                  purchaseDetails.status == PurchaseStatus.restored) {
          // 購入完了または復元完了
          await _verifyAndSavePurchase(purchaseDetails);
        } else if (purchaseDetails.status == PurchaseStatus.canceled) {
          // キャンセル
          _isPurchasePending = false;
        }
        
        // 購入完了後の処理
        if (purchaseDetails.pendingCompletePurchase) {
          await _inAppPurchase.completePurchase(purchaseDetails);
        }
      }
      
      notifyListeners();
    }
  }
  
  /// 購入を検証して保存
  Future<void> _verifyAndSavePurchase(PurchaseDetails purchaseDetails) async {
    try {
      // サーバーサイド検証を実行
      final verificationResult = await _verifyPurchaseWithServer(purchaseDetails);
      
      if (verificationResult['success'] == true && verificationResult['isValid'] == true) {
        // 検証成功の場合、プレミアム状態を更新
        await _subscriptionService.setPremium(true);
        _isPurchasePending = false;
        
        // 有効期限があれば保存
        if (verificationResult['expiresDate'] != null) {
          // 有効期限を保存する処理を実装する場合はここに追加
        }
      } else {
        // 検証失敗の場合
        _errorMessage = '購入の検証に失敗しました: ${verificationResult['error'] ?? "Unknown error"}';
        _isPurchasePending = false;
      }
    } catch (e) {
      _errorMessage = '購入情報の検証中にエラーが発生しました: $e';
      _isPurchasePending = false;
    }
    
    notifyListeners();
  }
  
  /// サーバーサイド検証を実行
  Future<Map<String, dynamic>> _verifyPurchaseWithServer(PurchaseDetails purchaseDetails) async {
    try {
      // デバイスIDを取得
      final deviceId = _preferencesService.deviceId;
      
      // プラットフォーム固有のデータを準備
      String platform = 'web';
      if (!kIsWeb) {
        try {
          platform = Platform.isIOS ? 'ios' : 'android';
        } catch (e) {
          platform = 'unknown';
        }
      }
      
      Map<String, dynamic> requestBody = {
        'platform': platform,
        'receipt': purchaseDetails.verificationData.serverVerificationData,
        'productId': purchaseDetails.productID,
        'deviceId': deviceId,
      };
      
      // Androidの場合は追加データが必要
      if (!kIsWeb) {
        try {
          if (Platform.isAndroid) {
            requestBody['packageName'] = ApiConstants.packageName;
            requestBody['purchaseToken'] = purchaseDetails.verificationData.serverVerificationData;
          }
        } catch (e) {
          // Platform check failed, continue without Android-specific data
        }
      }
      
      // HTTP リクエストを送信
      final response = await http.post(
        Uri.parse(ApiConstants.verifyPurchaseUrl),
        headers: ApiConstants.authHeaders,
        body: jsonEncode(requestBody),
      ).timeout(ApiConstants.apiTimeout);
      
      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body) as Map<String, dynamic>;
        
        // 検証結果を標準形式に変換
        return {
          'success': responseData['success'] ?? false,
          'isValid': responseData['valid'] ?? false,
          'expiresDate': responseData['expiresDate'],
          'error': responseData['error'],
        };
      } else {
        // HTTPエラーの場合
        return {
          'success': false,
          'isValid': false,
          'error': 'サーバー検証エラー: HTTP ${response.statusCode}',
        };
      }
    } catch (e) {
      // ネットワークエラーやその他の例外
      if (kDebugMode) {
        debugPrint('Purchase verification error: $e');
      }
      
      return {
        'success': false,
        'isValid': false,
        'error': '検証サービスに接続できませんでした: $e',
      };
    }
  }
  
  /// アプリのサブスクリプション管理画面を開く
  Future<void> openSubscriptionManagement() async {
    try {
      if (kIsWeb) {
        // Webの場合は購入機能なしを通知
        _errorMessage = 'ウェブ版では購入機能はご利用いただけません';
        notifyListeners();
      } else {
        try {
          if (Platform.isIOS) {
            // iOSの場合は設定アプリのサブスクリプション画面を開く
            const url = 'itms-apps://apps.apple.com/account/subscriptions';
            final uri = Uri.parse(url);
            if (await canLaunchUrl(uri)) {
              await launchUrl(uri);
            } else {
              _errorMessage = 'サブスクリプション管理画面を開けませんでした';
              notifyListeners();
            }
          } else if (Platform.isAndroid) {
            // Androidの場合はGoogle Playのサブスクリプション画面を開く
            const url = 'https://play.google.com/store/account/subscriptions';
            final uri = Uri.parse(url);
            if (await canLaunchUrl(uri)) {
              await launchUrl(uri, mode: LaunchMode.externalApplication);
            } else {
              _errorMessage = 'サブスクリプション管理画面を開けませんでした';
              notifyListeners();
            }
          }
        } catch (e) {
          _errorMessage = 'プラットフォーム情報の取得に失敗しました';
          notifyListeners();
        }
      }
    } catch (e) {
      _errorMessage = 'サブスクリプション管理画面を開く際にエラーが発生しました: $e';
      notifyListeners();
    }
  }
  
  /// 購入を復元
  Future<void> restorePurchases() async {
    // Web プラットフォームでは復元不可
    if (isWebPlatform) {
      _errorMessage = 'ウェブ版では購入機能はご利用いただけません';
      notifyListeners();
      return;
    }
    
    _isPurchasePending = true;
    _errorMessage = null;
    notifyListeners();
    
    try {
      await _inAppPurchase.restorePurchases();
    } catch (e) {
      _errorMessage = '購入の復元に失敗しました: $e';
      _isPurchasePending = false;
      notifyListeners();
    }
  }
  
  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
