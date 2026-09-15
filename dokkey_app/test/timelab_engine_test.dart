import 'package:flutter_test/flutter_test.dart';
import 'package:dokkey_app/timelab/models/timelab_models.dart';
import 'package:dokkey_app/timelab/core/timelab_i18n.dart';
import 'package:dokkey_app/timelab/core/timelab_theme_engine.dart';
import 'package:dokkey_app/timelab/chain_timer/chain_timer_engine.dart';
import 'package:dokkey_app/timelab/velocity_grid/velocity_grid_engine.dart';
import 'package:dokkey_app/timelab/tally_clicker/tally_clicker_engine.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Timelab Theme Engine Tests', () {
    test('3대 테마 프리셋 설정값 검증', () {
      final classic = TimelabThemeConfig.of(TimelabTheme.classicDigital);
      expect(classic.displayName, '클래식 디지털');
      expect(classic.primaryColor.toARGB32(), 0xFF00FF66);

      final cyber = TimelabThemeConfig.of(TimelabTheme.cyberDefuser);
      expect(cyber.displayName, '사이버 디퓨저');
      expect(cyber.primaryColor.toARGB32(), 0xFFFF0055);

      final orbital = TimelabThemeConfig.of(TimelabTheme.orbitalLaunch);
      expect(orbital.displayName, '우주 발사');
      expect(orbital.primaryColor.toARGB32(), 0xFF00E5FF);
    });

    test('잔여 시간에 따른 앰버/크리티컬 동적 컬러 전환 검증', () {
      final classic = TimelabThemeConfig.of(TimelabTheme.classicDigital);
      // 50% 진행 -> 초록 LCD
      expect(classic.getDynamicDisplayColor(progress: 0.5, remaining: const Duration(seconds: 30)), classic.primaryColor);
      // 10% 진행 -> 앰버 오렌지
      expect(classic.getDynamicDisplayColor(progress: 0.1, remaining: const Duration(seconds: 5)), classic.warningColor);

      final orbital = TimelabThemeConfig.of(TimelabTheme.orbitalLaunch);
      // 20초 남음 -> 사이언 블루
      expect(orbital.getDynamicDisplayColor(progress: 0.5, remaining: const Duration(seconds: 20)), orbital.primaryColor);
      // 8초 남음 -> 옐로 플래시
      expect(orbital.getDynamicDisplayColor(progress: 0.1, remaining: const Duration(seconds: 8)), orbital.warningColor);
    });
  });

  group('Chain Timer (The Defuser) Engine Tests', () {
    late ChainTimerEngine engine;

    setUp(() {
      engine = ChainTimerEngine();
    });

    tearDown(() {
      engine.dispose();
    });

    test('초기 상태 및 슬롯 제약 조건 검증', () {
      expect(engine.status, ChainTimerStatus.idle);
      expect(engine.activeSlotCount, 3);
      expect(engine.steps.length, 3);
      expect(engine.currentSet, 1);
      expect(engine.totalSets, 1);
    });

    test('슬롯 활성화 개수 및 세트 수 변경 검증', () {
      engine.setActiveSlotCount(2);
      expect(engine.activeSlotCount, 2);

      engine.setTotalSets(5);
      expect(engine.totalSets, 5);

      // 최대 9세트 제한
      engine.setTotalSets(12);
      expect(engine.totalSets, 9);
    });

    test('타이머 시작, 일시정지, 리셋 상태 전이', () {
      engine.startOrResume();
      expect(engine.status, ChainTimerStatus.running);

      engine.pause();
      expect(engine.status, ChainTimerStatus.paused);

      engine.reset();
      expect(engine.status, ChainTimerStatus.idle);
      expect(engine.currentStepIndex, 0);
    });

    test('ChainStep 커스텀 사운드 및 지연시간(Delay) 설정 & 직렬화 검증', () {
      engine.updateStepDuration(0, const Duration(seconds: 15));
      engine.updateStepDelay(0, const Duration(seconds: 3));
      engine.steps[0].soundId = 'custom';
      engine.steps[0].customSoundPath = '/storage/emulated/0/Music/quiet_song.mp3';
      engine.steps[0].customSoundName = 'quiet_song.mp3';

      expect(engine.steps[0].duration.inSeconds, 15);
      expect(engine.steps[0].delayAfter.inSeconds, 3);
      expect(engine.steps[0].soundDisplayName('ko'), '📁 quiet_song.mp3');
      expect(engine.steps[0].soundDisplayName('en'), '📁 quiet_song.mp3', reason: '커스텀 파일명은 언어 무관');

      final json = engine.steps[0].toJson();
      final restored = ChainStep.fromJson(json);
      expect(restored.duration.inSeconds, 15);
      expect(restored.delayAfter.inSeconds, 3);
      expect(restored.customSoundPath, '/storage/emulated/0/Music/quiet_song.mp3');
      expect(restored.customSoundName, 'quiet_song.mp3');
    });

    test('오디오 재생 상태(audioPlaying) 전환 및 스킵(skipAudioOrDelay) 동작 검증', () {
      engine.setActiveSlotCount(2);
      engine.updateStepDuration(0, const Duration(seconds: 10));
      engine.updateStepDelay(0, const Duration(seconds: 2));

      engine.startOrResume();
      expect(engine.status, ChainTimerStatus.running);

      // 타이머 완료 시뮬레이션: audioPlaying 상태 진입
      engine.status = ChainTimerStatus.audioPlaying;

      // 스킵 호출 시 지연 대기(delaying)로 전환
      engine.skipAudioOrDelay();
      expect(engine.status, ChainTimerStatus.delaying);
      expect(engine.remainingDelay.inSeconds, 2);

      // 딜레이 중 스킵 호출 시 2단계로 즉시 전환
      engine.skipAudioOrDelay();
      expect(engine.status, ChainTimerStatus.running);
      expect(engine.currentStepIndex, 1);
    });
  });

  group('Velocity Grid Stopwatch Engine Tests', () {
    late VelocityGridEngine gridEngine;

    setUp(() {
      gridEngine = VelocityGridEngine();
    });

    tearDown(() {
      gridEngine.dispose();
    });

    test('주자 인원수 변경 (1~9인) 및 초기화 검증', () {
      gridEngine.setLaneCount(6);
      expect(gridEngine.lanes.length, 6);
      expect(gridEngine.laneCount, 6);

      gridEngine.setLaneCount(9);
      expect(gridEngine.lanes.length, 9);
      expect(gridEngine.laneCount, 9);
    });

    test('동시 시작 및 주자별 순차 터치 완주 / 랭킹 부여 검증', () {
      gridEngine.setLaneCount(3);
      gridEngine.start();
      expect(gridEngine.isRunning, true);

      // 2번 주자 먼저 터치 -> 1위
      gridEngine.recordRunnerFinish(1);
      expect(gridEngine.lanes[1].isFinished, true);
      expect(gridEngine.lanes[1].rank, 1);
      expect(gridEngine.lanes[1].lapTime, isNotNull);

      // 0번 주자 터치 -> 2위
      gridEngine.recordRunnerFinish(0);
      expect(gridEngine.lanes[0].isFinished, true);
      expect(gridEngine.lanes[0].rank, 2);

      expect(gridEngine.allFinished, false);

      // 2번 주자 터치 -> 3위 및 전원 완주
      gridEngine.recordRunnerFinish(2);
      expect(gridEngine.lanes[2].isFinished, true);
      expect(gridEngine.lanes[2].rank, 3);
      expect(gridEngine.allFinished, true);
      expect(gridEngine.isRunning, false);
    });

    test('VelocityRecord 영구 저장 및 삭제 기능 검증', () async {
      gridEngine.setLaneCount(2);
      gridEngine.start();
      gridEngine.recordRunnerFinish(0);
      gridEngine.recordRunnerFinish(1);

      final record = await gridEngine.saveCurrentRecord('결승전 테스트');
      expect(gridEngine.savedRecords.length, 1);
      expect(gridEngine.savedRecords.first.title, '결승전 테스트');
      expect(gridEngine.savedRecords.first.laneCount, 2);
      expect(gridEngine.savedRecords.first.results.length, 2);

      // JSON 직렬화 & 역직렬화
      final json = record.toJson();
      final restored = VelocityRecord.fromJson(json);
      expect(restored.title, '결승전 테스트');
      expect(restored.results.first.rank, 1);

      // 삭제
      await gridEngine.deleteRecord(record.id);
      expect(gridEngine.savedRecords.isEmpty, true);
    });

    test('6개국어 현지화: 러너 이름·기본 기록 제목·순위 라벨 검증', () async {
      final koEngine = VelocityGridEngine(lang: 'ko');
      final enEngine = VelocityGridEngine(lang: 'en');

      expect(koEngine.lanes.first.name, '주자 1');
      expect(enEngine.lanes.first.name, 'Runner 1');

      final koRecord = await koEngine.saveCurrentRecord('');
      expect(koRecord.title, '스톱워치 기록 (${koEngine.laneCount}인)');
      final enRecord = await enEngine.saveCurrentRecord('');
      expect(enRecord.title.contains('Stopwatch Record'), true);

      expect(TimelabI18n.rankLabel('ko', 1), '🥇 1위');
      expect(TimelabI18n.rankLabel('en', 1), '🥇 1st');
      expect(TimelabI18n.rankLabel('ja', 2), '🥈 2位');
      expect(TimelabI18n.rankLabel('zh', 3), '🥉 第3名');
      expect(TimelabI18n.rankLabel('de', 4), '4.', reason: '독일어 서수 표기는 4.');
      expect(TimelabI18n.rankLabel('hi', 5), '#5');

      // 테마 이름 현지화 (displayName은 레거시 폴백, localizedName이 실제 경로)
      expect(TimelabThemeConfig.of(TimelabTheme.classicDigital).localizedName('en'), 'Classic Digital');
      expect(TimelabThemeConfig.of(TimelabTheme.cyberDefuser).localizedName('zh'), '赛博拆弹雷达');
      expect(TimelabThemeConfig.of(TimelabTheme.orbitalLaunch).localizedName('hi'), 'कक्षीय प्रक्षेपण');

      // 사운드 프리셋 이름 6개국어
      expect(ChainStep(index: 0, duration: const Duration(seconds: 5)).soundDisplayName('en'), '⚡ Theme default SFX');
      expect(ChainStep(index: 0, duration: const Duration(seconds: 5), soundId: 'magic').soundDisplayName('ko'), '🪄 도깨비 방망이 마법');
      expect(ChainStep(index: 0, duration: const Duration(seconds: 5), soundId: 'gate').soundDisplayName('ja'), '🚪 重厚な鉄門開放');

      await koEngine.deleteRecord(koRecord.id);
      await enEngine.deleteRecord(enRecord.id);
      koEngine.dispose();
      enEngine.dispose();
    });
  });

  group('Tally Clicker Engine Tests', () {
    late TallyClickerEngine clickerEngine;

    setUp(() {
      clickerEngine = TallyClickerEngine();
    });

    test('기본값 및 증가(+1), 감소(-1), 리셋(0) 검증', () {
      clickerEngine.reset();
      expect(clickerEngine.count, 0);

      clickerEngine.increment();
      clickerEngine.increment();
      clickerEngine.increment();
      expect(clickerEngine.count, 3);

      clickerEngine.decrement();
      expect(clickerEngine.count, 2);

      clickerEngine.reset();
      expect(clickerEngine.count, 0);

      // 0 이하로는 감소되지 않음
      clickerEngine.decrement();
      expect(clickerEngine.count, 0);
    });

    test('목표 수치(Target) 설정 및 달성(Target Reached) 검증', () {
      clickerEngine.reset();
      clickerEngine.setTargetCount(5);
      expect(clickerEngine.targetCount, 5);
      expect(clickerEngine.progressToTarget, 0.0);

      clickerEngine.increment(); // 1
      clickerEngine.increment(); // 2
      expect(clickerEngine.progressToTarget, 0.4);

      clickerEngine.increment(); // 3
      clickerEngine.increment(); // 4
      clickerEngine.increment(); // 5
      expect(clickerEngine.count, 5);
      expect(clickerEngine.progressToTarget, 1.0);
      expect(clickerEngine.isTargetReached, true);
    });

    test('10단위 및 100단위 마일스톤 트리거 검증', () {
      clickerEngine.reset();
      clickerEngine.setTargetCount(null); // 목표치 해제

      for (int i = 0; i < 9; i++) {
        clickerEngine.increment();
      }
      expect(clickerEngine.count, 9);
      expect(clickerEngine.isMilestone10, false);

      clickerEngine.increment(); // 10
      expect(clickerEngine.count, 10);
      expect(clickerEngine.isMilestone10, true);

      // 100까지 증가 시뮬레이션
      for (int i = 11; i <= 100; i++) {
        clickerEngine.increment();
      }
      expect(clickerEngine.count, 100);
      expect(clickerEngine.isMilestone100, true);
    });
  });

  group('Duration Formatter & Hold-to-Repeat Tests', () {
    test('스마트 시간 포맷팅 formatDurationHuman 6개국어 및 분/시간 변환 검증', () {
      // 1. 60초 미만 (초 단위)
      expect(TimelabI18n.formatDurationHuman('ko', 45), '45초');
      expect(TimelabI18n.formatDurationHuman('en', 45), '45s');

      // 2. 분 단위 (정수 분)
      expect(TimelabI18n.formatDurationHuman('ko', 1800), '30분');
      expect(TimelabI18n.formatDurationHuman('en', 1800), '30m');
      expect(TimelabI18n.formatDurationHuman('ja', 1800), '30分');

      // 3. 분 + 초 복합
      expect(TimelabI18n.formatDurationHuman('ko', 1845), '30분 45초');
      expect(TimelabI18n.formatDurationHuman('en', 1845), '30m 45s');

      // 4. 시간 단위 (정수 시간)
      expect(TimelabI18n.formatDurationHuman('ko', 3600), '1시간');
      expect(TimelabI18n.formatDurationHuman('en', 3600), '1h');
      expect(TimelabI18n.formatDurationHuman('zh', 3600), '1小时');

      // 5. 시간 + 분 복합
      expect(TimelabI18n.formatDurationHuman('ko', 5400), '1시간 30분');
      expect(TimelabI18n.formatDurationHuman('en', 5400), '1h 30m');
    });
  });

  group('Chain Timer Routine Preset & Custom Routine Tests', () {
    test('빌트인 6종 프리셋 규격 및 6개국어 타이틀/설명 검증', () {
      expect(builtinRoutinePresets.length, 6);

      final langs = ['ko', 'en', 'ja', 'zh', 'de', 'hi'];

      for (final preset in builtinRoutinePresets) {
        expect(preset.id.isNotEmpty, true);
        expect(preset.icon.isNotEmpty, true);
        expect(preset.activeSlots >= 1 && preset.activeSlots <= 3, true);
        expect(preset.totalSets >= 1 && preset.totalSets <= 9, true);

        for (final lang in langs) {
          final title = preset.localizedTitle(lang);
          final desc = preset.localizedDesc(lang);
          expect(title.isNotEmpty, true);
          expect(desc.isNotEmpty, true);
        }
      }
    });

    test('포모도로 프리셋 적용 시 2단계/4세트 및 25분/5분 설정 검증', () {
      final engine = ChainTimerEngine();
      final pomodoro = builtinRoutinePresets.firstWhere((p) => p.id == 'pomodoro');

      engine.applyRoutinePreset(pomodoro);

      expect(engine.activeSlotCount, 2);
      expect(engine.totalSets, 4);
      expect(engine.steps[0].duration, const Duration(minutes: 25));
      expect(engine.steps[1].duration, const Duration(minutes: 5));
      expect(engine.status, ChainTimerStatus.idle);
      expect(engine.remainingTime, const Duration(minutes: 25));

      engine.dispose();
    });

    test('타바타 프리셋 적용 시 2단계/8세트 및 20초/10초 설정 검증', () {
      final engine = ChainTimerEngine();
      final tabata = builtinRoutinePresets.firstWhere((p) => p.id == 'tabata');

      engine.applyRoutinePreset(tabata);

      expect(engine.activeSlotCount, 2);
      expect(engine.totalSets, 8);
      expect(engine.steps[0].duration, const Duration(seconds: 20));
      expect(engine.steps[1].duration, const Duration(seconds: 10));

      engine.dispose();
    });

    test('커스텀 루틴 모델 JSON 직렬화 및 역직렬화 무결성 검증', () {
      final custom = ChainRoutinePreset(
        id: 'cr_test_123',
        icon: '🧘',
        customName: '저녁 요가 루틴',
        activeSlots: 2,
        totalSets: 3,
        steps: [
          ChainStep(index: 1, duration: const Duration(minutes: 10), delayAfter: const Duration(seconds: 5)),
          ChainStep(index: 2, duration: const Duration(minutes: 2), delayAfter: Duration.zero),
          ChainStep(index: 3, duration: const Duration(seconds: 3)),
        ],
      );

      final json = custom.toJson();
      final restored = ChainRoutinePreset.fromJson(json);

      expect(restored.id, 'cr_test_123');
      expect(restored.icon, '🧘');
      expect(restored.customName, '저녁 요가 루틴');
      expect(restored.activeSlots, 2);
      expect(restored.totalSets, 3);
      expect(restored.steps[0].duration.inMinutes, 10);
      expect(restored.steps[0].delayAfter.inSeconds, 5);
      expect(restored.steps[1].duration.inMinutes, 2);
    });

    test('타이머 사운드 정책 기본값 및 프리셋 연계 검증', () {
      final engine = ChainTimerEngine();

      // 1) 기본값: 초음 비활성화(false), 3초 전 카운트다운 활성화(true)
      expect(engine.enableTicking, isFalse, reason: '기본값은 무음(소리 없음)이어야 함');
      expect(engine.enableCountdownBeep, isTrue, reason: '기본값은 3초 전 카운트다운 활성화이어야 함');

      // 2) 포모도로 적용 시: 초음 OFF, 카운트다운 OFF (완전 몰입 무소음)
      final pomodoro = builtinRoutinePresets.firstWhere((p) => p.id == 'pomodoro');
      engine.applyRoutinePreset(pomodoro);
      expect(engine.enableTicking, isFalse);
      expect(engine.enableCountdownBeep, isFalse);

      // 3) 디퓨저 적용 시: 초음 ON, 카운트다운 ON (긴장감 유지)
      final defuser = builtinRoutinePresets.firstWhere((p) => p.id == 'defuser');
      engine.applyRoutinePreset(defuser);
      expect(engine.enableTicking, isTrue);
      expect(engine.enableCountdownBeep, isTrue);

      // 4) 커스텀 사운드 설정 직렬화 및 복원 검증
      final custom = ChainRoutinePreset(
        id: 'cr_sound_test',
        icon: '🥊',
        customName: '스파링 루틴',
        activeSlots: 2,
        totalSets: 3,
        enableTicking: false,
        enableCountdownBeep: true,
        steps: [
          ChainStep(index: 1, duration: const Duration(minutes: 3)),
          ChainStep(index: 2, duration: const Duration(minutes: 1)),
          ChainStep(index: 3, duration: const Duration(seconds: 3)),
        ],
      );
      final restored = ChainRoutinePreset.fromJson(custom.toJson());
      expect(restored.enableTicking, isFalse);
      expect(restored.enableCountdownBeep, isTrue);

      engine.dispose();
    });
  });
}


