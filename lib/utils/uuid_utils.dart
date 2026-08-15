import 'package:uuid/uuid.dart';

/// UUID utilities for generating unique trace identifiers (`x-trace-id`).
class UuidUtils {
  static const Uuid _uuid = Uuid();

  /// Generates a fresh RFC 4122 v4 UUID string for request tracing.
  static String generateTraceId() {
    return _uuid.v4();
  }
}
