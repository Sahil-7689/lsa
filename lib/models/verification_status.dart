/// Possible lifecycle statuses of the LSA Onboarding Gate.
enum VerificationStatus {
  idle,
  processing,
  quarantined,
  success;

  /// Human-readable display label matching HPF specification.
  String get displayLabel {
    switch (this) {
      case VerificationStatus.idle:
        return 'Idle';
      case VerificationStatus.processing:
        return 'Processing';
      case VerificationStatus.quarantined:
        return 'Quarantined (Fail-Closed)';
      case VerificationStatus.success:
        return 'Success';
    }
  }
}
