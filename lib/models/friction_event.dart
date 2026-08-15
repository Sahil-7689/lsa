/// Represents an isolated UI friction tracking event.
class FrictionEvent {
  final DateTime timestamp;
  final String fieldName;
  final double hesitationDurationSeconds;

  const FrictionEvent({
    required this.timestamp,
    required this.fieldName,
    required this.hesitationDurationSeconds,
  });

  /// Formatted console output per HPF specification:
  /// [UI_FRICTION_LOG]
  /// Timestamp: 2026-08-07T11:31:05Z
  /// Field: parent_consent_code
  /// Hesitation Duration: 5.2s
  String toLogString() {
    return '[UI_FRICTION_LOG]\n'
        'Timestamp: ${timestamp.toUtc().toIso8601String()}\n'
        'Field: $fieldName\n'
        'Hesitation Duration: ${hesitationDurationSeconds.toStringAsFixed(1)}s';
  }

  @override
  String toString() => toLogString();
}
