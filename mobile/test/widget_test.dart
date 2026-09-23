import 'package:flutter_test/flutter_test.dart';
import 'package:gusto_pos_mobile/main.dart';

void main() {
  testWidgets('GustoPOS app smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const GustoPosApp());
    expect(find.text('GUSTO POS'), findsOneWidget);
  });
}
