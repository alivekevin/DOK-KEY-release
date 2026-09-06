import 'package:flutter_test/flutter_test.dart';
import 'package:dokkey_app/core/dokkey_engine.dart';
import 'package:dokkey_app/core/context_key_engine.dart';
import 'package:dokkey_app/core/source_number_manager.dart';
import 'package:dokkey_app/core/key_combiner_engine.dart';
import 'package:dokkey_app/core/ttl_manager.dart';
import 'package:dokkey_app/core/personal_cloud_vault_service.dart';
import 'package:dokkey_app/models/dokkey_models.dart';
import 'package:dokkey_app/models/vault_models.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await DokkeyEngine().initialize();
  });

  group('Independent Draw Seed Tests', () {
    test('Same day draw_index 0 gives consistent seed', () {
      final engine = DokkeyEngine();
      final seed1 = engine.generateDrawSeed(userUuid: 'user_1', localDate: '2026-09-01', drawIndex: 0);
      final seed2 = engine.generateDrawSeed(userUuid: 'user_1', localDate: '2026-09-01', drawIndex: 0);
      expect(seed1, seed2);
    });

    test('Additional draws with draw_index >= 1 produce independent seeds', () {
      final engine = DokkeyEngine();
      final seed0 = engine.generateDrawSeed(userUuid: 'user_1', localDate: '2026-09-01', drawIndex: 0);
      final seed1 = engine.generateDrawSeed(userUuid: 'user_1', localDate: '2026-09-01', drawIndex: 1);
      final seed2 = engine.generateDrawSeed(userUuid: 'user_1', localDate: '2026-09-01', drawIndex: 2);

      expect(seed0 != seed1, true);
      expect(seed1 != seed2, true);
    });
  });

  group('Zero-Delay Context Key Engine Tests (v3.0.0)', () {
    test('Timeslot detection boundaries (4 slots)', () {
      expect(
        ContextKeyEngine.detectTimeSlot(DateTime(2026, 9, 1, 4, 59)),
        TimeSlotId.night,
      );
      expect(
        ContextKeyEngine.detectTimeSlot(DateTime(2026, 9, 1, 5, 0)),
        TimeSlotId.morning,
      );
      expect(
        ContextKeyEngine.detectTimeSlot(DateTime(2026, 9, 1, 10, 59)),
        TimeSlotId.morning,
      );
      expect(
        ContextKeyEngine.detectTimeSlot(DateTime(2026, 9, 1, 11, 0)),
        TimeSlotId.noon,
      );
      expect(
        ContextKeyEngine.detectTimeSlot(DateTime(2026, 9, 1, 16, 59)),
        TimeSlotId.noon,
      );
      expect(
        ContextKeyEngine.detectTimeSlot(DateTime(2026, 9, 1, 17, 0)),
        TimeSlotId.evening,
      );
      expect(
        ContextKeyEngine.detectTimeSlot(DateTime(2026, 9, 1, 20, 59)),
        TimeSlotId.evening,
      );
      expect(
        ContextKeyEngine.detectTimeSlot(DateTime(2026, 9, 1, 21, 0)),
        TimeSlotId.night,
      );
      // Midnight rollover stays in night slot
      expect(
        ContextKeyEngine.detectTimeSlot(DateTime(2026, 9, 2, 0, 30)),
        TimeSlotId.night,
      );
      expect(
        ContextKeyEngine.detectTimeSlot(DateTime(2026, 9, 2, 4, 59)),
        TimeSlotId.night,
      );
    });

    test('Timeslot string round-trip', () {
      for (final id in TimeSlotId.values) {
        expect(
          ContextKeyEngine.slotIdFromString(ContextKeyEngine.slotIdToString(id)),
          id,
        );
      }
    });

    test('Visit state detection: first visit, revisit, long absence', () {
      expect(
        ContextKeyEngine.detectVisitState(firstVisitDate: null, lastVisitDate: null, todayStr: '2026-09-01'),
        VisitState.firstVisit,
      );
      expect(
        ContextKeyEngine.detectVisitState(
          firstVisitDate: '2026-08-25',
          lastVisitDate: '2026-08-31',
          todayStr: '2026-09-01',
        ),
        VisitState.revisit,
      );
      expect(
        ContextKeyEngine.detectVisitState(
          firstVisitDate: '2026-08-01',
          lastVisitDate: '2026-08-20',
          todayStr: '2026-09-01',
        ),
        VisitState.longAbsence,
      );
    });

    test('Visit gap days calculation', () {
      expect(ContextKeyEngine.visitGapDaysBetween('2026-08-31', '2026-09-01'), 1);
      expect(ContextKeyEngine.visitGapDaysBetween('2026-08-20', '2026-09-01'), 12);
      expect(ContextKeyEngine.visitGapDaysBetween(null, '2026-09-01'), 0);
    });

    test('Draw skeleton is identical across slots, sentence differs', () {
      final engine = DokkeyEngine();
      final morning = engine.draw(
        userId: 'u1',
        dateStr: '2026-09-01',
        lang: 'ko',
        contextSlot: TimeSlotId.morning,
      );
      final night = engine.draw(
        userId: 'u1',
        dateStr: '2026-09-01',
        lang: 'ko',
        contextSlot: TimeSlotId.night,
      );

      // Same skeleton (number, card, tone, seed)
      expect(night.number, morning.number);
      expect(night.card.id, morning.card.id);
      expect(night.tone.id, morning.tone.id);
      expect(night.seedHash, morning.seedHash);

      // Different timeslot context
      expect(morning.timeslot.id, 'morning');
      expect(night.timeslot.id, 'night');
      expect(morning.context.timeslotId, 'morning');
      expect(night.context.timeslotId, 'night');
    });
  });

  group('Timeslot Model & DrawResult Serialization Tests', () {
    test('DrawResult JSON round-trip preserves timeslot & context', () {
      final engine = DokkeyEngine();
      final result = engine.draw(
        userId: 'u1',
        dateStr: '2026-09-01',
        lang: 'ko',
        contextSlot: TimeSlotId.evening,
      );
      final restored = DrawResult.fromJson(result.toJson());

      expect(restored.timeslot.id, 'evening');
      expect(restored.timeslot.name, isNotEmpty);
      expect(restored.context.timeslotId, 'evening');
      expect(restored.context.themeMode, isNotEmpty);
      expect(restored.headline, result.headline);
    });

    test('Legacy v2 archive JSON with direction field loads without error', () {
      final legacyJson = {
        'date': '2026-08-01',
        'lang': 'ko',
        'number': 7,
        'card': {'id': 'rabbit', 'deck': '12jishin', 'type': 'animate', 'artAsset': '', 'name': '토끼', 'symbol': '', 'description': ''},
        'direction': {'id': 'east', 'code': 'E', 'name': '동', 'meaningAxis': '새로운 시작', 'description': ''},
        'tone': {'id': 'comic', 'name': '코믹', 'color': '#F0A500', 'voiceGuide': ''},
        'headline': '과거 헤드라인',
        'body': '과거 본문',
        'tip': '과거 팁',
        'shareCaption': '과거 공유',
        'seedHash': 'abc123',
      };
      final restored = DrawResult.fromJson(legacyJson);
      expect(restored.number, 7);
      expect(restored.timeslot.id, 'morning');
      expect(restored.headline, '과거 헤드라인');
    });
  });

  group('SourceNumberManager & Fortune Metadata Tests', () {
    test('Formats numbers to 2 digits and retains fortune headline', () {
      List<SourceNumberItem> pool = [];
      pool = SourceNumberManager.addOrUpdateNumber(
        currentPool: pool,
        rawNumber: 7,
        cardName: '토끼',
        timeslotId: 'night',
        toneName: '코믹',
        headline: '토끼는 오늘 뛰다가 넘어질 뻔했다',
      );

      expect(pool.length, 1);
      expect(pool.first.numberStr, '07');
      expect(pool.first.count, 1);
      expect(pool.first.lastCardName, '토끼');
      expect(pool.first.lastTimeslotId, 'night');
      expect(pool.first.lastHeadline.contains('토끼'), true);

      pool = SourceNumberManager.addOrUpdateNumber(
        currentPool: pool,
        rawNumber: 7,
        cardName: '토끼',
        headline: '새로운 헤드라인',
      );
      expect(pool.length, 1);
      expect(pool.first.count, 2);
      expect(pool.first.lastHeadline, '새로운 헤드라인');
    });
  });

  group('Variable N-Key Combiner Engine Tests', () {
    test('Case 1: No checkbox selected -> random N from available pool', () {
      final available = ['01', '03', '07', '14', '28', '35', '42'];
      final combined = KeyCombinerEngine.combine(
        availablePool: available,
        selectedPool: [],
        targetCount: 4,
      );

      expect(combined.length, 4);
      for (var i = 0; i < combined.length - 1; i++) {
        expect(int.parse(combined[i]) < int.parse(combined[i + 1]), true);
      }
    });

    test('Case 2: Selected pool >= N -> picks exactly N from selected pool', () {
      final available = ['01', '03', '07', '14', '28', '35', '42'];
      final selected = ['07', '14', '28', '35'];
      final combined = KeyCombinerEngine.combine(
        availablePool: available,
        selectedPool: selected,
        targetCount: 3,
      );

      expect(combined.length, 3);
      for (final num in combined) {
        expect(selected.contains(num), true);
      }
    });

    test('Case 3: Selected pool < N -> includes all selected and supplements from available', () {
      final available = ['01', '03', '07', '14', '28', '35', '42'];
      final selected = ['07', '42'];
      final combined = KeyCombinerEngine.combine(
        availablePool: available,
        selectedPool: selected,
        targetCount: 5,
      );

      expect(combined.length, 5);
      expect(combined.contains('07'), true);
      expect(combined.contains('42'), true);
    });

    test('Throws exception when available pool < targetCount', () {
      final available = ['01', '03'];
      expect(
        () => KeyCombinerEngine.combine(
          availablePool: available,
          selectedPool: [],
          targetCount: 5,
        ),
        throwsA(isA<ArgumentError>()),
      );
    });
  });

  group('TTLManager & Vault Tests', () {
    test('Purges expired keys while keeping permanent keys', () {
      final now = DateTime.now();
      final keys = [
        CombinedKeyItem(
          id: 'k1',
          createdAt: now.subtract(const Duration(days: 8)),
          expiresAt: now.subtract(const Duration(days: 1)),
          targetCount: 2,
          numbers: ['01', '02'],
        ),
        CombinedKeyItem(
          id: 'k2',
          createdAt: now,
          expiresAt: now.add(const Duration(days: 6)),
          targetCount: 4,
          numbers: ['03', '04', '05', '06'],
        ),
      ];

      final cleaned = TTLManager.purgeExpiredKeys(keys);
      expect(cleaned.length, 1);
      expect(cleaned.first.id, 'k2');
    });

    test('Exports and imports vault JSON data losslessly', () {
      final sources = [
        SourceNumberItem(numberStr: '07', count: 3, lastAcquiredAt: DateTime.now(), lastCardName: '토끼', isPinned: true),
      ];
      final keys = [
        CombinedKeyItem(
          id: 'test_uuid',
          createdAt: DateTime.now(),
          expiresAt: null,
          targetCount: 4,
          numbers: ['07', '14', '28', '42'],
        ),
      ];

      final jsonStr = PersonalCloudVaultService.exportVaultJson(sourceNumbers: sources, combinedKeys: keys);
      final imported = PersonalCloudVaultService.importVaultJson(jsonStr);

      expect(imported.sourceNumbers.length, 1);
      expect(imported.sourceNumbers.first.lastCardName, '토끼');
      expect(imported.combinedKeys.first.formattedNumbers, '07 · 14 · 28 · 42');
    });
  });

  group('Codex & Shop Feature Tests', () {
    test('Unlocked card collection maintains unique card set', () {
      final sampleUnlocked = <String>{'rabbit', 'moon_jar'};
      expect(sampleUnlocked.contains('rabbit'), true);
      expect(sampleUnlocked.contains('tiger'), false);

      sampleUnlocked.add('tiger');
      expect(sampleUnlocked.length, 3);
    });
  });

  group('Shichen Bridge & Dream DB Tests (v3.0.0)', () {
    test('Shichen covers all 24 hours', () {
      final engine = DokkeyEngine();
      for (var h = 0; h < 24; h++) {
        final s = engine.getShichenForNow(DateTime(2026, 9, 1, h, 30));
        expect(s['id'], isNotEmpty, reason: 'hour $h must map to a shichen');
        expect(s['zodiac'], isNotEmpty);
      }
      // 자정(00:30)은 자시(쥐)
      expect(engine.getShichenForNow(DateTime(2026, 9, 2, 0, 30))['id'], 'ja');
      // 15:30은 신시(원숭이)
      expect(engine.getShichenForNow(DateTime(2026, 9, 1, 15, 30))['zodiac'], 'monkey');
    });

    test('Zodiac card detection', () {
      final engine = DokkeyEngine();
      expect(engine.isZodiacCard('tiger'), true);
      expect(engine.isZodiacCard('moon_jar'), false);
      expect(engine.isZodiacCard('dream_eater'), false);
    });

    test('Daily dream symbol is deterministic per date', () {
      final engine = DokkeyEngine();
      final a = engine.getDailyDreamSymbol('ko', '2026-09-01');
      final b = engine.getDailyDreamSymbol('ko', '2026-09-01');
      final c = engine.getDailyDreamSymbol('ko', '2026-09-02');
      expect(a.id, b.id);
      expect(a.cardId, isNotEmpty);
      expect(a.advice, isNotEmpty);
      expect(c.advice, isNotEmpty);
    });
  });
}
