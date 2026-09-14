import 'dart:async';
import 'package:flutter/foundation.dart';
import '../core/timelab_sound_engine.dart';
import '../models/timelab_models.dart';

/// 💣 3단 시퀀스 체인 타이머 (The Defuser) 상태 관리 엔진
class ChainTimerEngine extends ChangeNotifier {
  TimelabTheme theme = TimelabTheme.cyberDefuser;

  // 3-Phase 시퀀스 슬롯 (1번 필수, 2번/3번 선택)
  final List<ChainStep> steps = [
    ChainStep(index: 1, duration: const Duration(seconds: 10), delayAfter: const Duration(seconds: 2)),
    ChainStep(index: 2, duration: const Duration(seconds: 5), delayAfter: const Duration(seconds: 1)),
    ChainStep(index: 3, duration: const Duration(seconds: 3), delayAfter: Duration.zero),
  ];

  // 활성화된 슬롯 개수 (1, 2, 또는 3)
  int activeSlotCount = 3;

  // 반복 루프 설정 (1 ~ 9 세트)
  int totalSets = 1;
  int currentSet = 1;

  // 런타임 제어 변수
  ChainTimerStatus status = ChainTimerStatus.idle;
  int currentStepIndex = 0; // 0, 1, 2 (steps 리스트 인덱스)
  Duration remainingTime = Duration.zero;
  Duration totalStepDuration = Duration.zero;
  Duration remainingDelay = Duration.zero;

  Timer? _ticker;
  DateTime? _lastTick;
  int _lastTickSecond = -1;

  final TimelabSoundEngine _sound = TimelabSoundEngine();

  ChainTimerEngine() {
    _resetToInitial();
  }

  void setTheme(TimelabTheme newTheme) {
    theme = newTheme;
    notifyListeners();
  }

  void setTotalSets(int sets) {
    totalSets = sets.clamp(1, 9);
    notifyListeners();
  }

  void setActiveSlotCount(int count) {
    activeSlotCount = count.clamp(1, 3);
    if (status == ChainTimerStatus.idle) {
      _resetToInitial();
    }
    notifyListeners();
  }

  void updateStepDuration(int stepIndex, Duration newDuration) {
    if (stepIndex >= 0 && stepIndex < steps.length) {
      steps[stepIndex].duration = newDuration;
      if (status == ChainTimerStatus.idle && currentStepIndex == stepIndex) {
        _resetToInitial();
      }
      notifyListeners();
    }
  }

  void updateStepDelay(int stepIndex, Duration newDelay) {
    if (stepIndex >= 0 && stepIndex < steps.length) {
      steps[stepIndex].delayAfter = newDelay;
      notifyListeners();
    }
  }

  void _resetToInitial() {
    currentSet = 1;
    currentStepIndex = 0;
    status = ChainTimerStatus.idle;
    totalStepDuration = steps[0].duration;
    remainingTime = steps[0].duration;
    remainingDelay = Duration.zero;
  }

  /// 전체 진행률 (0.0 ~ 1.0)
  double get currentStepProgress {
    if (totalStepDuration.inMilliseconds <= 0) return 0.0;
    return (remainingTime.inMilliseconds / totalStepDuration.inMilliseconds).clamp(0.0, 1.0);
  }

  /// 20% 이하 또는 크리티컬 상태인지 여부
  bool get isCritical {
    if (status == ChainTimerStatus.running) {
      if (theme == TimelabTheme.orbitalLaunch) {
        return remainingTime.inSeconds <= 10 && remainingTime > Duration.zero;
      }
      return currentStepProgress <= 0.20 && remainingTime > Duration.zero;
    }
    return false;
  }

  // --- 타이머 실행 제어 ---

  void startOrResume() {
    if (status == ChainTimerStatus.idle || status == ChainTimerStatus.finished) {
      currentSet = 1;
      currentStepIndex = 0;
      totalStepDuration = steps[0].duration;
      remainingTime = steps[0].duration;
      remainingDelay = Duration.zero;
      status = ChainTimerStatus.running;
    } else if (status == ChainTimerStatus.paused) {
      status = remainingDelay > Duration.zero ? ChainTimerStatus.delaying : ChainTimerStatus.running;
    }

    _lastTick = DateTime.now();
    _lastTickSecond = remainingTime.inSeconds;
    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(milliseconds: 20), _onTick);
    notifyListeners();
  }

  void pause() {
    if (status == ChainTimerStatus.running || status == ChainTimerStatus.delaying) {
      status = ChainTimerStatus.paused;
      _ticker?.cancel();
      notifyListeners();
    }
  }

  void reset() {
    _ticker?.cancel();
    _resetToInitial();
    notifyListeners();
  }

  void _onTick(Timer timer) {
    if (_lastTick == null) return;
    final now = DateTime.now();
    final elapsed = now.difference(_lastTick!);
    _lastTick = now;

    if (status == ChainTimerStatus.running) {
      remainingTime -= elapsed;

      // 1초 단위 틱 사운드 & 크리티컬 펄스
      final currentSec = remainingTime.inSeconds;
      if (currentSec != _lastTickSecond && remainingTime > Duration.zero) {
        _lastTickSecond = currentSec;
        if (isCritical) {
          _sound.playCriticalPulse(theme);
        } else {
          _sound.playTick(theme);
        }
      }

      if (remainingTime <= Duration.zero) {
        remainingTime = Duration.zero;
        _onStepCompleted();
      }
    } else if (status == ChainTimerStatus.delaying) {
      remainingDelay -= elapsed;
      if (remainingDelay <= Duration.zero) {
        remainingDelay = Duration.zero;
        _advanceToNextStep();
      }
    }

    notifyListeners();
  }

  void _onStepCompleted() {
    final currentStep = steps[currentStepIndex];
    _sound.playCustomOrPreset(
      soundId: currentStep.soundId,
      customFilePath: currentStep.customSoundPath,
      fallbackTheme: theme,
    );

    // 지연(Delay)이 설정되어 있으면 delaying 상태로 진입
    if (currentStep.delayAfter > Duration.zero) {
      status = ChainTimerStatus.delaying;
      remainingDelay = currentStep.delayAfter;
    } else {
      _advanceToNextStep();
    }
  }

  void _advanceToNextStep() {
    if (currentStepIndex + 1 < activeSlotCount) {
      // 다음 단계로 진입
      currentStepIndex++;
      totalStepDuration = steps[currentStepIndex].duration;
      remainingTime = steps[currentStepIndex].duration;
      remainingDelay = Duration.zero;
      _lastTickSecond = remainingTime.inSeconds;
      status = ChainTimerStatus.running;
    } else {
      // 1세트 완료: 루프 체크
      if (currentSet < totalSets) {
        currentSet++;
        currentStepIndex = 0;
        totalStepDuration = steps[0].duration;
        remainingTime = steps[0].duration;
        remainingDelay = Duration.zero;
        _lastTickSecond = remainingTime.inSeconds;
        status = ChainTimerStatus.running;
      } else {
        // 전체 세트 최종 완주 / 피날레
        status = ChainTimerStatus.finished;
        _ticker?.cancel();
        _sound.playFinale(theme);
      }
    }
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }
}
