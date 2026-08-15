import 'dart:convert';
import 'package:crypto/crypto.dart';

/// Cryptographic hash utilities for generating deterministic logic hashes.
class HashUtils {
  /// Logic version token representing business logic version.
  static const String logicVersion = 'habotconnect_lsa_logic_v1.0';

  /// Schema version token representing payload schema version.
  static const String schemaVersion = 'schema_v1.0_2026';

  /// Deterministically computes the SHA-256 logic hash required by `x-logic-hash`.
  ///
  /// Hashed input:
  /// "$logicVersion:$schemaVersion" (or with optional custom seed)
  ///
  /// Produces a 64-character hexadecimal SHA-256 string.
  static String generateLogicHash({String? customSeed}) {
    final String input = customSeed ?? '$logicVersion:$schemaVersion';
    final List<int> bytes = utf8.encode(input);
    final Digest digest = sha256.convert(bytes);
    return digest.toString();
  }

  /// Hashes any arbitrary string using SHA-256.
  static String sha256Hash(String input) {
    final List<int> bytes = utf8.encode(input);
    return sha256.convert(bytes).toString();
  }
}
