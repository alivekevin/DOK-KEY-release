import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/timelab_i18n.dart';
import '../core/timelab_sound_engine.dart';
import '../core/timelab_screen_keeper.dart';
import '../models/timelab_models.dart';

/// ⚡ 9-레인 그리드 스톱워치 (The Velocity Grid) 상태 관리 엔진
class VelocityGridEngine extends ChangeNotifier {
  static const String _storageKey = 'dokkey_velocity_records_v1';

  /// 🌐 현재 UI 언어 (페이지에서 주입) — 러너 이름·기본 기록 제목 현지화용
  final String lang;

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
  List<VelocityRecord> savedRecords = [];

  VelocityGridEngine({this.lang = 'ko'}) {
    _initLanes();
    loadRecords();
  }

  /// 기록 목록 불러오기 (SharedPreferences)
  Future<void> loadRecords() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonStr = prefs.getString(_storageKey);
      if (jsonStr != null && jsonStr.isNotEmpty) {
        final List<dynamic> decoded = jsonDecode(jsonStr);
        savedRecords = decoded.map((item) => VelocityRecord.fromJson(item as Map<String, dynamic>)).toList();
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error loading velocity records: $e');
    }
  }

  /// 현재 완주 기록 영구 저장 (PRO 전용)
  Future<VelocityRecord> saveCurrentRecord(String title) async {
    final newRecord = VelocityRecord(
      id: 'vr_${DateTime.now().millisecondsSinceEpoch}',
      title: title.trim().isEmpty
          ? TimelabI18n.defaultRecordTitle(lang, laneCount)
          : title.trim(),
      date: DateTime.now(),
      laneCount: laneCount,
      results: lanes.map((l) => l.copyWith()).toList(),
    );

    savedRecords.insert(0, newRecord);
    await _persistRecords();
    notifyListeners();
    return newRecord;
  }

  /// 기록 삭제
  Future<void> deleteRecord(String id) async {
    savedRecords.removeWhere((r) => r.id == id);
    await _persistRecords();
    notifyListeners();
  }

  Future<void> _persistRecords() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonList = savedRecords.map((r) => r.toJson()).toList();
      await prefs.setString(_storageKey, jsonEncode(jsonList));
    } catch (e) {
      debugPrint('Error saving velocity records: $e');
    }
  }

  void _initLanes() {
    lanes = List.generate(
      laneCount,
      (i) => RunnerLane(laneNumber: i + 1, name: TimelabI18n.runnerName(lang, i + 1)),
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
    TimeLabScreenKeeper.setKeepScreenOn(true);
    notifyListeners();
  }

  void pause() {
    if (!isRunning) return;
    _ticker?.cancel();
    isRunning = false;
    _pausedElapsed = elapsedTime;
    TimeLabScreenKeeper.setKeepScreenOn(false);
    notifyListeners();
  }

  void reset() {
    _ticker?.cancel();
    _initLanes();
    TimeLabScreenKeeper.setKeepScreenOn(false);
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
      TimeLabScreenKeeper.setKeepScreenOn(false);
    }

    notifyListeners();
  }

  @override
  void dispose() {
    _ticker?.cancel();
    TimeLabScreenKeeper.setKeepScreenOn(false);
    super.dispose();
  }
}
