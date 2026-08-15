import 'package:flutter/foundation.dart';
import '../exceptions/lineage_exception.dart';
import '../models/friction_event.dart';
import '../models/quarantined_record.dart';
import '../models/verification_request.dart';
import '../models/verification_response.dart';
import '../models/verification_status.dart';
import '../services/compliance_api.dart';
import '../services/friction_tracker.dart';
import '../services/quarantine_service.dart';
import '../services/security_service.dart';

/// Immutable state model for the LsaVerificationScreen.
class VerificationState {
  final String lsaId;
  final String parentConsentCode;
  final String? predecessorId;
  final VerificationStatus status;
  final String? statusMessage;
  final String? verificationId;
  final String? lastTraceId;
  final String? lastLogicHash;
  final bool isSubmissionLocked;
  final List<QuarantinedRecord> quarantinedRecords;
  final List<FrictionEvent> frictionEvents;

  const VerificationState({
    this.lsaId = 'LSA-7049',
    this.parentConsentCode = '',
    this.predecessorId = 'PRED-9982-XYZ',
    this.status = VerificationStatus.idle,
    this.statusMessage,
    this.verificationId,
    this.lastTraceId,
    this.lastLogicHash,
    this.isSubmissionLocked = false,
    this.quarantinedRecords = const [],
    this.frictionEvents = const [],
  });

  VerificationState copyWith({
    String? lsaId,
    String? parentConsentCode,
    String? predecessorId,
    bool clearPredecessorId = false,
    VerificationStatus? status,
    String? statusMessage,
    bool clearStatusMessage = false,
    String? verificationId,
    bool clearVerificationId = false,
    String? lastTraceId,
    String? lastLogicHash,
    bool? isSubmissionLocked,
    List<QuarantinedRecord>? quarantinedRecords,
    List<FrictionEvent>? frictionEvents,
  }) {
    return VerificationState(
      lsaId: lsaId ?? this.lsaId,
      parentConsentCode: parentConsentCode ?? this.parentConsentCode,
      predecessorId: clearPredecessorId ? null : (predecessorId ?? this.predecessorId),
      status: status ?? this.status,
      statusMessage: clearStatusMessage ? null : (statusMessage ?? this.statusMessage),
      verificationId: clearVerificationId ? null : (verificationId ?? this.verificationId),
      lastTraceId: lastTraceId ?? this.lastTraceId,
      lastLogicHash: lastLogicHash ?? this.lastLogicHash,
      isSubmissionLocked: isSubmissionLocked ?? this.isSubmissionLocked,
      quarantinedRecords: quarantinedRecords ?? this.quarantinedRecords,
      frictionEvents: frictionEvents ?? this.frictionEvents,
    );
  }
}

/// Controller coordinating UI interactions, validation, security pipeline,
/// fail-closed quarantine enforcement, and friction tracking.
class VerificationController extends ChangeNotifier {
  final ComplianceApi _complianceApi;
  final SecurityService _securityService;
  final QuarantineService _quarantineService;
  late final FrictionTracker _frictionTracker;

  VerificationState _state;

  VerificationController({
    ComplianceApi? complianceApi,
    SecurityService? securityService,
    QuarantineService? quarantineService,
    FrictionTracker? frictionTracker,
    VerificationState? initialState,
  })  : _complianceApi = complianceApi ?? ComplianceApi(),
        _securityService = securityService ?? SecurityService(),
        _quarantineService = quarantineService ?? QuarantineService(),
        _state = initialState ?? const VerificationState() {
    _frictionTracker = frictionTracker ??
        FrictionTracker(
          onFrictionEvent: _handleFrictionEvent,
        );
  }

  VerificationState get state => _state;

  ComplianceApi get complianceApi => _complianceApi;
  SecurityService get securityService => _securityService;
  QuarantineService get quarantineService => _quarantineService;
  FrictionTracker get frictionTracker => _frictionTracker;

  void _handleFrictionEvent(FrictionEvent event) {
    _state = _state.copyWith(
      frictionEvents: [..._state.frictionEvents, event],
    );
    notifyListeners();
  }

  /// Updates the LSA ID value.
  void updateLsaId(String value) {
    if (_state.isSubmissionLocked) return;
    _state = _state.copyWith(lsaId: value);
    notifyListeners();
  }

  /// Updates the Parent Consent Code value and notifies friction tracker.
  void updateParentConsentCode(String value) {
    if (_state.isSubmissionLocked) return;
    _frictionTracker.onUserInteraction('parent_consent_code');
    _state = _state.copyWith(parentConsentCode: value);
    notifyListeners();
  }

  /// System update for Predecessor ID.
  void updatePredecessorId(String? value) {
    if (value == null || value.isEmpty) {
      _state = _state.copyWith(clearPredecessorId: true);
    } else {
      _state = _state.copyWith(predecessorId: value);
    }
    notifyListeners();
  }

  /// Focus event handler for input fields.
  void onFieldFocused(String fieldName) {
    _frictionTracker.onFieldFocused(fieldName);
  }

  /// Blur event handler for input fields.
  void onFieldBlurred(String fieldName) {
    _frictionTracker.onFieldBlurred(fieldName);
  }

