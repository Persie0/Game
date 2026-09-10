import 'package:flutter/widgets.dart';

import 'app_controller.dart';
import 'ui/app.dart';

export 'ui/app.dart' show MuseumHeistApp;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final controller = await AppController.create();
  runApp(MuseumHeistApp(controller: controller));
}
