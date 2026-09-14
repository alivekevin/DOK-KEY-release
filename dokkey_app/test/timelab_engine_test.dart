import 'package:flutter_test/flutter_test.dart';
import 'package:dokkey_app/timelab/models/timelab_models.dart';
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
      expect(classic.primaryColor.value, 0xFF00FF66);

      final cyber = TimelabThemeConfig.of(TimelabTheme.cyberDefuser);
      expect(cyber.displayName, '사이버 디퓨저');
      expect(cyber.primaryColor.value, 0xFFFF0055);

      final orbital = TimelabThemeConfig.of(TimelabTheme.orbitalLaunch);
      expect(orbital.displayName, '우주 발사');
      expect(orbital.primaryColor.value, 0xFF00E5FF);
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
      expect(engine.steps[0].soundDisplayName, '📁 quiet_song.mp3');

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
}
