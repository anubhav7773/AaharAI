import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

class BillingService {
  BillingService({InAppPurchase? store}) : _iap = store ?? InAppPurchase.instance;

  final InAppPurchase _iap;
  StreamSubscription<List<PurchaseDetails>>? _subscription;

  static const weeklyPlanId = 'aaharai_pro_weekly';
  static const monthlyPlanId = 'aaharai_pro_monthly';
  static const annualPlanId = 'aaharai_pro_annual';

  static const Set<String> productIds = {
    weeklyPlanId,
    monthlyPlanId,
    annualPlanId,
  };

  final isProUser = ValueNotifier<bool>(false);
  final products = ValueNotifier<List<ProductDetails>>(<ProductDetails>[]);
  final _proUserChanges = StreamController<bool>.broadcast();
  final _productChanges =
      StreamController<List<ProductDetails>>.broadcast();

  Stream<bool> get proUserChanges => _proUserChanges.stream;
  Stream<List<ProductDetails>> get productChanges => _productChanges.stream;

  Future<void> initialize() async {
    if (!await _iap.isAvailable()) {
      debugPrint('[BillingService] Google Play Store unavailable.');
      return;
    }

    _subscription ??= _iap.purchaseStream.listen(
      _handlePurchaseUpdates,
      onError: (Object error) => debugPrint('[BillingService] $error'),
    );
    await loadProducts();
    await restorePurchases();
  }

  Future<void> loadProducts() async {
    final response = await _iap.queryProductDetails(productIds);
    if (response.error != null) {
      debugPrint('[BillingService] Query error: ${response.error!.message}');
      return;
    }
    products.value = response.productDetails;
    _productChanges.add(products.value);
  }

  Future<bool> buySubscription(ProductDetails product) {
    return _iap.buyNonConsumable(
      purchaseParam: PurchaseParam(productDetails: product),
    );
  }

  Future<void> restorePurchases() => _iap.restorePurchases();

  Future<void> _handlePurchaseUpdates(
    List<PurchaseDetails> purchases,
  ) async {
    for (final purchase in purchases) {
      if (purchase.status == PurchaseStatus.purchased ||
          purchase.status == PurchaseStatus.restored) {
        if (_verifyPurchase(purchase)) {
          isProUser.value = true;
          _proUserChanges.add(true);
        }
        if (purchase.pendingCompletePurchase) {
          await _iap.completePurchase(purchase);
        }
      } else if (purchase.status == PurchaseStatus.error) {
        debugPrint('[BillingService] Purchase error: ${purchase.error?.message}');
      }
    }
  }

  bool _verifyPurchase(PurchaseDetails purchase) {
    return productIds.contains(purchase.productID);
  }

  void dispose() {
    _subscription?.cancel();
    isProUser.dispose();
    products.dispose();
    _proUserChanges.close();
    _productChanges.close();
  }
}
