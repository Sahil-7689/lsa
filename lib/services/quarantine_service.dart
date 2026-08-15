import 'package:flutter/foundation.dart';
import '../models/quarantined_record.dart';
import '../utils/uuid_utils.dart';

/// Service managing quarantined payloads under the Fail-Closed architecture.
class QuarantineService {
  final List<QuarantinedRecord> _quarantinedRecords = [];

  List<QuarantinedRecord> get quarantinedRecords =>
      List.unmodifiable(_quarantinedRecords);

  /// Quarantines a payload, logs the isolation, and persists the record.
  QuarantinedRecord quarantine({
    required String reason,
    String? failedField,
    String? traceId,
    required Map<String, dynamic> rawPayload,
  }) {
    final QuarantinedRecord record = QuarantinedRecord(
      id: 'QUAR-${UuidUtils.generateTraceId().substring(0, 8).toUpperCase()}',
      quarantinedAt: DateTime.now(),
      reason: reason,
      failedField: failedField,
      traceId: traceId,
      rawPayload: rawPayload,
    );

    _quarantinedRecords.add(record);

    debugPrint('================ [FAIL-CLOSED QUARANTINE] ================');
    debugPrint('Quarantine ID : ${record.id}');
    debugPrint('Timestamp     : ${record.quarantinedAt.toUtc().toIso8601String()}');
    debugPrint('Reason        : ${record.reason}');
    debugPrint('Failed Field  : ${record.failedField ?? 'N/A'}');
    debugPrint('Trace ID      : ${record.traceId ?? 'N/A'}');
    debugPrint('Payload       : ${record.rawPayload}');
    debugPrint('==========================================================');

    return record;
  }

  /// Clears the recorded quarantine logs.
  void clear() {
    _quarantinedRecords.clear();
  }
}
