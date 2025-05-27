import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:in_app_purchase_android/in_app_purchase_android.dart';
import 'package:in_app_purchase_storekit/in_app_purchase_storekit.dart';
import 'package:nemuru/services/preferences_service.dart';
import 'package:nemuru/services/subscription_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

/// In-App Purchaseを管理するサービス
class PurchaseService extends ChangeNotifier {
  final InAppPurchase _inAppPurchase = InAppPurchase.instance;
  final PreferencesService _preferencesService;
  final SubscriptionService _subscriptionService;
  StreamSubscription<List<PurchaseDetails>>? _subscription;
  
  // 商品ID
  static const String _monthlySubscriptionId = 'nemuru_premium_monthly';
  static const String _yearlySubscriptionId = 'nemuru_premium_yearly';
  
  // 商品リスト
  List<ProductDetails> _products = [];
  
  // 購入中フラグ
  bool _isPurchasePending = false;
  
  // エラーメッセージ
  String? _errorMessage;
  
  // Supabaseクライアント
  final SupabaseClient _supabase = Supabase.instance.client;
  
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
      final Set<String> _kIds = <String>{
        _monthlySubscriptionId,
        _yearlySubscriptionId,
      };
      
      final ProductDetailsResponse response = 
          await _inAppPurchase.queryProductDetails(_kIds);
      
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
    
    _isPurchasePending = true;
    _errorMessage = null;
    notifyListeners();
    
    try {
      // 購入フローを開始
      final PurchaseParam purchaseParam = PurchaseParam(
        productDetails: product,
        applicationUserName: null,
      );
      
      if (Platform.isIOS) {
        await _inAppPurchase.buyNonConsumable(purchaseParam: purchaseParam);
      } else {
        await _inAppPurchase.buyNonConsumable(purchaseParam: purchaseParam);
      }
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
          _errorMessage = '購入エラー: ${purchaseDetails.error?.message}';
          _isPurchasePending = false;
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
      
      // Supabase Edge Functionを呼び出す
      final response = await _supabase.functions.invoke(
        'verify-purchase',
        body: {
          'receipt': purchaseDetails.verificationData.serverVerificationData,
          'deviceId': deviceId,
          'productId': purchaseDetails.productID,
          'platform': Platform.isIOS ? 'ios' : 'android',
        },
      );
      
      return response.data as Map<String, dynamic>;
    } catch (e) {
      print('Supabase Functionの呼び出しエラー: $e');
      
      // エラーが発生した場合、デバッグモードでは仮の検証結果を返す
      if (const bool.fromEnvironment('dart.vm.product') == false) {
        return {
          'success': true,
          'isValid': true,
          'expiresDate': DateTime.now().add(const Duration(days: 30)).toIso8601String(),
        };
      }
      
      rethrow;
    }
  }
  
  /// アプリのサブスクリプション管理画面を開く
  Future<void> openSubscriptionManagement() async {
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
      _errorMessage = 'サブスクリプション管理画面を開く際にエラーが発生しました: $e';
      notifyListeners();
    }
  }
  
  /// 購入を復元
  Future<void> restorePurchases() async {
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
