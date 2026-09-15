import 'dart:typed_data';
import '../core/timelab_i18n.dart';

/// ⏱️ 시네마틱 타임 랩 3대 테마 프리셋
enum TimelabTheme {
  classicDigital, // 클래식 디지털: 매트 카본 + 7-세그먼트 그린 LCD + 앰버 전환 + 릴레이 틱
  cyberDefuser,   // 사이버 시한폭탄: 다크 HUD + 네온 레드 글로우 + CRT 글리치 + 심장박동 & 폭발
  orbitalLaunch,  // 우주 발사: 딥 스페이스 네이비 + 궤도 격자 + 사이언 블루 + T-10 플래시 & 부스터 럼블
}

/// 3-Phase 체인 타이머 단계 슬롯 모델
class ChainStep {
  final int index; // 1, 2, 3
  Duration duration;
  String? soundId; // 'gate', 'blast', 'buzzer', 'beep', 'gong', 'magic', 'custom' 등
  String? customSoundPath; // 휴대폰 내부 오디오 파일 절대 경로
  String? customSoundName; // 사용자 표시용 파일명 (예: "조용한 노래.mp3")
  Uint8List? customSoundBytes; // 웹 및 모바일 범용 오디오 바이너리 데이터
  Duration delayAfter; // 해당 타이머 완료 후 다음 단계까지의 대기 시간

  ChainStep({
    required this.index,
    required this.duration,
    this.soundId,
    this.customSoundPath,
    this.customSoundName,
    this.customSoundBytes,
    this.delayAfter = Duration.zero,
  });

  /// 🌐 6개국어 사운드 표시 이름
  String soundDisplayName(String lang) {
    if (customSoundName != null && customSoundName!.isNotEmpty) {
      return '📁 $customSoundName';
    }
    switch (soundId) {
      case 'gate':
        return TimelabI18n.soundGate(lang);
      case 'blast':
        return TimelabI18n.soundBlast(lang);
      case 'buzzer':
        return TimelabI18n.soundBuzzer(lang);
      case 'beep':
        return TimelabI18n.soundBeep(lang);
      case 'gong':
        return TimelabI18n.soundGong(lang);
      case 'magic':
        return TimelabI18n.soundMagic(lang);
      default:
        return TimelabI18n.soundDefault(lang);
    }
  }

  ChainStep copyWith({
    Duration? duration,
    String? soundId,
    String? customSoundPath,
    String? customSoundName,
    Uint8List? customSoundBytes,
    Duration? delayAfter,
  }) {
    return ChainStep(
      index: index,
      duration: duration ?? this.duration,
      soundId: soundId ?? this.soundId,
      customSoundPath: customSoundPath ?? this.customSoundPath,
      customSoundName: customSoundName ?? this.customSoundName,
      customSoundBytes: customSoundBytes ?? this.customSoundBytes,
      delayAfter: delayAfter ?? this.delayAfter,
    );
  }

  Map<String, dynamic> toJson() => {
    'index': index,
    'durationMs': duration.inMilliseconds,
    'soundId': soundId,
    'customSoundPath': customSoundPath,
    'customSoundName': customSoundName,
    'delayAfterMs': delayAfter.inMilliseconds,
  };

  factory ChainStep.fromJson(Map<String, dynamic> json) => ChainStep(
    index: json['index'] as int? ?? 1,
    duration: Duration(milliseconds: json['durationMs'] as int? ?? 10000),
    soundId: json['soundId'] as String?,
    customSoundPath: json['customSoundPath'] as String?,
    customSoundName: json['customSoundName'] as String?,
    delayAfter: Duration(milliseconds: json['delayAfterMs'] as int? ?? 0),
  );
}

/// 체인 타이머 런타임 상태
enum ChainTimerStatus {
  idle,
  running,
  audioPlaying, // 단계 완료 후 음악/종료음 재생 중 (3분/5분 완곡 대기)
  delaying,     // 음악 완료 후 설정된 지연(Delay) 대기
  paused,
  finished,
}

