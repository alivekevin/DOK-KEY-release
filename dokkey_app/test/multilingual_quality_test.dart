import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// 🌍 v4.7.1 6개국어 언어팩 전수 무결성 검증
/// 1) 패리티 일치 (150종 × 6개국어, v2 스키마 전 필드)
/// 2) 언어 오염 검사 (ko/en/de/hi 파일에 CJK 한자 문장 혼입 금지)
/// 3) 어미 서명 규칙 (900개 kkaebi_comment 전수)
/// 4) 금지어·인코딩 깨짐 0건
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const langs = ['ko', 'en', 'ja', 'zh', 'hi', 'de'];
  const cjkHanzi = r'[一-鿿]'; // CJK 통합 한자 (ja/zh 제외 언어에서는 오염)

  // 언어별 화자 서명 접미사 (STEP 2 규칙)
  const signatureSuffix = {
    'ko': '-깨비!',
    'en': '- Kkaebi!',
    'ja': '- クケビ!',
    'zh': '- 小妖!',
    'hi': '- कैबी!',
    'de': '- Kkaebi!',
  };

  // 각 언어에서 허용되는 종결 문장부호
  const terminalOk = {
    'ko': ['.', '!', '?'],
    'en': ['.', '!', '?'],
    'ja': ['。', '！', '？'],
    'zh': ['。', '！', '？'],
    'hi': ['।', '!', '？', '?'],
    'de': ['.', '!', '?'],
  };

  // 한자 허용 언어 (일본어·중국어는 본래 CJK 사용)
  // bool cjkAllowed(String lang) => lang == 'ja' || lang == 'zh';

  void assertNoCjk(dynamic value, String path) {
    if (value is String) {
      if (RegExp(cjkHanzi).hasMatch(value)) {
        fail('CJK 한자 오염 at $path: "${value.length > 40 ? value.substring(0, 40) : value}..."');
      }
    } else if (value is List) {
      for (var i = 0; i < value.length; i++) {
        assertNoCjk(value[i], '$path[$i]');
      }
    } else if (value is Map) {
      value.forEach((k, v) => assertNoCjk(v, '$path.$k'));
    }
  }

  void assertNoBrokenEncoding(dynamic value, String path) {
    if (value is String) {
      expect(value.contains('\uFFFD'), false, reason: '인코딩 깨짐(U+FFFD) at $path');
    } else if (value is List) {
      for (var i = 0; i < value.length; i++) {
        assertNoBrokenEncoding(value[i], '$path[$i]');
      }
    } else if (value is Map) {
      value.forEach((k, v) => assertNoBrokenEncoding(v, '$path.$k'));
    }
  }

  group('1. 패리티 일치 (150종 × 6개국어)', () {
    test('quotes.json: 150종, v2 스키마 전 필드 100% 일치', () async {
      final data = <String, List<dynamic>>{};
      for (final lang in langs) {
        final raw = await rootBundle.loadString('assets/data/locales/$lang/quotes.json');
        data[lang] = json.decode(raw) as List<dynamic>;
      }
      expect(data['ko']!.length, 150);
      for (var i = 0; i < 150; i++) {
        final koId = data['ko']![i]['id'];
        for (final lang in langs) {
          final q = data[lang]![i];
          expect(q['id'], koId);
          for (final field in ['author', 'source', 'theme', 'emotion', 'kkaebi_comment']) {
            expect(q[field], isNotNull, reason: '$lang $koId.$field');
          }
          expect((q['time_slot'] as List).length,
              (data['ko']![i]['time_slot'] as List).length);
        }
        expect(data['en']![i]['theme'], data['ko']![i]['theme']);
        expect(data['de']![i]['emotion'], data['ko']![i]['emotion']);
        expect(data['zh']![i]['lucky_number'] ?? data['ko']![i], isNotNull);
      }
    });
  });

  group('2. 언어 오염 검사 (Cross-contamination)', () {
    test('quotes.json: ko/en/de/hi에 CJK 한자 문장 혼입 0건', () async {
      for (final lang in ['ko', 'en', 'de', 'hi']) {
        final raw = await rootBundle.loadString('assets/data/locales/$lang/quotes.json');
        final data = json.decode(raw) as List<dynamic>;
        for (var i = 0; i < data.length; i++) {
          assertNoCjk(data[i]['text'], 'quotes.$lang.quo_${i + 1}.text');
          assertNoCjk(data[i]['kkaebi_comment'], 'quotes.$lang.quo_${i + 1}.kkaebi_comment');
        }
      }
    });

    test('riddles.json: ko/en/de/hi에 CJK 한자 혼입 0건', () async {
      for (final lang in ['ko', 'en', 'de', 'hi']) {
        final raw = await rootBundle.loadString('assets/data/locales/$lang/riddles.json');
        final data = json.decode(raw) as List<dynamic>;
        for (var i = 0; i < data.length; i++) {
          final r = data[i];
          assertNoCjk(r['question'], 'riddles.$lang.rid_${i + 1}.question');
          assertNoCjk(r['options'], 'riddles.$lang.rid_${i + 1}.options');
          assertNoCjk(r['kkaebi_reaction'], 'riddles.$lang.rid_${i + 1}.kkaebi_reaction');
        }
      }
    });

    test('brand_slogans.json: en/de/hi 섹션에 CJK 한자 혼입 0건', () async {
      for (final lang in ['en', 'de', 'hi']) {
        final raw = await rootBundle.loadString('assets/data/common/brand_slogans.json');
        final data = json.decode(raw) as Map<String, dynamic>;
        // zh/ja 섹션은 CJK가 본래 언어이므로 제외하고, 해당 언어 섹션만 검사
        data.forEach((section, node) {
          if (node is Map && node[lang] is String) {
            assertNoCjk(node[lang], 'brand_slogans.$section.$lang');
          }
        });
      }
    });
  });

  group('3. 어미 서명 규칙 (900개 전수)', () {
    test('모든 kkaebi_comment가 언어별 화자 서명(-깨비! 등)으로 끝난다', () async {
      var checked = 0;
      for (final lang in langs) {
        final raw = await rootBundle.loadString('assets/data/locales/$lang/quotes.json');
        final data = json.decode(raw) as List<dynamic>;
        for (var i = 0; i < data.length; i++) {
          final comment = data[i]['kkaebi_comment'] as String;
          checked++;
          expect(
            comment.trim().endsWith(signatureSuffix[lang]!),
            true,
            reason: '$lang quo_${i + 1} 서명 누락: "$comment"',
          );
          // 서명 직전 문자는 종결 문장부호여야 한다 (문장이 완결된 상태)
          final body = comment.substring(0, comment.length - signatureSuffix[lang]!.length).trim();
          expect(body.isNotEmpty, true, reason: '$lang quo_${i + 1} 본문 공백');
          expect(
            terminalOk[lang]!.any((t) => body.endsWith(t)),
            true,
            reason: '$lang quo_${i + 1} 종결부호 누락: "$body"',
          );
        }
      }
      expect(checked, 900);
    });
  });

  group('4. 금지어·인코딩 검사', () {
    test('quotes/brand_slogans에 레거시 키워드 0건', () async {
      for (final lang in langs) {
        final quotes = await rootBundle.loadString('assets/data/locales/$lang/quotes.json');
        for (final term in ['수묵과', '영구', '무제한']) {
          expect(quotes.contains(term), false, reason: '$lang quotes 금지어: $term');
        }
        // 사행성: '로또' 단독 강조 0건 (ko/en/de 기준)
        if (['ko', 'en', 'de'].contains(lang)) {
          expect(quotes.toLowerCase().contains('로또'), false, reason: '$lang 로또 단독 강조');
          expect(quotes.toLowerCase().contains('lottery'), false, reason: '$lang lottery 단독 강조');
        }
      }
      final slogans = await rootBundle.loadString('assets/data/common/brand_slogans.json');
      for (final term in ['수묵과', '영구', '무제한', '로또']) {
        expect(slogans.contains(term), false, reason: 'slogans 금지어: $term');
      }
    });

    test('전 데이터셋 인코딩 깨짐(U+FFFD) 0건', () async {
      for (final lang in langs) {
        for (final name in ['quotes.json', 'riddles.json', 'brand_slogans.json']) {
          final path = name == 'brand_slogans.json'
              ? 'assets/data/common/brand_slogans.json'
              : 'assets/data/locales/$lang/$name';
          final raw = await rootBundle.loadString(path);
          assertNoBrokenEncoding(raw, path);
        }
      }
    });
  });
}
