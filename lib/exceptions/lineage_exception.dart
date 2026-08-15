/// Thrown when data lineage validation fails (e.g. predecessor_id is null or empty).
/// Triggers immediate Fail-Closed Quarantine without any outbound network request.
class LineageException implements Exception {
  final String message;
  final String? field;

  const LineageException(
    this.message, {
    this.field = 'predecessor_id',
  });

  @override
  String toString() => 'LineageException: $message (Field: $field)';
}
