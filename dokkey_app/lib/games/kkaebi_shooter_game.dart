import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../core/sound_service.dart';
import '../core/theme.dart';
import '../providers/dokkey_provider.dart';
import 'core/game_shell.dart';

/// 🚀 게임 6: 깨비 X-RION (정통 엑세리온 하이엔드 아케이드 슈팅)
/// 3D 원근 그리드 지형 스크롤 + 관성 뱅킹 비행 + 듀얼 웨폰 + 곡선 급강하 편대 AI + 위성 드론

enum XrionEnemyType { grunt, diver, heavy, boss }
enum XrionItemType { power, shield, bomb, energy }

class XrionBullet {
  double x, y, vx, vy;
  bool isVulcan;
  bool isPlayer;
  bool dead = false;

  XrionBullet({
    required this.x,
    required this.y,
    required this.vx,
    required this.vy,
    this.isVulcan = false,
    this.isPlayer = true,
  });
}

class XrionEnemy {
  double x, y;
  double formationX, formationY;
  double vx = 0, vy = 0;
  XrionEnemyType type;
  int hp;
  int maxHp;
  bool isDiving = false;
  double diveTimer = 0;
  double diveAngle = 0;
  double animTick = 0;
  bool dead = false;

  XrionEnemy({
    required this.x,
    required this.y,
    required this.type,
    required this.formationX,
    required this.formationY,
  })  : hp = switch (type) {
          XrionEnemyType.grunt => 1,
          XrionEnemyType.diver => 2,
          XrionEnemyType.heavy => 4,
          XrionEnemyType.boss => 60,
        },
        maxHp = switch (type) {
          XrionEnemyType.grunt => 1,
          XrionEnemyType.diver => 2,
          XrionEnemyType.heavy => 4,
          XrionEnemyType.boss => 60,
        };
}

class XrionDropItem {
  double x, y, vy;
  XrionItemType type;
  bool dead = false;

  XrionDropItem({
    required this.x,
    required this.y,
    required this.type,
    this.vy = 85.0,
  });
}

class XrionStar {
  double x, y, speed, size;
  Color color;
  XrionStar({required this.x, required this.y, required this.speed, required this.size, required this.color});
}

/// 🚀 X-RION 순수 로직 모델
class XrionModel {
  double width, height;
  final Random rng;

  // 플레이어 기체 상태
  double shipX, shipY;
  double shipVx = 0, shipVy = 0;
  double rollAngle = 0.0; // 3D 뱅킹 각도 (-0.45 ~ +0.45 rad)
  
  int score = 0;
  int lives = 3;
  int shields = 1; // 기본 1회 방어 쉴드
  int bombs = 2; // 전면 폭탄
  bool hasSatellites = false; // 아기 도깨비 위성 드론
  double vulcanEnergy = 100.0; // 0 ~ 100
  static const double maxVulcanEnergy = 100.0;

  double invulnerableTimer = 2.0; // 무적 시간
  bool gameOver = false;
  bool cleared = false;
  int stage = 1;

  final List<XrionBullet> bullets = [];
  final List<XrionEnemy> enemies = [];
  final List<XrionDropItem> items = [];
  final List<XrionStar> stars = [];

  // 3D 그리드 지형
  double gridZ = 0.0;
  double horizonY;

  // 내부 쿨다운 타이머
  double _dualBeamCd = 0;
  double _vulcanCd = 0;
  double _enemyFireCd = 1.0;
  double _waveSpawnCd = 0;
  double _diveCooldown = 2.0;
  bool _bossSpawned = false;

  XrionModel({
    required this.width,
    required this.height,
    Random? random,
  })  : rng = random ?? Random(),
        shipX = width / 2,
        shipY = height * 0.76,
        horizonY = height * 0.28 {
    _initStarfield();
    _spawnFormationWave();
  }

  void resize(double newW, double newH) {
    if (newW <= 10 || newH <= 10) return;
    final scaleX = newW / (width > 0 ? width : newW);
    final scaleY = newH / (height > 0 ? height : newH);
    width = newW;
    height = newH;
    horizonY = height * 0.28;
    shipX = (shipX * scaleX).clamp(24.0, width - 24.0);
    shipY = (shipY * scaleY).clamp(horizonY + 20.0, height - 30.0);
  }

  void _initStarfield() {
    stars.clear();
    for (var i = 0; i < 45; i++) {
      final depth = rng.nextDouble();
      stars.add(XrionStar(
        x: rng.nextDouble() * width,
        y: rng.nextDouble() * height,
        speed: 40 + depth * 160,
        size: 1.0 + depth * 2.2,
        color: depth > 0.7 ? const Color(0xFF64FFDA) : (depth > 0.4 ? Colors.white : const Color(0xFF90CAF9)),
      ));
    }
  }

