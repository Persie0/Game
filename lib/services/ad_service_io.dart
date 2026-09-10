import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import 'ad_service_contract.dart';

AdService createAdService() => _MobileAdService();

class _MobileAdService implements AdService {
  static const _androidBanner = String.fromEnvironment('ADMOB_BANNER_ANDROID');
  static const _iosBanner = String.fromEnvironment('ADMOB_BANNER_IOS');
  static const _androidRewarded =
      String.fromEnvironment('ADMOB_REWARDED_ANDROID');
  static const _iosRewarded = String.fromEnvironment('ADMOB_REWARDED_IOS');
  static const _androidInterstitial =
      String.fromEnvironment('ADMOB_INTERSTITIAL_ANDROID');
  static const _iosInterstitial =
      String.fromEnvironment('ADMOB_INTERSTITIAL_IOS');

  bool _canRequestAds = false;
  bool _adsInitialized = false;

  @override
  bool get supported => Platform.isAndroid || Platform.isIOS;

  String get _bannerId => Platform.isAndroid ? _androidBanner : _iosBanner;
  String get _rewardedId =>
      Platform.isAndroid ? _androidRewarded : _iosRewarded;
  String get _interstitialId =>
      Platform.isAndroid ? _androidInterstitial : _iosInterstitial;

  @override
  bool get configured =>
      supported &&
      (_bannerId.isNotEmpty ||
          _rewardedId.isNotEmpty ||
          _interstitialId.isNotEmpty);

  @override
  Future<void> initialize() async {
    if (!supported || !configured) {
      return;
    }

    try {
      final consentUpdated = Completer<void>();
      ConsentInformation.instance.requestConsentInfoUpdate(
        ConsentRequestParameters(),
        () async {
          try {
            await ConsentForm.loadAndShowConsentFormIfRequired((_) {});
          } finally {
            if (!consentUpdated.isCompleted) {
              consentUpdated.complete();
            }
          }
        },
        (_) {
          if (!consentUpdated.isCompleted) {
            consentUpdated.complete();
          }
        },
      );
      await consentUpdated.future.timeout(
        const Duration(seconds: 15),
        onTimeout: () {},
      );
      await _refreshConsentAndSdk();
    } catch (_) {
      // Ads are optional. Consent/network/SDK failures must never block startup.
      _canRequestAds = false;
    }
  }

  Future<void> _refreshConsentAndSdk() async {
    _canRequestAds = await ConsentInformation.instance.canRequestAds();
    if (_canRequestAds && !_adsInitialized) {
      await MobileAds.instance.initialize();
      _adsInitialized = true;
    }
  }

  @override
  Future<bool> privacyOptionsRequired() async {
    if (!supported || !configured) {
      return false;
    }
    try {
      final status = await ConsentInformation.instance
          .getPrivacyOptionsRequirementStatus();
      return status == PrivacyOptionsRequirementStatus.required;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<void> showPrivacyOptions() async {
    if (!supported || !configured) {
      return;
    }
    try {
      await ConsentForm.showPrivacyOptionsForm((_) {});
      await _refreshConsentAndSdk();
    } catch (_) {
      // Keep the game usable if UMP is temporarily unavailable.
    }
  }

  @override
  Widget banner({required bool enabled}) {
    if (!enabled ||
        !supported ||
        !_adsInitialized ||
        !_canRequestAds ||
        _bannerId.isEmpty) {
      return const SizedBox.shrink();
    }
    return _BannerSlot(adUnitId: _bannerId);
  }

  @override
  Future<bool> showRewarded() async {
    if (!supported ||
        !_adsInitialized ||
        !_canRequestAds ||
        _rewardedId.isEmpty) {
      return false;
    }

    final completer = Completer<bool>();
    RewardedAd? loadedAd;
    try {
      await RewardedAd.load(
        adUnitId: _rewardedId,
        request: const AdRequest(),
        rewardedAdLoadCallback: RewardedAdLoadCallback(
          onAdLoaded: (ad) {
            loadedAd = ad;
            var earned = false;
            ad.fullScreenContentCallback = FullScreenContentCallback(
              onAdDismissedFullScreenContent: (ad) {
                ad.dispose();
                loadedAd = null;
                if (!completer.isCompleted) {
                  completer.complete(earned);
                }
              },
              onAdFailedToShowFullScreenContent: (ad, error) {
                ad.dispose();
                loadedAd = null;
                if (!completer.isCompleted) {
                  completer.complete(false);
                }
              },
            );
            ad.show(onUserEarnedReward: (_, _) => earned = true);
          },
          onAdFailedToLoad: (_) {
            if (!completer.isCompleted) {
              completer.complete(false);
            }
          },
        ),
      );
      return await completer.future.timeout(
        const Duration(minutes: 3),
        onTimeout: () {
          loadedAd?.dispose();
          return false;
        },
      );
    } catch (_) {
      loadedAd?.dispose();
      return false;
    }
  }

  @override
  Future<void> maybeShowInterstitial({required bool enabled}) async {
    if (!enabled ||
        !supported ||
        !_adsInitialized ||
        !_canRequestAds ||
        _interstitialId.isEmpty) {
      return;
    }

    final completer = Completer<void>();
    InterstitialAd? loadedAd;
    try {
      await InterstitialAd.load(
        adUnitId: _interstitialId,
        request: const AdRequest(),
        adLoadCallback: InterstitialAdLoadCallback(
          onAdLoaded: (ad) {
            loadedAd = ad;
            ad.fullScreenContentCallback = FullScreenContentCallback(
              onAdDismissedFullScreenContent: (ad) {
                ad.dispose();
                loadedAd = null;
                if (!completer.isCompleted) {
                  completer.complete();
                }
              },
              onAdFailedToShowFullScreenContent: (ad, error) {
                ad.dispose();
                loadedAd = null;
                if (!completer.isCompleted) {
                  completer.complete();
                }
              },
            );
            ad.show();
          },
          onAdFailedToLoad: (_) {
            if (!completer.isCompleted) {
              completer.complete();
            }
          },
        ),
      );
      await completer.future.timeout(
        const Duration(minutes: 2),
        onTimeout: () {
          loadedAd?.dispose();
        },
      );
    } catch (_) {
      loadedAd?.dispose();
    }
  }
}

class _BannerSlot extends StatefulWidget {
  const _BannerSlot({required this.adUnitId});

  final String adUnitId;

  @override
  State<_BannerSlot> createState() => _BannerSlotState();
}

class _BannerSlotState extends State<_BannerSlot> {
  BannerAd? _ad;
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _ad = BannerAd(
      size: AdSize.banner,
      adUnitId: widget.adUnitId,
      listener: BannerAdListener(
        onAdLoaded: (_) {
          if (mounted) {
            setState(() => _loaded = true);
          }
        },
        onAdFailedToLoad: (ad, _) {
          ad.dispose();
          if (identical(_ad, ad)) {
            _ad = null;
          }
        },
      ),
      request: const AdRequest(),
    )..load();
  }

  @override
  void dispose() {
    _ad?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ad = _ad;
    if (!_loaded || ad == null) {
      return const SizedBox.shrink();
    }
    return SizedBox(
      width: ad.size.width.toDouble(),
      height: ad.size.height.toDouble(),
      child: AdWidget(ad: ad),
    );
  }
}
