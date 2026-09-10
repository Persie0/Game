import 'package:flutter_test/flutter_test.dart';
import 'package:museum_heist/main.dart';

void main() {
  testWidgets('Museum Heist renders the daily puzzle shell', (tester) async {
    await tester.pumpWidget(const MuseumHeistApp());
    await tester.pumpAndSettle();

    expect(find.text('Museum Heist'), findsOneWidget);
    expect(find.text('Daily Heist'), findsOneWidget);
    expect(find.text('Free Play'), findsOneWidget);
  });
}
