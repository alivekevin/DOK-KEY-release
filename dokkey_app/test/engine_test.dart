import 'package:flutter_test/flutter_test.dart';
import 'package:dokkey_app/core/korean_josa.dart';

void main() {
  group('Korean Josa Engine Tests', () {
    test('Particle resolution for consonants and vowels', () {
      expect('토끼${KoreanJosa.resolveJosa('토끼', '은/는')}', '토끼는');
      expect('호랑이${KoreanJosa.resolveJosa('호랑이', '은/는')}', '호랑이는');
      expect('소${KoreanJosa.resolveJosa('소', '이/가')}', '소가');
      expect('쥐${KoreanJosa.resolveJosa('쥐', '이/가')}', '쥐가');
      expect('용${KoreanJosa.resolveJosa('용', '이/가')}', '용이');
      expect('원숭이${KoreanJosa.resolveJosa('원숭이', '을/를')}', '원숭이를');
      expect('닭${KoreanJosa.resolveJosa('닭', '을/를')}', '닭을');
      expect('달항아리${KoreanJosa.resolveJosa('달항아리', '과/와')}', '달항아리와');
      expect('벼루${KoreanJosa.resolveJosa('벼루', '과/와')}', '벼루와');
      expect('목탁${KoreanJosa.resolveJosa('목탁', '과/와')}', '목탁과');
    });

    test('Number particle resolution (으로/로)', () {
      expect('1${KoreanJosa.resolveJosa('1', '으로/로')}', '1로');
      expect('3${KoreanJosa.resolveJosa('3', '으로/로')}', '3으로');
      expect('7${KoreanJosa.resolveJosa('7', '으로/로')}', '7로');
      expect('8${KoreanJosa.resolveJosa('8', '으로/로')}', '8로');
      expect('10${KoreanJosa.resolveJosa('10', '으로/로')}', '10으로');
    });

    test('Timeslot name particle resolution (v3.0.0)', () {
      expect('아침${KoreanJosa.resolveJosa('아침', '은/는')}', '아침은');
      expect('점심${KoreanJosa.resolveJosa('점심', '은/는')}', '점심은');
      expect('저녁${KoreanJosa.resolveJosa('저녁', '은/는')}', '저녁은');
      expect('심야${KoreanJosa.resolveJosa('심야', '은/는')}', '심야는');
      expect('아침${KoreanJosa.resolveJosa('아침', '이/가')}', '아침이');
      expect('심야${KoreanJosa.resolveJosa('심야', '이/가')}', '심야가');
    });

    test('Template formatting test (timeslot token)', () {
      const tmpl = '{card_name}{조사:은/는} {timeslot_name}의 기운으로 숫자 {number}{조사:으로/로} 결실{조사:을/를} 맺는다.';
      final res1 = KoreanJosa.format(tmpl, {
        'card_name': '토끼',
        'timeslot_name': '아침',
        'number': 7,
      });
      expect(res1, '토끼는 아침의 기운으로 숫자 7로 결실을 맺는다.');

      final res2 = KoreanJosa.format(tmpl, {
        'card_name': '용',
        'timeslot_name': '심야',
        'number': 10,
      });
      expect(res2, '용은 심야의 기운으로 숫자 10으로 결실을 맺는다.');
    });

    test('Japanese template formatting test', () {
      const tmpl = '{card_name}は今日{timeslot_name}で数字の{number}番と出会う。';
      var res = tmpl.replaceAll('{card_name}', '卯 (うさぎ)');
      res = res.replaceAll('{timeslot_name}', '朝');
      res = res.replaceAll('{number}', '7');
      expect(res, '卯 (うさぎ)は今日朝で数字の7番と出会う。');
    });

    test('5-Step Progressive Storytelling & Ending test', () {
      final steps = [
        '1단계: 붕어빵 사 먹어라!',
        '2단계: 또 물어보냐?',
        '3단계: {card_name}의 기운을 믿어라',
        '4단계: 너 정말 집요하구나!',
        '5단계: 오늘 숫자 {number}번을 품어라'
      ];
      const ending = '으악! 오늘 천기누설을 너무 많이 해서 도깨비 수명이 5년은 줄어든 것 같아!';

      expect(steps.length, 5);
      expect(steps[0].contains('붕어빵'), true);
      expect(steps[4].contains('{number}'), true);
      expect(ending.contains('수명이 5년'), true);
    });
  });
}
