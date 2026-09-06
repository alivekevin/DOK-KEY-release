import '../models/vault_models.dart';

class TTLManager {
  /// Filters out all expired keys (expiresAt != null and now > expiresAt)
  /// Retains permanent keys (expiresAt == null) and valid non-expired keys
  static List<CombinedKeyItem> purgeExpiredKeys(List<CombinedKeyItem> keys) {
    final now = DateTime.now();
    return keys.where((k) {
      if (k.expiresAt == null) return true; // Permanent key
      return now.isBefore(k.expiresAt!); // Still valid
    }).toList();
  }

  /// Sets a combined key to Permanent (clears expiresAt)
  static CombinedKeyItem unlockPermanent(CombinedKeyItem key) {
    key.expiresAt = null;
    key.isCloudSynced = true; // Auto sync to private cloud
    return key;
  }
}