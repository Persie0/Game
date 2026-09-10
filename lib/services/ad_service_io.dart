import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import 'ad_service_contract.dart';

AdService createAdService() => _MobileAdService();

class _MobileAdService implements AdService {
  static const _androidBanner = String.fromEnvironment('ADMOB_BANNER_ANDROID');
  static const _iosBanner = String.fromEnvironment('ADMOB_BANNER_IOS');
  static const _androidRewarded = String.fromEnvironment('ADMOB_REWARDED_ANDROID');
  static const _iosRewarded = String.fromEnvironment('ADMOB_REWARDED_IOS');
  static const _androidInterstitial =
      String.fromEnvironment('ADMOB_INTERSTITIAL_ANDROID');
  static const _iosInterstitial = String.fromEnvironment('ADMOB_INTERSTITIAL_IOS');

  bool _canRequestAds = false;

  @override
  bool get supported => Platform.isAndroid || Platform.isIOS;

  String get _bannerId => Platform.isAndroid ? _androidBanner : _iosBanner;
  String get _rewardedId => Platform.isAndroid ? _androidRewarded : _iosRewarded;
  String get _interstitialId =>
      Platform.isAndroid ? _androidInterstitial : _iosInterstitial;

  @override
  bool get configured => supported &&
      (_bannerId.isNotEmpty || _rewardedId.isNotEmpty || _interstitialId.isNotEmpty);

  @override
  Future<void> initialize() async {
    if (!supported || !configured) return;
    final consentUpdated = Completer<void>();
    ConsentInformation.instance.requestConsentInfoUpdate(
      ConsentRequestParameters(),
      () async {
        await ConsentForm.loadAndShowConsentFormIfRequired((_) {});
        if (!consentUpdated.isCompleted) consentUpdated.complete();
      },
      (_) {
        if (!consentUpdated.isCompleted) consentUpdated.complete();
      },
    );
    await consentUpdated.future;
    _canRequestAds = await ConsentInformation.instance.canRequestAds();
    if (_canRequestAds) await MobileAds.instance.initialize();
  }

  @override
  Future<bool> privacyOptionsRequired() async {
    if (!supported || !configured) return false;
    final status =
        await ConsentInformation.instance.getPrivacyOptionsRequirementStatus();
    return status == PrivacyOptionsRequirementStatus.required;
  }

  @override
  Future<void> showPrivacyOptions() async {
    if (!supported || !configured) return;
    await ConsentForm.showPrivacyOptionsForm((_) {});
    _canRequestAds = await ConsentInformation.instance.canRequestAds();
  }

  @override
  Widget banner({required bool enabled}) {
    if (!enabled || !supported || !_canRequestAds || _bannerId.isEmpty) {
      return const SizedBox.shrink();
    }
    return _BannerSlot(adUnitId: _bannerId);
  }

  @override
  Future<bool> showRewarded() async {
    if (!supported || !_canRequestAds || _rewardedId.isEmpty) return false;
    final completer = Completer<bool>();
    await RewardedAd.load(
      adUnitId: _rewardedId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          var earned = false;
          ad.fullScreenContentCallback = FullScreenContentCallback(
            onAdDismissedFullScreenContent: (ad) {
              ad.dispose();
              if (!completer.isCompleted) completer.complete(earned);
            },
            onAdFailedToShowFullScreenContent: (ad, error) {
              ad.dispose();
              if (!completer.isCompleted) completer.complete(false);
            },
          );
          ad.show(onUserEarnedReward: (_, __) => earned = true);
        },
        onAdFailedToLoad: (_) {
          if (!completer.isCompleted) completer.complete(false);
        },
      ),
    );
    return completer.future;
  }

  @override
  Future<void> maybeShowInterstitial({required bool enabled}) async {
    if (!enabled || !supported || !_canRequestAds || _interstitialId.isEmpty) return;
    final completer = Completer<void>();
    await InterstitialAd.load(
      adUnitId: _interstitialId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          ad.fullScreenContentCallback = FullScreenContentCallback(
            onAdDismissedFullScreenContent: (ad) {
              ad.dispose();
              if (!completer.isCompleted) completer.complete();
            },
            onAdFailedToShowFullScreenContent: (ad, error) {
              ad.dispose();
              if (!completer.isCompleted) completer.complete();
            },
          );
          ad.show();
        },
        onAdFailedToLoad: (_) {
          if (!completer.isCompleted) completer.complete();
        },
      ),
    );
    await completer.future;
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
        onAdLoaded: (_) => mounted ? setState(() => _loaded = true) : null,
        onAdFailedToLoad: (ad, _) => ad.dispose(),
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
    if (!_loaded || _ad == null) return const SizedBox.shrink();
    return SizedBox(
      width: _ad!.size.width.toDouble(),
      height: _ad!.size.height.toDouble(),
      child: AdWidget(ad: _ad!),
    );
  }
}
