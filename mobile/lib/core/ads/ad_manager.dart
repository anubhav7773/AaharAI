import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import 'ad_helper.dart';

class AdManager {
  InterstitialAd? _interstitialAd;
  bool _isLoading = false;
  int _scanCounter = 0;

  static const interstitialScanThreshold = 3;

  Future<void> initialize() async {
    await MobileAds.instance.initialize();
    loadInterstitialAd();
  }

  void loadInterstitialAd() {
    if (_isLoading || _interstitialAd != null) return;
    final adUnitId = _interstitialAdUnitId;
    if (adUnitId == null) return;
    _isLoading = true;
    InterstitialAd.load(
      adUnitId: adUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _interstitialAd = ad;
          _isLoading = false;
          ad.fullScreenContentCallback = FullScreenContentCallback(
            onAdDismissedFullScreenContent: (ad) {
              ad.dispose();
              _interstitialAd = null;
              loadInterstitialAd();
            },
            onAdFailedToShowFullScreenContent: (ad, error) {
              debugPrint(
                  '[AdMob] Interstitial failed to show: ${error.message}');
              ad.dispose();
              _interstitialAd = null;
              loadInterstitialAd();
            },
          );
        },
        onAdFailedToLoad: (error) {
          _isLoading = false;
          debugPrint('[AdMob] Interstitial failed to load: ${error.message}');
        },
      ),
    );
  }

  String? get _interstitialAdUnitId {
    try {
      return AdHelper.interstitialAdUnitId;
    } on UnsupportedError {
      debugPrint('[AdMob] Platform does not support mobile ads.');
      return null;
    }
  }

  void showInterstitialIfEligible({required bool isProUser}) {
    if (isProUser) return;
    _scanCounter++;
    if (_scanCounter < interstitialScanThreshold) return;
    final ad = _interstitialAd;
    if (ad == null) {
      loadInterstitialAd();
      return;
    }
    _scanCounter = 0;
    _interstitialAd = null;
    ad.show();
  }

  int get currentScanCount => _scanCounter;

  @visibleForTesting
  void setScanCountForTesting(int count) => _scanCounter = count;

  void dispose() {
    _interstitialAd?.dispose();
    _interstitialAd = null;
  }
}

final adManagerProvider = Provider<AdManager>((ref) {
  final manager = AdManager();
  manager.initialize();
  ref.onDispose(manager.dispose);
  return manager;
});
