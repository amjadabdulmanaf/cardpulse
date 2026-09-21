import 'package:flutter_test/flutter_test.dart';
import 'package:cardpulse/main.dart';
import 'package:cardpulse/services/storage_service.dart';

void main() {
  testWidgets('App load test', (WidgetTester tester) async {
    final storage = StorageService();
    await tester.pumpWidget(CardPulseApp(storageService: storage));
    await tester.pumpAndSettle();

    expect(find.text('CardPulse'), findsOneWidget);
  });
}
