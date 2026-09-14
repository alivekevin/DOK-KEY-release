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
  String? soundId; // null = 테마 기본 사운드
  Duration delayAfter; // 해당 타이머 완료 후 다음 단계까지의 대기 시간

  ChainStep({
    required this.index,
    required this.duration,
    this.soundId,
    this.delayAfter = Duration.zero,
  });

  ChainStep copyWith({
    Duration? duration,
    String? soundId,
    Duration? delayAfter,
  }) {
    return ChainStep(
      index: index,
      duration: duration ?? this.duration,
      soundId: soundId ?? this.soundId,
      delayAfter: delayAfter ?? this.delayAfter,
    );
  }
}

/// 체인 타이머 런타임 상태
enum ChainTimerStatus {
  idle,
  running,
  paused,
  delaying,
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
}
