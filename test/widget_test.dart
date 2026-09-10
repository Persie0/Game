import 'package:flutter_test/flutter_test.dart';
import 'package:museum_heist/app_controller.dart';
import 'package:museum_heist/game/progress.dart';
import 'package:museum_heist/main.dart';

void main() {
  testWidgets('home renders production navigation and daily heist', (tester) async {
    final controller = await AppController.memory(
      PersistentState(onboardingDone: true),
    );
    addTearDown(controller.dispose);

    await tester.pumpWidget(MuseumHeistApp(controller: controller));
    await tester.pumpAndSettle();

    expect(find.text('Museum Heist'), findsOneWidget);
    expect(find.text("Today's Gallery"), findsOneWidget);
    expect(find.text('Heists'), findsOneWidget);
    expect(find.text('Stats'), findsOneWidget);
    expect(find.text('Settings'), findsOneWidget);

    await tester.tap(find.text('Stats'));
    await tester.pumpAndSettle();
    expect(find.text('Career'), findsOneWidget);

    await tester.tap(find.text('Settings'));
    await tester.pumpAndSettle();
    expect(find.text('Gameplay'), findsOneWidget);
    expect(find.text('Auto-mark impossible rooms'), findsOneWidget);
  });
}
