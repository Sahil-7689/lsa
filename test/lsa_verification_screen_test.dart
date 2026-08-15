import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:habot_connect_lsa/byts/lsa_id_field_byt.dart';
import 'package:habot_connect_lsa/byts/parent_consent_field_byt.dart';
import 'package:habot_connect_lsa/byts/predecessor_field_byt.dart';
import 'package:habot_connect_lsa/byts/status_banner_byt.dart';
import 'package:habot_connect_lsa/byts/verification_button_byt.dart';
import 'package:habot_connect_lsa/byts/verification_header_byt.dart';
import 'package:habot_connect_lsa/controllers/verification_controller.dart';
import 'package:habot_connect_lsa/models/verification_status.dart';
import 'package:habot_connect_lsa/screen/lsa_verification_screen.dart';
import 'package:habot_connect_lsa/services/compliance_api.dart';

void main() {
  group('LsaVerificationScreen Widget & Byt Integration Tests', () {
    test('Verify LsaVerificationScreen is strictly a StatelessWidget', () {
      final controller = VerificationController();
      final screen = LsaVerificationScreen(controller: controller);
      expect(screen, isA<StatelessWidget>());
    });

    testWidgets('Renders all required Byts and UI elements', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final controller = VerificationController();

      await tester.pumpWidget(
        MaterialApp(
          home: LsaVerificationScreen(controller: controller),
        ),
      );

      // Header verification
      expect(find.byType(VerificationHeaderByt), findsOneWidget);
      expect(find.text('LSA Onboarding Gate'), findsOneWidget);
      expect(find.text('HabotConnect Data Compliance'), findsOneWidget);

      // Status Banner
      expect(find.byType(StatusBannerByt), findsOneWidget);
      expect(find.text('Idle'), findsOneWidget);

      // Form Byts
      expect(find.byType(LsaIdFieldByt), findsOneWidget);
      expect(find.text('LSA ID'), findsOneWidget);
      expect(find.text('LSA-7049'), findsOneWidget);

      expect(find.byType(ParentConsentFieldByt), findsOneWidget);
      expect(find.text('Parent Consent Code'), findsOneWidget);

      expect(find.byType(PredecessorFieldByt), findsOneWidget);
      expect(find.text('Predecessor ID'), findsOneWidget);
      expect(find.text('PRED-9982-XYZ'), findsOneWidget);

      // Button
      expect(find.byType(VerificationButtonByt), findsOneWidget);
      expect(find.text('Verify & Submit'), findsOneWidget);
    });

    testWidgets('Full successful submission UI flow', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final mockClient = MockClient((http.Request request) async {
        return http.Response(
          jsonEncode({
            'status': 'success',
            'verification_id': 'VER-55443',
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      final controller = VerificationController(
        complianceApi: ComplianceApi(
          baseUrl: 'http://localhost:3000',
          client: mockClient,
        ),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: LsaVerificationScreen(controller: controller),
        ),
      );

      // Enter Parent Consent Code
      final consentField = find.byKey(const Key('parent_consent_field'));
      expect(consentField, findsOneWidget);
      await tester.enterText(consentField, 'PCC-2026-9901');
      await tester.pump();

      // Tap "Verify & Submit"
      final submitButton = find.byKey(const Key('verify_submit_button'));
      await tester.ensureVisible(submitButton);
      await tester.tap(submitButton);
      await tester.pumpAndSettle();

      // Verify Success State
      expect(find.text('Success'), findsOneWidget);
      expect(find.text('Verification ID: VER-55443'), findsOneWidget);
      expect(controller.state.status, equals(VerificationStatus.success));
    });

    testWidgets('Full HTTP 500 error quarantine UI flow', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final mockClient = MockClient((http.Request request) async {
        return http.Response(
          jsonEncode({'status': null}),
          500,
          headers: {'content-type': 'application/json'},
        );
      });

      final controller = VerificationController(
        complianceApi: ComplianceApi(
          baseUrl: 'http://localhost:3000',
          client: mockClient,
        ),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: LsaVerificationScreen(controller: controller),
        ),
      );

      // Enter Parent Consent Code
      final consentField = find.byKey(const Key('parent_consent_field'));
      await tester.enterText(consentField, 'FAIL-500');
      await tester.pump();

      // Tap "Verify & Submit"
      final submitButton = find.byKey(const Key('verify_submit_button'));
      await tester.ensureVisible(submitButton);
      await tester.tap(submitButton);
      await tester.pumpAndSettle();

      // Verify Quarantined State
      expect(find.text('Quarantined (Fail-Closed)'), findsOneWidget);
      expect(find.text('Data Quarantined – Compliance Failure'), findsOneWidget);
      expect(find.text('Submission Locked'), findsOneWidget);
    });
  });
}
