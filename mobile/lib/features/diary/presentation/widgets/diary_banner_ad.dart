import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../../../../core/ads/ad_helper.dart';
import '../../../../core/billing/subscription_provider.dart';

class DiaryBannerAd extends ConsumerStatefulWidget {
  const DiaryBannerAd({super.key});

  @override
  ConsumerState<DiaryBannerAd> createState() => _DiaryBannerAdState();
}

class _DiaryBannerAdState extends ConsumerState<DiaryBannerAd> {
  BannerAd? _bannerAd;
  bool _isLoaded = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadAd());
  }

  void _loadAd() {
    if (ref.read(isProUserProvider).valueOrNull == true || _bannerAd != null) {
      return;
    }
    final ad = BannerAd(
      adUnitId: AdHelper.bannerAdUnitId,
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (_) {
          if (mounted) setState(() => _isLoaded = true);
        },
        onAdFailedToLoad: (ad, error) {
          debugPrint('[AdMob] Banner failed to load: ${error.message}');
          ad.dispose();
        },
      ),
    );
    _bannerAd = ad..load();
  }

  @override
  Widget build(BuildContext context) {
    final isPro = ref.watch(isProUserProvider).valueOrNull == true;
    if (isPro) return const SizedBox.shrink();
    if (_bannerAd == null) _loadAd();
    if (!_isLoaded || _bannerAd == null) {
      return const SizedBox(
        height: 50,
        child: Center(
          child: Text('Sponsored Content',
              style: TextStyle(fontSize: 10, color: Color(0xFF9CA3AF))),
        ),
      );
    }
    return SizedBox(
      width: _bannerAd!.size.width.toDouble(),
      height: _bannerAd!.size.height.toDouble(),
      child: AdWidget(ad: _bannerAd!),
    );
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    super.dispose();
  }
}
