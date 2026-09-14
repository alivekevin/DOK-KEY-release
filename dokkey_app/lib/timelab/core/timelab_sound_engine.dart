import 'package:flutter/services.dart';
import '../../core/sound_service.dart';
import '../models/timelab_models.dart';

/// 🔊 시네마틱 타임 랩 전용 SFX & 햅틱 사운드 엔진
class TimelabSoundEngine {
  static final TimelabSoundEngine _instance = TimelabSoundEngine._internal();
  factory TimelabSoundEngine() => _instance;
  TimelabSoundEngine._internal();

  final SoundService _sound = SoundService();

  /// 1. 테마별 틱(Tick) 사운드 & 미세 햅틱
  void playTick(TimelabTheme theme) {
    switch (theme) {
      case TimelabTheme.classicDigital:
        // 기계식 릴레이 틱
        _sound.playCardFlip();
        HapticFeedback.selectionClick();
        break;
      case TimelabTheme.cyberDefuser:
        // 전자 펄스 틱
        _sound.playUnlock();
        HapticFeedback.lightImpact();
        break;
      case TimelabTheme.orbitalLaunch:
        // 관제탑 비프 틱
        _sound.playSuccessChime();
        HapticFeedback.selectionClick();
        break;
    }
  }

  /// 2. 위기 구간(20% 이하 / 심장박동 / 점화 10초 전) 사운드
  void playCriticalPulse(TimelabTheme theme) {
    switch (theme) {
      case TimelabTheme.classicDigital:
        HapticFeedback.mediumImpact();
        break;
      case TimelabTheme.cyberDefuser:
        // 쿵-쿵 심장박동 펄스
        _sound.playRiddleWrong();
        HapticFeedback.heavyImpact();
        break;
      case TimelabTheme.orbitalLaunch:
        // 경고 비프음
        _sound.playSuccessChime();
        HapticFeedback.mediumImpact();
        break;
    }
  }

  /// 3. 타이머 단계 완료 / 지연 전환 SFX
  void playStepComplete(TimelabTheme theme) {
    switch (theme) {
      case TimelabTheme.classicDigital:
        _sound.playSuccessChime();
        HapticFeedback.mediumImpact();
        break;
      case TimelabTheme.cyberDefuser:
        _sound.playRiddleCorrect();
        HapticFeedback.heavyImpact();
        break;
      case TimelabTheme.orbitalLaunch:
        _sound.playCoinJangle();
        HapticFeedback.heavyImpact();
        break;
    }
  }

  /// 4. 전체 시퀀스 완주 / 폭발 / 로켓 발사 피날레 SFX
  void playFinale(TimelabTheme theme) {
    switch (theme) {
      case TimelabTheme.classicDigital:
        _sound.playAlchemyFanfare();
        HapticFeedback.heavyImpact();
        break;
      case TimelabTheme.cyberDefuser:
        // 고출력 폭발음
        _sound.playGong();
        HapticFeedback.heavyImpact();
        Future.delayed(const Duration(milliseconds: 180), () {
          HapticFeedback.heavyImpact();
          _sound.playGayageum();
        });
        break;
      case TimelabTheme.orbitalLaunch:
        // 로켓 부스터 점화 & 궤도 진입 팡파레
        _sound.playAlchemyFanfare();
        _sound.playSuccessChime();
        HapticFeedback.heavyImpact();
        break;
    }
  }

  /// 5. 스톱워치 주자 터치 기록 (Lap Lock)
  void playLapLock(int rank) {
    if (rank == 1) {
      _sound.playCoinJangle();
      HapticFeedback.heavyImpact();
    } else {
      _sound.playUnlock();
      HapticFeedback.lightImpact();
    }
  }
}
