import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../core/sound_service.dart';
import '../core/theme.dart';
import '../providers/dokkey_provider.dart';
import 'core/game_shell.dart';

/// 💥 게임 4: 도깨비 벽돌깨기 — 순수 로직 모델
class BreakoutModel {
  final double width, height;
  final Random rng;

  double paddleX; // 중심
  final double paddleW;
  static const double paddleYOffset = 56;
  static const double ballR = 6.5;

  final List<Ball> balls = [];
  final List<Brick> bricks = [];
  final List<PowerUp> powerUps = [];
  final List<Laser> lasers = [];

  int score = 0;
  int lives = 3;
  bool gameOver = false;
  bool cleared = false;

  double paddleWideTimer = 0;
  double fireballTimer = 0;
  double laserTimer = 0;
  double _laserCd = 0;

  int cols = 7;
  int rows = 6;

  BreakoutModel({
    required this.width,
    required this.height,
    Random? random,
  })  : rng = random ?? Random(),
        paddleX = width / 2,
        paddleW = width * 0.24 {
    _buildBricks();
    _resetBall();
  }

  bool get fireballActive => fireballTimer > 0;
  bool get laserActive => laserTimer > 0;
  double get paddleTop => height - paddleYOffset;

  void _buildBricks() {
    final bw = (width - 24) / cols;
    const bh = 22.0;
    // 벽돌 상단 여백 (50px): 공이 상단 벽돌을 뚫고 올라갔을 때 상단 천장(0~50px)에서 시원하게 튕김
    const topMargin = 45.0;

    final rowColors = [
      const Color(0xFFFF3366), // 1열: 루비 레드 (HP: 2)
      const Color(0xFFFF6D00), // 2열: 앰버 오렌지 (HP: 2)
      const Color(0xFFFFD600), // 3열: 골드 옐로우
      const Color(0xFF00E676), // 4열: 에메랄드 그린
      const Color(0xFF00E5FF), // 5열: 시안 블루
      const Color(0xFFB388FF), // 6열: 아메시스트 퍼플
    ];

    for (var r = 0; r < rows; r++) {
      for (var c = 0; c < cols; c++) {
        final isCoin = rng.nextDouble() < 0.12;
        bricks.add(Brick(
          x: 12 + c * bw,
          y: topMargin + r * (bh + 6),
          w: bw - 5,
          h: bh,
          hp: (r < 2) ? 2 : 1,
          maxHp: (r < 2) ? 2 : 1,
          isCoin: isCoin,
          color: rowColors[r % rowColors.length],
        ));
      }
    }
  }

  void _resetBall() {
    balls
      ..clear()
      ..add(Ball(
        x: paddleX,
        y: paddleTop - ballR - 3,
        vx: (rng.nextDouble() > 0.5 ? 1 : -1) * 160,
        vy: -320,
      ));
  }

  void movePaddle(double x) {
    final pw = paddleWideTimer > 0 ? paddleW * 1.45 : paddleW;
    paddleX = x.clamp(pw / 2 + 6, width - pw / 2 - 6);
  }

  void applyPowerUp(PowerUpType type) {
    switch (type) {
      case PowerUpType.multi:
        if (balls.isNotEmpty) {
          final src = balls.first;
          balls.add(Ball(
            x: src.x,
            y: src.y,
            vx: -src.vx * 0.9,
            vy: src.vy,
          ));
          balls.add(Ball(
            x: src.x,
            y: src.y,
            vx: src.vy * 0.5,
            vy: -src.vx.abs() * 0.7 - 120,
          ));
        }
        break;
      case PowerUpType.fireball:
        fireballTimer = 8.0;
        break;
      case PowerUpType.wide:
        paddleWideTimer = 10.0;
        break;
      case PowerUpType.laser:
        laserTimer = 8.0;
        break;
      case PowerUpType.coin:
        score += 50;
        break;
    }
  }

