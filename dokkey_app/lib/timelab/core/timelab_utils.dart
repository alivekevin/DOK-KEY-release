/// ⏱️ 시네마틱 타임 랩 공용 유틸리티
class TimelabUtils {
  TimelabUtils._();

  /// mm:ss.cc 포맷 (밀리초 2자리) — 체인 타이머 · 9-레인 스톱워치 · 기록 보관함 공용
  /// (과거 3개 파일에 중복 정의되던 포맷터의 단일 구현)
  static String formatStopwatch(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    final ms = (d.inMilliseconds.remainder(1000) ~/ 10).toString().padLeft(2, '0');
    return '$m:$s.$ms';
  }
}
