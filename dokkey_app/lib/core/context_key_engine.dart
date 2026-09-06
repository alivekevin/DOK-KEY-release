import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Zero-Delay Context Key Engine (v3.0.0)
///
/// 모든 자동 감지 키는 앱 첫 프레임 이전에 동기 확정된다.
/// 세션 중 값은 불변이며, 어떤 키도 OS 권한을 요구하지 않는다.
enum TimeSlotId { morning, noon, evening, night }

enum VisitState { firstVisit, revisit, longAbsence }

class ContextKeyEngine {
  // --- Resolved context (immutable per session) ---
  TimeSlotId slotId = TimeSlotId.morning;
  VisitState visitState = VisitState.firstVisit;
  int visitGapDays = 0;
  int visitCount = 1;
  bool online = true;
  String platformTheme = 'dark'; // OS brightness at launch
  String themeOverride = 'auto'; // auto | dark | light

  // --- Optional profile keys ---
  String ageGroup = 'anon'; // anon | teens | 20s | 30s | 40s | 50s+
  String gender = 'anon'; // anon | m | f | other
  String nickname = ''; // '' == none

  bool get isLightTheme =>
      themeOverride == 'auto' ? platformTheme == 'light' : themeOverride == 'light';

  bool get isFirstVisit => visitState == VisitState.firstVisit;
  bool get isLongAbsence => visitState == VisitState.longAbsence;
  bool get hasNickname => nickname.trim().isNotEmpty;

  String get displayNickname {
    final n = nickname.trim();
    return n.isEmpty ? '' : n;
  }

  /// 1. 시간대 감지 — 순수 함수, 동기 0ms, 자정 통과(심야) 처리
  static TimeSlotId detectTimeSlot([DateTime? now]) {
    final h = (now ?? DateTime.now()).hour;
    if (h >= 5 && h < 11) return TimeSlotId.morning;
    if (h >= 11 && h < 17) return TimeSlotId.noon;
    if (h >= 17 && h < 21) return TimeSlotId.evening;
    return TimeSlotId.night;
  }

  static TimeSlotId slotIdFromString(String id) {
    switch (id) {
      case 'noon':
        return TimeSlotId.noon;
      case 'evening':
        return TimeSlotId.evening;
      case 'night':
        return TimeSlotId.night;
      default:
        return TimeSlotId.morning;
    }
  }

  static String slotIdToString(TimeSlotId id) {
    switch (id) {
      case TimeSlotId.morning:
        return 'morning';
      case TimeSlotId.noon:
        return 'noon';
      case TimeSlotId.evening:
        return 'evening';
      case TimeSlotId.night:
        return 'night';
    }
  }

  /// 2. 방문 이력 — 앱 시작 시 1회 연산 (initialize 단계에서 호출)
  static VisitState detectVisitState({
    required String? firstVisitDate,
    required String? lastVisitDate,
    required String todayStr,
  }) {
    if (firstVisitDate == null || firstVisitDate.isEmpty) {
      return VisitState.firstVisit;
    }
    final gap = visitGapDaysBetween(lastVisitDate, todayStr);
    if (gap >= 7) return VisitState.longAbsence;
    return VisitState.revisit;
  }

  static int visitGapDaysBetween(String? lastVisitDate, String todayStr) {
    if (lastVisitDate == null || lastVisitDate.isEmpty) return 0;
    final last = DateTime.tryParse(lastVisitDate);
    final today = DateTime.tryParse(todayStr);
    if (last == null || today == null) return 0;
    final gap = today.difference(DateTime(last.year, last.month, last.day)).inDays;
    return gap < 0 ? 0 : gap;
  }

  /// 3. 테마/조도 감지 — matchMedia(prefers-color-scheme) 대응
  static String detectPlatformTheme() {
    final brightness =
        WidgetsBinding.instance.platformDispatcher.platformBrightness;
    return brightness == Brightness.light ? 'light' : 'dark';
  }

  /// 4. 네트워크 기본 상태 — 단순 온라인/오프라인 부울 1회 체크 (복잡한 API 배제)
  static Future<bool> detectOnline() async {
    if (kIsWeb) {
      try {
        final result = await Connectivity().checkConnectivity();
        return !result.contains(ConnectivityResult.none);
      } catch (_) {
        return true;
      }
    }
    try {
      final result = await Connectivity().checkConnectivity();
      return !result.contains(ConnectivityResult.none);
    } catch (_) {
      // 감지 실패 시 낙관적 온라인 (서버리스 앱이므로 오프라인 판정이 기능에 영향 없음)
      return true;
    }
  }

  /// 전체 초기화 — 앱 첫 프레임 이전에 1회 호출
  Future<void> initialize(SharedPreferences prefs) async {
    slotId = detectTimeSlot();

    // Visit history
    final todayStr = DateTime.now().toIso8601String().substring(0, 10);
    String? firstVisit = prefs.getString('pref_first_visit_date');
    String? lastVisit = prefs.getString('pref_last_visit_date');
    visitState = detectVisitState(
      firstVisitDate: firstVisit,
      lastVisitDate: lastVisit,
      todayStr: todayStr,
    );
    visitGapDays = visitGapDaysBetween(lastVisit, todayStr);
    visitCount = prefs.getInt('pref_visit_count') ?? 0;
    visitCount += 1;

    if (firstVisit == null || firstVisit.isEmpty) {
      firstVisit = todayStr;
      await prefs.setString('pref_first_visit_date', firstVisit);
    }
    await prefs.setString('pref_last_visit_date', todayStr);
    await prefs.setInt('pref_visit_count', visitCount);

    // Theme
    platformTheme = detectPlatformTheme();
    themeOverride = prefs.getString('pref_theme_override') ?? 'auto';

    // Network (single boolean check)
    online = await detectOnline();

    // Profile
    ageGroup = prefs.getString('pref_age_group') ?? 'anon';
    gender = prefs.getString('pref_gender') ?? 'anon';
    nickname = prefs.getString('pref_nickname') ?? '';
  }

  Future<void> setThemeOverride(String mode) async {
    themeOverride = mode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('pref_theme_override', mode);
  }

  Future<void> updateProfile({
    required String ageGroup,
    required String gender,
    required String nickname,
  }) async {
    this.ageGroup = ageGroup;
    this.gender = gender;
    this.nickname = nickname;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('pref_age_group', ageGroup);
    await prefs.setString('pref_gender', gender);
    await prefs.setString('pref_nickname', nickname);
  }

  DrawContextSeed toSeed() => DrawContextSeed(
    slotId: slotId,
    themeMode: isLightTheme ? 'light' : 'dark',
    visitState: visitState,
    online: online,
    profileRef: hasNickname ? nickname : 'anon',
  );
}

/// DrawContext에 주입되는 경량 스냅샷
class DrawContextSeed {
  final TimeSlotId slotId;
  final String themeMode;
  final VisitState visitState;
  final bool online;
  final String profileRef;

  const DrawContextSeed({
    required this.slotId,
    required this.themeMode,
    required this.visitState,
    required this.online,
    required this.profileRef,
  });

  String get visitStateString {
    switch (visitState) {
      case VisitState.firstVisit:
        return 'first_visit';
      case VisitState.revisit:
        return 'revisit';
      case VisitState.longAbsence:
        return 'long_absence';
    }
  }
}
