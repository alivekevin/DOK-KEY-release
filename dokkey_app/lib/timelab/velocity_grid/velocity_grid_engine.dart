import 'dart:async';
import 'package:flutter/foundation.dart';
import '../core/timelab_sound_engine.dart';
import '../models/timelab_models.dart';

/// ⚡ 9-레인 그리드 스톱워치 (The Velocity Grid) 상태 관리 엔진
class VelocityGridEngine extends ChangeNotifier {
  TimelabTheme theme = TimelabTheme.orbitalLaunch;

  int laneCount = 4; // 1 ~ 9 인원
  late List<RunnerLane> lanes;

  bool isRunning = false;
  Duration elapsedTime = Duration.zero;
  int _nextRank = 1;
  bool allFinished = false;

  Timer? _ticker;
  DateTime? _startTime;
  Duration _pausedElapsed = Duration.zero;

  final TimelabSoundEngine _sound = TimelabSoundEngine();

  VelocityGridEngine() {
    _initLanes();
  }

  void _initLanes() {
    lanes = List.generate(
      laneCount,
      (i) => RunnerLane(laneNumber: i + 1, name: '주자 ${i + 1}'),
    );
    _nextRank = 1;
    allFinished = false;
    elapsedTime = Duration.zero;
    _pausedElapsed = Duration.zero;
    isRunning = false;
  }

  void setTheme(TimelabTheme newTheme) {
    theme = newTheme;
    notifyListeners();
  }

  void setLaneCount(int count) {
    if (isRunning) return;
    laneCount = count.clamp(1, 9);
    _initLanes();
    notifyListeners();
  }

  void setRunnerName(int index, String newName) {
    if (index >= 0 && index < lanes.length) {
      lanes[index] = lanes[index].copyWith(name: newName);
      notifyListeners();
    }
  }

  void start() {
    if (isRunning) return;
    _startTime = DateTime.now();
    isRunning = true;
    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(milliseconds: 16), _onTick);
    _sound.playTick(theme);
    notifyListeners();
  }

  void pause() {
    if (!isRunning) return;
    _ticker?.cancel();
    isRunning = false;
    _pausedElapsed = elapsedTime;
    notifyListeners();
  }

  void reset() {
    _ticker?.cancel();
    _initLanes();
    notifyListeners();
  }

  void _onTick(Timer timer) {
    if (_startTime == null) return;
    final now = DateTime.now();
    elapsedTime = _pausedElapsed + now.difference(_startTime!);
    notifyListeners();
  }

  /// 주자 완주 터치 (Lap Freeze & Lock)
  void recordRunnerFinish(int index) {
    if (!isRunning) return;
    if (index < 0 || index >= lanes.length) return;
    if (lanes[index].isFinished) return;

    final currentLap = elapsedTime;
    final rank = _nextRank;
    _nextRank++;

    lanes[index] = lanes[index].copyWith(
      lapTime: currentLap,
      rank: rank,
      isFinished: true,
    );

    _sound.playLapLock(rank);

    // 전원 완주 여부 확인
    final finishedCount = lanes.where((l) => l.isFinished).length;
    if (finishedCount >= lanes.length) {
      allFinished = true;
      _ticker?.cancel();
      isRunning = false;
      _sound.playFinale(theme);
    }

    notifyListeners();
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }
}