  void _spawnFormationWave() {
    if (gameOver || cleared) return;
    enemies.clear();
    final rows = min(2 + stage, 4);
    final cols = 6;
    final startY = horizonY + 30;
    final startX = width * 0.15;
    final spacingX = (width * 0.7) / (cols - 1);
    final spacingY = 44.0;

    for (var r = 0; r < rows; r++) {
      final type = r == 0
          ? (stage >= 2 ? XrionEnemyType.heavy : XrionEnemyType.diver)
          : (r == 1 ? XrionEnemyType.diver : XrionEnemyType.grunt);
      for (var c = 0; c < cols; c++) {
        final fx = startX + c * spacingX;
        final fy = startY + r * spacingY;
        enemies.add(XrionEnemy(
          x: fx + (rng.nextDouble() - 0.5) * 40,
          y: -50 - (r * 30.0),
          formationX: fx,
          formationY: fy,
          type: type,
        ));
      }
    }
  }

  void _spawnBoss() {
    _bossSpawned = true;
    enemies.clear();
    enemies.add(XrionEnemy(
      x: width / 2,
      y: -80,
      formationX: width / 2,
      formationY: horizonY + 60,
      type: XrionEnemyType.boss,
    ));
  }

  /// 8방향 가상 조이스틱 / 드래그 입력 (dx: -1.0 ~ 1.0, dy: -1.0 ~ 1.0)
  void applyInput(double dx, double dy) {
    const accel = 920.0;
    shipVx += dx * accel * 0.016;
    shipVy += dy * accel * 0.016;
  }

  /// 직접 터치 드래그 위치로 부드럽게 유도
  void dragTo(Offset target) {
    final diffX = target.dx - shipX;
    final diffY = target.dy - shipY;
    shipVx += diffX * 7.5;
    shipVy += diffY * 7.5;
  }

  /// 1. 고속 듀얼 레이저 (Twin Beam) 발사
  bool fireDualBeam() {
    if (_dualBeamCd > 0 || gameOver || cleared) return false;
    _dualBeamCd = 0.18; // 초당 5.5회

    final spread = hasSatellites ? 18.0 : 12.0;
    // 메인 기체 트윈 샷
    bullets.add(XrionBullet(x: shipX - spread, y: shipY - 14, vx: 0, vy: -580, isVulcan: false));
    bullets.add(XrionBullet(x: shipX + spread, y: shipY - 14, vx: 0, vy: -580, isVulcan: false));

    // 위성 드론 추가 샷
    if (hasSatellites) {
      bullets.add(XrionBullet(x: shipX - 32, y: shipY + 2, vx: -40, vy: -550, isVulcan: false));
      bullets.add(XrionBullet(x: shipX + 32, y: shipY + 2, vx: 40, vy: -550, isVulcan: false));
    }
    return true;
  }

  /// 2. 오토 발칸 캐논 (Rapid Vulcan) 연사 발사
  bool fireVulcan() {
    if (_vulcanCd > 0 || vulcanEnergy < 1.0 || gameOver || cleared) return false;
    _vulcanCd = 0.075; // 초당 ~13.3발 고속 머신건
    vulcanEnergy = max(0.0, vulcanEnergy - 1.25);

    final rx = (rng.nextDouble() - 0.5) * 6.0;
    bullets.add(XrionBullet(
      x: shipX + rx,
      y: shipY - 18,
      vx: (rng.nextDouble() - 0.5) * 35.0,
      vy: -680,
      isVulcan: true,
    ));
    return true;
  }

  /// 3. 도깨비 벼락 폭탄 (Tactical Bomb)
  bool triggerBomb() {
    if (bombs <= 0 || gameOver || cleared) return false;
    bombs--;
    // 모든 적 탄환 소멸
    bullets.removeWhere((b) => !b.isPlayer);
    // 화면 내 모든 일반 적 전멸, 보스에게는 25 데미지
    for (final e in enemies) {
      if (e.type == XrionEnemyType.boss) {
        e.hp = max(0, e.hp - 25);
      } else {
        e.hp = 0;
      }
    }
    return true;
  }

