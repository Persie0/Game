import 'package:flutter/widgets.dart';

abstract interface class AdService {
  bool get supported;
  bool get configured;

  Future<void> initialize();
  Future<bool> privacyOptionsRequired();
  Future<void> showPrivacyOptions();
  Widget banner({required bool enabled});
  Future<bool> showRewarded();
  Future<void> maybeShowInterstitial({required bool enabled});
}
