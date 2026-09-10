import 'package:flutter/widgets.dart';

import 'ad_service_contract.dart';

AdService createAdService() => _StubAdService();

class _StubAdService implements AdService {
  @override
  bool get supported => false;

  @override
  bool get configured => false;

  @override
  Future<void> initialize() async {}

  @override
  Future<bool> privacyOptionsRequired() async => false;

  @override
  Future<void> showPrivacyOptions() async {}

  @override
  Widget banner({required bool enabled}) => const SizedBox.shrink();

  @override
  Future<bool> showRewarded() async => false;

  @override
  Future<void> maybeShowInterstitial({required bool enabled}) async {}
}