  /// 한 틱 업데이트. 반환: 파괴된 벽돌 좌표 목록
  List<Offset> update(double dt) {
    final destroyedPoints = <Offset>[];
    if (gameOver || cleared) return destroyedPoints;

    paddleWideTimer = max(0, paddleWideTimer - dt);
    fireballTimer = max(0, fireballTimer - dt);
    laserTimer = max(0, laserTimer - dt);
    final pw = paddleWideTimer > 0 ? paddleW * 1.45 : paddleW;

    // 레이저 자동 발사
    if (laserActive) {
      _laserCd -= dt;
      if (_laserCd <= 0) {
        _laserCd = 0.35;
        lasers.add(Laser(x: paddleX - pw * 0.35, y: paddleTop));
        lasers.add(Laser(x: paddleX + pw * 0.35, y: paddleTop));
      }
    }
    for (final laser in lasers) {
      laser.y -= 540 * dt;
      for (final brick in bricks) {
        if (brick.hp > 0 &&
            laser.x >= brick.x &&
            laser.x <= brick.x + brick.w &&
            laser.y <= brick.y + brick.h &&
            laser.y >= brick.y) {
          laser.dead = true;
          brick.hp--;
          if (brick.hp <= 0) {
            destroyedPoints.add(Offset(brick.x + brick.w / 2, brick.y + brick.h / 2));
            score += 25;
          } else {
            score += 10;
          }
          break;
        }
      }
    }
    lasers.removeWhere((l) => l.dead || l.y < -10);

    // 공 물리 업데이트
    for (final ball in balls) {
      ball.x += ball.vx * dt;
      ball.y += ball.vy * dt;

      // 1. 좌우 벽 반사
      if (ball.x < ballR + 6) {
        ball.x = ballR + 6;
        ball.vx = ball.vx.abs();
      }
      if (ball.x > width - ballR - 6) {
        ball.x = width - ballR - 6;
        ball.vx = -ball.vx.abs();
      }

      // 2. 상단 천장 반사 (수정: 실제 화면 최상단 벽 ballR+4까지 도달하여 시원하게 튕김)
      if (ball.y < ballR + 4) {
        ball.y = ballR + 4;
        ball.vy = ball.vy.abs();
      }

      // 3. 패들 반사 (입사각에 따른 조향)
      if (ball.vy > 0 &&
          ball.y + ballR >= paddleTop &&
          ball.y - ballR < paddleTop + 14 &&
          ball.x >= paddleX - pw / 2 - ballR &&
          ball.x <= paddleX + pw / 2 + ballR) {
        final rel = ((ball.x - paddleX) / (pw / 2)).clamp(-1.0, 1.0);
        final currentSpeed = sqrt(ball.vx * ball.vx + ball.vy * ball.vy);
        final speed = min(max(320.0, currentSpeed * 1.02), 580.0);
        final angle = rel * (pi / 3); // 최대 60도
        ball.vx = sin(angle) * speed;
        ball.vy = -cos(angle) * speed;
        ball.y = paddleTop - ballR - 1;
        try {
          HapticFeedback.lightImpact();
        } catch (_) {}
      }

      // 4. 벽돌 충돌 판정
      for (final brick in bricks) {
        if (brick.hp <= 0) continue;
        if (ball.x + ballR > brick.x &&
            ball.x - ballR < brick.x + brick.w &&
            ball.y + ballR > brick.y &&
            ball.y - ballR < brick.y + brick.h) {
          // 침투 깊이로 반사축 결정
          final overlapLeft = ball.x + ballR - brick.x;
          final overlapRight = brick.x + brick.w - (ball.x - ballR);
          final overlapTop = ball.y + ballR - brick.y;
          final overlapBottom = brick.y + brick.h - (ball.y - ballR);
          final minOverlap = min(min(overlapLeft, overlapRight), min(overlapTop, overlapBottom));

          if (!fireballActive) {
            if (minOverlap == overlapLeft) {
              ball.vx = -ball.vx.abs();
            } else if (minOverlap == overlapRight) {
              ball.vx = ball.vx.abs();
            } else if (minOverlap == overlapTop) {
              ball.vy = -ball.vy.abs();
            } else {
              ball.vy = ball.vy.abs();
            }
          }

          brick.hp--;
          if (brick.hp <= 0) {
            destroyedPoints.add(Offset(brick.x + brick.w / 2, brick.y + brick.h / 2));
            score += brick.isCoin ? 100 : 30;
            if (brick.isCoin) applyPowerUp(PowerUpType.coin);
          } else {
            score += 15;
          }

          // 파워업 아이템 드랍
          if (rng.nextDouble() < 0.16) {
            final types = PowerUpType.values;
            powerUps.add(PowerUp(
              x: brick.x + brick.w / 2,
              y: brick.y + brick.h / 2,
              type: types[rng.nextInt(types.length)],
            ));
          }
          break;
        }
      }

      // 5. 바닥 낙하 판정
      if (ball.y > height + 20) {
        ball.dead = true;
      }
    }
    balls.removeWhere((b) => b.dead);

    if (balls.isEmpty && !cleared) {
      lives--;
      if (lives <= 0) {
        gameOver = true;
      } else {
        _resetBall();
      }
    }

    // 파워업 낙하 및 패들 획득
    for (final pu in powerUps) {
      pu.y += 140 * dt;
      if (pu.y >= paddleTop - 12 &&
          pu.y <= paddleTop + 20 &&
          (pu.x - paddleX).abs() < pw / 2 + 14) {
        pu.dead = true;
        applyPowerUp(pu.type);
        score += 40;
        SoundService().playCoinJangle();
      }
    }
    powerUps.removeWhere((p) => p.dead || p.y > height + 20);

    // 모든 벽돌 파괴 시 클리어
    if (bricks.every((b) => b.hp <= 0)) {
      cleared = true;
    }
    return destroyedPoints;
  }
}

