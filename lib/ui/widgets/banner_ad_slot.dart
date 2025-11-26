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
    _loadBanner();
  }

  Future<void> _loadBanner() async {
    final ad = AdService.createBanner();
    await ad.load();
    if (!mounted) {
      ad.dispose();
      return;
    }
    setState(() {
      _bannerAd = ad;
      _isLoaded = true;
    });
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final baseColor = widget.darkMode
        ? Colors.white.withValues(alpha: 0.08)
        : Colors.black.withValues(alpha: 0.05);

    return Padding(
      padding: widget.padding,
      child: Container(
        decoration: BoxDecoration(
          color: baseColor,
          borderRadius: widget.borderRadius,
          border: Border.all(
            color: widget.darkMode
                ? Colors.white.withValues(alpha: 0.12)
                : Colors.black.withValues(alpha: 0.08),
          ),
        ),
        padding: const EdgeInsets.all(8),
        child: AnimatedSize(
          duration: const Duration(milliseconds: 200),
          alignment: Alignment.center,
          child: _isLoaded && _bannerAd != null
              ? SizedBox(
                  height: _bannerAd!.size.height.toDouble(),
                  width: _bannerAd!.size.width.toDouble(),
                  child: AdWidget(ad: _bannerAd!),
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const CircularProgressIndicator(strokeWidth: 2),
                    const SizedBox(width: 12),
                    Text(
                      'Loading test ad…',
                      style: TextStyle(
                        color: widget.darkMode ? Colors.white70 : Colors.black87,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}