  /// 매 프레임 업데이트
  void update(double dt, {void Function(Offset pos, Color color, int count)? onExplosion}) {
    if (gameOver || cleared) return;

    // 쿨다운 및 회복
    _dualBeamCd = max(0, _dualBeamCd - dt);
    _vulcanCd = max(0, _vulcanCd - dt);
    invulnerableTimer = max(0, invulnerableTimer - dt);
    // 발칸 에너지 자동 완속 회복
    vulcanEnergy = min(maxVulcanEnergy, vulcanEnergy + 6.0 * dt);

    // 1. 관성 물리 & 기체 뱅킹
    if (shipX.isNaN) shipX = width / 2;
    if (shipY.isNaN) shipY = height * 0.82;
    if (shipVx.isNaN) shipVx = 0;
    if (shipVy.isNaN) shipVy = 0;

    const maxSpeed = 340.0;
    const friction = 0.88;
    shipVx = (shipVx * pow(friction, dt * 60)).clamp(-maxSpeed, maxSpeed);
    shipVy = (shipVy * pow(friction, dt * 60)).clamp(-maxSpeed, maxSpeed);

    shipX = (shipX + shipVx * dt).clamp(24.0, width - 24.0);
    shipY = (shipY + shipVy * dt).clamp(horizonY + 20.0, height - 30.0);

    // 목표 뱅킹 각도 계산 (좌우 속도에 비례하여 부드럽게 틸트)
    final targetRoll = (shipVx / maxSpeed) * 0.45;
    rollAngle += (targetRoll - rollAngle) * 0.18;

    // 2. 3D 지형 그리드 및 별빛 스크롤
    gridZ = (gridZ + dt * 1.8) % 1.0;
    for (final s in stars) {
      s.y += s.speed * dt;
      if (s.y > height) {
        s.y = 0;
        s.x = rng.nextDouble() * width;
      }
    }

    // 3. 총알 이동 및 충돌
    for (final b in bullets) {
      b.x += b.vx * dt;
      b.y += b.vy * dt;
      if (b.y < -20 || b.y > height + 20 || b.x < -20 || b.x > width + 20) {
        b.dead = true;
      }
    }

    // 플레이어 총알 vs 적기 충돌
    for (final b in bullets.where((b) => b.isPlayer && !b.dead)) {
      for (final e in enemies.where((e) => !e.dead)) {
        final hitRadius = e.type == XrionEnemyType.boss ? 48.0 : (e.type == XrionEnemyType.heavy ? 22.0 : 16.0);
        final dist = (Offset(b.x, b.y) - Offset(e.x, e.y)).distance;
        if (dist < hitRadius) {
          b.dead = true;
          final dmg = b.isVulcan ? 1 : 2;
          e.hp -= dmg;
          onExplosion?.call(Offset(b.x, b.y), b.isVulcan ? Colors.amber : const Color(0xFF64FFDA), 4);

          if (e.hp <= 0) {
            e.dead = true;
            final killScore = switch (e.type) {
              XrionEnemyType.grunt => 50,
              XrionEnemyType.diver => 100,
              XrionEnemyType.heavy => 250,
              XrionEnemyType.boss => 1500,
            };
            score += killScore;
            // 적 격추 시 발칸 에너지 +10 보너스 충전
            vulcanEnergy = min(maxVulcanEnergy, vulcanEnergy + 10.0);
            onExplosion?.call(Offset(e.x, e.y), const Color(0xFFFF5252), e.type == XrionEnemyType.boss ? 40 : 16);

            // 아이템 드랍 확률
            if (e.type == XrionEnemyType.heavy || e.type == XrionEnemyType.boss || rng.nextDouble() < 0.15) {
              final itemPool = [XrionItemType.power, XrionItemType.shield, XrionItemType.bomb, XrionItemType.energy];
              items.add(XrionDropItem(
                x: e.x,
                y: e.y,
                type: itemPool[rng.nextInt(itemPool.length)],
              ));
            }
          }
          break;
        }
      }
    }

    // 적기 총알 vs 플레이어 충돌
    if (invulnerableTimer <= 0) {
      for (final b in bullets.where((b) => !b.isPlayer && !b.dead)) {
        final dist = (Offset(b.x, b.y) - Offset(shipX, shipY)).distance;
        if (dist < 18) {
          b.dead = true;
          _takeDamage(onExplosion);
          break;
        }
      }
    }
    bullets.removeWhere((b) => b.dead);

    // 4. 적기 AI: 편대 진입 + 베지어 곡선 급강하
    _diveCooldown -= dt;
    final divingEnemies = enemies.where((e) => e.isDiving && !e.dead).length;
    if (_diveCooldown <= 0 && divingEnemies < (1 + stage)) {
      _diveCooldown = 2.2 - (stage * 0.3).clamp(0.2, 1.5);
      final eligible = enemies.where((e) => !e.isDiving && !e.dead && e.type != XrionEnemyType.boss).toList();
      if (eligible.isNotEmpty) {
        final diver = eligible[rng.nextInt(eligible.length)];
        diver.isDiving = true;
        diver.diveTimer = 0;
        diver.diveAngle = atan2(shipY - diver.y, shipX - diver.x);
      }
    }

    for (final e in enemies.where((e) => !e.dead)) {
      e.animTick += dt * 8;
      if (e.type == XrionEnemyType.boss) {
        // 보스 기동 패턴 (좌우 부유 + 부채꼴 탄막)
        e.y += (e.formationY - e.y) * 0.05;
        e.x = width / 2 + sin(e.animTick * 0.4) * (width * 0.35);
        if (rng.nextDouble() < 0.04) {
          // 3웨이 조준 탄막
          final baseAng = atan2(shipY - e.y, shipX - e.x);
          for (var a = -1; a <= 1; a++) {
            final ang = baseAng + a * 0.22;
            bullets.add(XrionBullet(
              x: e.x,
              y: e.y + 24,
              vx: cos(ang) * 230,
              vy: sin(ang) * 230,
              isPlayer: false,
            ));
          }
        }
      } else if (e.isDiving) {
        // 급강하 다이빙 물리 (베지어 S자 곡선 돌진)
        e.diveTimer += dt;
        final speed = (e.type == XrionEnemyType.diver ? 320.0 : 250.0);
        e.x += cos(e.diveAngle + sin(e.diveTimer * 4.5) * 0.9) * speed * dt;
        e.y += (sin(e.diveAngle).abs() * speed + 60.0) * dt;

        // 급강하 중 조준 사격
        if (rng.nextDouble() < 0.02) {
          bullets.add(XrionBullet(
            x: e.x,
            y: e.y + 10,
            vx: (shipX - e.x).clamp(-120.0, 120.0),
            vy: 240,
            isPlayer: false,
          ));
        }

        // 화면 하단 통과 시 상단 편대로 복귀
        if (e.y > height + 30) {
          e.y = -30;
          e.x = e.formationX;
          e.isDiving = false;
        }
      } else {
        // 편대 대기 비행 (부드러운 사인파 진동)
        e.formationX += sin(e.animTick * 0.3) * 15 * dt;
        e.x += (e.formationX - e.x) * 0.08;
        e.y += (e.formationY - e.y) * 0.08;
      }

      // 적기 몸통 충돌 판정
      if (invulnerableTimer <= 0) {
        final hitRadius = e.type == XrionEnemyType.boss ? 42.0 : 20.0;
        final dist = (Offset(e.x, e.y) - Offset(shipX, shipY)).distance;
        if (dist < hitRadius) {
          _takeDamage(onExplosion);
          if (e.type != XrionEnemyType.boss) {
            e.dead = true;
          }
        }
      }
    }

    // 적기 일반 발사 쿨다운
    _enemyFireCd -= dt;
    final aliveEnemies = enemies.where((e) => !e.dead).toList();
    if (_enemyFireCd <= 0 && aliveEnemies.isNotEmpty) {
      _enemyFireCd = max(0.4, 1.4 - (stage * 0.15));
      final shooter = aliveEnemies[rng.nextInt(aliveEnemies.length)];
      bullets.add(XrionBullet(
        x: shooter.x,
        y: shooter.y + 12,
        vx: (shipX - shooter.x) * 0.8,
        vy: 220,
        isPlayer: false,
      ));
    }

    // 5. 드랍 아이템 이동 및 획득
    for (final it in items) {
      it.y += it.vy * dt;
      if (it.y > height + 20) it.dead = true;

      final dist = (Offset(it.x, it.y) - Offset(shipX, shipY)).distance;
      if (dist < 26) {
        it.dead = true;
        score += 200;
        switch (it.type) {
          case XrionItemType.power:
            hasSatellites = true;
            break;
          case XrionItemType.shield:
            shields = min(2, shields + 1);
            break;
          case XrionItemType.bomb:
            bombs = min(4, bombs + 1);
            break;
          case XrionItemType.energy:
            vulcanEnergy = maxVulcanEnergy;
            break;
        }
        try {
          SoundService().playCoinJangle();
        } catch (_) {}
      }
    }
    items.removeWhere((it) => it.dead);
    enemies.removeWhere((e) => e.dead);

    // 6. 웨이브 클리어 및 보스전 전환
    if (enemies.isEmpty) {
      _waveSpawnCd -= dt;
      if (_waveSpawnCd <= 0) {
        _waveSpawnCd = 1.6;
        if (!_bossSpawned && stage % 2 == 0) {
          _spawnBoss();
        } else {
          _bossSpawned = false;
          stage++;
          score += 1000;
          if (stage > 5) {
            cleared = true;
          } else {
            _spawnFormationWave();
          }
        }
      }
    }
  }

