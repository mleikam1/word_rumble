import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'package:google_mobile_ads/google_mobile_ads.dart';

class AdService {
  static const _androidAppId = 'ca-app-pub-3940256099942544~3347511713';
  static const _iosAppId = 'ca-app-pub-3940256099942544~1458002511';

  static const _androidBannerId = 'ca-app-pub-3940256099942544/6300978111';
  static const _iosBannerId = 'ca-app-pub-3940256099942544/2934735716';

  static bool _ready = false;
  static bool get isReady => _ready;
  static bool get _isAndroid => defaultTargetPlatform == TargetPlatform.android;

  static String get bannerAdUnitId =>
      _isAndroid ? _androidBannerId : _iosBannerId;

  static String get appId => _isAndroid ? _androidAppId : _iosAppId;

  static Future<void> initialize() async {
    if (kIsWeb ||
        (!_isAndroid && defaultTargetPlatform != TargetPlatform.iOS)) {
      return;
    }
    try {
      await MobileAds.instance.initialize();
      _ready = true;
    } on MissingPluginException {
      // The game can still run when the mobile ads plugin is unavailable.
    } on PlatformException catch (error) {
      debugPrint('Mobile ads unavailable: ${error.code}');
    }
  }

  static BannerAd createBanner({
    AdSize size = AdSize.banner,
    BannerAdListener listener = const BannerAdListener(),
  }) {
    return BannerAd(
      size: size,
      adUnitId: bannerAdUnitId,
      request: const AdRequest(),
      listener: listener,
    );
  }

  static Future<RewardedAd> loadRewardedAd() async {
    final completer = Completer<RewardedAd>();

    await RewardedAd.load(
      adUnitId:
          _isAndroid
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
