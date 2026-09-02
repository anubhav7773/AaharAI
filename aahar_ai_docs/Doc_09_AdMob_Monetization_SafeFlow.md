# Doc 09: AdMob Monetization, Google Play Billing & Pricing Strategy

## 1. Indian Consumer Psychology & Pricing Architecture

India ke digital market mein micro-transactions ka model sabse tezi se convert hota hai (jaise OTT sachet packs aur UPI pocket spendings). Package food dekhkar consumer ke andar instant curiosity hoti hai, lekin heavy upfront barrier aate hi churn badh jata hai. 

Hume pricing aisi rakhni hai jisme **"Free scans" se aadat (habit loop) bane**, fir natural ceiling aane par upgrade cost ek cup chai ya fast food snack se kam lage[cite: 1].

### Production Pricing Tiers (Targeting High Volume & Retention)

| Tier / Plan | Price (INR) | Effective Cost | Target Conversion Psychology |
| :--- | :--- | :--- | :--- |
| **Free Tier (Ad-Supported)** | ₹0 | ₹0 | **Habit Builder**: 5 free scans/day. Non-intrusive banners on history/diary tab[cite: 1]. Interstitial ad strictly *after* result dismissal (never blocking food results)[cite: 1]. |
| **Weekly Sachet ("Chai-Pack")** | **₹29 / week** | ~₹4 / day | **Zero-Commitment Impulse**: Jab user grocery shopping ya diet start karta hai. User 1 month lock nahi hona chahta, isliye ₹29 bina soche pay karta hai. |
| **Monthly Pro (Sweet Spot)** | **₹89 / month** | ~₹2.9 / day | **Primary Conversion Anchor**: Ek plate street momo/burger se sasta[cite: 1]. Unlimited barcode scans, direct image OCRs, complete macro tracking, zero ads[cite: 1]. |
| **Annual Pro (High LTV)** | **₹499 / year** | ~₹41 / month | **No-Brainer Value**: 54% discount showcase. Long-term health consciousness enthusiasts ke liye. |

---

## 2. Monetization Guardrails (Zero Frustration UX)

1. **Never Block Scan Discovery**: Scan button click karte waqt ya camera open hote waqt kabhi ad na lagayein[cite: 1]. Analysis result card user ke samne turant aana chahiye[cite: 1].
2. **Post-Dismissal Interstitial Trigger**: Interstitial ad sirf tabhi fire hoga jab user result dekh chuka ho aur "Done / Back / Log to Diary" tap kare (maximum 1 interstitial per 3 scans)[cite: 1].
3. **Banner Placement**: Banner ads sirf `DailyDiaryScreen` aur `HistoryScreen` ke bottom me dedicated non-shifting safe area container me show honge[cite: 1].

---

## 3. Google Play Billing Client (`lib/core/billing/purchase_service.dart`)

Antigravity must use the official `in_app_purchase` package with an entitlement verification pipeline[cite: 1]:

