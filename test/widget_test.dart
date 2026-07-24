import 'package:flutter_test/flutter_test.dart';
import 'package:internship_digitalheroes/main.dart';

void main() {
  testWidgets('LeadDesk app smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const LeadDeskApp());
    expect(find.text('LeadDesk'), findsOneWidget);
  });
}
