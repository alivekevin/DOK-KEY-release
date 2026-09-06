import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'context_key_engine.dart';
import '../models/dokkey_models.dart';

/// 📜 데일리 명언 선정 엔진 (v4.7.0 Wisdom-First)
///
/// 결정론적 원칙: 동일 유저 + 동일 날짜 = 동일 명언.
/// 테마 로테이션(요일) → 시간대 적합도 → 감정 보정 순의 가중 스코어로 선정하며,
/// 최근 14일 노출 이력은 후보에서 제외한다.
class DailyQuoteEngine {
  DailyQuoteEngine._();

  /// 요일별 테마 로테이션 (월~일)
  static const List<String> weeklyThemeRotation = [
    'growth',    // 월: 성장/도전
    'zen',       // 화: 명상/중도
    'comfort',   // 수: 위로/치유
    'challenge', // 목: 도약/역발상
    'gratitude', // 금: 감사/축복
    'zen',       // 토: 여유/관찰
    'fortune',   // 일: 운명/흐름
  ];

  /// 감정 보정 테이블: 최근 기분 상태 → 가중 테마
  static const Map<String, List<String>> moodThemeBias = {
    'low': ['comfort', 'zen'],
    'neutral': [],
    'high': ['challenge', 'gratitude'],
  };

  /// 오늘의 명언 선정
  ///
  /// [pool]: 로드된 전체 명언 풀 (quotes.json v2)
  /// [userUuid]: 결정론 시드용 유저 ID
  /// [recentIds]: 최근 14일 노출된 명언 ID (중복 방지)
  /// [moodBias]: 최근 감정 ('low' | 'neutral' | 'high' | null)
  /// [currentSlot]: 현재 시간대 (time_slot 적합도 가중)
  static QuoteModel? pickDailyQuote({
    required List<QuoteModel> pool,
    required String userUuid,
    required DateTime now,
    List<String> recentIds = const [],
    String? moodBias,
    TimeSlotId? currentSlot,
  }) {
    if (pool.isEmpty) return null;

    final todayStr =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    final recent = recentIds.toSet();
    final weekdayTheme = weeklyThemeRotation[now.weekday - 1];
    final moodThemes = moodThemeBias[moodBias] ?? const [];

    QuoteModel? best;
    double bestScore = -1;
    final candidates = pool.where((q) => !recent.contains(q.id)).toList();
    final target = candidates.isEmpty ? pool : candidates;

    for (final q in target) {
      double score = 0;

      // 1. 테마 로테이션 정합 (요일 테마 +3, 감정 보정 테마 +2.5)
      if (q.theme == weekdayTheme) score += 3.0;
      if (moodThemes.contains(q.theme)) score += 2.5;

      // 2. 시간대 적합도 (+1.5)
      final slotStr = currentSlot == null
          ? ''
          : ContextKeyEngine.slotIdToString(currentSlot);
      if (q.timeSlots.contains(slotStr)) score += 1.5;

      // 3. 결정론적 개인화 랭크 (동일 날짜+유저는 항상 같은 순위)
      final digest = sha256.convert(utf8.encode('$userUuid:$todayStr:${q.id}:DOK_KEY_WISDOM'));
      score += (int.parse(digest.toString().substring(0, 8), radix: 16) % 1000) / 1000.0;

      if (score > bestScore) {
        bestScore = score;
        best = q;
      }
    }
    return best;
  }

  /// 명언 톤 → 8대 감정 매핑 (ScreenEmotionFxOverlay 연동용)
  /// QuoteModel.emotion 문자열을 EmotionType 문자열로 정규화한다.
  static String fxEmotionOf(QuoteModel quote) {
    switch (quote.emotion) {
      case 'joy':
        return 'joy';
      case 'shy':
      case 'love':
        return 'shy';
      case 'sad':
        return 'sad';
      case 'fire':
      case 'awaken':
        return 'fire';
      case 'rage':
        return 'rage';
      case 'curious':
        return 'curious';
      case 'shock':
        return 'shock';
      case 'normal':
      case 'calm':
      default:
        return 'normal';
    }
  }

  /// 명언 고유 결정론 시드 (히어로 연출/공유 링크용)
  static String quoteSeed(String userUuid, String quoteId, DateTime now) {
    final day = '${now.year}-${now.month}-${now.day}';
    return sha256.convert(utf8.encode('$userUuid:$quoteId:$day')).toString().substring(0, 12);
  }
}
