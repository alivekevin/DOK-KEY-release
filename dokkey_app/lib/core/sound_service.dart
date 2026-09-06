import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// SoundScape Service (v3.0.0)
/// 실제 합성 SFX 파일 + 앰비언스 BGM + 타이밍 햅틱 + 웹 Autoplay/Vibrate 안전 처리
class SoundService {
  static final SoundService _instance = SoundService._internal();
  factory SoundService() => _instance;
  SoundService._internal();

  bool _soundEnabled = true;
  bool _initialized = false;
  final Map<String, AudioPlayer> _players = {};
  AudioPlayer? _ambientPlayer;
  bool _ambientStarted = false;

  bool get soundEnabled => _soundEnabled;

  /// 앱 시작 시 저장된 설정으로 복원 (첫 프레임 이전)
  Future<void> initialize() async {
    if (_initialized) return;
    final prefs = await SharedPreferences.getInstance();
    _soundEnabled = prefs.getBool('pref_sound_enabled') ?? true;
    _initialized = true;
  }

  Future<void> toggleSound() async {
    _soundEnabled = !_soundEnabled;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('pref_sound_enabled', _soundEnabled);
    if (!_soundEnabled) {
      await stopAmbient();
    } else {
      await startAmbient();
    }
  }

  AudioPlayer _playerFor(String key) {
    return _players.putIfAbsent(key, () => AudioPlayer());
  }

  void _safeHaptic(VoidCallback hapticCall) {
    if (kIsWeb) return; // 웹 브라우저에서는 사용자 제스처 전 navigator.vibrate 경고 방지
    try {
      hapticCall();
    } catch (_) {}
  }

  Future<void> _playAsset(String key, String asset, {double volume = 1.0}) async {
    if (!_soundEnabled) return;
    try {
      final player = _playerFor(key);
      await player.stop();
      await player.setVolume(volume);
      await player.play(AssetSource('audio/$asset'));
    } catch (e) {
      // 웹 브라우저 Autoplay 차단 등의 상황에서는 조용히 무시
      debugPrint('SFX $asset skipped: $e');
    }
  }

  /// 앰비언스 BGM (도깨비불 밤 분위기 루프)
  Future<void> startAmbient() async {
    if (!_soundEnabled || _ambientStarted) return;
    try {
      _ambientPlayer ??= AudioPlayer();
      await _ambientPlayer!.setReleaseMode(ReleaseMode.loop);
      await _ambientPlayer!.setVolume(0.10);
      await _ambientPlayer!.play(AssetSource('audio/ambient_night.wav'));
      _ambientStarted = true;
    } catch (e) {
      debugPrint('Ambient start skipped: $e');
    }
  }

  Future<void> stopAmbient() async {
    try {
      await _ambientPlayer?.stop();
      _ambientStarted = false;
    } catch (_) {}
  }

  /// 1. Key Turn: Heavy mechanical key clank & Heavy Haptic
  Future<void> playKeyTurn() async {
    _safeHaptic(() => HapticFeedback.heavyImpact());
    await _playAsset('key_turn', 'key_turn.wav');
  }

  /// 2. Card Flip: Whoosh wind flutter & Medium Haptic
  Future<void> playCardFlip() async {
    _safeHaptic(() => HapticFeedback.mediumImpact());
    await _playAsset('card_flip', 'card_flip.wav');
  }

  /// 3. Success Chime: Clear wind-chime bell & Selection Haptic
  Future<void> playSuccessChime() async {
    _safeHaptic(() => HapticFeedback.selectionClick());
    await _playAsset('chime', 'chime.wav');
  }

  /// 4. Riddle Correct: Cheerful rewarding chime & Heavy Haptic
  Future<void> playRiddleCorrect() async {
    _safeHaptic(() => HapticFeedback.heavyImpact());
    await _playAsset('riddle_correct', 'riddle_correct.wav');
  }

  /// 5. Riddle Wrong: Soft thud & Light Haptic
  Future<void> playRiddleWrong() async {
    _safeHaptic(() => HapticFeedback.lightImpact());
    await _playAsset('riddle_wrong', 'riddle_wrong.wav');
  }

  /// 6. Treasure Box Open: creak & pop
  Future<void> playBoxOpen() async {
    _safeHaptic(() => HapticFeedback.mediumImpact());
    await _playAsset('box_open', 'box_open.wav');
  }

  /// 7. Unlock (draw reveal): double click
  Future<void> playUnlock() async {
    _safeHaptic(() => HapticFeedback.mediumImpact());
    await _playAsset('unlock', 'unlock.wav');
  }

  /// 8. Ink Splash (card reveal effect)
  Future<void> playInkSplash() async {
    await _playAsset('ink_splash', 'ink_splash.wav', volume: 0.8);
  }

  /// 9. Coin Jangle (엽전 짤랑 — 열쇠 연성/숫자 획득)
  Future<void> playCoinJangle() async {
    _safeHaptic(() => HapticFeedback.lightImpact());
    await _playAsset('coin', 'coin.wav', volume: 0.9);
  }

  /// 10. Gong (징 — 대박 당첨/업적 달성) + 묵직한 햅틱
  Future<void> playGong() async {
    _safeHaptic(() => HapticFeedback.heavyImpact());
    await _playAsset('gong', 'gong.wav', volume: 0.95);
  }

  /// 11. Gayageum Pluck (가야금 — 꿈풀이/감성 전환)
  Future<void> playGayageum() async {
    await _playAsset('gayageum', 'gayageum.wav', volume: 0.8);
  }

  /// Alchemy Combo: 엽전 짤랑 + 징 하이라이트 (연성 시네마틱용 시퀀스)
  Future<void> playAlchemyFanfare() async {
    await playCoinJangle();
    Future.delayed(const Duration(milliseconds: 550), () {
      if (_soundEnabled) playGong();
    });
  }

  /// 12. Kkaebi Cast Short (1.5~3s): "금 나와라 뚝딱!" + 쾅 + 마법 효과음
  Future<void> playKkaebiCastShort() async {
    _safeHaptic(() => HapticFeedback.heavyImpact());
    await _playAsset('kkaebi_cast', 'kkaebi_cast_short.mp3', volume: 1.0);
  }

  /// 13. Kkaebi Cast Full (10s): 풀 시네마틱 보이스
  Future<void> playKkaebiCastFull() async {
    _safeHaptic(() => HapticFeedback.heavyImpact());
    await _playAsset('kkaebi_cast_full', 'kkaebi_cast_full.mp3', volume: 1.0);
  }

  /// 14. Welcome Intro (앱 초기 진입 시 챠링~ 경쾌한 환영음 & 가야금 울림)
  Future<void> playWelcomeIntro() async {
    _safeHaptic(() => HapticFeedback.selectionClick());
    await _playAsset('welcome_chime', 'chime.wav', volume: 0.85);
    Future.delayed(const Duration(milliseconds: 320), () {
      if (_soundEnabled) {
        _playAsset('welcome_gayageum', 'gayageum.wav', volume: 0.65);
      }
    });
  }
}