/// 9-레인 그리드 스톱워치 개별 주자 모델
class RunnerLane {
  final int laneNumber; // 1 ~ 9
  final String name;
  Duration? lapTime; // 완료 시 기록 (null = 달리는 중)
  int? rank; // 완주 순위 (1위, 2위 등)
  bool isFinished;

  RunnerLane({
    required this.laneNumber,
    required this.name,
    this.lapTime,
    this.rank,
    this.isFinished = false,
  });

  RunnerLane copyWith({
    String? name,
    Duration? lapTime,
    int? rank,
    bool? isFinished,
  }) {
    return RunnerLane(
      laneNumber: laneNumber,
      name: name ?? this.name,
      lapTime: lapTime ?? this.lapTime,
      rank: rank ?? this.rank,
      isFinished: isFinished ?? this.isFinished,
    );
  }

  Map<String, dynamic> toJson() => {
    'laneNumber': laneNumber,
    'name': name,
    'lapTimeMs': lapTime?.inMilliseconds,
    'rank': rank,
    'isFinished': isFinished,
  };

  factory RunnerLane.fromJson(Map<String, dynamic> json) => RunnerLane(
    laneNumber: json['laneNumber'] as int? ?? 1,
    name: json['name'] as String? ?? '주자 1',
    lapTime: json['lapTimeMs'] != null ? Duration(milliseconds: json['lapTimeMs'] as int) : null,
    rank: json['rank'] as int?,
    isFinished: json['isFinished'] as bool? ?? false,
  );
}

/// ⚡ 스톱워치 영구 저장 기록 모델 (PRO 전용)
class VelocityRecord {
  final String id;
  final String title;
  final DateTime date;
  final int laneCount;
  final List<RunnerLane> results;

  VelocityRecord({
    required this.id,
    required this.title,
    required this.date,
    required this.laneCount,
    required this.results,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'date': date.toIso8601String(),
    'laneCount': laneCount,
    'results': results.map((r) => r.toJson()).toList(),
  };

  factory VelocityRecord.fromJson(Map<String, dynamic> json) => VelocityRecord(
    id: json['id'] as String? ?? '',
    title: json['title'] as String? ?? '스톱워치 기록',
    date: DateTime.tryParse(json['date'] as String? ?? '') ?? DateTime.now(),
    laneCount: json['laneCount'] as int? ?? 1,
    results: (json['results'] as List<dynamic>?)
            ?.map((r) => RunnerLane.fromJson(r as Map<String, dynamic>))
            .toList() ??
        [],
  );
}

/// ⚡ 체인 타이머 완성형 루틴 프리셋 모델
class ChainRoutinePreset {
  final String id;
  final String icon;
  final String? customName;
  final int activeSlots;
  final int totalSets;
  final List<ChainStep> steps;
  final bool? enableTicking;
  final bool? enableCountdownBeep;

  const ChainRoutinePreset({
    required this.id,
    required this.icon,
    this.customName,
    required this.activeSlots,
    required this.totalSets,
    required this.steps,
    this.enableTicking,
    this.enableCountdownBeep,
  });

  String localizedTitle(String lang) {
    if (customName != null && customName!.isNotEmpty) {
      return customName!;
    }
    return TimelabI18n.routinePresetTitle(lang, id);
  }

  String localizedDesc(String lang) {
    if (customName != null && customName!.isNotEmpty) {
      return TimelabI18n.customRoutineSummary(lang, activeSlots, totalSets);
    }
    return TimelabI18n.routinePresetDesc(lang, id);
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'icon': icon,
    'customName': customName,
    'activeSlots': activeSlots,
    'totalSets': totalSets,
    'steps': steps.map((s) => s.toJson()).toList(),
    'enableTicking': enableTicking,
    'enableCountdownBeep': enableCountdownBeep,
  };

