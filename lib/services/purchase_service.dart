import 'purchase_service_contract.dart';
import 'purchase_service_stub.dart'
    if (dart.library.io) 'purchase_service_io.dart' as platform;

export 'purchase_service_contract.dart';

PurchaseService createPurchaseService() => platform.createPurchaseService();
