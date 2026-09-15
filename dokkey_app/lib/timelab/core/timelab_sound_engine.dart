import 'dart:async';
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

  /// 2.1 종료 직전 3초(3, 2, 1초) 카운트다운 비프 & 햅틱
  void playCountdownBeep(int second) {
    _sound.playCardFlip();
    if (second == 1) {
      HapticFeedback.heavyImpact();
    } else {
      HapticFeedback.mediumImpact();
    }
  }

  StreamSubscription? _completeSub;

  /// 🛡️ 재생 시퀀스 번호 — 프리셋 SFX 지연 콜백이 이전 재생에 속하면 무시 (경합 방지)
  int _playSeq = 0;

  /// 3. 커스텀 파일 또는 지정된 SFX 프리셋 재생 (완료 시 onComplete 콜백 트리거)
  Future<void> playCustomOrPreset({
    String? soundId,
    String? customFilePath,
    Uint8List? customSoundBytes,
    required TimelabTheme fallbackTheme,
    VoidCallback? onComplete,
  }) async {
    _completeSub?.cancel();
    final seq = ++_playSeq;
    final guardedComplete = onComplete == null
        ? null
        : () {
            if (seq == _playSeq) onComplete();
          };

    // 1) 커스텀 오디오 바이트 데이터 (Web 및 모든 플랫폼 100% 호환)
    if (customSoundBytes != null && customSoundBytes.isNotEmpty) {
      try {
        await _player.stop();

        if (guardedComplete != null) {
          _completeSub = _player.onPlayerComplete.listen((_) {
            _completeSub?.cancel();
            guardedComplete();
          });
        }

        await _player.play(BytesSource(customSoundBytes));
        HapticFeedback.heavyImpact();
        return;
      } catch (e) {
        debugPrint('Failed to play custom sound bytes: $e');
      }
    }

    // 2) 휴대폰 로컬 파일 경로 (모바일 / 데스크톱)
    if (customFilePath != null && customFilePath.isNotEmpty) {
      try {
        if (!kIsWeb && File(customFilePath).existsSync()) {
          await _player.stop();

          if (guardedComplete != null) {
          _completeSub = _player.onPlayerComplete.listen((_) {
            _completeSub?.cancel();
            guardedComplete();
            });
          }

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
        _scheduleSfxCompletion(const Duration(milliseconds: 1800), guardedComplete);
        return;
      case 'blast':
        _sound.playGong();
        HapticFeedback.heavyImpact();
        _scheduleSfxCompletion(const Duration(milliseconds: 2200), guardedComplete);
        return;
      case 'buzzer':
        _sound.playRiddleWrong();
        HapticFeedback.mediumImpact();
        _scheduleSfxCompletion(const Duration(milliseconds: 1400), guardedComplete);
        return;
      case 'beep':
        _sound.playSuccessChime();
        HapticFeedback.selectionClick();
        _scheduleSfxCompletion(const Duration(milliseconds: 1200), guardedComplete);
        return;
      case 'gong':
        _sound.playGong();
        HapticFeedback.heavyImpact();
        _scheduleSfxCompletion(const Duration(milliseconds: 2000), guardedComplete);
        return;
      case 'magic':
        _sound.playKkaebiCastShort();
        HapticFeedback.heavyImpact();
        _scheduleSfxCompletion(const Duration(milliseconds: 1600), guardedComplete);
        return;
    }

    // 3) 폴백: 테마별 기본 단계 완료 사운드
    playStepComplete(fallbackTheme);
    _scheduleSfxCompletion(const Duration(milliseconds: 1500), guardedComplete);
  }

  void _scheduleSfxCompletion(Duration duration, VoidCallback? onComplete) {
    if (onComplete != null) {
      Future.delayed(duration, () {
        onComplete();
      });
    }
  }

  /// 재생 중인 커스텀 오디오 즉시 중단
  Future<void> stopCustomAudio() async {
    _completeSub?.cancel();
    try {
      await _player.stop();
    } catch (_) {}
  }

  /// 커스텀 오디오 일시 정지
  Future<void> pauseCustomAudio() async {
    try {
      await _player.pause();
    } catch (_) {}
  }

  /// 커스텀 오디오 이어서 재생
  Future<void> resumeCustomAudio() async {
    try {
      await _player.resume();
    } catch (_) {}
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