  factory ChainRoutinePreset.fromJson(Map<String, dynamic> json) => ChainRoutinePreset(
    id: json['id'] as String? ?? '',
    icon: json['icon'] as String? ?? '⏱️',
    customName: json['customName'] as String?,
    activeSlots: json['activeSlots'] as int? ?? 3,
    totalSets: json['totalSets'] as int? ?? 1,
    steps: (json['steps'] as List<dynamic>?)
            ?.map((s) => ChainStep.fromJson(s as Map<String, dynamic>))
            .toList() ??
        [],
    enableTicking: json['enableTicking'] as bool?,
    enableCountdownBeep: json['enableCountdownBeep'] as bool?,
  );
}

/// 🚀 기본 제공 빌트인 실전 루틴 프리셋 6종
final List<ChainRoutinePreset> builtinRoutinePresets = [
  ChainRoutinePreset(
    id: 'pomodoro',
    icon: '🍅',
    activeSlots: 2,
    totalSets: 4,
    enableTicking: false,
    enableCountdownBeep: false,
    steps: [
      ChainStep(index: 1, duration: const Duration(minutes: 25), delayAfter: Duration.zero),
      ChainStep(index: 2, duration: const Duration(minutes: 5), delayAfter: Duration.zero),
      ChainStep(index: 3, duration: const Duration(seconds: 3), delayAfter: Duration.zero),
    ],
  ),
  ChainRoutinePreset(
    id: 'tabata',
    icon: '🔥',
    activeSlots: 2,
    totalSets: 8,
    enableTicking: false,
    enableCountdownBeep: true,
    steps: [
      ChainStep(index: 1, duration: const Duration(seconds: 20), delayAfter: Duration.zero),
      ChainStep(index: 2, duration: const Duration(seconds: 10), delayAfter: Duration.zero),
      ChainStep(index: 3, duration: const Duration(seconds: 3), delayAfter: Duration.zero),
    ],
  ),
  ChainRoutinePreset(
    id: 'boxing',
    icon: '🥊',
    activeSlots: 2,
    totalSets: 3,
    enableTicking: false,
    enableCountdownBeep: true,
    steps: [
      ChainStep(index: 1, duration: const Duration(minutes: 3), delayAfter: Duration.zero),
      ChainStep(index: 2, duration: const Duration(minutes: 1), delayAfter: Duration.zero),
      ChainStep(index: 3, duration: const Duration(seconds: 3), delayAfter: Duration.zero),
    ],
  ),
  ChainRoutinePreset(
    id: 'ramen',
    icon: '🍜',
    activeSlots: 1,
    totalSets: 1,
    enableTicking: false,
    enableCountdownBeep: true,
    steps: [
      ChainStep(index: 1, duration: const Duration(minutes: 3), delayAfter: Duration.zero),
      ChainStep(index: 2, duration: const Duration(seconds: 5), delayAfter: Duration.zero),
      ChainStep(index: 3, duration: const Duration(seconds: 3), delayAfter: Duration.zero),
    ],
  ),
  ChainRoutinePreset(
    id: 'pitch',
    icon: '🎤',
    activeSlots: 2,
    totalSets: 1,
    enableTicking: false,
    enableCountdownBeep: true,
    steps: [
      ChainStep(index: 1, duration: const Duration(minutes: 5), delayAfter: const Duration(seconds: 3)),
      ChainStep(index: 2, duration: const Duration(minutes: 3), delayAfter: Duration.zero),
      ChainStep(index: 3, duration: const Duration(seconds: 3), delayAfter: Duration.zero),
    ],
  ),
  ChainRoutinePreset(
    id: 'defuser',
    icon: '💣',
    activeSlots: 3,
    totalSets: 1,
    enableTicking: true,
    enableCountdownBeep: true,
    steps: [
      ChainStep(index: 1, duration: const Duration(seconds: 10), delayAfter: const Duration(seconds: 2)),
      ChainStep(index: 2, duration: const Duration(seconds: 5), delayAfter: const Duration(seconds: 1)),
      ChainStep(index: 3, duration: const Duration(seconds: 3), delayAfter: Duration.zero),
    ],
  ),
];

