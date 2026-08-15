import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:habot_connect_lsa/controllers/verification_controller.dart';
import 'package:habot_connect_lsa/exceptions/lineage_exception.dart';
import 'package:habot_connect_lsa/models/verification_request.dart';
import 'package:habot_connect_lsa/models/verification_status.dart';
import 'package:habot_connect_lsa/services/compliance_api.dart';
import 'package:habot_connect_lsa/services/security_service.dart';
import 'package:habot_connect_lsa/utils/hash_utils.dart';
import 'package:habot_connect_lsa/utils/uuid_utils.dart';

void main() {
  group('HabotConnect HPF — Security Pipeline & Lineage Tests', () {
    late SecurityService securityService;

    setUp(() {
      securityService = SecurityService();
    });

    test('Cryptographic Utilities: SHA-256 Hash & UUID generation', () {
      final String hash = HashUtils.generateLogicHash();
      expect(hash, isNotEmpty);
      expect(hash.length, equals(64)); // SHA-256 hex string is 64 characters

      // Deterministic validation
      final String hash2 = HashUtils.generateLogicHash();
      expect(hash, equals(hash2));

      final String traceId1 = UuidUtils.generateTraceId();
      final String traceId2 = UuidUtils.generateTraceId();
      expect(traceId1, isNotEmpty);
      expect(traceId1, isNot(equals(traceId2))); // Fresh dynamic UUID
    });

    // =========================================================================
    // TEST 1 — Valid submission
    // =========================================================================
    test('Test 1 — Valid submission: API called with trace-id & logic-hash -> Success', () async {
      String? capturedTraceId;
      String? capturedLogicHash;
      Map<String, dynamic>? capturedBody;
      bool apiCalled = false;

      final mockClient = MockClient((http.Request request) async {
        apiCalled = true;
        capturedTraceId = request.headers['x-trace-id'];
        capturedLogicHash = request.headers['x-logic-hash'];
        capturedBody = jsonDecode(request.body) as Map<String, dynamic>;

        return http.Response(
          jsonEncode({
            'status': 'success',
            'verification_id': 'VER-12345',
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
        initialState: const VerificationState(
          lsaId: 'LSA-7049',
          parentConsentCode: 'PCC-2026-9901',
          predecessorId: 'PRED-9982-XYZ',
        ),
      );

      await controller.submitVerification();

      expect(apiCalled, isTrue, reason: 'API must be called for valid input');
      expect(capturedTraceId, isNotNull);
      expect(capturedTraceId, isNotEmpty);
      expect(capturedLogicHash, isNotNull);
      expect(capturedLogicHash!.length, equals(64));
      expect(capturedBody?['lsa_id'], equals('LSA-7049'));
      expect(capturedBody?['parent_consent_code'], equals('PCC-2026-9901'));
      expect(capturedBody?['predecessor_id'], equals('PRED-9982-XYZ'));
      expect(capturedBody?['timestamp_utc'], isNotNull);

      expect(controller.state.status, equals(VerificationStatus.success));
      expect(controller.state.verificationId, equals('VER-12345'));
    });

    // =========================================================================
    // TEST 2 — Missing predecessor
    // =========================================================================
    test('Test 2 — Missing predecessor: LineageException thrown, API NOT called, Quarantined', () async {
      bool apiCalled = false;

      final mockClient = MockClient((http.Request request) async {
        apiCalled = true;
        return http.Response('{"status":"success"}', 200);
      });

      // Directly verify LineageException is thrown by security service
      expect(
        () => securityService.validateLineageAndRequest(
          VerificationRequest.create(
            predecessorId: null,
            lsaId: 'LSA-7049',
            parentConsentCode: 'PCC-2026-9901',
          ),
        ),
        throwsA(isA<LineageException>()),
      );

      // Verify controller handles LineageException with fail-closed quarantine
      final controller = VerificationController(
        complianceApi: ComplianceApi(
          baseUrl: 'http://localhost:3000',
          client: mockClient,
        ),
        initialState: const VerificationState(
          lsaId: 'LSA-7049',
          parentConsentCode: 'PCC-2026-9901',
          predecessorId: null, // Missing predecessor
        ),
      );

      await controller.submitVerification();

      expect(apiCalled, isFalse, reason: 'API must NOT be called when predecessor is missing');
      expect(controller.state.status, equals(VerificationStatus.quarantined));
      expect(controller.state.isSubmissionLocked, isTrue);
      expect(controller.state.parentConsentCode, isEmpty, reason: 'Volatile data must be cleared');
      expect(controller.state.quarantinedRecords.length, equals(1));
    });

    // =========================================================================
    // TEST 3 — Empty predecessor
    // =========================================================================
    test('Test 3 — Empty predecessor: API NOT called, Quarantined', () async {
      bool apiCalled = false;

      final mockClient = MockClient((http.Request request) async {
        apiCalled = true;
        return http.Response('{"status":"success"}', 200);
      });

      // Directly verify LineageException on empty/whitespace string
      expect(
        () => securityService.validateLineageAndRequest(
          VerificationRequest.create(
            predecessorId: '   ',
            lsaId: 'LSA-7049',
            parentConsentCode: 'PCC-2026-9901',
          ),
        ),
        throwsA(isA<LineageException>()),
      );

      final controller = VerificationController(
        complianceApi: ComplianceApi(
          baseUrl: 'http://localhost:3000',
          client: mockClient,
        ),
        initialState: const VerificationState(
          lsaId: 'LSA-7049',
          parentConsentCode: 'PCC-2026-9901',
          predecessorId: '', // Empty predecessor
        ),
      );

      await controller.submitVerification();

      expect(apiCalled, isFalse, reason: 'API must NOT be called when predecessor is empty');
      expect(controller.state.status, equals(VerificationStatus.quarantined));
      expect(controller.state.isSubmissionLocked, isTrue);
      expect(controller.state.parentConsentCode, isEmpty);
    });

    // =========================================================================
    // TEST 4 — HTTP 500 Response
    // =========================================================================
    test('Test 4 — HTTP 500: Quarantined, form reset, submission locked', () async {
      final mockClient = MockClient((http.Request request) async {
        return http.Response(
          jsonEncode({
            'error': 'Internal Server Error',
            'status': null,
          }),
          500,
          headers: {'content-type': 'application/json'},
        );
      });

      final controller = VerificationController(
        complianceApi: ComplianceApi(
          baseUrl: 'http://localhost:3000',
          client: mockClient,
        ),
        initialState: const VerificationState(
          lsaId: 'LSA-7049',
          parentConsentCode: 'FAIL-500',
          predecessorId: 'PRED-9982-XYZ',
        ),
      );

      await controller.submitVerification();

      expect(controller.state.status, equals(VerificationStatus.quarantined));
      expect(controller.state.parentConsentCode, isEmpty, reason: 'Volatile data must be cleared on compliance failure');
      expect(controller.state.isSubmissionLocked, isTrue, reason: 'Submission must be locked');
      expect(controller.state.statusMessage, contains('Compliance Failure'));
    });

    // =========================================================================
    // TEST 5 — Null status in response
    // =========================================================================
    test('Test 5 — Null status response: Fail-Closed Quarantined (Do not interpret null as success)', () async {
      final mockClient = MockClient((http.Request request) async {
        return http.Response(
          jsonEncode({
            'status': null,
            'verification_id': 'VER-99999',
          }),
          200, // Even with HTTP 200, a null status must fail-closed
          headers: {'content-type': 'application/json'},
        );
      });

      final controller = VerificationController(
        complianceApi: ComplianceApi(
          baseUrl: 'http://localhost:3000',
          client: mockClient,
        ),
        initialState: const VerificationState(
          lsaId: 'LSA-7049',
          parentConsentCode: 'PCC-2026-9901',
          predecessorId: 'PRED-9982-XYZ',
        ),
      );

      await controller.submitVerification();

      expect(controller.state.status, equals(VerificationStatus.quarantined));
      expect(controller.state.isSubmissionLocked, isTrue);
      expect(controller.state.parentConsentCode, isEmpty);
      expect(controller.state.verificationId, isNull);
    });
  });
}
