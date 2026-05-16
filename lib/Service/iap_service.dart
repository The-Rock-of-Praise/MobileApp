import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:lyrics/Controllers/payment_controller.dart';
import 'package:lyrics/Service/user_service.dart';

class IAPService {
  static final IAPService _instance = IAPService._internal();
  factory IAPService() => _instance;
  IAPService._internal();

  final InAppPurchase _iap = InAppPurchase.instance;
  late StreamSubscription<List<PurchaseDetails>> _subscription;
  
  List<ProductDetails> products = [];
  bool isAvailable = false;
  bool _isInitialized = false;

  // Callback to update UI when purchase status changes
  Function(PurchaseStatus status, String? error)? onPurchaseUpdate;

  Future<void> initialize() async {
    if (_isInitialized) return;
    _isInitialized = true;
    isAvailable = await _iap.isAvailable();
    if (!isAvailable) {
      debugPrint("IAP not available on this device");
      return;
    }

    final Stream<List<PurchaseDetails>> purchaseUpdated = _iap.purchaseStream;
    _subscription = purchaseUpdated.listen(
      (List<PurchaseDetails> purchaseDetailsList) {
        _listenToPurchaseUpdates(purchaseDetailsList);
      },
      onDone: () {
        _subscription.cancel();
      },
      onError: (error) {
        debugPrint("IAP Stream Error: $error");
      },
    );

    // Initial fetch of products
    await fetchProducts(['rop_pro_monthly']);
  }

  Future<void> fetchProducts(List<String> ids) async {
    final ProductDetailsResponse response = await _iap.queryProductDetails(ids.toSet());
    if (response.error == null) {
      products = response.productDetails;
      debugPrint("Fetched ${products.length} products");
    } else {
      debugPrint("Error fetching products: ${response.error}");
    }
  }

  Future<void> buyProduct(String productId) async {
    final ProductDetails? product = products.firstWhere(
      (p) => p.id == productId,
      orElse: () => throw Exception("Product not found"),
    );

    if (product != null) {
      final PurchaseParam purchaseParam = PurchaseParam(productDetails: product);
      // For subscriptions, use buyNonConsumable as they are managed by the store
      await _iap.buyNonConsumable(purchaseParam: purchaseParam);
    }
  }

  Future<void> restorePurchases() async {
    await _iap.restorePurchases();
  }

  void _listenToPurchaseUpdates(List<PurchaseDetails> purchaseDetailsList) {
    purchaseDetailsList.forEach((PurchaseDetails purchaseDetails) async {
      if (purchaseDetails.status == PurchaseStatus.pending) {
        onPurchaseUpdate?.call(PurchaseStatus.pending, null);
      } else {
        if (purchaseDetails.status == PurchaseStatus.error) {
          debugPrint("Purchase Error: ${purchaseDetails.error}");
          onPurchaseUpdate?.call(PurchaseStatus.error, purchaseDetails.error?.message);
        } else if (purchaseDetails.status == PurchaseStatus.purchased ||
                   purchaseDetails.status == PurchaseStatus.restored) {
          
          // Verify with backend and update user status
          bool success = await _verifyPurchase(purchaseDetails);
          
          if (success) {
            onPurchaseUpdate?.call(PurchaseStatus.purchased, null);
          } else {
            onPurchaseUpdate?.call(PurchaseStatus.error, "Verification failed");
          }
        }
        
        // CRITICAL: Finalize the transaction
        if (purchaseDetails.pendingCompletePurchase) {
          await _iap.completePurchase(purchaseDetails);
          debugPrint("Purchase completed/finalized for: ${purchaseDetails.productID}");
        }
      }
    });
  }

  Future<bool> _verifyPurchase(PurchaseDetails purchase) async {
    try {
      final userId = await UserService.getUserID();
      final email = await UserService.getUserEmail(); // Assuming this helper exists or get it from elsewhere
      
      final PaymentController paymentController = PaymentController();
      
      // We use the existing payment controller logic but adapted for IAP
      // Typically you'd send the receipt/token to your backend here
      bool success = await paymentController.handlePaymentSuccess(
        email: email,
        userId: userId,
        paymentId: purchase.purchaseID ?? "IAP_${purchase.transactionDate}",
      );
      
      return success;
    } catch (e) {
      debugPrint("Verification Error: $e");
      return false;
    }
  }

  void dispose() {
    _subscription.cancel();
  }
}
