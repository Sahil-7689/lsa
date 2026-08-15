/// Represents the parsed response from the compliance verification API.
class VerificationResponse {
  final int statusCode;
  final String? status;
  final String? verificationId;
  final String? reason;
  final Map<String, dynamic>? rawData;

  const VerificationResponse({
    required this.statusCode,
    this.status,
    this.verificationId,
    this.reason,
    this.rawData,
  });

  /// Factory constructor to parse JSON response.
  factory VerificationResponse.fromJson(int statusCode, Map<String, dynamic>? json) {
    if (json == null) {
      return VerificationResponse(
        statusCode: statusCode,
        status: null,
        rawData: null,
      );
    }
    return VerificationResponse(
      statusCode: statusCode,
      status: json['status'] as String?,
      verificationId: json['verification_id'] as String?,
      reason: json['reason'] as String?,
      rawData: json,
    );
  }

  /// Evaluates whether the response meets strict compliance success criteria.
  /// Note: A null status is NEVER considered success (Fail-Closed).
  bool get isSuccess {
    return statusCode == 200 &&
        status != null &&
        status!.trim().toLowerCase() == 'success';
  }

  @override
  String toString() =>
      'VerificationResponse(statusCode: $statusCode, status: $status, verificationId: $verificationId, reason: $reason)';
}
