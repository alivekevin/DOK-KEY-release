/// Vault & Key Combiner Data Models for DOK-KEY

class SourceNumberItem {
  final String numberStr; // "01" ~ "99" (2자리 고정)
  int count; // 획득 횟수 (1, 2, 3...)
  DateTime lastAcquiredAt; // 최근 획득 시점
  String lastCardId; // 최근 연동된 카드 ID
  String lastCardName; // 최근 연동된 카드 이름
  String lastTimeslotId; // 최근 연동된 방향 ID
  String lastToneName; // 최근 연동된 톤 이름
  String lastToneColor; // 최근 연동된 톤 컬러 Hex
  String lastHeadline; // 최근 운세 헤드라인 요약
  bool isPinned; // 유저 고정 여부

  SourceNumberItem({
    required this.numberStr,
    this.count = 1,
    required this.lastAcquiredAt,
    this.lastCardId = '',
    this.lastCardName = '',
    this.lastTimeslotId = '',
    this.lastToneName = '',
    this.lastToneColor = '#F0A500',
    this.lastHeadline = '',
    this.isPinned = false,
  });

  Map<String, dynamic> toJson() => {
    'numberStr': numberStr,
    'count': count,
    'lastAcquiredAt': lastAcquiredAt.toIso8601String(),
    'lastCardId': lastCardId,
    'lastCardName': lastCardName,
    'lastTimeslotId': lastTimeslotId,
    'lastToneName': lastToneName,
    'lastToneColor': lastToneColor,
    'lastHeadline': lastHeadline,
    'isPinned': isPinned,
  };

  factory SourceNumberItem.fromJson(Map<String, dynamic> json) => SourceNumberItem(
    numberStr: json['numberStr'] ?? '01',
    count: json['count'] ?? 1,
    lastAcquiredAt: DateTime.tryParse(json['lastAcquiredAt'] ?? '') ?? DateTime.now(),
    lastCardId: json['lastCardId'] ?? '',
    lastCardName: json['lastCardName'] ?? '',
    lastTimeslotId: json['lastTimeslotId'] ?? '',
    lastToneName: json['lastToneName'] ?? '',
    lastToneColor: json['lastToneColor'] ?? '#F0A500',
    lastHeadline: json['lastHeadline'] ?? '',
    isPinned: json['isPinned'] ?? false,
  );
}

class CombinedKeyItem {
  final String id; // UUID
  final DateTime createdAt;
  DateTime? expiresAt; // 기본: createdAt + 7일, PRO 장기 보관 시 null
  final int targetCount; // N자리 (2 <= N <= Max)
  final List<String> numbers; // ["07", "14", "28", "42"]
  String? userTag; // 유저 메모
  bool isCloudSynced; // 개인 클라우드 백업 여부

  CombinedKeyItem({
    required this.id,
    required this.createdAt,
    this.expiresAt,
    required this.targetCount,
    required this.numbers,
    this.userTag,
    this.isCloudSynced = false,
  });

  bool get isPermanent => expiresAt == null;
  bool get isTenYearLocked => isPermanent;
  bool get isExpired => expiresAt != null && DateTime.now().isAfter(expiresAt!);

  String get dDayString {
    if (isPermanent) return '10-YEAR';
    final diff = expiresAt!.difference(DateTime.now());
    if (diff.isNegative) return 'EXPIRED';
    final days = diff.inDays;
    if (days == 0) {
      final hours = diff.inHours;
      return hours > 0 ? '${hours}h left' : 'D-0';
    }
    return 'D-$days';
  }

  String get formattedNumbers => numbers.join(' · ');

  Map<String, dynamic> toJson() => {
    'id': id,
    'createdAt': createdAt.toIso8601String(),
    'expiresAt': expiresAt?.toIso8601String(),
    'targetCount': targetCount,
    'numbers': numbers,
    'userTag': userTag,
    'isCloudSynced': isCloudSynced,
  };

  factory CombinedKeyItem.fromJson(Map<String, dynamic> json) => CombinedKeyItem(
    id: json['id'] ?? '',
    createdAt: DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
    expiresAt: json['expiresAt'] != null ? DateTime.tryParse(json['expiresAt']) : null,
    targetCount: json['targetCount'] ?? (json['numbers'] as List? ?? []).length,
    numbers: List<String>.from(json['numbers'] ?? []),
    userTag: json['userTag'],
    isCloudSynced: json['isCloudSynced'] ?? false,
  );
}

class VaultBackupData {
  final String version;
  final DateTime exportedAt;
  final List<SourceNumberItem> sourceNumbers;
  final List<CombinedKeyItem> combinedKeys;

  VaultBackupData({
    this.version = '1.0.0',
    required this.exportedAt,
    required this.sourceNumbers,
    required this.combinedKeys,
  });

  Map<String, dynamic> toJson() => {
    'brand': 'DOK-KEY',
    'version': version,
    'exportedAt': exportedAt.toIso8601String(),
    'sourceNumbers': sourceNumbers.map((s) => s.toJson()).toList(),
    'combinedKeys': combinedKeys.map((k) => k.toJson()).toList(),
  };

  factory VaultBackupData.fromJson(Map<String, dynamic> json) => VaultBackupData(
    version: json['version'] ?? '1.0.0',
    exportedAt: DateTime.tryParse(json['exportedAt'] ?? '') ?? DateTime.now(),
    sourceNumbers: (json['sourceNumbers'] as List? ?? [])
        .map((s) => SourceNumberItem.fromJson(s))
        .toList(),
    combinedKeys: (json['combinedKeys'] as List? ?? [])
        .map((k) => CombinedKeyItem.fromJson(k))
        .toList(),
  );
}