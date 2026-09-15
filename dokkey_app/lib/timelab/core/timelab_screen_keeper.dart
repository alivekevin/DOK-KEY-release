import 'package:flutter/foundation.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

/// 타임 랩 타이머/스톱워치 구동 중 화면 꺼짐 방지(Wakelock) 관리자
class TimeLabScreenKeeper {
  static bool _isEnabled = false;

  /// 화면 켜짐 유지 상태 설정
  static Future<void> setKeepScreenOn(bool keepOn) async {
    if (_isEnabled == keepOn) return;
    try {
      if (keepOn) {
        await WakelockPlus.enable();
        _isEnabled = true;
      } else {
        await WakelockPlus.disable();
        _isEnabled = false;
      }
    } catch (e) {
      // 단위 테스트 환경이거나 미지원 브라우저인 경우 안전하게 통과
      debugPrint('[TimeLabScreenKeeper] Wakelock toggle error ($keepOn): $e');
    }
  }

  /// 강제 해제 (페이지 이탈/초기화 시 호출)
  static Future<void> release() async {
    if (!_isEnabled) return;
    try {
      await WakelockPlus.disable();
      _isEnabled = false;
    } catch (e) {
      debugPrint('[TimeLabScreenKeeper] Wakelock release error: $e');
    }
  }

  /// 현재 켜짐 유지 여부
  static bool get isEnabled => _isEnabled;
}
