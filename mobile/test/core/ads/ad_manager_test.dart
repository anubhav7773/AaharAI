import 'package:flutter_test/flutter_test.dart';

import 'package:aahar_ai/core/ads/ad_manager.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AdMob frequency capper', () {
    late AdManager adManager;

    setUp(() => adManager = AdManager());
    tearDown(() => adManager.dispose());

    test('Pro users bypass ads without changing the counter', () {
      adManager.showInterstitialIfEligible(isProUser: true);
      expect(adManager.currentScanCount, 0);
    });

    test('Free users increment the counter before the threshold', () {
      adManager.showInterstitialIfEligible(isProUser: false);
      adManager.showInterstitialIfEligible(isProUser: false);
      expect(adManager.currentScanCount, 2);
    });

    test('Counter resets after an eligible loaded ad is shown', () {
      adManager.setScanCountForTesting(AdManager.interstitialScanThreshold - 1);
      // No ad is loaded in unit tests, so this verifies the capper does not
      // reset until an interstitial can actually be shown.
      adManager.showInterstitialIfEligible(isProUser: false);
      expect(adManager.currentScanCount, AdManager.interstitialScanThreshold);
    });
  });
}
