import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../core/sound_service.dart';
import '../core/theme.dart';
import '../providers/dokkey_provider.dart';
import 'core/game_shell.dart';

/// 🏄 게임 8: 깨비 바다 서퍼 (Ocean Surfer / Wave Runner)
/// 다이내믹 파도 서핑 + 원터치/더블 점프 + 파도 램프 슈퍼 점프 + 공중 트릭 스핀 + 무지개 쓰나미 피버 모드

enum SeaObstacleType {
  coralReef, // 산호 암초
  whirlpool, // 소용돌이
  seaBarrel, // 바다 통나무/럼주통
  waveRamp, // 거대 파도 램프 (점프대)
}

enum SeaItemType {
  coin, // 금화 (+50점)
  pearl, // 진주 (+150점, 피버+15%)
  starfish, // 무지개 불가사리 (+300점, 피버+35%)
  heart, // 생명 회복
}

class SeaEntity {
  double x; // 0 ~ width
  double y; // 0 (상단 지평선) ~ height (하단)
  double speed;
  double width;
  double height;
  bool collected = false;

  SeaEntity({
    required this.x,
    required this.y,
    required this.speed,
    required this.width,
    required this.height,
  });
}

class SeaObstacle extends SeaEntity {
  final SeaObstacleType type;
  double animAngle = 0.0;

  SeaObstacle({
    required super.x,
    required super.y,
    required super.speed,
    required super.width,
    required super.height,
    required this.type,
  });
}

class SeaItem extends SeaEntity {
  final SeaItemType type;
  double floatOffset = 0.0;

  SeaItem({
    required super.x,
    required super.y,
    required super.speed,
    required super.width,
    required super.height,
    required this.type,
  });
}

class SplashParticle {
  double x, y;
  double vx, vy;
  double size;
  double life;
  Color color;

  SplashParticle({
    required this.x,
    required this.y,
    required this.vx,
    required this.vy,
    required this.size,
    required this.life,
    required this.color,
  });
}

/// 🏄 바다 서퍼 순수 로직 모델
class OceanSurferModel {
  double width, height;
  final Random rng;

  // 플레이어 물리
  double px; // 화면 가로 위치
  double py = 0.0; // 파도 위 높이 (점프 고도: 0 = 수면)
  double vy = 0.0; // 점프 수직 속도
  double targetPx; // 조작 목표 위치
  double rollAngle = 0.0; // 좌우 턴 뱅킹 각도
  double stuntSpinAngle = 0.0; // 점프 중 공중 스핀 각도

  int jumpsLeft = 2; // 더블 점프
  bool isStunting = false;
  double stuntBonusTimer = 0.0;

  // 게임 진행 & 스탯
  int lives = 3;
  int score = 0;
  double distance = 0.0; // 이동 거리 (m)
  double speed = 320.0; // 전진 속도 (px/s)
  bool gameOver = false;
  bool cleared = false; // 2000m 도달 시 승리

  // 피버 모드
  double feverGauge = 0.0; // 0 ~ 100
  double feverTimer = 0.0; // 피버 남은 시간
  bool get isFever => feverTimer > 0;

  // 무적 (피격 후)
  double invincibleTimer = 0.0;
  bool get isInvincible => invincibleTimer > 0 || isFever;

  // 엔티티 관리
  final List<SeaObstacle> obstacles = [];
  final List<SeaItem> items = [];
  final List<SplashParticle> particles = [];

  double _spawnTimer = 0.0;
  double _itemSpawnTimer = 0.0;
  double waveOffset = 0.0;

  static const double gravity = 1200.0;
  static const double jumpVel = 480.0;
  static const double superJumpVel = 750.0;

  OceanSurferModel({
    required this.width,
    required this.height,
    Random? random,
  })  : rng = random ?? Random(),
        px = width / 2,
        targetPx = width / 2;

  void steer(double targetRatio) {
    targetRatio = targetRatio.clamp(0.08, 0.92);
    targetPx = width * targetRatio;
  }

  void moveRelative(double dx) {
    targetPx = (targetPx + dx).clamp(width * 0.08, width * 0.92);
  }

  bool jump() {
    if (gameOver) return false;
    if (jumpsLeft > 0) {
      vy = jumpVel;
      jumpsLeft--;
      // 공중에서 더블 점프 시 스핀 트릭 트리거
      if (jumpsLeft == 0) {
        triggerStunt();
      }
      return true;
    }
    return false;
  }

  void triggerStunt() {
    if (py > 20 && !isStunting) {
      isStunting = true;
      stuntBonusTimer = 0.8;
      score += (150 * (isFever ? 2 : 1));
      _addStuntParticles();
    }
  }

  void resize(double newW, double newH) {
    if (newW <= 10 || newH <= 10) return;
    final ratioX = newW / (width > 0 ? width : newW);
    width = newW;
    height = newH;
    px = (px * ratioX).clamp(newW * 0.08, newW * 0.92);
    targetPx = (targetPx * ratioX).clamp(newW * 0.08, newW * 0.92);
  }

