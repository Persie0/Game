import 'ad_service_contract.dart';
import 'ad_service_stub.dart' if (dart.library.io) 'ad_service_io.dart' as platform;

export 'ad_service_contract.dart';

AdService createAdService() => platform.createAdService();
