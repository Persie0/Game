import 'package:flutter/widgets.dart';

import 'app_controller.dart';
import 'ui/app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final controller = await AppController.create();
  runApp(MuseumHeistApp(controller: controller));
}

export 'ui/app.dart' show MuseumHeistApp;