  void update(double dt) {
    if (gameOver) return;

    if (px.isNaN) px = width / 2;
    if (targetPx.isNaN) targetPx = width / 2;
    if (py.isNaN) py = 0.0;
    if (vy.isNaN) vy = 0.0;
    if (distance.isNaN) distance = 0.0;

    // 전진 속도 & 거리 업데이트
    final currentSpeed = isFever ? speed * 1.5 : speed;
    distance += (currentSpeed * dt) / 50; // 거리 (m)
    score += (dt * (currentSpeed / 20) * (isFever ? 2 : 1)).floor();
    speed = min(680.0, speed + 5.5 * dt);
    waveOffset += currentSpeed * dt * 0.22;

    // 무적 & 피버 타이머
    if (invincibleTimer > 0) invincibleTimer -= dt;
    if (stuntBonusTimer > 0) {
      stuntBonusTimer -= dt;
      if (stuntBonusTimer <= 0) isStunting = false;
    }

    if (feverTimer > 0) {
      feverTimer -= dt;
      if (feverTimer <= 0) {
        feverGauge = 0.0;
      }
    }

    // 플레이어 가로 보간 & 뱅킹 롤
    final diff = targetPx - px;
    px += diff * min(1.0, 14.0 * dt);
    rollAngle = (diff / 60.0).clamp(-0.4, 0.4);

    // 점프 중력 물리
    vy -= gravity * dt;
    py += vy * dt;
    if (py <= 0) {
      if (vy < -300) {
        _addWaterSplash(px, height * 0.76, 12);
      }
      py = 0;
      vy = 0;
      jumpsLeft = 2;
      isStunting = false;
      stuntSpinAngle = 0.0;
    } else {
      if (isStunting) {
        stuntSpinAngle += 14.0 * dt;
      }
    }

    // 엔티티 스폰
    _updateSpawns(dt, currentSpeed);

    // 엔티티 이동 & 충돌 판정
    _updateEntities(dt, currentSpeed);

    // 파티클 업데이트
    _updateParticles(dt);

    // 2000m 완주 체크
    if (distance >= 2000) {
      cleared = true;
      gameOver = true;
    }
  }

  void _updateSpawns(double dt, double curSpeed) {
    _spawnTimer -= dt;
    if (_spawnTimer <= 0) {
      _spawnTimer = 0.9 + rng.nextDouble() * 1.1 - (speed / 1400);
      _spawnObstacle();
    }

    _itemSpawnTimer -= dt;
    if (_itemSpawnTimer <= 0) {
      _itemSpawnTimer = 0.6 + rng.nextDouble() * 0.7;
      _spawnItem();
    }
  }

  void _spawnObstacle() {
    final laneRatio = 0.15 + rng.nextDouble() * 0.7;
    final ox = width * laneRatio;
    final r = rng.nextDouble();
    SeaObstacleType type;
    double w = 48, h = 48;

    if (r < 0.22) {
      type = SeaObstacleType.waveRamp;
      w = 64;
      h = 32;
    } else if (r < 0.55) {
      type = SeaObstacleType.coralReef;
      w = 46;
      h = 46;
    } else if (r < 0.80) {
      type = SeaObstacleType.whirlpool;
      w = 54;
      h = 54;
    } else {
      type = SeaObstacleType.seaBarrel;
      w = 40;
      h = 40;
    }

    obstacles.add(SeaObstacle(
      x: ox,
      y: -60,
      speed: 1.0,
      width: w,
      height: h,
      type: type,
    ));
  }

  void _spawnItem() {
    final laneRatio = 0.12 + rng.nextDouble() * 0.76;
    final ix = width * laneRatio;
    final r = rng.nextDouble();
    SeaItemType type;

    if (lives < 3 && r < 0.08) {
      type = SeaItemType.heart;
    } else if (r < 0.25) {
      type = SeaItemType.starfish;
    } else if (r < 0.55) {
      type = SeaItemType.pearl;
    } else {
      type = SeaItemType.coin;
    }

    items.add(SeaItem(
      x: ix,
      y: -40,
      speed: 1.0,
      width: 32,
      height: 32,
      type: type,
    ));
  }

  void _updateEntities(double dt, double curSpeed) {
    final playerY = height * 0.76;
    final playerRadius = 24.0;

    // 1. 장애물 이동 및 충돌
    for (final obs in obstacles) {
      obs.y += curSpeed * dt;
      obs.animAngle += 3.0 * dt;

      // 충돌 검사
      if (!obs.collected && (obs.y - playerY).abs() < (obs.height / 2 + playerRadius)) {
        if ((obs.x - px).abs() < (obs.width / 2 + playerRadius - 6)) {
          _handleObstacleCollision(obs);
        }
      }
    }
    obstacles.removeWhere((o) => o.y > height + 80);

    // 2. 아이템 이동 및 수집
    for (final item in items) {
      item.y += curSpeed * dt;
      item.floatOffset += 4.0 * dt;

      // 피버 모드일 때 마그넷 자석 효과
      if (isFever && item.y > 0) {
        final dx = px - item.x;
        item.x += dx * min(1.0, 8.0 * dt);
      }

      if (!item.collected && (item.y - playerY).abs() < (item.height / 2 + playerRadius + 10)) {
        if ((item.x - px).abs() < (item.width / 2 + playerRadius + 8)) {
          _collectItem(item);
        }
      }
    }
    items.removeWhere((i) => i.y > height + 60 || i.collected);
  }

