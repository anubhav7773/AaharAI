import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:path_provider/path_provider.dart';

class BillingService {
  BillingService({InAppPurchase? store, File? cacheFileOverride})
      : _customStore = store,
        _customCacheFile = cacheFileOverride;

  final InAppPurchase? _customStore;
  final File? _customCacheFile;
  StreamSubscription<List<PurchaseDetails>>? _subscription;

  InAppPurchase get _iap => _customStore ?? InAppPurchase.instance;

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

  Future<File?> _resolveCacheFile() async {
    if (_customCacheFile != null) return _customCacheFile;
    try {
      final dir = await getApplicationDocumentsDirectory();
      return File('${dir.path}/aaharai_pro_entitlement.json');
    } catch (_) {
      return null;
    }
  }

  Future<void> persistEntitlement(bool isPro) async {
    try {
      final file = await _resolveCacheFile();
      if (file != null) {
        await file.writeAsString(
          jsonEncode({
            'is_pro': isPro,
            'updated_at': DateTime.now().toIso8601String(),
          }),
        );
      }
    } catch (e) {
      debugPrint('[BillingService] Failed to persist entitlement: $e');
    }
  }

  Future<bool> loadCachedEntitlement() async {
    try {
      final file = await _resolveCacheFile();
      if (file != null && await file.exists()) {
        final content = await file.readAsString();
        final data = jsonDecode(content);
        if (data is Map && data['is_pro'] == true) {
          isProUser.value = true;
          _proUserChanges.add(true);
          return true;
        }
      }
    } catch (e) {
      debugPrint('[BillingService] Failed to load cached entitlement: $e');
    }
    return false;
  }

  Future<void> initialize() async {
    await loadCachedEntitlement();

    if (!await _iap.isAvailable()) {
      debugPrint('[BillingService] Google Play Store unavailable.');
      return;
    }

    _subscription ??= _iap.purchaseStream.listen(
      _handlePurchaseUpdates,
      onError: (Object error) => debugPrint('[BillingService] $error'),
    );
    await loadProducts();
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
          await persistEntitlement(true);
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
