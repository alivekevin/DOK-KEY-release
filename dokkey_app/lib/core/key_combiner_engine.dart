import 'dart:math';
import 'package:uuid/uuid.dart';
import '../models/vault_models.dart';

/// 🔮 마법 열쇠 조합 연성 엔진 (v4.1.0 Commercial)
///
/// - 유니크 모드 (allowDuplicates = false): 고유 번호 비복원 추출
/// - 중첩 모드 (allowDuplicates = true): 복원 추출 + 획득 빈도 가중치 반영
/// - 하이브리드: 체크박스로 고정한 '필수 포함 숫자' 우선 배치 + 부족분은 가중치 확률로 자동 연성
class KeyCombinerEngine {
  static const _uuid = Uuid();

  /// 추출 개수 프리셋 (N = 2 듀오 시너지 / 3 삼합 비기 / 4 사신수 마법(기본) / 6 대박 행운)
  static const List<int> presets = [2, 3, 4, 6];
  static const int defaultTargetCount = 4;

  /// 조합 연성 실행
  ///
  /// [availablePool]: 보관함 내 전체 고유 2자리 숫자 목록 ("03", "07", ...)
  /// [selectedPool]: 사용자가 체크박스로 고정한 '필수 포함 숫자' (하이브리드 픽)
  /// [targetCount]: 추출 개수 N (2~6 프리셋)
  /// [allowDuplicates]: true 시 복원 추출로 동일 숫자 중첩 허용 (["07","07","21","21"])
  /// [weightByNumber]: 숫자별 획득 빈도 가중치 (item.count) — 중첩 모드에서 반영
  static List<String> combine({
    required List<String> availablePool,
    required List<String> selectedPool,
    required int targetCount,
    bool allowDuplicates = false,
    Map<String, int> weightByNumber = const {},
    Random? rng,
  }) {
    final random = rng ?? Random();
    final fixed = _dedupe(selectedPool);

    if (allowDuplicates) {
      return _combineWithRestoration(
        availablePool: availablePool,
        fixed: fixed,
        targetCount: targetCount,
        weightByNumber: weightByNumber,
        random: random,
      );
    }
    return _combineUnique(
      availablePool: availablePool,
      fixed: fixed,
      targetCount: targetCount,
      random: random,
    );
  }

  /// 결과에 중복(중첩 기운)이 발생했는지 판별 — "✨ 중첩 기운 발동!" 연출용
  static bool hasDuplicates(List<String> numbers) {
    return numbers.toSet().length != numbers.length;
  }

  /// 조합 프리셋 라벨 (다국어 키 반환용)
  static String presetLabel(int n) {
    switch (n) {
      case 2:
        return 'duo';
      case 3:
        return 'trio';
      case 4:
        return 'quad';
      case 6:
        return 'grand';
      default:
        return 'custom';
    }
  }

  // ------------------------------------------------------------------
  // 유니크 모드: 비복원 추출 (중복 없는 번호셋 — 로또 6/45, 사신수 고유 열쇠)
  // ------------------------------------------------------------------
  static List<String> _combineUnique({
    required List<String> availablePool,
    required List<String> fixed,
    required int targetCount,
    required Random random,
  }) {
    if (availablePool.length < targetCount) {
      throw ArgumentError('보관함의 고유 숫자가 부족합니다.');
    }

    final result = <String>{};

    // 하이브리드 1: 사용자가 고정한 필수 포함 숫자 우선 배치
    for (final num in fixed) {
      if (availablePool.contains(num)) {
        result.add(num);
      }
      if (result.length >= targetCount) break;
    }

    // 하이브리드 2: 부족분은 전체 풀에서 무작위 비복원 보충
    if (result.length < targetCount) {
      final remaining = availablePool.where((n) => !result.contains(n)).toList()
        ..shuffle(random);
      for (final num in remaining) {
        if (result.length >= targetCount) break;
        result.add(num);
      }
    }

    if (result.length < targetCount) {
      throw ArgumentError('보관함의 고유 숫자가 부족합니다.');
    }

    return _sorted(result.toList());
  }

  // ------------------------------------------------------------------
  // 중첩 모드: 복원 추출 + 획득 빈도 가중치 (도깨비 행운 가중치 연성)
  // ------------------------------------------------------------------
  static List<String> _combineWithRestoration({
    required List<String> availablePool,
    required List<String> fixed,
    required int targetCount,
    required Map<String, int> weightByNumber,
    required Random random,
  }) {
    if (availablePool.isEmpty) {
      throw ArgumentError('보관함의 고유 숫자가 부족합니다.');
    }

    final result = <String>[];

    // 하이브리드 1: 필수 포함 숫자 우선 배치 (1회씩)
    for (final num in fixed) {
      if (availablePool.contains(num)) {
        result.add(num);
      }
      if (result.length >= targetCount) break;
    }

    // 하이브리드 2: 부족분은 빈도 가중치 복원 추출 (동일 숫자 중첩 허용)
    final weightedPool = availablePool
        .map((n) => _WeightedEntry(n, _weightOf(n, weightByNumber)))
        .toList();
    final totalWeight = weightedPool.fold<double>(0, (sum, e) => sum + e.weight);
    if (totalWeight <= 0) {
      throw ArgumentError('유효한 가중치 풀이 없습니다.');
    }

    while (result.length < targetCount) {
      double roll = random.nextDouble() * totalWeight;
      String picked = weightedPool.last.number;
      for (final entry in weightedPool) {
        roll -= entry.weight;
        if (roll <= 0) {
          picked = entry.number;
          break;
        }
      }
      result.add(picked);
    }

    return _sorted(result.toList());
  }

  /// 도깨비 행운 가중치: 획득 빈도(count)가 높은 숫자일수록 중첩 슬롯에 당첨될 확률 상승
  static double _weightOf(String number, Map<String, int> weightByNumber) {
    final count = weightByNumber[number] ?? 1;
    return 1.0 + sqrt(count.clamp(1, 99).toDouble());
  }

  static List<String> _dedupe(List<String> input) {
    final seen = <String>{};
    return input.where((n) => seen.add(n)).toList();
  }

  static List<String> _sorted(List<String> list) {
    return list..sort((a, b) => int.parse(a).compareTo(int.parse(b)));
  }

  /// Creates a persistent CombinedKeyItem with 7-day TTL
  static CombinedKeyItem createCombinedKeyItem({
    required List<String> numbers,
    String? userTag,
    Duration ttl = const Duration(days: 7),
  }) {
    final now = DateTime.now();
    return CombinedKeyItem(
      id: _uuid.v4(),
      createdAt: now,
      expiresAt: now.add(ttl),
      targetCount: numbers.length,
      numbers: numbers,
      userTag: userTag,
      isCloudSynced: false,
    );
  }
}

class _WeightedEntry {
  final String number;
  final double weight;
  const _WeightedEntry(this.number, this.weight);
}
