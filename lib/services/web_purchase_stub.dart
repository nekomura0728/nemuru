/// Web platform stub for in_app_purchase functionality
/// This provides mock implementations for web platform compatibility

class InAppPurchase {
  static InAppPurchase instance = InAppPurchase._();
  InAppPurchase._();
  
  Future<bool> isAvailable() async => false;
  
  Stream<List<PurchaseDetails>> get purchaseStream => 
      const Stream<List<PurchaseDetails>>.empty();
      
  Future<ProductDetailsResponse> queryProductDetails(Set<String> productIds) async {
    return ProductDetailsResponse(
      productDetails: [],
      notFoundIDs: productIds.toList(),
      error: null,
    );
  }
  
  Future<bool> buyNonConsumable({required PurchaseParam purchaseParam}) async {
    return false;
  }
  
  Future<void> completePurchase(PurchaseDetails purchaseDetails) async {
    // No-op for web
  }
  
  Future<void> restorePurchases() async {
    // No-op for web
  }
}

class ProductDetailsResponse {
  final List<ProductDetails> productDetails;
  final List<String> notFoundIDs;
  final IAPError? error;
  
  ProductDetailsResponse({
    required this.productDetails,
    required this.notFoundIDs,
    this.error,
  });
}

class ProductDetails {
  final String id;
  final String title;
  final String description;
  final String price;
  final double rawPrice;
  final String currencyCode;
  
  ProductDetails({
    required this.id,
    required this.title,
    required this.description,
    required this.price,
    required this.rawPrice,
    required this.currencyCode,
  });
}

class PurchaseDetails {
  final String productID;
  final String purchaseID;
  final String transactionDate;
  final PurchaseStatus status;
  final IAPError? error;
  final bool pendingCompletePurchase;
  final PurchaseVerificationData verificationData;
  
  PurchaseDetails({
    required this.productID,
    required this.purchaseID,
    required this.transactionDate,
    required this.status,
    this.error,
    required this.pendingCompletePurchase,
    required this.verificationData,
  });
}

class PurchaseParam {
  final ProductDetails productDetails;
  final String? applicationUserName;
  
  PurchaseParam({
    required this.productDetails,
    this.applicationUserName,
  });
}

class PurchaseVerificationData {
  final String localVerificationData;
  final String serverVerificationData;
  final String source;
  
  PurchaseVerificationData({
    required this.localVerificationData,
    required this.serverVerificationData,
    required this.source,
  });
}

enum PurchaseStatus {
  pending,
  purchased,
  error,
  restored,
  canceled,
}

class IAPError {
  final String code;
  final String? message;
  
  IAPError({
    required this.code,
    this.message,
  });
}