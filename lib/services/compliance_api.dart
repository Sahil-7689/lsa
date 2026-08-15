import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/verification_request.dart';
import '../models/verification_response.dart';

/// Service for executing outbound compliance verification REST API requests.
class ComplianceApi {
  /// Base API URL. Configurable for production, emulator, or local testing.
  final String baseUrl;
  final http.Client _client;

  /// Default production and local environment constants.
  static const String productionBaseUrl = 'https://api.habotconnect.com';
  static const String androidEmulatorBaseUrl = 'http://10.0.2.2:3000';
  static const String localHostBaseUrl = 'http://localhost:3000';

  /// Resolves the default base URL based on runtime platform.
  static String get defaultBaseUrl {
    if (kIsWeb) {
      return localHostBaseUrl;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return androidEmulatorBaseUrl;
      case TargetPlatform.iOS:
      case TargetPlatform.macOS:
      case TargetPlatform.windows:
      case TargetPlatform.linux:
      case TargetPlatform.fuchsia:
        return localHostBaseUrl;
    }
  }

  ComplianceApi({
    String? baseUrl,
    http.Client? client,
  })  : baseUrl = baseUrl ?? defaultBaseUrl,
        _client = client ?? http.Client();

  /// Submits the verification request with mandated compliance metadata headers.
  ///
  /// Required headers:
  /// - `Content-Type`: application/json
  /// - `x-trace-id`: dynamic UUID
  /// - `x-logic-hash`: dynamic SHA-256
  Future<VerificationResponse> verifyCompliance({
    required VerificationRequest request,
    required String traceId,
    required String logicHash,
  }) async {
    final Uri url = Uri.parse('$baseUrl/v1/compliance/verify');

    final Map<String, String> headers = {
      'Content-Type': 'application/json',
      'x-trace-id': traceId,
      'x-logic-hash': logicHash,
    };

    final String requestBody = jsonEncode(request.toJson());

    debugPrint('--> POST $url');
    debugPrint('    Headers: $headers');
    debugPrint('    Body: $requestBody');

    try {
      final http.Response response = await _client.post(
        url,
        headers: headers,
        body: requestBody,
      );

      debugPrint('<-- ${response.statusCode} $url');
      debugPrint('    Response Body: ${response.body}');

      Map<String, dynamic>? decoded;
      try {
        if (response.body.isNotEmpty) {
          final dynamic parsed = jsonDecode(response.body);
          if (parsed is Map<String, dynamic>) {
            decoded = parsed;
          }
        }
      } catch (e) {
        debugPrint('JSON Decode Error: $e');
        decoded = null;
      }

      return VerificationResponse.fromJson(response.statusCode, decoded);
    } catch (e) {
      debugPrint('Compliance API Network Error: $e');
      return VerificationResponse(
        statusCode: 500,
        status: null,
        reason: 'Network or server communication error: $e',
      );
    }
  }

  void dispose() {
    _client.close();
  }
}
