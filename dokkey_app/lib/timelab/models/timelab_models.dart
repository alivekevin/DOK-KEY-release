import 'dart:convert';
import 'package:flutter/material.dart';

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
  Duration delayAfter; // 해당 타이머 완료 후 다음 단계까지의 대기 시간

  ChainStep({
    required this.index,
    required this.duration,
    this.soundId,
    this.customSoundPath,
    this.customSoundName,
    this.delayAfter = Duration.zero,
  });

  String get soundDisplayName {
    if (customSoundName != null && customSoundName!.isNotEmpty) {
      return '📁 $customSoundName';
    }
    switch (soundId) {
      case 'gate':
        return '🚪 묵직한 철문 개방';
      case 'blast':
        return '💥 시한폭탄 대폭발';
      case 'buzzer':
        return '🏁 레이싱 출발 부저';
      case 'beep':
        return '📡 관제탑 비프음';
      case 'gong':
        return '🔔 황금 징 피날레';
      case 'magic':
        return '🪄 도깨비 방망이 마법';
      default:
        return '⚡ 테마 기본 사운드';
    }
  }

  ChainStep copyWith({
    Duration? duration,
    String? soundId,
    String? customSoundPath,
    String? customSoundName,
    Duration? delayAfter,
  }) {
    return ChainStep(
      index: index,
      duration: duration ?? this.duration,
      soundId: soundId ?? this.soundId,
      customSoundPath: customSoundPath ?? this.customSoundPath,
      customSoundName: customSoundName ?? this.customSoundName,
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