  void _handleObstacleCollision(SeaObstacle obs) {
    if (obs.type == SeaObstacleType.waveRamp) {
      // 🌊 거대 파도 램프! 슈퍼 하이 점프 & 스턴트 트릭 자동 발동
      vy = superJumpVel;
      jumpsLeft = 1;
      triggerStunt();
      score += 300;
      _addWaterSplash(obs.x, obs.y, 20);
      obs.collected = true;
      return;
    }

    // 소용돌이: 점프로 공중 회피 가능
    if (obs.type == SeaObstacleType.whirlpool) {
      if (py > 25) return; // 점프로 뛰어넘음!
    }

    // 산호/통나무: 점프로 회피 가능
    if (py > 32) return; // 높은 점프로 뛰어넘음!

    // 피버 모드면 장애물 파괴 & 보너스 점수
    if (isFever) {
      obs.collected = true;
      score += 200;
      _addExplosionParticles(obs.x, obs.y);
      return;
    }

    // 일반 상태 충돌 시 대미지
    if (!isInvincible) {
      lives--;
      invincibleTimer = 1.6;
      _addWaterSplash(px, height * 0.76, 16);
      if (lives <= 0) {
        gameOver = true;
      }
    }
  }

  void _collectItem(SeaItem item) {
    item.collected = true;
    switch (item.type) {
      case SeaItemType.coin:
        score += (50 * (isFever ? 2 : 1));
        _addFever(6.0);
        break;
      case SeaItemType.pearl:
        score += (150 * (isFever ? 2 : 1));
        _addFever(16.0);
        break;
      case SeaItemType.starfish:
        score += (300 * (isFever ? 2 : 1));
        _addFever(35.0);
        break;
      case SeaItemType.heart:
        if (lives < 3) lives++;
        score += 200;
        break;
    }
    _addItemParticles(item.x, item.y, item.type);
  }

  void _addFever(double amount) {
    if (isFever) return;
    feverGauge = (feverGauge + amount).clamp(0.0, 100.0);
    if (feverGauge >= 100.0) {
      feverTimer = 5.5; // 5.5초간 무지개 쓰나미 피버 모드!
      SoundService().playSuccessChime();
    }
  }

  void _addWaterSplash(double x, double y, int count) {
    for (var i = 0; i < count; i++) {
      final angle = rng.nextDouble() * pi * 2;
      final pSpeed = 60 + rng.nextDouble() * 160;
      particles.add(SplashParticle(
        x: x,
        y: y,
        vx: cos(angle) * pSpeed,
        vy: sin(angle) * pSpeed - 40,
        size: 3 + rng.nextDouble() * 5,
        life: 0.4 + rng.nextDouble() * 0.4,
        color: rng.nextBool() ? Colors.white : const Color(0xFF64B5F6),
      ));
    }
  }

  void _addStuntParticles() {
    for (var i = 0; i < 14; i++) {
      final angle = rng.nextDouble() * pi * 2;
      particles.add(SplashParticle(
        x: px,
        y: height * 0.76 - py,
        vx: cos(angle) * 180,
        vy: sin(angle) * 180,
        size: 4 + rng.nextDouble() * 4,
        life: 0.5,
        color: isFever ? Colors.amberAccent : Colors.cyanAccent,
      ));
    }
  }

  void _addItemParticles(double x, double y, SeaItemType type) {
    final c = switch (type) {
      SeaItemType.coin => Colors.amber,
      SeaItemType.pearl => Colors.lightBlueAccent,
      SeaItemType.starfish => Colors.pinkAccent,
      SeaItemType.heart => Colors.redAccent,
    };
    for (var i = 0; i < 8; i++) {
      final angle = rng.nextDouble() * pi * 2;
      particles.add(SplashParticle(
        x: x,
        y: y,
        vx: cos(angle) * 90,
        vy: sin(angle) * 90,
        size: 3 + rng.nextDouble() * 3,
        life: 0.35,
        color: c,
      ));
    }
  }

  void _addExplosionParticles(double x, double y) {
    for (var i = 0; i < 16; i++) {
      final angle = rng.nextDouble() * pi * 2;
      particles.add(SplashParticle(
        x: x,
        y: y,
        vx: cos(angle) * 140,
        vy: sin(angle) * 140,
        size: 4 + rng.nextDouble() * 4,
        life: 0.45,
        color: Colors.orangeAccent,
      ));
    }
  }

