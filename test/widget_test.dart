import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:museum_heist/app_controller.dart';
import 'package:museum_heist/game/progress.dart';
import 'package:museum_heist/main.dart';

void main() {
  testWidgets('Art Deco HQ renders mission navigation and daily heist', (
    tester,
  ) async {
    final controller = await AppController.memory(
      PersistentState(onboardingDone: true),
    );
    addTearDown(controller.dispose);

    await tester.pumpWidget(MuseumHeistApp(controller: controller));
    await tester.pumpAndSettle();

    expect(find.text('Heist HQ'), findsOneWidget);
    expect(find.text("Today's Gallery"), findsOneWidget);
    expect(find.text('HEISTS'), findsOneWidget);
    expect(find.text('DOSSIER'), findsOneWidget);
    expect(find.text('GEAR'), findsOneWidget);

    await tester.tap(find.text('DOSSIER'));
    await tester.pumpAndSettle();
    expect(find.text('Career record'), findsOneWidget);
    expect(find.text('FIELD METRICS'), findsOneWidget);

    await tester.tap(find.text('GEAR'));
    await tester.pumpAndSettle();
    expect(find.text('Gear & preferences'), findsOneWidget);
    expect(find.text('FIELD ASSISTS'), findsOneWidget);
    expect(find.text('Auto-mark impossible rooms'), findsOneWidget);
  });

  testWidgets('tutorial teaches by interacting with target rooms', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(412, 915);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final controller = await AppController.memory(PersistentState());
    addTearDown(controller.dispose);

    await tester.pumpWidget(MuseumHeistApp(controller: controller));
    await tester.pumpAndSettle();

    expect(find.text('WELCOME TO THE CREW'), findsOneWidget);
    expect(find.text('BEGIN TRAINING'), findsOneWidget);

    await tester.ensureVisible(find.text('BEGIN TRAINING'));
    await tester.tap(find.text('BEGIN TRAINING'));
    await tester.pumpAndSettle();
    expect(find.text('STEP 1 · INFILTRATE'), findsOneWidget);

    final firstTarget = find.bySemanticsLabel('Training room 2, target room');
    await tester.ensureVisible(firstTarget);
    await tester.tap(firstTarget);
    await tester.pumpAndSettle();
    expect(find.text('STEP 2 · SPREAD OUT'), findsOneWidget);

    final secondTarget = find.bySemanticsLabel('Training room 12, target room');
    await tester.ensureVisible(secondTarget);
    await tester.tap(secondTarget);
    await tester.pumpAndSettle();
    expect(find.text('STEP 3 · WATCH THE LASERS'), findsOneWidget);
    expect(find.text('RULES LOCKED IN'), findsOneWidget);

    await tester.ensureVisible(find.text('RULES LOCKED IN'));
    await tester.tap(find.text('RULES LOCKED IN'));
    await tester.pumpAndSettle();
    expect(find.text('TRAINING COMPLETE'), findsOneWidget);

    await tester.ensureVisible(find.text('ENTER HEIST HQ'));
    await tester.tap(find.text('ENTER HEIST HQ'));
    await tester.pumpAndSettle();
    expect(find.text('Heist HQ'), findsOneWidget);
  });
}
