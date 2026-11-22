import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../../services/ad_service.dart';

class BannerAdSlot extends StatefulWidget {
  final bool darkMode;
  final EdgeInsets padding;
  final BorderRadiusGeometry borderRadius;

  const BannerAdSlot({
    super.key,
    this.darkMode = false,
    this.padding = const EdgeInsets.symmetric(horizontal: 16),
    this.borderRadius = const BorderRadius.all(Radius.circular(12)),
  });

  @override
  State<BannerAdSlot> createState() => _BannerAdSlotState();
}

class _BannerAdSlotState extends State<BannerAdSlot> {
  BannerAd? _bannerAd;
  bool _isLoaded = false;

  @override
  void initState() {
    super.initState();
    if (AdService.isReady) _loadBanner();
  }

  Future<void> _loadBanner() async {
    final ad = AdService.createBanner(
      listener: BannerAdListener(
        onAdLoaded: (_) {
          if (mounted) setState(() => _isLoaded = true);
        },
        onAdFailedToLoad: (ad, error) {
          if (_bannerAd == ad) {
            _bannerAd = null;
            ad.dispose();
          }
        },
      ),
    );
    _bannerAd = ad;
    await ad.load();
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ad = _bannerAd;
    if (!_isLoaded || ad == null) return const SizedBox.shrink();
    final baseColor =
        widget.darkMode
            ? Colors.white.withValues(alpha: 0.08)
            : Colors.black.withValues(alpha: 0.05);

    return Padding(
      padding: widget.padding,
      child: Container(
        decoration: BoxDecoration(
          color: baseColor,
          borderRadius: widget.borderRadius,
          border: Border.all(
            color:
                widget.darkMode
                    ? Colors.white.withValues(alpha: 0.12)
                    : Colors.black.withValues(alpha: 0.08),
          ),
        ),
        padding: const EdgeInsets.all(8),
        child: SizedBox(
          height: ad.size.height.toDouble(),
          width: ad.size.width.toDouble(),
          child: AdWidget(ad: ad),
        ),
      ),
    );
  }
}
