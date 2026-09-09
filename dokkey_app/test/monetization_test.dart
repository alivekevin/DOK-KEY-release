import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:dokkey_app/core/key_combiner_engine.dart';
import 'package:dokkey_app/providers/dokkey_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// item 6: 가상의 무료/유료 사용자 기반 유료화 정책 검증
/// - 무료: 조합 슬롯 9개, 키 TTL 7일 자동 순환
/// - Pro(10년 안심 패스): 조합 슬롯 99개, TTL 10년 고정, 기존 키 일괄 승격
/// - 도감/원천 번호는 등급과 무관하게 안전 보존
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('FREE user (무료 9슬롯 · 7일 TTL)', () {
    test('free slot cap is 9 and 10th combine throws MAX_SLOTS_REACHED', () async {
      final provider = DokkeyProvider();
      await provider.initialize();

      expect(provider.isProUser, false);
      expect(provider.maxCombinedSlots, DokkeyProvider.maxFreeCombinedSlots);
      expect(provider.maxCombinedSlots, 9);

      // 신규 유저 스타터 지급분을 제외한 순수 주입분만 카운트
      final baseline = provider.sourceNumbers.length;
      final preExisting = provider.sourceNumbers.map((s) => s.numberStr).toSet();
      for (var n = 1; n <= 20; n++) {
        await provider.injectNumber(n.toString().padLeft(2, '0'));
      }
      final newUnique = [for (var n = 1; n <= 20; n++) if (!preExisting.contains(n.toString().padLeft(2, '0'))) n].length;
      expect(provider.sourceNumbers.length, baseline + newUnique);

      // 9개 연성 성공
      for (var i = 0; i < 9; i++) {
        await provider.combineAndSaveKeys(targetCount: 2, selectedPool: {});
        // 유니크 모드는 보유 고유 번호 풀에서 비복원 추출하므로 재연성 가능
      }
      expect(provider.combinedKeys.length, 9);

      // 10번째 연성은 한도 초과로 거부
      expect(
        () => provider.combineAndSaveKeys(targetCount: 2, selectedPool: {}),
        throwsA(predicate((e) => e.toString().contains('MAX_SLOTS_REACHED'))),
      );
    });

    test('free combined key TTL is 7 days', () async {
      final provider = DokkeyProvider();
      await provider.initialize();

      for (var n = 1; n <= 5; n++) {
        await provider.injectNumber(n.toString().padLeft(2, '0'));
      }
      final key = await provider.combineAndSaveKeys(targetCount: 2, selectedPool: {});
      final ttl = key.expiresAt!.difference(key.createdAt);
      expect(ttl, const Duration(days: 7));
    });

    test('expired free keys are purged on next launch (slot recycling)', () async {
      final provider = DokkeyProvider();
      await provider.initialize();

      for (var n = 1; n <= 3; n++) {
        await provider.injectNumber(n.toString().padLeft(2, '0'));
      }
      final stale = KeyCombinerEngine.createCombinedKeyItem(
        numbers: ['01', '02'],
        ttl: const Duration(days: -1), // 이미 만료된 키
      );
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getStringList('pref_combined_keys') ?? [];
      raw.insert(0, json.encode(stale.toJson()));
      await prefs.setStringList('pref_combined_keys', raw);

      // 재실행 시뮬레이션
      final relaunched = DokkeyProvider();
      await relaunched.initialize();
      expect(
        relaunched.combinedKeys.any((k) => k.id == stale.id),
        false,
        reason: '만료 키는 재실행 시 자동 정리되어 슬롯이 순환된다',
      );
    });
  });

  group('PRO user (10년 안심 패스 · 99슬롯)', () {
    test('pro slot cap is 99 and TTL is 10 years', () async {
      final provider = DokkeyProvider();
      await provider.initialize();

      await provider.upgradeToProPass();
      expect(provider.isProUser, true);
      expect(provider.maxCombinedSlots, DokkeyProvider.maxProCombinedSlots);
      expect(provider.maxCombinedSlots, 99);

      for (var n = 1; n <= 30; n++) {
        await provider.injectNumber(n.toString().padLeft(2, '0'));
      }
      for (var i = 0; i < 30; i++) {
        await provider.combineAndSaveKeys(targetCount: 2, selectedPool: {});
      }
      expect(provider.combinedKeys.length, 30);
      expect(provider.combinedKeys.length, lessThan(99));

      // Pro 키 TTL은 10년 (3650일)
      final ttl = provider.combinedKeys.first.expiresAt!
          .difference(provider.combinedKeys.first.createdAt);
      expect(ttl.inDays, 3650);
    });

    test('upgrading extends existing 7-day keys to the 10-year safe lock', () async {
      final provider = DokkeyProvider();
      await provider.initialize();

      for (var n = 1; n <= 4; n++) {
        await provider.injectNumber(n.toString().padLeft(2, '0'));
      }
      final freeKey = await provider.combineAndSaveKeys(targetCount: 2, selectedPool: {});
      expect(freeKey.expiresAt!.difference(freeKey.createdAt), const Duration(days: 7));

      await provider.upgradeToProPass();
      final extended = provider.combinedKeys.firstWhere((k) => k.id == freeKey.id);
      final remaining = extended.expiresAt!.difference(DateTime.now());
      expect(remaining.inDays, greaterThan(3000), reason: '기존 키가 10년 안심 보관으로 승격된다');
    });

    test('deleting keys frees slots for both tiers (codex preserved)', () async {
      final provider = DokkeyProvider();
      await provider.initialize();

      await provider.upgradeToProPass();
      final baseline = provider.sourceNumbers.length;
      final preExisting = provider.sourceNumbers.map((s) => s.numberStr).toSet();
      for (var n = 1; n <= 12; n++) {
        await provider.injectNumber(n.toString().padLeft(2, '0'));
      }
      final newUnique = [for (var n = 1; n <= 12; n++) if (!preExisting.contains(n.toString().padLeft(2, '0'))) n].length;
      for (var i = 0; i < 12; i++) {
        await provider.combineAndSaveKeys(targetCount: 2, selectedPool: {});
      }
      final before = provider.combinedKeys.length;
      await provider.deleteCombinedKey(provider.combinedKeys.first.id);
      expect(provider.combinedKeys.length, before - 1);
      expect(provider.canAddCombinedKey, true);

      // 일괄 정리
      final cleared = await provider.clearAllCombinedKeys();
      expect(cleared, before - 1);
      expect(provider.combinedKeys.isEmpty, true);

      // 도감/원천 번호는 등급·삭제와 무관하게 보존
      expect(provider.sourceNumbers.length, baseline + newUnique);
      expect(provider.collectedNumbers.length, greaterThanOrEqualTo(newUnique));
    });

    test('bulk cleanup removes only expired keys, keeps valid ones', () async {
      final provider = DokkeyProvider();
      await provider.initialize();
      await provider.upgradeToProPass();

      for (var n = 1; n <= 6; n++) {
        await provider.injectNumber(n.toString().padLeft(2, '0'));
      }
      final fresh = KeyCombinerEngine.createCombinedKeyItem(numbers: ['01', '02']);
      final stale = KeyCombinerEngine.createCombinedKeyItem(
        numbers: ['03', '04'],
        ttl: const Duration(days: -1),
      );
      provider.combinedKeysManualInsertForTest(fresh, stale);

      final removed = await provider.clearExpiredCombinedKeys();
      expect(removed, 1);
      expect(provider.combinedKeys.any((k) => k.id == fresh.id), true);
      expect(provider.combinedKeys.any((k) => k.id == stale.id), false);
    });
  });

  group('Source Numbers Keybox (01 ~ 99)', () {
    test('supports all 99 unique numbers with duplicate counters', () async {
      final provider = DokkeyProvider();
      await provider.initialize();

      for (var n = 1; n <= 99; n++) {
        await provider.injectNumber(n.toString().padLeft(2, '0'));
      }
      expect(provider.sourceNumbers.length, 99);

      // 중복 획득 시 count 누적 메타데이터 확인
      final initialCount = provider.sourceNumbers.firstWhere((s) => s.numberStr == '77').count;
      await provider.injectNumber('77');
      final item = provider.sourceNumbers.firstWhere((s) => s.numberStr == '77');
      expect(item.count, initialCount + 1);
      expect(item.lastHeadline.contains('인스펙터'), true);
    });

    test('source numbers survive tier changes and key deletion', () async {
      final provider = DokkeyProvider();
      await provider.initialize();

      final baseline = provider.sourceNumbers.length;
      final preExisting = provider.sourceNumbers.map((s) => s.numberStr).toSet();
      for (var n = 1; n <= 10; n++) {
        await provider.injectNumber(n.toString().padLeft(2, '0'));
      }
      final newUnique = [for (var n = 1; n <= 10; n++) if (!preExisting.contains(n.toString().padLeft(2, '0'))) n].length;
      await provider.upgradeToProPass();
      expect(provider.sourceNumbers.length, baseline + newUnique);

      await provider.clearAllCombinedKeys();
      expect(provider.sourceNumbers.length, baseline + newUnique, reason: '조합키 삭제는 원천 번호 풀에 영향 없음');
    });
  });
}