class Ball {
  double x, y, vx, vy;
  bool dead = false;
  Ball({required this.x, required this.y, required this.vx, required this.vy});
}

class Brick {
  final double x, y, w, h;
  int hp;
  final int maxHp;
  final bool isCoin;
  final Color color;
  Brick({
    required this.x,
    required this.y,
    required this.w,
    required this.h,
    required this.hp,
    required this.maxHp,
    required this.isCoin,
    required this.color,
  });
}

enum PowerUpType { multi, fireball, wide, laser, coin }

class PowerUp {
  double x, y;
  final PowerUpType type;
  bool dead = false;
  PowerUp({required this.x, required this.y, required this.type});
}

class Laser {
  final double x;
  double y;
  bool dead = false;
  Laser({required this.x, required this.y});
}

/// 💥 게임 4: 도깨비 벽돌깨기 화면
class KkaebiBreakoutGame extends StatefulWidget {
  const KkaebiBreakoutGame({super.key});

  static const String gameId = 'breakout';

  @override
  State<KkaebiBreakoutGame> createState() => _KkaebiBreakoutGameState();
}

class _KkaebiBreakoutGameState extends State<KkaebiBreakoutGame>
    with GameLoopMixin {
  BreakoutModel? model;
  bool _finished = false;
  Size _field = Size.zero;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final mq = MediaQuery.of(context);
      _field = Size(
        mq.size.width,
        mq.size.height - mq.padding.top - mq.padding.bottom - 90,
      );
      setState(() {
        model = BreakoutModel(width: _field.width, height: _field.height);
      });
    });
  }

  @override
  void onUpdate(double dt) {
    if (_finished || model == null || model!.width == 0) return;
    final destroyed = model!.update(dt);
    for (final pt in destroyed) {
      shake.add(0.2);
      particles.burst(
        x: pt.dx,
        y: pt.dy,
        count: 14,
        speed: 200,
        color: const Color(0xFFFFD700),
      );
      SoundService().playSuccessChime();
    }

    if (model!.gameOver || model!.cleared) {
      _finished = true;
      if (model!.cleared) {
        shake.add(0.5);
        particles.burst(
          x: _field.width / 2,
          y: _field.height / 2,
          color: const Color(0xFFFFE66D),
          count: 50,
          speed: 320,
          size: 6,
        );
      }
      finishGame(
        context,
        gameId: KkaebiBreakoutGame.gameId,
        title: '깨비 벽돌깨기',
        score: model!.score,
        cleared: model!.cleared,
        onRetry: () => Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const KkaebiBreakoutGame()),
        ),
      );
    }
  }

  @override
  void onPaint(Canvas canvas, Size size) {
    // 배경: 심해/밤하늘 그라데이션
    canvas.drawRect(
      Offset.zero & size,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF141926), Color(0xFF0C101A)],
        ).createShader(Offset.zero & size),
    );

    // 상단/좌우 네온 사이드 프레임 (천장 및 벽 경계선 가시화)
    final wallPaint = Paint()
      ..color = const Color(0xFFFFD700).withOpacity(0.35)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
    canvas.drawLine(const Offset(4, 2), Offset(size.width - 4, 2), wallPaint); // 상단 천장 벽
    canvas.drawLine(const Offset(4, 2), Offset(4, size.height), wallPaint); // 좌측 벽
    canvas.drawLine(Offset(size.width - 4, 2), Offset(size.width - 4, size.height), wallPaint); // 우측 벽

    if (model == null || model!.width == 0) return;

    // 1. 3D 입체 베벨 벽돌 렌더링
    for (final brick in model!.bricks) {
      if (brick.hp <= 0) continue;
      final rect = Rect.fromLTWH(brick.x, brick.y, brick.w, brick.h);
      final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(5));

      // 벽돌 본체 채색
      canvas.drawRRect(
        rrect,
        Paint()
          ..color = brick.isCoin
              ? const Color(0xFFFFD700)
              : (brick.hp == 2 ? brick.color : brick.color.withOpacity(0.75)),
      );

      // 입체 베벨 하이라이트 (상단/좌측)
      final hlPaint = Paint()
        ..color = Colors.white.withOpacity(0.4)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2;
      canvas.drawLine(rect.topLeft + const Offset(1, 1), rect.topRight + const Offset(-1, 1), hlPaint);
      canvas.drawLine(rect.topLeft + const Offset(1, 1), rect.bottomLeft + const Offset(1, -1), hlPaint);

      // 입체 베벨 음영 (하단/우측)
      final shPaint = Paint()
        ..color = Colors.black.withOpacity(0.35)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2;
      canvas.drawLine(rect.bottomLeft + const Offset(1, -1), rect.bottomRight + const Offset(-1, -1), shPaint);
      canvas.drawLine(rect.topRight + const Offset(-1, 1), rect.bottomRight + const Offset(-1, -1), shPaint);

      // 코인 벽돌 아이콘 표시
      if (brick.isCoin) {
        canvas.drawCircle(
          Offset(brick.x + brick.w / 2, brick.y + brick.h / 2),
          6,
          Paint()..color = const Color(0xFFB8860B),
        );
      }
    }

    // 2. 공 (오브 & 불꽃 효과)
    for (final ball in model!.balls) {
      // 발광 외곽 오라
      canvas.drawCircle(
        Offset(ball.x, ball.y),
        BreakoutModel.ballR + 4,
        Paint()
          ..color = model!.fireballActive
              ? const Color(0xFFFF3D00).withOpacity(0.45)
              : const Color(0xFFFFD700).withOpacity(0.35)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
      );
      // 공 본체
      canvas.drawCircle(
        Offset(ball.x, ball.y),
        BreakoutModel.ballR,
        Paint()..color = model!.fireballActive ? const Color(0xFFFF3D00) : const Color(0xFFFFF9C4),
      );
    }

    // 3. 패들 (황금 도깨비 방망이)
    final pw = model!.paddleWideTimer > 0 ? model!.paddleW * 1.45 : model!.paddleW;
    final paddleRect = Rect.fromLTWH(
      model!.paddleX - pw / 2,
      model!.paddleTop,
      pw,
      13,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(paddleRect, const Radius.circular(7)),
      Paint()
        ..shader = const LinearGradient(
          colors: [Color(0xFFFFD700), Color(0xFFFF9100)],
        ).createShader(paddleRect),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(paddleRect, const Radius.circular(7)),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5
        ..color = Colors.white.withOpacity(0.6),
    );

    // 4. 레이저 빔
    for (final laser in model!.lasers) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(Rect.fromLTWH(laser.x - 2.5, laser.y, 5, 16), const Radius.circular(3)),
        Paint()..color = const Color(0xFF00E5FF),
      );
    }

    // 5. 파워업 드랍 캡슐
    for (final pu in model!.powerUps) {
      final (icon, color) = switch (pu.type) {
        PowerUpType.multi => ('x2', const Color(0xFF00E5FF)),
        PowerUpType.fireball => ('🔥', const Color(0xFFFF3D00)),
        PowerUpType.wide => ('↔', const Color(0xFF00E676)),
        PowerUpType.laser => ('⚡', const Color(0xFFFFD600)),
        PowerUpType.coin => ('💰', const Color(0xFFFFD700)),
      };

      // 캡슐 배경
      final puRect = Rect.fromCenter(center: Offset(pu.x, pu.y), width: 26, height: 26);
      canvas.drawRRect(
        RRect.fromRectAndRadius(puRect, const Radius.circular(13)),
        Paint()..color = const Color(0xFF1E283C),
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(puRect, const Radius.circular(13)),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5
          ..color = color,
      );

      final tp = TextPainter(
        text: TextSpan(
          text: icon,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(pu.x - tp.width / 2, pu.y - tp.height / 2));
    }

    particles.paint(canvas);
  }

  @override
  Widget build(BuildContext context) {
    final isKo = context.watch<DokkeyProvider>().lang == 'ko';
    final hearts = List.generate(3, (i) => i < (model?.lives ?? 3) ? '❤️' : '🖤').join(' ');

    return Scaffold(
      backgroundColor: DokkeyTheme.bgDark,
      body: SafeArea(
        child: Column(
          children: [
            GameHud(
              title: isKo ? '깨비 벽돌깨기' : 'Kkaebi Breakout',
              score: model?.score ?? 0,
              rightLabel: '생명: $hearts',
              onQuit: () => Navigator.of(context).pop(),
              accent: const Color(0xFFFF5722),
            ),
            // 활성화된 파워업 상태 표시 배너
            if (model != null &&
                (model!.fireballActive || model!.paddleWideTimer > 0 || model!.laserActive))
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                color: const Color(0xFF1E2433),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (model!.fireballActive)
                      _buildBuffTag('🔥 파이어볼 ${model!.fireballTimer.toStringAsFixed(1)}s', const Color(0xFFFF5722)),
                    if (model!.paddleWideTimer > 0)
                      _buildBuffTag('↔ 와이드패들 ${model!.paddleWideTimer.toStringAsFixed(1)}s', const Color(0xFF00E676)),
                    if (model!.laserActive)
                      _buildBuffTag('⚡ 레이저건 ${model!.laserTimer.toStringAsFixed(1)}s', const Color(0xFF00E5FF)),
                  ],
                ),
              ),
            Expanded(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onPanUpdate: (d) {
                  model?.movePaddle(d.localPosition.dx);
                },
                onTapDown: (d) {
                  model?.movePaddle(d.localPosition.dx);
                },
                child: gameCanvas(overlayBuilder: () => const SizedBox.expand()),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBuffTag(String text, Color color) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color, width: 1.0),
      ),
      child: Text(
        text,
        style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold),
      ),
    );
  }
}
