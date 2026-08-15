/// Represents a record that failed compliance/lineage validation and was quarantined.
class QuarantinedRecord {
  final String id;
  final DateTime quarantinedAt;
  final String reason;
  final String? failedField;
  final String? traceId;
  final Map<String, dynamic> rawPayload;

  const QuarantinedRecord({
    required this.id,
    required this.quarantinedAt,
    required this.reason,
    this.failedField,
    this.traceId,
    required this.rawPayload,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'quarantined_at': quarantinedAt.toUtc().toIso8601String(),
        'reason': reason,
        'failed_field': failedField,
        'trace_id': traceId,
        'raw_payload': rawPayload,
      };

  @override
  String toString() =>
      'QuarantinedRecord(id: $id, reason: $reason, failedField: $failedField)';
}
