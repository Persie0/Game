import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

import 'purchase_service_contract.dart';

PurchaseService createPurchaseService() {
  if (Platform.isAndroid || Platform.isIOS || Platform.isMacOS) {
    return _StorePurchaseService();
  }
  return _UnsupportedPurchaseService();
}

class _UnsupportedPurchaseService implements PurchaseService {
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

class _StorePurchaseService implements PurchaseService {
  static const lifetimeProductId = 'museum_heist_pro_lifetime';

  final InAppPurchase _iap = InAppPurchase.instance;
  final ValueNotifier<bool> _pro = ValueNotifier(false);
  final ValueNotifier<String?> _error = ValueNotifier(null);
  final Map<String, ProductDetails> _details = {};
  StreamSubscription<List<PurchaseDetails>>? _subscription;
  bool _available = false;

  @override
  ValueListenable<bool> get proEntitlement => _pro;

  @override
  ValueListenable<String?> get error => _error;

  @override
  bool get storeAvailable => _available;

  @override
  List<StoreProduct> get products => [
        for (final product in _details.values)
          StoreProduct(
            id: product.id,
            title: product.title,
            description: product.description,
            price: product.price,
          ),
      ];

  @override
  Future<void> initialize() async {
    _subscription ??= _iap.purchaseStream.listen(
      _onPurchases,
      onError: (Object error) => _error.value = error.toString(),
    );
    try {
      _available = await _iap.isAvailable();
      if (!_available) {
        return;
      }
      final response = await _iap.queryProductDetails({lifetimeProductId});
      if (response.error != null) {
        _error.value = response.error!.message;
      }
      for (final detail in response.productDetails) {
        _details[detail.id] = detail;
      }
      if (!_details.containsKey(lifetimeProductId) && response.error == null) {
        _error.value = 'The lifetime product is not configured in this store.';
      }
    } catch (error) {
      _error.value = error.toString();
    }
  }

  @override
  Future<bool> buyLifetime() async {
    final product = _details[lifetimeProductId];
    if (!_available || product == null) {
      _error.value = 'The lifetime product is not configured in this store yet.';
      return false;
    }
    _error.value = null;
    try {
      return await _iap.buyNonConsumable(
        purchaseParam: PurchaseParam(productDetails: product),
      );
    } catch (error) {
      _error.value = error.toString();
      return false;
    }
  }

  @override
  Future<bool> restore() async {
    if (!_available) {
      _error.value = 'The store is currently unavailable.';
      return false;
    }
    _error.value = null;
    try {
      await _iap.restorePurchases();
      return true;
    } catch (error) {
      _error.value = error.toString();
      return false;
    }
  }

  Future<void> _onPurchases(List<PurchaseDetails> purchases) async {
    for (final purchase in purchases) {
      switch (purchase.status) {
        case PurchaseStatus.pending:
          break;
        case PurchaseStatus.error:
          _error.value = purchase.error?.message ?? 'Purchase failed.';
        case PurchaseStatus.canceled:
          _error.value = null;
        case PurchaseStatus.purchased:
        case PurchaseStatus.restored:
          if (purchase.productID == lifetimeProductId) {
            if (_hasReceiptEvidence(purchase)) {
              _pro.value = true;
              _error.value = null;
            } else {
              _error.value =
                  'The store returned a purchase without verifiable receipt data. Pro was not granted.';
            }
          }
      }

      if (purchase.pendingCompletePurchase) {
        try {
          await _iap.completePurchase(purchase);
        } catch (error) {
          _error.value = 'Could not finalize the store transaction: $error';
        }
      }
    }
  }

  bool _hasReceiptEvidence(PurchaseDetails purchase) {
    final verification = purchase.verificationData;
    return purchase.productID == lifetimeProductId &&
        verification.source.trim().isNotEmpty &&
        verification.serverVerificationData.trim().isNotEmpty;
  }

  @override
  void dispose() {
    unawaited(_subscription?.cancel());
    _pro.dispose();
    _error.dispose();
  }
}
