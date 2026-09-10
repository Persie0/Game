import 'package:flutter/foundation.dart';

class StoreProduct {
  const StoreProduct({
    required this.id,
    required this.title,
    required this.description,
    required this.price,
  });

  final String id;
  final String title;
  final String description;
  final String price;
}

abstract interface class PurchaseService {
  ValueListenable<bool> get proEntitlement;
  ValueListenable<String?> get error;
  List<StoreProduct> get products;
  bool get storeAvailable;

  Future<void> initialize();
  Future<bool> buyLifetime();
  Future<bool> restore();
  void dispose();
}
