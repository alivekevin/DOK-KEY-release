import 'dart:convert';
import 'package:crypto/crypto.dart';
import '../models/vault_models.dart';

class PersonalCloudVaultService {
  /// Exports vault data to a standard JSON string
  static String exportVaultJson({
    required List<SourceNumberItem> sourceNumbers,
    required List<CombinedKeyItem> combinedKeys,
  }) {
    final backup = VaultBackupData(
      exportedAt: DateTime.now(),
      sourceNumbers: sourceNumbers,
      combinedKeys: combinedKeys,
    );
    return const JsonEncoder.withIndent('  ').convert(backup.toJson());
  }

  /// Imports and validates vault data from a JSON string
  static VaultBackupData importVaultJson(String jsonString) {
    try {
      final decoded = json.decode(jsonString);
      if (decoded is! Map<String, dynamic> || decoded['brand'] != 'DOK-KEY') {
        throw const FormatException('Invalid DOK-KEY vault backup format');
      }
      return VaultBackupData.fromJson(decoded);
    } catch (e) {
      throw FormatException('Failed to restore vault backup: $e');
    }
  }

  /// Calculates a SHA-256 fingerprint of the current vault for sync validation
  static String calculateChecksum(List<SourceNumberItem> sources, List<CombinedKeyItem> keys) {
    final raw = '${sources.length}:${keys.length}:${sources.map((s) => s.numberStr).join()}:${keys.map((k) => k.id).join()}';
    return sha256.convert(utf8.encode(raw)).toString();
  }
}