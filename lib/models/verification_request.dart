/// Immutable request payload sent to `POST /v1/compliance/verify`.
class VerificationRequest {
  final String? predecessorId;
  final String lsaId;
  final String parentConsentCode;
  final String timestampUtc;

  const VerificationRequest({
    required this.predecessorId,
    required this.lsaId,
    required this.parentConsentCode,
    required this.timestampUtc,
  });

  /// Factory constructor generating the dynamic UTC timestamp automatically.
  factory VerificationRequest.create({
    required String? predecessorId,
    required String lsaId,
    required String parentConsentCode,
    DateTime? timestamp,
  }) {
    final DateTime time = (timestamp ?? DateTime.now()).toUtc();
    return VerificationRequest(
      predecessorId: predecessorId,
      lsaId: lsaId,
      parentConsentCode: parentConsentCode,
      timestampUtc: time.toIso8601String(),
    );
  }

  /// Converts request model to JSON map.
  Map<String, dynamic> toJson() {
    return {
      'predecessor_id': predecessorId,
      'lsa_id': lsaId,
      'parent_consent_code': parentConsentCode,
      'timestamp_utc': timestampUtc,
    };
  }

  /// Deserializes JSON map to VerificationRequest.
  factory VerificationRequest.fromJson(Map<String, dynamic> json) {
    return VerificationRequest(
      predecessorId: json['predecessor_id'] as String?,
      lsaId: (json['lsa_id'] as String?) ?? '',
      parentConsentCode: (json['parent_consent_code'] as String?) ?? '',
      timestampUtc: (json['timestamp_utc'] as String?) ?? '',
    );
  }

  @override
  String toString() =>
      'VerificationRequest(predecessorId: $predecessorId, lsaId: $lsaId, parentConsentCode: $parentConsentCode, timestampUtc: $timestampUtc)';
}
