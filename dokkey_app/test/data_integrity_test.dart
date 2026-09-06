import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// PHASE 2: 5개국어(KO/EN/JA/ZH/HI) 데이터셋 무결성 자동 검증
/// - 키 일치율 100% (ko 기준 en/ja/zh/hi 동일 ID)
/// - 빈 문자열/null 제로화
/// - 플레이스홀더({card_name} 등) 언어별 보존 (한국어 조사 토큰 {조사:...} 제외)
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const langs = ['ko', 'en', 'ja', 'zh', 'hi', 'de'];
  const nonKoLangs = ['en', 'ja', 'zh', 'hi', 'de'];

  Future<Map<String, dynamic>> loadJson(String lang, String name) async {
    final str = await rootBundle.loadString('assets/data/locales/$lang/$name');
    return json.decode(str) as Map<String, dynamic>;
  }

  List<String> placeholders(String? text) {
    final matches = RegExp(r'\{[a-zA-Z_가-힣:]+\}').allMatches(text ?? '');
    return matches.map((m) => m.group(0)!).where((p) => !p.startsWith('{조사')).toList()..sort();
  }

  void checkNoEmpty(dynamic value, String path) {
    if (value == null) {
      fail('NULL at $path');
    } else if (value is String && value.trim().isEmpty) {
      fail('EMPTY at $path');
    } else if (value is List) {
      for (var i = 0; i < value.length; i++) {
        checkNoEmpty(value[i], '$path[$i]');
      }
    } else if (value is Map) {
      value.forEach((k, v) => checkNoEmpty(v, '$path.$k'));
    }
  }

  group('PHASE 2: Locale Dataset Integrity (6 Languages: KO/EN/JA/ZH/HI/DE)', () {
    test('cards.json: 36 card IDs fully matched across 6 languages', () async {
      final maps = <String, Map<String, dynamic>>{};
      for (final lang in langs) {
        final raw = await rootBundle.loadString('assets/data/locales/$lang/cards.json');
        maps[lang] = json.decode(raw) as Map<String, dynamic>;
      }
      expect(maps['ko']!.length, 36);
      for (final lang in nonKoLangs) {
        expect(maps[lang]!.keys.toSet(), maps['ko']!.keys.toSet());
      }
      maps.forEach((lang, map) {
        map.forEach((id, info) {
          checkNoEmpty(info, 'cards.$lang.$id');
        });
      });
    });

    test('riddles.json: 50 riddles with identical IDs and valid answer indices across 6 languages', () async {
      final data = <String, List<dynamic>>{};
      for (final lang in langs) {
        final raw = await rootBundle.loadString('assets/data/locales/$lang/riddles.json');
        data[lang] = json.decode(raw) as List<dynamic>;
      }
      expect(data['ko']!.length, 50);
      for (var i = 0; i < data["ko"]!.length; i++) {
        final koId = data['ko']![i]['id'];
        for (final lang in nonKoLangs) {
          expect(data[lang]![i]['id'], koId);
        }
        for (final lang in langs) {
          final r = data[lang]![i];
          checkNoEmpty(r, 'riddles.$lang.$koId');
          final options = (r['options'] as List).length;
          expect(r['answer_index'], inInclusiveRange(0, options - 1));
          final reaction = r['kkaebi_reaction'] as Map;
          expect(reaction.containsKey('correct'), true);
          expect(reaction.containsKey('wrong'), true);
        }
      }
    });

    test('quotes.json: 150 quotes (insight+proverb+classic) with identical IDs, categories and tone tags across 6 languages', () async {
      final data = <String, List<dynamic>>{};
      for (final lang in langs) {
        final raw = await rootBundle.loadString('assets/data/locales/$lang/quotes.json');
        data[lang] = json.decode(raw) as List<dynamic>;
      }
      expect(data['ko']!.length, 150);
      for (var i = 0; i < data["ko"]!.length; i++) {
        final koId = data['ko']![i]['id'];
        for (final lang in nonKoLangs) {
          expect(data[lang]![i]['id'], koId);
          expect(data[lang]![i]['category'], data['ko']![i]['category']);
          expect(
            (data[lang]![i]['tone_tags'] as List).toSet(),
            (data['ko']![i]['tone_tags'] as List).toSet(),
          );
          // v4.7.0: author/theme/emotion/time_slot/kkaebi_comment 패리티
          expect(data[lang]![i]['author'], isNotEmpty);
          expect(data[lang]![i]['theme'], data['ko']![i]['theme']);
          expect(data[lang]![i]['emotion'], data['ko']![i]['emotion']);
          expect(
            (data[lang]![i]['time_slot'] as List).toSet(),
            (data['ko']![i]['time_slot'] as List).toSet(),
          );
          expect(data[lang]![i]['kkaebi_comment'], isNotEmpty);
        }
        for (final lang in langs) {
          checkNoEmpty(data[lang]![i], 'quotes.$lang.$koId');
        }
      }
    });

    test('dream_symbols.json: 30 symbols with fortune/lucky parity & keyword counts across 6 languages', () async {
      final data = <String, List<dynamic>>{};
      for (final lang in langs) {
        final raw = await rootBundle.loadString('assets/data/locales/$lang/dream_symbols.json');
        data[lang] = (json.decode(raw) as Map<String, dynamic>)['symbols'] as List<dynamic>;
      }
      expect(data['ko']!.length, 30);
      var totalKeywords = 0;
      for (final s in data['ko']!) {
        totalKeywords += (s['keywords'] as List).length;
      }
      expect(totalKeywords, greaterThanOrEqualTo(100));

      for (var i = 0; i < 30; i++) {
        final koId = data['ko']![i]['id'];
        for (final lang in nonKoLangs) {
          expect(data[lang]![i]['id'], koId);
          expect(data[lang]![i]['fortune'], data['ko']![i]['fortune']);
          expect(data[lang]![i]['lucky_number'], data['ko']![i]['lucky_number']);
        }
        for (final lang in langs) {
          final s = data[lang]![i];
          checkNoEmpty(s, 'dreams.$lang.$koId');
          expect(s['fortune'], isIn(['auspicious', 'ominous', 'normal']));
          final lucky = s['lucky_number'] as num;
          expect(lucky, inInclusiveRange(1, 99));
          expect((s['keywords'] as List).length,
              (data['ko']![i]['keywords'] as List).length);
        }
      }
    });

    test('kkaebi_chat.json: identical topic IDs, passcode first, step parity across 6 languages', () async {
      final data = <String, Map<String, dynamic>>{};
      for (final lang in langs) {
        data[lang] = await loadJson(lang, 'kkaebi_chat.json');
      }
      final topics = {for (final lang in langs) lang: data[lang]!['topics'] as List<dynamic>};
      final koIds = topics['ko']!.map((t) => t['id']).toList();
      for (final lang in nonKoLangs) {
        expect(topics[lang]!.map((t) => t['id']).toList(), koIds);
        expect(topics[lang]!.first['id'], 'passcode');
      }
      expect(koIds.first, 'passcode');

      for (var i = 0; i < koIds.length; i++) {
        final koSteps = (topics['ko']![i]['steps'] as List).length;
        for (final lang in nonKoLangs) {
          final steps = topics[lang]![i]['steps'] as List;
          expect(steps.length, koSteps);
        }
      }
    });

    test('tones.json: 12 tones, template counts & placeholder parity across 6 languages', () async {
      final data = <String, Map<String, dynamic>>{};
      for (final lang in langs) {
        data[lang] = await loadJson(lang, 'tones.json');
      }
      for (final lang in nonKoLangs) {
        expect(data[lang]!.keys.toSet(), data['ko']!.keys.toSet());
      }

      data['ko']!.forEach((toneId, info) {
        final koTemplates = (info['templates'] as List).length;
        for (final lang in nonKoLangs) {
          final templates = data[lang]![toneId]['templates'] as List;
          expect(templates.length, koTemplates);
          expect(data[lang]![toneId]['color'], info['color']);
          for (var i = 0; i < koTemplates; i++) {
            for (final field in ['headline', 'body', 'tip', 'share_caption']) {
              final koPh = placeholders((info['templates'] as List)[i][field]);
              final otherPh = placeholders(templates[i][field]);
              expect(otherPh, koPh, reason: 'tones.$toneId.t$i.$field ($lang)');
            }
          }
        }
      });
    });

    test('context_greetings.json: identical state/slot structure across 6 languages', () async {
      final data = <String, Map<String, dynamic>>{};
      for (final lang in langs) {
        data[lang] = await loadJson(lang, 'context_greetings.json');
      }
      for (final lang in nonKoLangs) {
        expect(data[lang]!.keys.toSet(), data['ko']!.keys.toSet());
        (data['ko']!).forEach((state, slots) {
          expect((data[lang]![state] as Map).keys.toSet(), (slots as Map).keys.toSet());
          slots.forEach((slot, items) {
            expect(
              ((data[lang]![state] as Map)[slot] as List).length,
              (items as List).length,
            );
          });
        });
      }
    });
  });
}