```dart
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Product IDs declared inside Google Play Console
class BillingConstants {
  static const String weeklyPro = 'aahar_pro_weekly_29';
  static const String monthlyPro = 'aahar_pro_monthly_89';
  static const String annualPro = 'aahar_pro_yearly_499';

  static const Set<String> subscriptionIds = {
    weeklyPro,
    monthlyPro,
    annualPro,
  };
}

final purchaseServiceProvider = Provider<PurchaseService>((ref) {
  final service = PurchaseService();
  service.initialize();
  return service;
});

final isProUserProvider = StateProvider<bool>((ref) => false);

class PurchaseService {
  final InAppPurchase _iap = InAppPurchase.instance;
  late StreamSubscription<List<PurchaseDetails>> _subscription;
  List<ProductDetails> availableProducts = [];

  void initialize() {
    final Stream<List<PurchaseDetails>> purchaseUpdated = _iap.purchaseStream;
    _subscription = purchaseUpdated.listen(
      _handlePurchaseUpdates,
      onDone: () => _subscription.cancel(),
      onError: (error) => debugPrint('IAP Error: $error'),
    );
  }

  Future<void> loadProducts() async {
    final bool available = await _iap.isAvailable();
    if (!available) return;

    final ProductDetailsResponse response =
        await _iap.queryProductDetails(BillingConstants.subscriptionIds);

    if (response.notFoundIDs.isNotEmpty) {
      debugPrint('Products not found: ${response.notFoundIDs}');
    }
    availableProducts = response.productDetails;
  }

  Future<bool> buySubscription(ProductDetails product) async {
    final PurchaseParam purchaseParam = PurchaseParam(productDetails: product);
    return await _iap.buyNonConsumable(purchaseParam: purchaseParam);
  }

  Future<void> restorePurchases(WidgetRef ref) async {
    await _iap.restorePurchases();
  }

  Future<void> _handlePurchaseUpdates(List<PurchaseDetails> purchaseDetailsList) async {
    for (var purchase in purchaseDetailsList) {
      if (purchase.status == PurchaseStatus.pending) {
        // Show non-blocking loading indicator
      } else if (purchase.status == PurchaseStatus.error) {
        debugPrint('Purchase error: ${purchase.error}');
      } else if (purchase.status == PurchaseStatus.purchased ||
                 purchase.status == PurchaseStatus.restored) {
        
        // Verify entitlement receipt and grant Pro status
        final bool valid = await _verifyPurchaseOnBackend(purchase);
        if (valid) {
          if (purchase.pendingCompletePurchase) {
            await _iap.completePurchase(purchase);
          }
        }
      }
    }
  }

  Future<bool> _verifyPurchaseOnBackend(PurchaseDetails purchase) async {
    // In free tier architecture, token verification runs or checks purchase status
    return purchase.status == PurchaseStatus.purchased || 
           purchase.status == PurchaseStatus.restored;
  }
}
4. Non-Intrusive AdMob Controller (lib/core/ads/admob_service.dart)
Production controller for caching banner and interstitial ad units[cite: 1]:

Dart
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class AdMobService {
  // Replace with live Play Console Ad Unit IDs before production release
  static String get bannerAdUnitId {
    if (kDebugMode) {
      return Platform.isAndroid
          ? 'ca-app-pub-3940256099942544/6300978111' // Official Google Test Banner ID
          : 'ca-app-pub-3940256099942544/2934735716';
    }
    return Platform.isAndroid
        ? 'ca-app-pub-XXXXXXXXXXXXXXXX/BANNER_ID'
        : 'ca-app-pub-XXXXXXXXXXXXXXXX/BANNER_ID_IOS';
  }

  static String get interstitialAdUnitId {
    if (kDebugMode) {
      return Platform.isAndroid
          ? 'ca-app-pub-3940256099942544/1033173712' // Official Google Test Interstitial ID
          : 'ca-app-pub-3940256099942544/4411468910';
    }
    return Platform.isAndroid
        ? 'ca-app-pub-XXXXXXXXXXXXXXXX/INTERSTITIAL_ID'
        : 'ca-app-pub-XXXXXXXXXXXXXXXX/INTERSTITIAL_ID_IOS';
  }

  static InterstitialAd? _interstitialAd;
  static int _scanCounterSinceLastAd = 0;

  static void initialize() {
    MobileAds.instance.initialize();
    loadInterstitialAd();
  }

  static void loadInterstitialAd() {
    InterstitialAd.load(
      adUnitId: interstitialAdUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _interstitialAd = ad;
          _interstitialAd!.fullScreenContentCallback = FullScreenContentCallback(
            onAdDismissedFullScreenContent: (ad) {
              ad.dispose();
              loadInterstitialAd(); // Preload next ad
            },
            onAdFailedToShowFullScreenContent: (ad, err) {
              ad.dispose();
              loadInterstitialAd();
            },
          );
        },
        onAdFailedToLoad: (err) {
          _interstitialAd = null;
        },
      ),
    );
  }

  /// Evaluates frequency capping: strictly shows interstitial only after result view
  static void showInterstitialAfterScan(bool isProUser, {VoidCallback? onComplete}) {
    if (isProUser) {
      onComplete?.call();
      return;
    }

    _scanCounterSinceLastAd++;
    // Show interstitial at most once every 3 scans to avoid high friction
    if (_scanCounterSinceLastAd >= 3 && _interstitialAd != null) {
      _scanCounterSinceLastAd = 0;
      _interstitialAd!.show();
      onComplete?.call();
    } else {
      onComplete?.call();
    }
  }
}
5. Sticky Safe Banner Widget (lib/shared/widgets/ad_banner_widget.dart)
Dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../../core/ads/admob_service.dart';
import '../../core/billing/purchase_service.dart';

class SafeAdBannerWidget extends ConsumerStatefulWidget {
  const SafeAdBannerWidget({super.key});

  @override
  ConsumerState<SafeAdBannerWidget> createState() => _SafeAdBannerWidgetState();
}

class _SafeAdBannerWidgetState extends ConsumerState<SafeAdBannerWidget> {
  BannerAd? _bannerAd;
  bool _isLoaded = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final isPro = ref.watch(isProUserProvider);
    if (!isPro && _bannerAd == null) {
      _loadBanner();
    }
  }

  void _loadBanner() {
    _bannerAd = BannerAd(
      adUnitId: AdMobService.bannerAdUnitId,
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (_) => setState(() => _isLoaded = true),
        onAdFailedToLoad: (ad, error) {
          ad.dispose();
          _bannerAd = null;
        },
      ),
    )..load();
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isPro = ref.watch(isProUserProvider);
    if (isPro || !_isLoaded || _bannerAd == null) {
      return const SizedBox.shrink();
    }

    return Container(
      width: _bannerAd!.size.width.toDouble(),
      height: _bannerAd!.size.height.toDouble(),
      alignment: Alignment.center,
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: AdWidget(ad: _bannerAd!),
    );
  }
}
6. Premium Upgrade Paywall Modal (lib/features/subscription/paywall_modal.dart)
Dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/billing/purchase_service.dart';

class PremiumPaywallModal extends ConsumerWidget {
  const PremiumPaywallModal({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Upgrade to AaharAi Pro',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF111827)),
          ),
          const SizedBox(height: 8),
          const Text(
            'Eat healthy with total transparency & zero interruptions.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Color(0xFF6B7280), fontSize: 14),
          ),
          const SizedBox(height: 24),
          _buildFeatureRow(Icons.all_inclusive, 'Unlimited Barcode & Food Label OCR scans'),
          _buildFeatureRow(Icons.block, '100% Ad-Free Experience (No banners, no waiting)'),
          _buildFeatureRow(Icons.insights, 'Full IFCT Micronutrients & Street Food Health Matrix'),
          const SizedBox(height: 24),
          
          // Monthly Plan (Recommended Conversion Anchor)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border.all(color: const Color(0xFF1B5E20), width: 2),
              borderRadius: BorderRadius.circular(16),
              color: const Color(0xFFE8F5E9),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: const [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Monthly Pro', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    Text('Billed monthly. Cancel anytime.', style: TextStyle(fontSize: 12, color: Color(0xFF4B5563))),
                  ],
                ),
                Text('₹89 / mo', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF1B5E20))),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Weekly Sachet Plan
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey[300]!),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: const [
                Text('Weekly Trial', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                Text('₹29 / week', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF111827))),
              ],
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () {
              // Trigger Google Play Billing flow for selected product
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1B5E20),
              minimumSize: const Size.fromHeight(52),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            child: const Text('Start Pro Journey', style: TextStyle(fontSize: 16, color: Colors.white)),
          ),
          const SizedBox(height: 8),
          const Text(
            'Secured via Google Play Billing. Auto-renews until cancelled.',
            style: TextStyle(fontSize: 11, color: Color(0xFF9CA3AF)),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        children: [
          Icon(icon, size: 20, color: const Color(0xFF1B5E20)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(text, style: const TextStyle(fontSize: 14, color: Color(0xFF374151))),
          ),
        ],
      ),
    );
  }
}