  /// Primary submission routine enforcing the Fail-Closed Security Pipeline.
  Future<void> submitVerification() async {
    // 0. Prevent submission if locked or already processing
    if (_state.isSubmissionLocked || _state.status == VerificationStatus.processing) {
      return;
    }

    _frictionTracker.onFormSubmitted();

    _state = _state.copyWith(
      status: VerificationStatus.processing,
      clearStatusMessage: true,
      clearVerificationId: true,
    );
    notifyListeners();

    final VerificationRequest request = VerificationRequest.create(
      predecessorId: _state.predecessorId,
      lsaId: _state.lsaId,
      parentConsentCode: _state.parentConsentCode,
    );

    // =========================================================================
    // STEP 1: VALIDATION & DATA LINEAGE GATE (Strict Fail-Closed)
    // =========================================================================
    try {
      _securityService.validateLineageAndRequest(request);
    } on LineageException catch (e) {
      _enforceQuarantine(
        reason: 'Lineage Exception: ${e.message}',
        failedField: e.field,
        rawPayload: request.toJson(),
        statusMessage: 'Data Quarantined – Compliance Failure: Missing Data Lineage (predecessor_id)',
      );
      return;
    } catch (e) {
      _enforceQuarantine(
        reason: 'Validation Error: $e',
        failedField: 'validation',
        rawPayload: request.toJson(),
        statusMessage: 'Data Quarantined – Compliance Failure: Required fields missing or invalid.',
      );
      return;
    }

    // =========================================================================
    // STEP 2: METADATA GENERATION
    // =========================================================================
    final SecurityMetadata metadata = _securityService.generateSecurityMetadata();
    _state = _state.copyWith(
      lastTraceId: metadata.traceId,
      lastLogicHash: metadata.logicHash,
    );

    // =========================================================================
    // STEP 3: OUTBOUND NETWORK REQUEST
    // =========================================================================
    final VerificationResponse response = await _complianceApi.verifyCompliance(
      request: request,
      traceId: metadata.traceId,
      logicHash: metadata.logicHash,
    );

    // =========================================================================
    // STEP 4: RESPONSE VALIDATION (Never fail open; null is treated as failure)
    // =========================================================================
    if (response.isSuccess) {
      _state = _state.copyWith(
        status: VerificationStatus.success,
        verificationId: response.verificationId,
        statusMessage: 'Verification Successful (ID: ${response.verificationId})',
      );
      notifyListeners();
    } else {
      // Compliance failure on HTTP 500, null status, or non-success code
      _enforceQuarantine(
        reason: 'Compliance Failure: Server returned status="${response.status}", HTTP=${response.statusCode}',
        failedField: 'api_response',
        traceId: metadata.traceId,
        rawPayload: request.toJson(),
        statusMessage: 'Data Quarantined – Compliance Failure',
      );
    }
  }

  /// Enforces Fail-Closed quarantine:
  /// 1. Records payload in QuarantineService
  /// 2. Clears volatile form data (parent_consent_code)
  /// 3. Locks further submissions
  /// 4. Updates status to Quarantined
  void _enforceQuarantine({
    required String reason,
    String? failedField,
    String? traceId,
    required Map<String, dynamic> rawPayload,
    required String statusMessage,
  }) {
    _quarantineService.quarantine(
      reason: reason,
      failedField: failedField,
      traceId: traceId,
      rawPayload: rawPayload,
    );

    _state = _state.copyWith(
      status: VerificationStatus.quarantined,
      statusMessage: statusMessage,
      parentConsentCode: '', // Clear/reset volatile form data
      isSubmissionLocked: true, // Lock submission
      quarantinedRecords: _quarantineService.quarantinedRecords,
    );
    notifyListeners();
  }

  /// Preset loader: Valid standard submission
  void loadPresetValid() {
    _state = _state.copyWith(
      lsaId: 'LSA-7049',
      parentConsentCode: 'PCC-2026-9901',
      predecessorId: 'PRED-9982-XYZ',
      status: VerificationStatus.idle,
      clearStatusMessage: true,
      clearVerificationId: true,
      isSubmissionLocked: false,
    );
    notifyListeners();
  }

  /// Preset loader: Missing predecessor ID (Simulates Lineage Failure)
  void loadPresetMissingPredecessor() {
    _state = _state.copyWith(
      lsaId: 'LSA-7049',
      parentConsentCode: 'PCC-2026-9901',
      clearPredecessorId: true,
      status: VerificationStatus.idle,
      clearStatusMessage: true,
      clearVerificationId: true,
      isSubmissionLocked: false,
    );
    notifyListeners();
  }

  /// Preset loader: Simulate HTTP 500 / Null status backend failure
  void loadPresetSimulate500() {
    _state = _state.copyWith(
      lsaId: 'LSA-7049',
      parentConsentCode: 'FAIL-500',
      predecessorId: 'PRED-9982-XYZ',
      status: VerificationStatus.idle,
      clearStatusMessage: true,
      clearVerificationId: true,
      isSubmissionLocked: false,
    );
    notifyListeners();
  }

  /// Unlocks form and resets to default state.
  void resetForm() {
    _state = const VerificationState(
      lsaId: 'LSA-7049',
      parentConsentCode: '',
      predecessorId: 'PRED-9982-XYZ',
      status: VerificationStatus.idle,
      isSubmissionLocked: false,
    );
    notifyListeners();
  }

  @override
  void dispose() {
    _frictionTracker.dispose();
    _complianceApi.dispose();
    super.dispose();
  }
}
