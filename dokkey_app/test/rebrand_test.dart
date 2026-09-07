import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dokkey_app/core/brand_config.dart';
import 'package:dokkey_app/core/context_key_engine.dart';
import 'package:dokkey_app/core/daily_quote_engine.dart';
import 'package:dokkey_app/core/dokkey_engine.dart';
import 'package:dokkey_app/models/dokkey_models.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// v4.7.0 Wisdom-First Rebrand 검증
/// 1) 6개국어 슬로건 단일 소스 일치
/// 2) 명언 엔진 결정론·중복 방지·감정 바인딩
/// 3) 홈 IA 순서 (명언 히어로가 수수께끼/운세/도감/숫자보다 위) — 소스 구조 검증
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  setUpAll(() async {
    await DokkeyEngine().initialize();
  });

  group('P1: Brand Slogan Consistency (6 Languages)', () {
    const langs = ['ko', 'en', 'ja', 'zh', 'hi', 'de'];

    test('brand_slogans.json has all sections filled in all languages', () async {
      await BrandConfig.ensureLoaded();
      for (final lang in langs) {
        expect(BrandConfig.mainSlogan(lang), isNotEmpty, reason: 'mainSlogan($lang)');
        expect(BrandConfig.subSlogan(lang), isNotEmpty, reason: 'subSlogan($lang)');
        expect(BrandConfig.appPurpose(lang), isNotEmpty, reason: 'appPurpose($lang)');
        expect(BrandConfig.ogTitle(lang), isNotEmpty, reason: 'ogTitle($lang)');
        expect(BrandConfig.ogDescription(lang), isNotEmpty, reason: 'ogDescription($lang)');
        expect(BrandConfig.webHero(lang), isNotEmpty, reason: 'webHero($lang)');
      }
    });

    test('slogan data contains no forbidden legacy terms', () async {
      final raw = await rootBundle.loadString('assets/data/common/brand_slogans.json');
      for (final term in ['수묵과', '영구', '무제한', '로또']) {
        expect(raw.contains(term), false, reason: '금지 용어: $term');
      }
    });
  });

  group('P3: Daily Quote Engine (Wisdom-First)', () {
    List<QuoteModel> pool(String lang) => DokkeyEngine().getAllQuotes(lang);

    test('deterministic: same user + same date = same quote', () {
      final day = DateTime(2026, 9, 6, 9, 0);
      final a = DailyQuoteEngine.pickDailyQuote(
        pool: pool('ko'), userUuid: 'u1', now: day, currentSlot: TimeSlotId.morning);
      final b = DailyQuoteEngine.pickDailyQuote(
        pool: pool('ko'), userUuid: 'u1', now: day, currentSlot: TimeSlotId.morning);
      expect(a!.id, b!.id);
      expect(a.kkaebiComment, isNotEmpty, reason: '깨비의 한마디가 반드시 존재');
      expect(a.authorLabel, isNotEmpty);
    });

    test('14-day dedup excludes recent picks', () {
      final quotes = pool('ko');
      final recent = quotes.take(140).map((q) => q.id).toList();
      final picked = DailyQuoteEngine.pickDailyQuote(
        pool: quotes,
        userUuid: 'u1',
        now: DateTime(2026, 9, 6),
        recentIds: recent,
      );
      expect(
        picked!.id,
        isIn(quotes.map((q) => q.id).toSet().difference(recent.toSet())),
      );
    });

    test('fx emotion mapping covers all binding values', () {
      const themes = {
        'growth': 'fire', 'challenge': 'rage', 'hope': 'joy', 'meeting': 'shy',
        'mystery': 'curious', 'fortune': 'curious', 'zen': 'normal',
      };
      for (final entry in themes.entries) {
        final q = QuoteModel(
          id: 't', text: 'x', category: 'insight', toneTags: [],
          theme: entry.key, emotion: entry.value,
        );
        expect(DailyQuoteEngine.fxEmotionOf(q), isIn(
          ['normal', 'joy', 'shy', 'sad', 'fire', 'rage', 'curious', 'shock'],
        ));
      }
    });
  });

  group('P2: Home IA Order (Wisdom-First)', () {
    test('home source declares sections in wisdom-first order: hero > fortune(orb) > codex > riddle > forge', () {
      final src = File('lib/screens/home_screen.dart').readAsStringSync();
      final hero = src.indexOf('QuoteHeroSection()');
      final fortuneOrb = src.indexOf('명언의 흐름을 확인하는 오늘의 운세');
      final codex = src.indexOf('99종 신수 · 신격 도감');
      final riddle = src.indexOf('깨비의 수수께끼 풀기');
      final numbers = src.indexOf('행운 숫자 연성소');
      for (final v in [hero, fortuneOrb, codex, riddle, numbers]) {
        expect(v, greaterThan(-1), reason: '홈 IA 핵심 섹션이 모두 존재해야 한다');
      }
      expect(hero, lessThan(fortuneOrb), reason: '1순위 명언 히어로 > 핵심 인터랙션 열쇠 돌리기');
      expect(fortuneOrb, lessThan(codex), reason: '열쇠 돌리기 > 99 도감');
      expect(codex, lessThan(riddle), reason: '99 도감 > 수수께끼');
      expect(riddle, lessThan(numbers), reason: '수수께끼 > 숫자 연성소');
      // 구 요소 제거 확인: 중복 Codex Mini Banner / Quote Ticker 잔재 없음
      expect(src.indexOf('Codex Mini Banner'), -1, reason: '구 Codex 배지는 제거');
      expect(src.indexOf("Kkaebi's Quote Ticker"), -1, reason: '구 명언 티커는 히어로로 대체');
    });

    test('home appbar uses 6-language sheet, not 3-cycle toggle', () {
      final src = File('lib/screens/home_screen.dart').readAsStringSync();
      expect(src.contains('_showLanguageSheet'), true, reason: '6개국어 시트 진입이 존재');
      expect(src.contains('toggleLanguage()'), false, reason: '3개국어 순환 토글은 제거되어야 한다');
      // 6개 언어 옵션이 모두 정의되어 있는지
      for (final code in ['ko', 'en', 'ja', 'zh', 'hi', 'de']) {
        expect(src.contains("'$code'"), true, reason: '언어 옵션 $code');
      }
    });
  });
}