  void _takeDamage(void Function(Offset pos, Color color, int count)? onExplosion) {
    if (shields > 0) {
      shields--;
      invulnerableTimer = 1.2;
      onExplosion?.call(Offset(shipX, shipY), const Color(0xFF00E5FF), 20);
      try {
        HapticFeedback.mediumImpact();
      } catch (_) {}
      return;
    }

    lives--;
    invulnerableTimer = 2.5;
    hasSatellites = false;
    onExplosion?.call(Offset(shipX, shipY), const Color(0xFFFF3D00), 35);
    try {
      HapticFeedback.heavyImpact();
    } catch (_) {}

    if (lives <= 0) {
      gameOver = true;
    }
  }
}

/// 🚀 깨비 X-RION 위젯 (캔버스 렌더러 + 아케이드 컨트롤러)
class KkaebiShooterGame extends StatefulWidget {
  const KkaebiShooterGame({super.key});

  static const String gameId = 'shooter';

  @override
  State<KkaebiShooterGame> createState() => _KkaebiShooterGameState();
}

class _KkaebiShooterGameState extends State<KkaebiShooterGame> with GameLoopMixin {
  XrionModel? model;
  bool _finished = false;
  bool _isHoldingVulcan = false;

  // 가상 조이스틱
  Offset _stickCenter = Offset.zero;
  Offset _stickDelta = Offset.zero;
  bool _isDraggingStick = false;

