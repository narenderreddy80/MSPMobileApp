import 'package:flutter_test/flutter_test.dart';
import 'package:msp_mobile_app/main.dart';

void main() {
  testWidgets('App shows login screen when not logged in', (WidgetTester tester) async {
    await tester.pumpWidget(const MSPFarmersApp(isLoggedIn: false));
    await tester.pumpAndSettle();
    expect(find.text('MSP Farmers'), findsOneWidget);
  });
}
