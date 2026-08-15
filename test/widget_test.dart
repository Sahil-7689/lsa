import 'package:flutter_test/flutter_test.dart';
import 'package:habot_connect_lsa/main.dart';
import 'package:habot_connect_lsa/screen/lsa_verification_screen.dart';

void main() {
  testWidgets('HabotConnectApp launches and displays LsaVerificationScreen', (WidgetTester tester) async {
    await tester.pumpWidget(const HabotConnectApp());
    expect(find.byType(LsaVerificationScreen), findsOneWidget);
    expect(find.text('LSA Onboarding Gate'), findsOneWidget);
  });
}
