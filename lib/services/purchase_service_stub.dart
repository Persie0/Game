import 'package:flutter/foundation.dart';

import 'purchase_service_contract.dart';

PurchaseService createPurchaseService() => _StubPurchaseService();

class _StubPurchaseService implements PurchaseService {
  final ValueNotifier<bool> _pro = ValueNotifier(false);
  final ValueNotifier<String?> _error = ValueNotifier(null);

  @override
  ValueListenable<bool> get proEntitlement => _pro;

  @override
  ValueListenable<String?> get error => _error;

  @override
  bool get storeAvailable => false;

  @override
  List<StoreProduct> get products => const [];

  @override
  Future<void> initialize() async {}

  @override
  Future<bool> buyLifetime() async {
    _error.value = 'Purchases are available on Android, iOS and macOS.';
    return false;
  }

  @override
  Future<bool> restore() async {
    _error.value = 'Purchases are not available on this platform.';
    return false;
  }

  @override
  void dispose() {
    _pro.dispose();
    _error.dispose();
  }
}
