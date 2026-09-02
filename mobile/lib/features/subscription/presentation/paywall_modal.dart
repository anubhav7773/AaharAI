import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

import '../../../core/billing/billing_service.dart';
import '../../../core/billing/subscription_provider.dart';

class PaywallModal extends ConsumerStatefulWidget {
  const PaywallModal({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const PaywallModal(),
    );
  }

  @override
  ConsumerState<PaywallModal> createState() => _PaywallModalState();
}

class _PaywallModalState extends ConsumerState<PaywallModal> {
  String _selectedTierId = BillingService.monthlyPlanId;
  bool _isProcessing = false;

  Future<void> _checkout() async {
    final billing = ref.read(billingServiceProvider);
    final products = ref.read(subscriptionProductsProvider).valueOrNull ?? [];
    final product = _findProduct(products);
    if (product == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Plans are currently unavailable.')),
      );
      return;
    }

    setState(() => _isProcessing = true);
    try {
      final initiated = await billing.buySubscription(product);
      if (!initiated && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Payment initiation cancelled.')),
        );
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  ProductDetails? _findProduct(List<ProductDetails> products) {
    for (final product in products) {
      if (product.id == _selectedTierId) return product;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final pro = ref.watch(isProUserProvider).valueOrNull ?? false;
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
      child: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFE5E7EB),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              const Text('AaharAi Pro Access',
                  style: TextStyle(
                      color: Color(0xFF1B5E20),
                      fontSize: 12,
                      fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              const Text('Know Every Molecule You Eat',
                  style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF111827))),
              const SizedBox(height: 8),
              Text(
                pro
                    ? 'Your Pro access is active.'
                    : 'Unlock unlimited scans, instant OCR analysis, and an ad-free experience.',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 13.5, color: Color(0xFF6B7280)),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  _tier(BillingService.weeklyPlanId, 'Weekly', '₹29', '/week'),
                  const SizedBox(width: 10),
                  _tier(BillingService.monthlyPlanId, 'Monthly', '₹89', '/month',
                      popular: true),
                  const SizedBox(width: 10),
                  _tier(BillingService.annualPlanId, 'Annual', '₹499', '/year'),
                ],
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _isProcessing || pro ? null : _checkout,
                  child: _isProcessing
                      ? const CircularProgressIndicator()
                      : const Text('Continue with Google Play'),
                ),
              ),
              TextButton(
                onPressed: _isProcessing
                    ? null
                    : () => ref.read(billingServiceProvider).restorePurchases(),
                child: const Text('Restore Purchases'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _tier(String id, String title, String price, String period,
      {bool popular = false}) {
    final selected = _selectedTierId == id;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedTierId = id),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 6),
          decoration: BoxDecoration(
            color: selected ? const Color(0xFFE8F5E9) : Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: selected
                  ? const Color(0xFF1B5E20)
                  : const Color(0xFFE5E7EB),
              width: selected ? 2 : 1,
            ),
          ),
          child: Column(
            children: [
              Text(title, style: const TextStyle(fontSize: 12)),
              const SizedBox(height: 4),
              Text(price,
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold)),
              Text(period,
                  style: const TextStyle(fontSize: 10, color: Colors.grey)),
              if (popular)
                const Text('Popular',
                    style: TextStyle(
                        fontSize: 9,
                        color: Color(0xFF1B5E20),
                        fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      ),
    );
  }
}
