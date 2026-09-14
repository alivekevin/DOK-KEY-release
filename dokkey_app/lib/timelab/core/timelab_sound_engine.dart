import 'dart:io';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import '../../core/sound_service.dart';
import '../models/timelab_models.dart';

/// 🔊 시네마틱 타임 랩 전용 SFX, 햅틱 및 커스텀 오디오 파일 재생 엔진
class TimelabSoundEngine {
  static final TimelabSoundEngine _instance = TimelabSoundEngine._internal();
  factory TimelabSoundEngine() => _instance;
  TimelabSoundEngine._internal();

  final SoundService _sound = SoundService();
  AudioPlayer? _customPlayer;

  AudioPlayer get _player {
    _customPlayer ??= AudioPlayer();
    return _customPlayer!;
  }

  /// 1. 테마별 틱(Tick) 사운드 & 미세 햅틱
  void playTick(TimelabTheme theme) {
    switch (theme) {
      case TimelabTheme.classicDigital:
        _sound.playCardFlip();
        HapticFeedback.selectionClick();
        break;
      case TimelabTheme.cyberDefuser:
        _sound.playUnlock();
        HapticFeedback.lightImpact();
        break;
      case TimelabTheme.orbitalLaunch:
        _sound.playSuccessChime();
        HapticFeedback.selectionClick();
        break;
    }
  }

  /// 2. 위기 구간(20% 이하 / 심장박동 / 점화 10초 전) 사운드 & 햅틱
  void playCriticalPulse(TimelabTheme theme) {
    switch (theme) {
      case TimelabTheme.classicDigital:
        HapticFeedback.mediumImpact();
        break;
      case TimelabTheme.cyberDefuser:
        _sound.playRiddleWrong();
        HapticFeedback.heavyImpact();
        break;
      case TimelabTheme.orbitalLaunch:
        _sound.playSuccessChime();
        HapticFeedback.mediumImpact();
        break;
    }
  }

  /// 3. 커스텀 파일 또는 지정된 SFX 프리셋 재생 (미지정 시 테마 기본음 폴백)
  Future<void> playCustomOrPreset({
    String? soundId,
    String? customFilePath,
    required TimelabTheme fallbackTheme,
  }) async {
    // 1) 휴대폰 내 커스텀 오디오 파일 (.mp3, .wav, .m4a 등)이 등록된 경우
    if (customFilePath != null && customFilePath.isNotEmpty) {
      try {
        if (!kIsWeb && File(customFilePath).existsSync()) {
          await _player.stop();
          await _player.play(DeviceFileSource(customFilePath));
          HapticFeedback.heavyImpact();
          return;
        }
      } catch (e) {
        debugPrint('Failed to play custom file: $e');
      }
    }

    // 2) 내장 프리셋 SFX 라이브러리 선택인 경우
    switch (soundId) {
      case 'gate':
        _sound.playBoxOpen();
        HapticFeedback.heavyImpact();
        return;
      case 'blast':
        _sound.playGong();
        HapticFeedback.heavyImpact();
        return;
      case 'buzzer':
        _sound.playRiddleWrong();
        HapticFeedback.mediumImpact();
        return;
      case 'beep':
        _sound.playSuccessChime();
        HapticFeedback.selectionClick();
        return;
      case 'gong':
        _sound.playGong();
        HapticFeedback.heavyImpact();
        return;
      case 'magic':
        _sound.playKkaebiCastShort();
        HapticFeedback.heavyImpact();
        return;
    }

    // 3) 폴백: 테마별 기본 단계 완료 사운드
    playStepComplete(fallbackTheme);
  }

  /// 4. 타이머 단계 기본 완료 SFX
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

  /// 5. 전체 시퀀스 완주 / 피날레 SFX
  void playFinale(TimelabTheme theme) {
    switch (theme) {
      case TimelabTheme.classicDigital:
        _sound.playAlchemyFanfare();
        HapticFeedback.heavyImpact();
        break;
      case TimelabTheme.cyberDefuser:
        _sound.playGong();
        HapticFeedback.heavyImpact();
        Future.delayed(const Duration(milliseconds: 180), () {
          HapticFeedback.heavyImpact();
          _sound.playGayageum();
        });
        break;
      case TimelabTheme.orbitalLaunch:
        _sound.playAlchemyFanfare();
        _sound.playSuccessChime();
        HapticFeedback.heavyImpact();
        break;
    }
  }

  /// 6. 스톱워치 주자 터치 기록 (Lap Lock)
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
