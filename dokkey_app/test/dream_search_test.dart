import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dokkey_app/models/dokkey_models.dart';

/// 🌙 깨비의 꿈풀이 — 자연어 검색(토크나이저) 전수 검증
/// - 실제 6개국어 dream_symbols.json 자산을 로드해 운영 코드(matchesQuery)를 그대로 검증
/// - 셀프 매치(라벨·키워드 전부), 자연어 질의, 조사 부착/문장부호 엣지, 교차 오염(타 동물 키워드) 검사
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const langs = ['ko', 'en', 'ja', 'zh', 'de', 'hi'];

  Future<List<DreamSymbol>> loadSymbols(String lang) async {
    final str = await rootBundle.loadString('assets/data/locales/$lang/dream_symbols.json');
    final data = json.decode(str) as Map<String, dynamic>;
    final list = data['symbols'] as List<dynamic>;
    return list.map((e) => DreamSymbol.fromJson(e as Map<String, dynamic>)).toList();
  }

  group('꿈풀이 검색 인덱스 무결성 (6개국어 120종)', () {
    for (final lang in langs) {
      test('[$lang] 120종 전체 — 라벨과 모든 키워드가 자기 자신을 검색한다', () async {
        final symbols = await loadSymbols(lang);
        expect(symbols.length, 120, reason: '$lang 심볼 수');
        for (final s in symbols) {
          expect(s.matchesQuery(s.label), isTrue, reason: '$lang ${s.id} 라벨 자기검색 실패: ${s.label}');
          for (final kw in s.keywords) {
            expect(s.matchesQuery(kw), isTrue, reason: '$lang ${s.id} 키워드 자기검색 실패: $kw');
          }
        }
      });

      test('[$lang] 빈 질의와 공백은 매칭되지 않는다', () async {
        final symbols = await loadSymbols(lang);
        expect(symbols.first.matchesQuery(''), isFalse);
        expect(symbols.first.matchesQuery('   '), isFalse);
      });
    }
  });

  group('자연어 질의 매칭 (언어별 대표 시나리오)', () {
    test('[ko] "호랑이한테 쫓기는 꿈" → 호랑이 (조사 부착 + 조항 분리)', () async {
      final symbols = await loadSymbols('ko');
      final tiger = symbols.firstWhere((s) => s.id == 'tiger');
      expect(tiger.matchesQuery('호랑이한테 쫓기는 꿈'), isTrue);
      expect(tiger.matchesQuery('호랑이가 나오는 꿈'), isTrue);
      expect(tiger.matchesQuery('호랑이!'), isTrue, reason: '문장부호가 붙어도 매칭');
      expect(symbols.where((s) => s.matchesQuery('호랑이한테 쫓기는 꿈')).map((s) => s.id), contains('tiger'));
    });

    test('[ko] 이빨·조상님·맑은 물 시나리오', () async {
      final symbols = await loadSymbols('ko');
      expect(symbols.firstWhere((s) => s.id == 'teeth').matchesQuery('이빨 빠지는 꿈'), isTrue);
      expect(symbols.firstWhere((s) => s.id == 'ancestor').matchesQuery('돌아가신 조상님이 꿈에 나왔어'), isTrue);
      expect(symbols.firstWhere((s) => s.id == 'water').matchesQuery('맑은 물'), isTrue);
    });

    test('[en] "being chased by a tiger" → tiger', () async {
      final symbols = await loadSymbols('en');
      final tiger = symbols.firstWhere((s) => s.id == 'tiger');
      expect(tiger.matchesQuery('being chased by a tiger'), isTrue);
      expect(tiger.matchesQuery('TIGER DREAM'), isTrue, reason: '대소문자 무관');
      expect(symbols.firstWhere((s) => s.id == 'teeth').matchesQuery('my teeth are falling out'), isTrue);
    });

    test('[ja] "虎に追いかけられる夢" → 虎', () async {
      final symbols = await loadSymbols('ja');
      final tiger = symbols.firstWhere((s) => s.id == 'tiger');
      expect(tiger.matchesQuery('虎に追いかけられる夢'), isTrue);
      expect(symbols.firstWhere((s) => s.id == 'teeth').matchesQuery('歯が抜ける夢を見た'), isTrue);
      expect(symbols.firstWhere((s) => s.id == 'snake').matchesQuery('蛇の夢'), isTrue);
    });

    test('[zh] "被老虎追赶的梦" → 猛虎', () async {
      final symbols = await loadSymbols('zh');
      final tiger = symbols.firstWhere((s) => s.id == 'tiger');
      expect(tiger.matchesQuery('被老虎追赶的梦'), isTrue);
      expect(symbols.firstWhere((s) => s.id == 'teeth').matchesQuery('梦见掉牙'), isTrue);
      expect(symbols.firstWhere((s) => s.id == 'water').matchesQuery('清澈的泉水'), isTrue);
    });

    test('[de] "vom Tiger verfolgt" → Tiger (소문자 정규화)', () async {
      final symbols = await loadSymbols('de');
      final tiger = symbols.firstWhere((s) => s.id == 'tiger');
      expect(tiger.matchesQuery('vom Tiger verfolgt'), isTrue);
      expect(symbols.firstWhere((s) => s.id == 'teeth').matchesQuery('Zähne verlieren'), isTrue);
      expect(symbols.firstWhere((s) => s.id == 'snake').matchesQuery('schlange'), isTrue);
    });

    test('[hi] "बाघ के पीछे" → बाघ', () async {
      final symbols = await loadSymbols('hi');
      final tiger = symbols.firstWhere((s) => s.id == 'tiger');
      expect(tiger.matchesQuery('बाघ के पीछे'), isTrue);
      expect(symbols.firstWhere((s) => s.id == 'teeth').matchesQuery('दांत टूटना'), isTrue);
      expect(symbols.firstWhere((s) => s.id == 'snake').matchesQuery('सांप का सपना'), isTrue);
    });
  });

  group('교차 오염 방지 (키워드가 다른 상징을 잡으면 안 됨)', () {
    test('[hi] "शेर"(사자)는 사자만 매칭 — 호랑이 오매칭 회귀 방지', () async {
      final symbols = await loadSymbols('hi');
      final tiger = symbols.firstWhere((s) => s.id == 'tiger');
      final lion = symbols.firstWhere((s) => s.id == 'lion');
      expect(lion.matchesQuery('शेर'), isTrue, reason: 'शेर는 사자 키워드');
      expect(tiger.keywords.contains('शेर'), isFalse, reason: '호랑이 키워드에서 사자 단어 제거 확인');
    });
  });

  group('토크나이저 엣지 케이스', () {
    test('[ko] "조상", "용", "용꿈", "조상님" 단일 및 복합 키워드 매칭', () async {
      final symbols = await loadSymbols('ko');
      final ancestor = symbols.firstWhere((s) => s.id == 'ancestor');
      final dragon = symbols.firstWhere((s) => s.id == 'dragon');

      expect(ancestor.matchesQuery('조상'), isTrue, reason: '"조상" 단일어 매칭');
      expect(ancestor.matchesQuery('조상님'), isTrue, reason: '"조상님" 단일어 매칭');
      expect(ancestor.matchesQuery('조상꿈'), isTrue, reason: '"조상꿈" 복합어 매칭');

      expect(dragon.matchesQuery('용'), isTrue, reason: '"용" 단일어 매칭');
      expect(dragon.matchesQuery('용꿈'), isTrue, reason: '"용꿈" 복합어 매칭');
      expect(dragon.matchesQuery('용이 나오는 꿈'), isTrue, reason: '"용이 나오는 꿈" 자연어 매칭');
    });

    test('[ko] 토큰 분리 정밀 매칭 — 전체 문장에 키워드가 없어도 토큰으로 발견', () async {
      final symbols = await loadSymbols('ko');
      // "조상님" 키워드는 있으나 문장 전체는 키워드와 완전히 다름
      final ancestor = symbols.firstWhere((s) => s.id == 'ancestor');
      expect(ancestor.matchesQuery('할아버지가 보고 싶은 꿈'), isTrue, reason: '할아버지 키워드 매칭');
    });

    test('[ko] 무의미한 질의는 결과가 없어야 함 (예외 없이)', () async {
      final symbols = await loadSymbols('ko');
      final hits = symbols.where((s) => s.matchesQuery('키보드 모니터')).length;
      expect(hits, 0, reason: '무관한 단어는 매칭되지 않음');
    });
  });
}