  void _updateParticles(double dt) {
    for (final p in particles) {
      p.x += p.vx * dt;
      p.y += p.vy * dt;
      p.life -= dt;
      p.size = max(0.5, p.size - 3 * dt);
    }
    particles.removeWhere((p) => p.life <= 0);
  }
}

// ---------------------------------------------------------------------------
// 🏄 깨비 바다 서퍼 위젯 & 하이엔드 캔버스
// ---------------------------------------------------------------------------

class KkaebiCaveGame extends StatefulWidget {
  static const String gameId = 'cave'; // 슬롯 8 호환 ID 유지

  const KkaebiCaveGame({super.key});

  @override
  State<KkaebiCaveGame> createState() => _KkaebiCaveGameState();
}

class _KkaebiCaveGameState extends State<KkaebiCaveGame> with GameLoopMixin {
  OceanSurferModel? _model;
  final FocusNode _focusNode = FocusNode();
  bool _finished = false;

  // 조작 상태
  bool _leftHeld = false;
  bool _rightHeld = false;

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  void onUpdate(double dt) {
    if (_finished || _model == null) return;

    if (_leftHeld) _model!.moveRelative(-320 * dt);
    if (_rightHeld) _model!.moveRelative(320 * dt);

    final wasOver = _model!.gameOver;
    _model!.update(dt);

    if (!wasOver && (_model!.gameOver || _model!.cleared)) {
      _finished = true;
      if (_model!.cleared) {
        SoundService().playGong();
      } else {
        SoundService().playRiddleWrong();
      }
      finishGame(
        context,
        gameId: KkaebiCaveGame.gameId,
        title: _model!.cleared ? '깨비 윈드서퍼 클리어!' : '깨비 윈드서퍼',
        score: _model!.score,
        cleared: _model!.cleared,
        onRetry: () => Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const KkaebiCaveGame()),
        ),
      );
    }
  }

  @override
  void onPaint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) return;
    if (_model == null || _model!.width <= 10) {
      _model = OceanSurferModel(width: size.width, height: size.height);
    } else if ((_model!.width - size.width).abs() > 10 || (_model!.height - size.height).abs() > 10) {
      _model!.resize(size.width, size.height);
    }

    _OceanSurferPainter(model: _model!).paint(canvas, size);
  }

  void _showHowToPlayDialog(BuildContext context) {
    final isKo = context.read<DokkeyProvider>().lang == 'ko';
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF021B2B),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(22),
          side: const BorderSide(color: Color(0xFF00E5FF), width: 2),
        ),
        title: Row(
          children: [
            const Text('🏄', style: TextStyle(fontSize: 26)),
            const SizedBox(width: 8),
            Text(
              isKo ? '깨비 윈드서퍼 조작 & 진행 가이드' : 'Ocean Surfer Guide',
              style: const TextStyle(
                color: Color(0xFF00E5FF),
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildGuideSection(
                icon: '🎯',
                title: isKo ? '게임 목표' : 'Goal',
                desc: isKo
                    ? '2,000m 완주하여 시원한 황금 해변에 도달하세요!'
                    : 'Surf 2,000m to reach the Golden Shore!',
              ),
              const SizedBox(height: 10),
              _buildGuideSection(
                icon: '🕹️',
                title: isKo ? '조작 방법' : 'Controls',
                desc: isKo
                    ? '• 좌우 이동: 하단 ◀ ▶ 버튼 / 화면 드래그 / A, D (←, →)\n• 점프 & 2단 점프: 하단 JUMP 버튼 / 화면 터치 / Space, W (↑, J)\n  ※ 공중에서 한번 더 누르면 더블 점프!\n• 스턴트 트릭: 하단 TRICK 버튼 / S, ↓, K\n  ※ 점프 중 회전 트릭으로 보너스 점수(+150점) 획득!'
                    : '• Steer: ◀ ▶ buttons / Drag / A, D (Arrow keys)\n• Jump: JUMP button / Tap / Space, W\n• Trick: TRICK button / S, K (+150 pts)',
              ),
              const SizedBox(height: 10),
              _buildGuideSection(
                icon: '🌊',
                title: isKo ? '장애물 & 파워업' : 'Obstacles & Items',
                desc: isKo
                    ? '• 🔴 산호 암초 & 럼주통: 피하거나 점프로 뛰어넘기\n• 🌀 소용돌이: 좌우로 회피하기\n• 🟩 파도 점프대: 밟으면 하늘 높이 슈퍼 하이 점프!\n• 🪙 금화 / 🦪 진주 / ⭐ 불가사리: 점수 & 피버 게이지 충전\n• 🌈 피버 모드: 100% 충전 시 무적 돌진 + 장애물 파괴!'
                    : '• Coral & Barrels: Dodge or Jump over\n• Whirlpool: Steer away\n• Wave Ramp: Super High Jump!\n• Coins/Pearls/Starfish: Score & Fever\n• Fever Mode: Invincible rush & smash obstacles!',
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(
              isKo ? '확인 (플레이 계속)' : 'Got it!',
              style: const TextStyle(
                color: Color(0xFF00E5FF),
                fontWeight: FontWeight.bold,
                fontSize: 15,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGuideSection({
    required String icon,
    required String title,
    required String desc,
  }) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(icon, style: const TextStyle(fontSize: 15)),
              const SizedBox(width: 6),
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 13.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            desc,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 12,
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }

  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    if (_model == null || _model!.gameOver) return KeyEventResult.ignored;

    final isDown = event is KeyDownEvent || event is KeyRepeatEvent;

    if (event.logicalKey == LogicalKeyboardKey.arrowLeft ||
        event.logicalKey == LogicalKeyboardKey.keyA) {
      _leftHeld = isDown;
      return KeyEventResult.handled;
    }
    if (event.logicalKey == LogicalKeyboardKey.arrowRight ||
        event.logicalKey == LogicalKeyboardKey.keyD) {
      _rightHeld = isDown;
      return KeyEventResult.handled;
    }
    if (isDown) {
      if (event.logicalKey == LogicalKeyboardKey.space ||
          event.logicalKey == LogicalKeyboardKey.arrowUp ||
          event.logicalKey == LogicalKeyboardKey.keyW ||
          event.logicalKey == LogicalKeyboardKey.keyJ) {
        if (_model!.jump()) {
          SoundService().playCardFlip();
        }
        return KeyEventResult.handled;
      }
      if (event.logicalKey == LogicalKeyboardKey.keyK ||
          event.logicalKey == LogicalKeyboardKey.arrowDown ||
          event.logicalKey == LogicalKeyboardKey.keyS) {
        _model!.triggerStunt();
        return KeyEventResult.handled;
      }
    }
    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    final isKo = context.watch<DokkeyProvider>().lang == 'ko';
    final hearts = List.generate(3, (idx) => idx < (_model?.lives ?? 3) ? '❤️' : '🖤').join(' ');

    return Focus(
      focusNode: _focusNode,
      autofocus: true,
      onKeyEvent: _handleKeyEvent,
      child: Scaffold(
        backgroundColor: const Color(0xFF021B2B),
        body: SafeArea(
          child: Column(
            children: [
              // 1. 상단 HUD
              GameHud(
                title: isKo ? '깨비 윈드서퍼' : 'Windsurfer',
                score: _model?.score ?? 0,
                rightLabel: '${_model?.distance.floor() ?? 0}m · $hearts',
                onQuit: () => Navigator.of(context).pop(),
                accent: const Color(0xFF00E5FF),
              ),

              // 2. 피버 게이지 바 (HUD 하단)
              if (_model != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  color: const Color(0xFF031E33),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _model!.isFever
                                ? (isKo ? '🌈 무지개 쓰나미 피버!!' : '🌈 RAINBOW FEVER!!')
                                : (isKo ? '피버 에너지' : 'FEVER ENERGY'),
                            style: TextStyle(
                              color: _model!.isFever ? Colors.amberAccent : const Color(0xFFB2EBF2),
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (_model!.isFever)
                            Text(
                              '${_model!.feverTimer.toStringAsFixed(1)}s',
                              style: const TextStyle(
                                color: Colors.amberAccent,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Container(
                        height: 6,
                        decoration: BoxDecoration(
                          color: Colors.black45,
                          borderRadius: BorderRadius.circular(3),
                          border: Border.all(
                            color: _model!.isFever ? Colors.amber : const Color(0xFF00ACC1),
                            width: 1,
                          ),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(2),
                          child: LinearProgressIndicator(
                            value: _model!.isFever
                                ? (_model!.feverTimer / 5.5).clamp(0.0, 1.0)
                                : (_model!.feverGauge / 100.0).clamp(0.0, 1.0),
                            backgroundColor: Colors.transparent,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              _model!.isFever ? Colors.amber : const Color(0xFF00E5FF),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

              // 3. 게임 캔버스 뷰포트
              Expanded(
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onHorizontalDragUpdate: (details) {
                          _model?.moveRelative(details.primaryDelta ?? 0);
                        },
                        onTapUp: (details) {
                          if (_model != null && _model!.jump()) {
                            SoundService().playCardFlip();
                          }
                        },
                        child: gameCanvas(overlayBuilder: () => const SizedBox.expand()),
                      ),
                    ),
                    // 상단 우측 가이드 버튼
                    Positioned(
                      top: 8,
                      right: 12,
                      child: InkWell(
                        onTap: () => _showHowToPlayDialog(context),
                        borderRadius: BorderRadius.circular(10),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.55),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: const Color(0xFF00E5FF).withOpacity(0.6), width: 1.2),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.help_outline_rounded, color: Color(0xFF00E5FF), size: 14),
                              const SizedBox(width: 4),
                              Text(
                                isKo ? '가이드' : 'Guide',
                                style: const TextStyle(color: Color(0xFF00E5FF), fontSize: 11, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // 4. 하단 모바일 컨트롤러 패드 (8번과 동일하게 SafeArea 최적화 위치)
              Container(
                padding: EdgeInsets.fromLTRB(16, 8, 16, max(10.0, MediaQuery.of(context).padding.bottom + 4)),
                decoration: const BoxDecoration(
                  color: Color(0xFF031926),
                  border: Border(top: BorderSide(color: Color(0xFF00838F), width: 1.5)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // 좌우 이동 버튼 세트
                    Row(
                      children: [
                        _buildTouchControl(
                          icon: Icons.arrow_left_rounded,
                          label: '◀',
                          onDown: () => _leftHeld = true,
                          onUp: () => _leftHeld = false,
                        ),
                        const SizedBox(width: 10),
                        _buildTouchControl(
                          icon: Icons.arrow_right_rounded,
                          label: '▶',
                          onDown: () => _rightHeld = true,
                          onUp: () => _rightHeld = false,
                        ),
                      ],
                    ),

                    // 스턴트 & 점프 버튼 세트
                    Row(
                      children: [
                        // 스턴트 버튼
                        _buildActionButton(
                          label: isKo ? '트릭' : 'TRICK',
                          subLabel: '✨',
                          color: const Color(0xFFFFB300),
                          size: 54,
                          onTap: () {
                            _model?.triggerStunt();
                          },
                        ),
                        const SizedBox(width: 10),
                        // 점프 버튼 (대형)
                        _buildActionButton(
                          label: isKo ? '점프' : 'JUMP',
                          subLabel: '🦘',
                          color: const Color(0xFF00E676),
                          size: 64,
                          onTap: () {
                            if (_model != null && _model!.jump()) {
                              SoundService().playCardFlip();
                            }
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTouchControl({
    required IconData icon,
    required String label,
    required VoidCallback onDown,
    required VoidCallback onUp,
  }) {
    return Listener(
      onPointerDown: (_) => onDown(),
      onPointerUp: (_) => onUp(),
      onPointerCancel: (_) => onUp(),
      child: Container(
        width: 58,
        height: 58,
        decoration: BoxDecoration(
          color: const Color(0xFF004D40).withOpacity(0.75),
          shape: BoxShape.circle,
          border: Border.all(color: const Color(0xFF80CBC4), width: 2),
          boxShadow: [
            BoxShadow(
              color: Colors.cyanAccent.withOpacity(0.3),
              blurRadius: 8,
              spreadRadius: 1,
            ),
          ],
        ),
        child: Center(
          child: Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required String label,
    required String subLabel,
    required Color color,
    required double size,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: color.withOpacity(0.85),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 2.2),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.5),
              blurRadius: 10,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(subLabel, style: const TextStyle(fontSize: 16)),
            Text(
              label,
              style: const TextStyle(
                color: Colors.black87,
                fontSize: 11,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// 🎨 바다 서퍼 하이엔드 캔버스 페인터
// ---------------------------------------------------------------------------

class _OceanSurferPainter extends CustomPainter {
  final OceanSurferModel model;

  _OceanSurferPainter({required this.model});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // 1. 열대 바다 배경 그라데이션
    final bgPaint = Paint()
      ..shader = ui.Gradient.linear(
        Offset(0, 0),
        Offset(0, h),
        model.isFever
            ? [
                const Color(0xFF4A148C),
                const Color(0xFF006064),
                const Color(0xFF00E5FF),
              ]
            : [
                const Color(0xFF0D47A1),
                const Color(0xFF00838F),
                const Color(0xFF00E5FF),
              ],
      );
    canvas.drawRect(Rect.fromLTWH(0, 0, w, h), bgPaint);

    // 2. 부드럽고 우아한 바다 파도 너울 (4단 소프트 롤링 파도)
    final numWaves = 4;
    final waveSpacing = (h + 120) / numWaves;

    for (var i = 0; i < numWaves; i++) {
      final waveY = ((i * waveSpacing + (model.waveOffset % waveSpacing)) % (h + 120)) - 60;
      final depth = (waveY / h).clamp(0.0, 1.0);

      // 원근감에 따른 파도 높이, 진폭 및 주기
      final amp = 6.0 + depth * 7.0;
      final wavelength = 120.0 + depth * 60.0;
      final phase = (model.waveOffset * 0.006) + i * 1.5;

      // 파도 크레스트 (부드러운 흰색/청록 거품선)
      final crestPaint = Paint()
        ..color = Colors.white.withOpacity((0.08 + depth * 0.12).clamp(0.06, 0.20))
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.8 + depth * 1.8
        ..strokeCap = StrokeCap.round;

      final path = Path();
      path.moveTo(0, waveY + sin(phase) * amp);
      for (var x = 0.0; x <= w + 24; x += 24) {
        final sy = sin((x / wavelength) + phase) * amp;
        path.lineTo(x, waveY + sy);
      }
      canvas.drawPath(path, crestPaint);

      // 잔잔한 파도 너울 음영 (아래쪽 엷은 반투명 채우기)
      if (depth > 0.3) {
        final shadowPath = Path.from(path)
          ..lineTo(w, waveY + 22 + depth * 15)
          ..lineTo(0, waveY + 22 + depth * 15)
          ..close();
        final fillPaint = Paint()
          ..shader = ui.Gradient.linear(
            Offset(0, waveY),
            Offset(0, waveY + 22 + depth * 15),
            [
              Colors.cyanAccent.withOpacity(0.04 + depth * 0.04),
              Colors.transparent,
            ],
          );
        canvas.drawPath(shadowPath, fillPaint);
      }
    }

    // 3. 바다 아이템 렌더링
    for (final item in model.items) {
      if (item.collected || item.y < -30 || item.y > h + 30) continue;
      _drawItem(canvas, item);
    }

    // 4. 장애물 렌더링
    for (final obs in model.obstacles) {
      if (obs.y < -50 || obs.y > h + 50) continue;
      _drawObstacle(canvas, obs);
    }

    // 5. 파티클 렌더링
    for (final p in model.particles) {
      final pPaint = Paint()..color = p.color.withOpacity((p.life * 2).clamp(0.0, 1.0));
      canvas.drawCircle(Offset(p.x, p.y), p.size, pPaint);
    }

    // 6. 플레이어 (깨비 서퍼 & 서핑보드)
    _drawSurfer(canvas, h);
  }

  void _drawItem(Canvas canvas, SeaItem item) {
    final center = Offset(item.x, item.y + sin(item.floatOffset) * 4);

    // 발광 글로우 (하드웨어 가속 안전 동심원)
    final glowColor = switch (item.type) {
      SeaItemType.coin => Colors.amber,
      SeaItemType.pearl => Colors.cyanAccent,
      SeaItemType.starfish => Colors.pinkAccent,
      SeaItemType.heart => Colors.redAccent,
    };
    canvas.drawCircle(center, 18, Paint()..color = glowColor.withOpacity(0.22));
    canvas.drawCircle(center, 14, Paint()..color = glowColor.withOpacity(0.35));

    final itemPaint = Paint()..style = PaintingStyle.fill;

    switch (item.type) {
      case SeaItemType.coin:
        itemPaint.color = Colors.amber;
        canvas.drawCircle(center, 12, itemPaint);
        itemPaint.color = Colors.yellowAccent;
        canvas.drawCircle(center, 8, itemPaint);
        break;
      case SeaItemType.pearl:
        itemPaint.color = Colors.white;
        canvas.drawCircle(center, 12, itemPaint);
        itemPaint.color = const Color(0xFFE0F7FA);
        canvas.drawCircle(center, 6, itemPaint);
        break;
      case SeaItemType.starfish:
        _drawStar(canvas, center, 14, Colors.pinkAccent);
        break;
      case SeaItemType.heart:
        final hPaint = Paint()..color = Colors.redAccent;
        canvas.drawCircle(center.translate(-5, -2), 7, hPaint);
        canvas.drawCircle(center.translate(5, -2), 7, hPaint);
        final triPath = Path()
          ..moveTo(center.dx - 11, center.dy)
          ..lineTo(center.dx + 11, center.dy)
          ..lineTo(center.dx, center.dy + 12)
          ..close();
        canvas.drawPath(triPath, hPaint);
        break;
    }
  }

  void _drawStar(Canvas canvas, Offset center, double radius, Color color) {
    final path = Path();
    final numPoints = 5;
    final innerRadius = radius * 0.45;
    for (var i = 0; i < numPoints * 2; i++) {
      final r = i.isEven ? radius : innerRadius;
      final angle = i * pi / numPoints - pi / 2;
      final x = center.dx + cos(angle) * r;
      final y = center.dy + sin(angle) * r;
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();
    canvas.drawPath(path, Paint()..color = color);
  }

  void _drawObstacle(Canvas canvas, SeaObstacle obs) {
    final center = Offset(obs.x, obs.y);

    switch (obs.type) {
      case SeaObstacleType.coralReef:
        // 뾰족한 산호 암초
        final coralPaint = Paint()..color = const Color(0xFFE53935);
        final path = Path()
          ..moveTo(center.dx - 22, center.dy + 16)
          ..lineTo(center.dx - 12, center.dy - 18)
          ..lineTo(center.dx, center.dy - 6)
          ..lineTo(center.dx + 14, center.dy - 22)
          ..lineTo(center.dx + 22, center.dy + 16)
          ..close();
        canvas.drawPath(path, coralPaint);
        canvas.drawPath(
            path,
            Paint()
              ..color = const Color(0xFFFF8A80)
              ..style = PaintingStyle.stroke
              ..strokeWidth = 2);
        break;

      case SeaObstacleType.whirlpool:
        // 회전하는 소용돌이
        final whirlPaint = Paint()
          ..color = const Color(0xFF00E5FF).withOpacity(0.6)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3;
        canvas.save();
        canvas.translate(center.dx, center.dy);
        canvas.rotate(obs.animAngle);
        for (var r = 8.0; r <= 24.0; r += 8.0) {
          canvas.drawArc(
            Rect.fromCircle(center: Offset.zero, radius: r),
            0,
            pi * 1.4,
            false,
            whirlPaint,
          );
        }
        canvas.restore();
        break;

      case SeaObstacleType.seaBarrel:
        // 바다 통나무통
        final barrelPaint = Paint()..color = const Color(0xFF6D4C41);
        final rect = Rect.fromCenter(center: center, width: 34, height: 26);
        canvas.drawRRect(RRect.fromRectAndRadius(rect, const Radius.circular(6)), barrelPaint);
        final ringPaint = Paint()
          ..color = Colors.amber
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2;
        canvas.drawLine(Offset(rect.left, rect.top + 6), Offset(rect.right, rect.top + 6), ringPaint);
        canvas.drawLine(Offset(rect.left, rect.bottom - 6), Offset(rect.right, rect.bottom - 6), ringPaint);
        break;

      case SeaObstacleType.waveRamp:
        // 거대 파도 램프 (점프대)
        final rampPaint = Paint()..color = const Color(0xFF00E676);
        final rampRect = Rect.fromCenter(center: center, width: 56, height: 24);
        canvas.drawRRect(RRect.fromRectAndRadius(rampRect, const Radius.circular(8)), rampPaint);
        final borderPaint = Paint()
          ..color = Colors.white
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2;
        canvas.drawRRect(RRect.fromRectAndRadius(rampRect, const Radius.circular(8)), borderPaint);
        // 화살표 표시
        final arrowPath = Path()
          ..moveTo(center.dx - 12, center.dy + 4)
          ..lineTo(center.dx, center.dy - 6)
          ..lineTo(center.dx + 12, center.dy + 4);
        canvas.drawPath(arrowPath, borderPaint);
        break;
    }
  }

  void _drawSurfer(Canvas canvas, double screenH) {
    final baseY = screenH * 0.76;
    final surferX = model.px;
    final surferY = baseY - model.py;

    // 무적 깜빡임
    if (model.invincibleTimer > 0 && (model.invincibleTimer * 10).floor().isEven && !model.isFever) {
      return;
    }

    canvas.save();
    canvas.translate(surferX, surferY);
    canvas.rotate(model.rollAngle + model.stuntSpinAngle);

    // 1. 서핑보드 그림자 & 물보라 (수면 기준)
    if (model.py > 0) {
      final shadowPaint = Paint()..color = Colors.black.withOpacity(0.25);
      canvas.drawOval(
        Rect.fromCenter(center: Offset(0, model.py + 10), width: 36, height: 14),
        shadowPaint,
      );
    }

    // 2. 서핑보드 본체
    final boardPaint = Paint()
      ..color = model.isFever ? Colors.amberAccent : const Color(0xFFFF5252);
    final boardPath = Path()
      ..moveTo(0, -28) // 노즈
      ..quadraticBezierTo(14, -10, 12, 18)
      ..quadraticBezierTo(0, 26, -12, 18)
      ..quadraticBezierTo(-14, -10, 0, -28)
      ..close();
    canvas.drawPath(boardPath, boardPaint);

    // 보드 스트라이프 라인
    final stripePaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;
    canvas.drawLine(const Offset(0, -24), const Offset(0, 22), stripePaint);

    // 3. 깨비 캐릭터 본체 (서핑 포즈)
    final kkaebiPaint = Paint()..color = const Color(0xFFFFD54F);
    canvas.drawCircle(const Offset(0, -6), 14, kkaebiPaint);

    // 깨비 도깨비 뿔
    final hornPaint = Paint()..color = const Color(0xFFFFB300);
    final hornPath = Path()
      ..moveTo(-5, -18)
      ..lineTo(0, -28)
      ..lineTo(5, -18)
      ..close();
    canvas.drawPath(hornPath, hornPaint);

    // 눈
    final eyePaint = Paint()..color = Colors.black87;
    canvas.drawCircle(const Offset(-4, -8), 2.5, eyePaint);
    canvas.drawCircle(const Offset(4, -8), 2.5, eyePaint);

    // 웃는 입
    final mouthPaint = Paint()
      ..color = Colors.redAccent
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8;
    canvas.drawArc(
      Rect.fromCenter(center: const Offset(0, -3), width: 8, height: 6),
      0,
      pi,
      false,
      mouthPaint,
    );

    // 피버 모드 오라
    if (model.isFever) {
      canvas.drawCircle(const Offset(0, -6), 26, Paint()..color = Colors.amberAccent.withOpacity(0.25));
      canvas.drawCircle(
        const Offset(0, -6),
        22,
        Paint()
          ..color = Colors.amberAccent.withOpacity(0.6)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3.5,
      );
    }

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _OceanSurferPainter oldDelegate) => true;
}

