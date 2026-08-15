import '../exceptions/lineage_exception.dart';
import '../models/verification_request.dart';
import '../utils/hash_utils.dart';
import '../utils/uuid_utils.dart';

/// Metadata bundle containing cryptographic and tracing headers.
class SecurityMetadata {
  final String traceId;
  final String logicHash;

  const SecurityMetadata({
    required this.traceId,
    required this.logicHash,
  });
}

/// Security validation service enforcing lineage, format validation, and metadata generation.
class SecurityService {
  /// Validates request fields before any data movement or network request.
  /// Throws [LineageException] if predecessor_id is null or empty.
  /// Throws [ArgumentError] if other mandatory fields are missing.
  void validateLineageAndRequest(VerificationRequest request) {
    // 1. Mandatory Data Lineage Validation (Fail-Closed)
    final String? predecessor = request.predecessorId;
    if (predecessor == null || predecessor.trim().isEmpty) {
      throw const LineageException(
        'Missing mandatory Data Lineage identifier (predecessor_id). Fail-Closed Quarantine enforced.',
        field: 'predecessor_id',
      );
    }

    // 2. LSA ID Validation
    if (request.lsaId.trim().isEmpty) {
      throw ArgumentError.value(
        request.lsaId,
        'lsa_id',
        'LSA ID is required and cannot be empty.',
      );
    }

    // 3. Parent Consent Code Validation
    if (request.parentConsentCode.trim().isEmpty) {
      throw ArgumentError.value(
        request.parentConsentCode,
        'parent_consent_code',
        'Parent Consent Code is required and cannot be empty.',
      );
    }
  }

  /// Generates dynamic metadata required for compliant outbound requests.
  SecurityMetadata generateSecurityMetadata({String? customSeed}) {
    final String traceId = UuidUtils.generateTraceId();
    final String logicHash = HashUtils.generateLogicHash(customSeed: customSeed);
    return SecurityMetadata(
      traceId: traceId,
      logicHash: logicHash,
    );
  }
}