  @override
  void onUpdate(double dt) {
    if (_finished || model == null || model!.width == 0) return;

    // 조이스틱 입력 반영
    if (_isDraggingStick) {
      final normX = (_stickDelta.dx / 40.0).clamp(-1.0, 1.0);
      final normY = (_stickDelta.dy / 40.0).clamp(-1.0, 1.0);
      model!.applyInput(normX, normY);
    }

    // 발칸 꾹 누름 연사 처리
    if (_isHoldingVulcan) {
      if (model!.fireVulcan()) {
        try {
          HapticFeedback.selectionClick();
        } catch (_) {}
      }
    }

    model!.update(dt, onExplosion: (pos, color, count) {
      particles.burst(
        x: pos.dx,
        y: pos.dy,
        color: color,
        count: count,
        speed: 260,
      );
      if (count > 25) shake.add(0.4);
    });

    if (model!.gameOver || model!.cleared) {
      _finished = true;
      particles.burst(
        x: model!.shipX,
        y: model!.shipY,
        color: const Color(0xFFFFD54F),
        count: 60,
        speed: 340,
        size: 5,
      );
      shake.add(0.6);

      finishGame(
        context,
        gameId: KkaebiShooterGame.gameId,
        title: '깨비 X-RION',
        score: model!.score,
        cleared: model!.cleared,
        onRetry: () => Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const KkaebiShooterGame()),
        ),
      );
    }
  }

  @override
  void onPaint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) return;
    if (model == null || model!.width <= 10) {
      model = XrionModel(width: size.width, height: size.height);
    } else if ((model!.width - size.width).abs() > 10 || (model!.height - size.height).abs() > 10) {
      model!.resize(size.width, size.height);
    }
    final m = model!;

    // 1. 심우주 배경
    final bgPaint = Paint()
      ..shader = ui.Gradient.linear(
        Offset.zero,
        Offset(0, size.height),
        [const Color(0xFF030712), const Color(0xFF0D1B2A), const Color(0xFF000814)],
      );
    canvas.drawRect(Offset.zero & size, bgPaint);

    // 2. 3D 원근 그리드 지형 (지평선 아래)
    final horizonY = m.horizonY;
    final gridPaint = Paint()
      ..color = const Color(0xFF00E5FF).withOpacity(0.28)
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;

    final vanishingPoint = Offset(size.width / 2, horizonY);

    // 방사형 세로 그리드 선 (소실점에서 아래로 퍼짐)
    const numRays = 16;
    for (var i = 0; i <= numRays; i++) {
      final bottomX = (i / numRays) * size.width * 1.6 - (size.width * 0.3);
      canvas.drawLine(vanishingPoint, Offset(bottomX, size.height), gridPaint);
    }

    // 전진하는 가로 그리드 링 (로그 원근감)
    const numRings = 10;
    for (var i = 0; i < numRings; i++) {
      final t = ((i + m.gridZ) / numRings);
      final curveT = pow(t, 2.4).toDouble(); // 원근감 가속
      final y = horizonY + curveT * (size.height - horizonY);
      final alpha = (curveT * 0.45).clamp(0.05, 0.45);
      final ringPaint = Paint()
        ..color = const Color(0xFF00E5FF).withOpacity(alpha)
        ..strokeWidth = 1.0 + curveT * 1.5;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), ringPaint);
    }

    // 지평선 네온 광선
    final glowLine = Paint()
      ..color = const Color(0xFF00E5FF).withOpacity(0.8)
      ..strokeWidth = 2.5
      ..maskFilter = const MaskFilter.blur(BlurStyle.solid, 4);
    canvas.drawLine(Offset(0, horizonY), Offset(size.width, horizonY), glowLine);

    // 3. 패럴랙스 별무리
    for (final s in m.stars) {
      canvas.drawCircle(Offset(s.x, s.y), s.size, Paint()..color = s.color);
    }

    // 4. 드랍 아이템
    for (final it in m.items) {
      final (icon, color) = switch (it.type) {
        XrionItemType.power => ('P', const Color(0xFFFFD54F)),
        XrionItemType.shield => ('S', const Color(0xFF00E5FF)),
        XrionItemType.bomb => ('B', const Color(0xFFFF5252)),
        XrionItemType.energy => ('E', const Color(0xFF69F0AE)),
      };
      final itemPaint = Paint()
        ..color = color.withOpacity(0.25)
        ..style = PaintingStyle.fill;
      final borderPaint = Paint()
        ..color = color
        ..strokeWidth = 1.8
        ..style = PaintingStyle.stroke;
      canvas.drawCircle(Offset(it.x, it.y), 13, itemPaint);
      canvas.drawCircle(Offset(it.x, it.y), 13, borderPaint);

      final tp = TextPainter(
        text: TextSpan(text: icon, style: TextStyle(color: color, fontSize: 13, fontWeight: FontWeight.bold)),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(it.x - tp.width / 2, it.y - tp.height / 2));
    }

    // 5. 총알 렌더링
    for (final b in m.bullets) {
      if (b.isPlayer) {
        if (b.isVulcan) {
          // 발칸 탄환 (황금빛 고속 트레이서)
          final vPaint = Paint()
            ..color = const Color(0xFFFFE082)
            ..strokeWidth = 3.5
            ..strokeCap = StrokeCap.round;
          canvas.drawLine(Offset(b.x, b.y), Offset(b.x, b.y + 12), vPaint);
        } else {
          // 트윈 레이저 빔 (네온 시안 플라즈마)
          final lPaint = Paint()
            ..color = const Color(0xFF00E5FF)
            ..strokeWidth = 4.0
            ..strokeCap = StrokeCap.round
            ..maskFilter = const MaskFilter.blur(BlurStyle.solid, 2);
          canvas.drawLine(Offset(b.x, b.y), Offset(b.x, b.y + 18), lPaint);
        }
      } else {
        // 적 탄환 (붉은 플라즈마 구체)
        final ep = Paint()..color = const Color(0xFFFF1744);
        canvas.drawCircle(Offset(b.x, b.y), 4.5, ep);
        canvas.drawCircle(Offset(b.x, b.y), 2.2, Paint()..color = Colors.white);
      }
    }

    // 6. 적기 렌더링
    for (final e in m.enemies) {
      canvas.save();
      canvas.translate(e.x, e.y);
      if (e.isDiving) {
        canvas.rotate(e.diveAngle - pi / 2);
      }

      if (e.type == XrionEnemyType.boss) {
        // 보스 기체
        final bossBody = Path()
          ..moveTo(0, 38)
          ..lineTo(54, -20)
          ..lineTo(32, -38)
          ..lineTo(0, -28)
          ..lineTo(-32, -38)
          ..lineTo(-54, -20)
          ..close();
        canvas.drawPath(bossBody, Paint()..color = const Color(0xFF311B92));
        canvas.drawPath(bossBody, Paint()..color = const Color(0xFFE040FB)..style = PaintingStyle.stroke..strokeWidth = 2.5);

        // 보스 체력 게이지
        final hpRatio = (e.hp / e.maxHp).clamp(0.0, 1.0);
        canvas.drawRect(Rect.fromLTWH(-40, -48, 80, 5), Paint()..color = Colors.black54);
        canvas.drawRect(Rect.fromLTWH(-40, -48, 80 * hpRatio, 5), Paint()..color = const Color(0xFFFF1744));
      } else {
        // 일반 적기 (그룬트, 다이버, 헤비)
        final (bodyColor, wingColor) = switch (e.type) {
          XrionEnemyType.grunt => (const Color(0xFFFFD600), const Color(0xFFFF6D00)),
          XrionEnemyType.diver => (const Color(0xFFFF1744), const Color(0xFFFF8A80)),
          XrionEnemyType.heavy => (const Color(0xFF7C4DFF), const Color(0xFFB388FF)),
          _ => (Colors.white, Colors.grey),
        };
        final p = Path()
          ..moveTo(0, 14)
          ..lineTo(14, -12)
          ..lineTo(0, -6)
          ..lineTo(-14, -12)
          ..close();
        canvas.drawPath(p, Paint()..color = bodyColor);
        canvas.drawPath(p, Paint()..color = wingColor..style = PaintingStyle.stroke..strokeWidth = 1.5);

        // 날개 날갯짓 애니메이션
        final wingSpread = sin(e.animTick) * 4.0;
        canvas.drawLine(const Offset(-14, -4), Offset(-20 - wingSpread, -12), Paint()..color = wingColor..strokeWidth = 2);
        canvas.drawLine(const Offset(14, -4), Offset(20 + wingSpread, -12), Paint()..color = wingColor..strokeWidth = 2);
      }
      canvas.restore();
    }

    // 7. 플레이어 기체 (3D 뱅킹 & 위성 드론)
    canvas.save();
    canvas.translate(m.shipX, m.shipY);
    canvas.rotate(m.rollAngle);

    // 무적 상태 깜빡임
    if (m.invulnerableTimer <= 0 || (m.invulnerableTimer * 10).toInt().isEven) {
      // 제트 엔진 화염
      final flameLength = 12.0 + sin(DateTime.now().millisecondsSinceEpoch * 0.03) * 6;
      final flamePath = Path()
        ..moveTo(-6, 16)
        ..lineTo(0, 16 + flameLength)
        ..lineTo(6, 16)
        ..close();
      canvas.drawPath(flamePath, Paint()..color = const Color(0xFFFF9100)..maskFilter = const MaskFilter.blur(BlurStyle.solid, 3));

      // 메인 전투기 바디 (3D 사이버 제트)
      final shipPath = Path()
        ..moveTo(0, -22)
        ..lineTo(18, 14)
        ..lineTo(8, 10)
        ..lineTo(0, 16)
        ..lineTo(-8, 10)
        ..lineTo(-18, 14)
        ..close();
      canvas.drawPath(shipPath, Paint()..color = const Color(0xFFECEFF1));
      canvas.drawPath(shipPath, Paint()..color = const Color(0xFF00E5FF)..style = PaintingStyle.stroke..strokeWidth = 2.0);

      // 콕핏 캐노피
      canvas.drawOval(
        Rect.fromCenter(center: const Offset(0, -4), width: 7, height: 14),
        Paint()..color = const Color(0xFF00B0FF),
      );

      // 에너지 쉴드
      if (m.shields > 0) {
        final shieldPaint = Paint()
          ..color = const Color(0xFF00E5FF).withOpacity(0.35)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.2
          ..maskFilter = const MaskFilter.blur(BlurStyle.solid, 4);
        canvas.drawCircle(Offset.zero, 28, shieldPaint);
      }

      // 아기 도깨비 위성 드론
      if (m.hasSatellites) {
        for (final dir in [-1, 1]) {
          final droneX = dir * 32.0;
          canvas.drawCircle(Offset(droneX, 2), 6, Paint()..color = const Color(0xFFFFD54F));
        }
      }
    }
    canvas.restore();

    particles.paint(canvas);
  }

  @override
  Widget build(BuildContext context) {
    final isKo = context.watch<DokkeyProvider>().lang == 'ko';
    final hearts = List.generate(3, (i) => i < (model?.lives ?? 3) ? '❤️' : '🖤').join(' ');

    return Scaffold(
      backgroundColor: const Color(0xFF030712),
      body: SafeArea(
        child: Column(
          children: [
            // 상단 통합 HUD
            GameHud(
              title: isKo ? '깨비 X-RION' : 'Kkaebi X-RION',
              score: model?.score ?? 0,
              rightLabel: 'STAGE ${model?.stage ?? 1} · $hearts',
              onQuit: () => Navigator.of(context).pop(),
              accent: const Color(0xFF00E5FF),
            ),

            // 게임 뷰포트
            Expanded(
              child: Stack(
                children: [
                  Positioned.fill(
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onPanStart: (details) {
                        if (_stickCenter == Offset.zero && model != null) {
                          model!.dragTo(details.localPosition);
                        }
                      },
                      onPanUpdate: (details) {
                        if (_stickCenter == Offset.zero && model != null) {
                          model!.dragTo(details.localPosition);
                        }
                      },
                      child: gameCanvas(overlayBuilder: () => const SizedBox.expand()),
                    ),
                  ),

                  // 발칸 게이지 & 폭탄 인디케이터
                  if (model != null)
                    Positioned(
                      top: 10,
                      left: 14,
                      right: 14,
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.6),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: const Color(0xFF00E5FF).withOpacity(0.4)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Text('VULCAN ', style: TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.bold)),
                                Container(
                                  width: 60,
                                  height: 6,
                                  decoration: BoxDecoration(
                                    color: Colors.white12,
                                    borderRadius: BorderRadius.circular(3),
                                  ),
                                  child: FractionallySizedBox(
                                    alignment: Alignment.centerLeft,
                                    widthFactor: (model!.vulcanEnergy / 100.0).clamp(0.0, 1.0),
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: model!.vulcanEnergy > 20 ? const Color(0xFFFFD54F) : Colors.redAccent,
                                        borderRadius: BorderRadius.circular(3),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Spacer(),
                          if (model!.shields > 0)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: const Color(0xFF00E5FF).withOpacity(0.15),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: const Color(0xFF00E5FF)),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.shield, size: 14, color: Color(0xFF00E5FF)),
                                  SizedBox(width: 4),
                                  Text('SHIELD', style: TextStyle(color: Color(0xFF00E5FF), fontSize: 10, fontWeight: FontWeight.bold)),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),
                ],
              ),
            ),

            // 🎮 하단 컨트롤러 패드 (왼쪽: 아날로그 스틱, 오른쪽: 3버튼 런처)
            Container(
              padding: EdgeInsets.fromLTRB(16, 8, 16, max(10.0, MediaQuery.of(context).padding.bottom + 4)),
              decoration: const BoxDecoration(
                color: Color(0xFF080F1D),
                border: Border(top: BorderSide(color: Color(0xFF1E2D48), width: 1.5)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // 왼쪽: 가상 아날로그 스틱
                  GestureDetector(
                    onPanStart: (details) {
                      setState(() {
                        _isDraggingStick = true;
                        _stickCenter = details.localPosition;
                        _stickDelta = Offset.zero;
                      });
                    },
                    onPanUpdate: (details) {
                      setState(() {
                        final diff = details.localPosition - _stickCenter;
                        final dist = diff.distance;
                        if (dist > 36) {
                          _stickDelta = Offset.fromDirection(diff.direction, 36);
                        } else {
                          _stickDelta = diff;
                        }
                      });
                    },
                    onPanEnd: (_) {
                      setState(() {
                        _isDraggingStick = false;
                        _stickDelta = Offset.zero;
                      });
                    },
                    child: Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.black.withOpacity(0.5),
                        border: Border.all(color: const Color(0xFF00E5FF).withOpacity(0.4), width: 1.8),
                      ),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          const Icon(Icons.all_out, color: Colors.white24, size: 30),
                          Transform.translate(
                            offset: _stickDelta,
                            child: Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: const RadialGradient(
                                  colors: [Color(0xFF00E5FF), Color(0xFF007799)],
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFF00E5FF).withOpacity(0.6),
                                    blurRadius: 8,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // 오른쪽: 3버튼 런처 (BOMB / BEAM / RAPID)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // BOMB 버튼
                      GestureDetector(
                        onTapDown: (_) {
                          if (model != null && model!.triggerBomb()) {
                            try {
                              HapticFeedback.heavyImpact();
                            } catch (_) {}
                          }
                        },
                        child: Container(
                          width: 48,
                          height: 54,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            color: (model?.bombs ?? 0) > 0 ? const Color(0xFFFF1744).withOpacity(0.85) : Colors.white12,
                            border: Border.all(color: const Color(0xFFFF5252), width: 1.5),
                          ),
                          child: Center(
                            child: Text(
                              '💣\n${model?.bombs ?? 0}',
                              textAlign: TextAlign.center,
                              style: const TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),

                      // DUAL BEAM 버튼 (단발 고속 레이저)
                      GestureDetector(
                        onTapDown: (_) {
                          if (model != null && model!.fireDualBeam()) {
                            try {
                              HapticFeedback.lightImpact();
                            } catch (_) {}
                          }
                        },
                        child: Container(
                          width: 58,
                          height: 54,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            gradient: const LinearGradient(
                              colors: [Color(0xFF00E5FF), Color(0xFF0091EA)],
                            ),
                            border: Border.all(color: Colors.white, width: 1.8),
                            boxShadow: [
                              BoxShadow(color: const Color(0xFF00E5FF).withOpacity(0.4), blurRadius: 6),
                            ],
                          ),
                          child: const Center(
                            child: Text(
                              'BEAM\n⚡',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 10),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),

                      // RAPID VULCAN 버튼 (누르고 있으면 연사)
                      GestureDetector(
                        onTapDown: (_) {
                          setState(() {
                            _isHoldingVulcan = true;
                          });
                        },
                        onTapUp: (_) {
                          setState(() {
                            _isHoldingVulcan = false;
                          });
                        },
                        onTapCancel: () {
                          setState(() {
                            _isHoldingVulcan = false;
                          });
                        },
                        child: Container(
                          width: 62,
                          height: 54,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            gradient: const LinearGradient(
                              colors: [Color(0xFFFFD54F), Color(0xFFFF8F00)],
                            ),
                            border: Border.all(color: Colors.white, width: 2.0),
                            boxShadow: [
                              BoxShadow(color: const Color(0xFFFFD54F).withOpacity(0.5), blurRadius: 8),
                            ],
                          ),
                          child: const Center(
                            child: Text(
                              'RAPID\n🔥',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: Colors.black87, fontWeight: FontWeight.w900, fontSize: 11),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
