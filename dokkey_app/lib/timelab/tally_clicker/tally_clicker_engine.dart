import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/timelab_models.dart';
import '../core/timelab_sound_engine.dart';

/// 🔢 택티컬 탭 카운터 (The Tactical Tally Clicker) 상태 관리 엔진
class TallyClickerEngine extends ChangeNotifier {
  int _count = 0;
  int? _targetCount;
  TimelabTheme _theme = TimelabTheme.classicDigital;
  bool _soundEnabled = true;
  bool _vibrationEnabled = true;

  // 마일스톤 이펙트 트리거 플래그 (UI 애니메이션용)
  bool _isMilestone10 = false;
  bool _isMilestone100 = false;
  bool _isTargetReached = false;

  final TimelabSoundEngine _soundEngine = TimelabSoundEngine();

  int get count => _count;
  int? get targetCount => _targetCount;
  TimelabTheme get theme => _theme;
  bool get soundEnabled => _soundEnabled;
  bool get vibrationEnabled => _vibrationEnabled;
  bool get isMilestone10 => _isMilestone10;
  bool get isMilestone100 => _isMilestone100;
  bool get isTargetReached => _isTargetReached;

  double get progressToTarget {
    if (_targetCount == null || _targetCount! <= 0) return 0.0;
    return (_count / _targetCount!).clamp(0.0, 1.0);
  }

  TallyClickerEngine({TimelabTheme initialTheme = TimelabTheme.classicDigital}) {
    _theme = initialTheme;
    _loadState();
  }

  Future<void> _loadState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _count = prefs.getInt('tally_clicker_count') ?? 0;
      final savedTarget = prefs.getInt('tally_clicker_target');
      _targetCount = (savedTarget != null && savedTarget > 0) ? savedTarget : null;
      _soundEnabled = prefs.getBool('tally_clicker_sound') ?? true;
      _vibrationEnabled = prefs.getBool('tally_clicker_vibrate') ?? true;
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading tally clicker state: $e');
    }
  }

  Future<void> _saveState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('tally_clicker_count', _count);
      if (_targetCount != null) {
        await prefs.setInt('tally_clicker_target', _targetCount!);
      } else {
        await prefs.remove('tally_clicker_target');
      }
      await prefs.setBool('tally_clicker_sound', _soundEnabled);
      await prefs.setBool('tally_clicker_vibrate', _vibrationEnabled);
    } catch (e) {
      debugPrint('Error saving tally clicker state: $e');
    }
  }

  /// 테마 전환
  void setTheme(TimelabTheme newTheme) {
    _theme = newTheme;
    notifyListeners();
  }

  /// 사운드 토글
  void toggleSound() {
    _soundEnabled = !_soundEnabled;
    _saveState();
    notifyListeners();
  }

  /// 진동 토글
  void toggleVibration() {
    _vibrationEnabled = !_vibrationEnabled;
    _saveState();
    notifyListeners();
  }

  /// 목표 수치 설정 (null 또는 0 이하일 경우 목표 해제)
  void setTargetCount(int? target) {
    if (target != null && target <= 0) {
      _targetCount = null;
    } else {
      _targetCount = target;
    }
    _saveState();
    notifyListeners();
  }

  /// 화면 탭 (+1 증가)
  void increment() {
    if (_count >= 99999) return;
    _count++;
    _checkFeedback(isIncrement: true);
    _saveState();
    notifyListeners();
  }

  /// 감소 (-1 오작동 정정)
  void decrement() {
    if (_count <= 0) return;
    _count--;
    if (_vibrationEnabled) {
      HapticFeedback.lightImpact();
    }
    _saveState();
    notifyListeners();
  }

  /// 0으로 리셋
  void reset() {
    _count = 0;
    _isMilestone10 = false;
    _isMilestone100 = false;
    _isTargetReached = false;
    if (_vibrationEnabled) {
      HapticFeedback.heavyImpact();
    }
    _saveState();
    notifyListeners();
  }

  /// 마일스톤 및 오디오/햅틱 피드백 계산
  void _checkFeedback({required bool isIncrement}) {
    if (!isIncrement) return;

    _isMilestone10 = false;
    _isMilestone100 = false;
    _isTargetReached = false;

    // 1. 목표 도달 확인
    if (_targetCount != null && _count == _targetCount) {
      _isTargetReached = true;
      if (_soundEnabled) {
        _soundEngine.playFinale(_theme);
      }
      if (_vibrationEnabled) {
        HapticFeedback.heavyImpact();
        Future.delayed(const Duration(milliseconds: 150), () {
          HapticFeedback.heavyImpact();
        });
      }
      return;
    }

    // 2. 100 단위 마일스톤 (예: 100, 200, 300...)
    if (_count > 0 && _count % 100 == 0) {
      _isMilestone100 = true;
      if (_soundEnabled) {
        _soundEngine.playStepComplete(_theme);
      }
      if (_vibrationEnabled) {
        HapticFeedback.heavyImpact();
      }
      return;
    }

    // 3. 10 단위 마일스톤 (예: 10, 20, 30...)
    if (_count > 0 && _count % 10 == 0) {
      _isMilestone10 = true;
      if (_soundEnabled) {
        _soundEngine.playTick(_theme);
      }
      if (_vibrationEnabled) {
        HapticFeedback.mediumImpact();
      }
      return;
    }

    // 4. 일반 1회 탭
    if (_soundEnabled) {
      _soundEngine.playTick(_theme);
    }
    if (_vibrationEnabled) {
      HapticFeedback.selectionClick();
    }
  }
}
