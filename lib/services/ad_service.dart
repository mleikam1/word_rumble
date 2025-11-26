import 'dart:async';
import 'dart:io';

import 'package:google_mobile_ads/google_mobile_ads.dart';

class AdService {
  static const _androidAppId = 'ca-app-pub-3940256099942544~3347511713';
  static const _iosAppId = 'ca-app-pub-3940256099942544~1458002511';

  static const _androidBannerId = 'ca-app-pub-3940256099942544/6300978111';
  static const _iosBannerId = 'ca-app-pub-3940256099942544/2934735716';

  static String get bannerAdUnitId =>
      Platform.isAndroid ? _androidBannerId : _iosBannerId;

  static String get appId => Platform.isAndroid ? _androidAppId : _iosAppId;

  static Future<InitializationStatus> initialize() {
    return MobileAds.instance.initialize();
  }

  static BannerAd createBanner({AdSize size = AdSize.banner}) {
    return BannerAd(
      size: size,
      adUnitId: bannerAdUnitId,
      request: const AdRequest(),
      listener: const BannerAdListener(),
    );
  }

  static Future<RewardedAd> loadRewardedAd() async {
    final completer = Completer<RewardedAd>();

    await RewardedAd.load(
      adUnitId: Platform.isAndroid
          ? 'ca-app-pub-3940256099942544/5224354917'
          : 'ca-app-pub-3940256099942544/1712485313',
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdFailedToLoad: (error) {
          if (!completer.isCompleted) {
            completer.completeError(error);
          }
        },
        onAdLoaded: (ad) {
          if (!completer.isCompleted) {
            completer.complete(ad);
          }
        },
      ),
    );

    return completer.future;
  }
}
