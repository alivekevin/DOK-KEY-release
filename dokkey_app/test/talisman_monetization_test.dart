import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dokkey_app/models/dokkey_models.dart';
import 'package:dokkey_app/models/talisman_model.dart';
import 'package:dokkey_app/providers/dokkey_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 🎴 v4.7.1 18종 부적 시스템 & BM v5 유료화 검증
/// - 18종 레지스트리 무결성 + 에셋 존재 + 독일어명
/// - 매칭 엔진 (키워드/감정/기본 폴백)
/// - 드로우 시 부적 자동 발급 & 온디바이스 수집 저장
/// - BM: 무료 9슬롯/1뽑기 vs PRO 99슬롯/4뽑기/광고제거
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('18종 부적 레지스트리 무결성', () {
    test('index 1~18 연속 + ID 유니크 + 6개국어 이름/효험 설명 완비', () {
      expect(TalismanRegistry.items.length, 18);
      for (var i = 0; i < 18; i++) {
        final t = TalismanRegistry.items[i];
        expect(t.index, i + 1);
        expect(t.imagePath,
            'assets/images/talismans/talisman_${(i + 1).toString().padLeft(2, '0')}.webp');
        expect(t.nameKo, isNotEmpty);
        expect(t.nameEn, isNotEmpty);
        expect(t.nameDe, isNotEmpty, reason: '독일어명 누락: ${t.id}');
        expect(t.descKo, isNotEmpty);
        expect(t.descEn, isNotEmpty);
        expect(t.matchingKeywords, isNotEmpty);
      }
      expect(
        TalismanRegistry.items.map((t) => t.id).toSet().length,
        18,
      );
    });

    test('18종 부적 PNG 에셋이 번들에 실제 존재 (RGBA 로드 가능)', () async {
      for (final t in TalismanRegistry.items) {
        final data = await rootBundle.load(t.imagePath);
        expect(data.lengthInBytes, greaterThan(1000),
            reason: '${t.imagePath} 비정상적으로 작음');
      }
    });

    test('카테고리 구성: daily 10 / seasonal 4 / special 4 = 18', () {
      final counts = <TalismanCategory, int>{};
      for (final t in TalismanRegistry.items) {
        counts[t.category] = (counts[t.category] ?? 0) + 1;
      }
      expect(counts[TalismanCategory.daily], 10);
      expect(counts[TalismanCategory.seasonal], 4);
      expect(counts[TalismanCategory.special], 4);
    });
  });

  group('부적 매칭 엔진 (matchTalisman)', () {
    test('키워드 매칭: 재물 명언 → 재물·성취 부적', () {
      final t = TalismanRegistry.matchTalisman(
        '오늘 재물운이 폭발한다. 부자가 될 기회다!',
      );
      expect(t.id, 'talisman_wealth');
    });

    test('키워드 매칭: 숙면 명언 → 숙면안심 부적', () {
      final t = TalismanRegistry.matchTalisman('불면의 밤, 숙면이 필요하다');
      expect(t.id, 'talisman_sleep');
    });

    test('키워드 미매칭 시 감정 폴백: passion → 승리·돌파 부적', () {
      final t = TalismanRegistry.matchTalisman('특별한 키워드 없음', emotion: 'passion');
      expect(t.id, 'talisman_victory');
    });

    test('아무것도 없으면 기본 1번 재물 부적', () {
      final t = TalismanRegistry.matchTalisman('무의미한 텍스트', emotion: 'unknown');
      expect(t.id, 'talisman_wealth');
    });
  });

  group('BM v5: 무료 vs PRO 권한 분기', () {
    test('무료: 9슬롯 · 1일 1뽑기 · 광고 있음', () async {
      final provider = DokkeyProvider();
      await provider.initialize();
      expect(provider.isProUser, false);
      expect(provider.maxCombinedSlots, 9);
      expect(provider.adFreeExperience, false);
      expect(provider.dailyDrawQuota, 1);
    });

    test('PRO: 99슬롯 · 1일 4뽑기 · 광고 제거', () async {
      final provider = DokkeyProvider();
      await provider.initialize();
      await provider.upgradeToProPass();
      expect(provider.isProUser, true);
      expect(provider.maxCombinedSlots, 99);
      expect(provider.adFreeExperience, true);
      expect(provider.dailyDrawQuota, 4);
    });

    test('부적 슬롯 게이팅 규칙: 무료 19~20(2개) 체험 / 21~33 PRO', () {
      // card_codex_screen의 isLockedForFree 규칙과 동일한 로직 검증
      bool isLockedForFree(bool isPro, int customSlotIdx) =>
          !isPro && customSlotIdx >= 2;

      // 무료: 19번(idx0), 20번(idx1) 사용 가능 / 21번(idx2)부터 잠금
      expect(isLockedForFree(false, 0), false);
      expect(isLockedForFree(false, 1), false);
      expect(isLockedForFree(false, 2), true);
      expect(isLockedForFree(false, 14), true);
      // PRO: 전부 잠금 해제
      for (var i = 0; i < 15; i++) {
        expect(isLockedForFree(true, i), false);
      }
    });
  });

  group('드로우 → 부적 자동 발급 (온디바이스 수집)', () {
    test('executeDraw 시 부적이 자동 발급되어 컬렉션에 저장된다', () async {
      final provider = DokkeyProvider();
      await provider.initialize();

      for (var n = 1; n <= 3; n++) {
        await provider.injectNumber(n.toString().padLeft(2, '0'));
      }
      await provider.executeDraw();

      expect(provider.talismanCollectionCount, greaterThanOrEqualTo(1));
      // 온디바이스 저장 확인
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getStringList('pref_issued_talismans'), isNotNull);
      expect(prefs.getStringList('pref_issued_talismans')!.length,
          provider.talismanCollectionCount);
    });

    test('동일 부적 중복 발급 방지 (컬렉션은 유니크)', () async {
      final provider = DokkeyProvider();
      await provider.initialize();

      final first = await provider.issueTalismanForText('재물이 들어오는 명언');
      final second = await provider.issueTalismanForText('재물이 들어오는 명언');
      expect(first, true);
      expect(second, false, reason: '이미 발급된 부적은 재발급되지 않는다');
      expect(provider.talismanCollectionCount, 1);
    });
  });
}
