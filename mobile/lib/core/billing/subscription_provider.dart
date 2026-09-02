import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

import 'billing_service.dart';

final billingServiceProvider = Provider<BillingService>((ref) {
  final service = BillingService();
  service.initialize();
  ref.onDispose(service.dispose);
  return service;
});

final isProUserProvider = StreamProvider<bool>((ref) async* {
  final billing = ref.watch(billingServiceProvider);
  yield billing.isProUser.value;
  yield* billing.proUserChanges;
});

final subscriptionProductsProvider =
    StreamProvider<List<ProductDetails>>((ref) async* {
  final billing = ref.watch(billingServiceProvider);
  yield billing.products.value;
  yield* billing.productChanges;
});
