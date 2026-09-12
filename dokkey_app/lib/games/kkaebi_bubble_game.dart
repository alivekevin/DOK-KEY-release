import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../core/sound_service.dart';
import '../core/theme.dart';
import '../providers/dokkey_provider.dart';
import 'core/game_shell.dart';

/// 🫧 게임 5: 깨비 뽀글뽀글 (Bubble Bobble Action Platformer) — 순수 로직 모델
enum MonsterType { walker, jumper, dasher }
enum ItemType { apple, banana, grape, diamond, crown }

class GamePlatform {
  final double x, y, w, h;
  const GamePlatform(this.x, this.y, this.w, this.h);

  Rect get rect => Rect.fromLTWH(x, y, w, h);
}

class BubbleEntity {
  double x, y, vx, vy;
  double age = 0;
  bool isFloating = false;
  MonsterType? trapped;
  bool dead = false;

  BubbleEntity({
    required this.x,
    required this.y,
    required this.vx,
    required this.vy,
    this.trapped,
  });
}

class MonsterEntity {
  double x, y, vx, vy;
  MonsterType type;
  bool facingLeft;
  bool onGround = false;
  double jumpTimer = 0;
  bool isTrapped = false;
  bool dead = false;

  MonsterEntity({
    required this.x,
    required this.y,
    required this.type,
    this.facingLeft = true,
  })  : vx = facingLeft ? -80.0 : 80.0,
        vy = 0;
}

class FruitItem {
  double x, y, vx, vy;
  ItemType type;
  int scoreValue;
  bool onGround = false;
  bool dead = false;

  FruitItem({
    required this.x,
    required this.y,
    required this.type,
    required this.scoreValue,
    required this.vx,
    required this.vy,
  });
}

class BubbleBobbleModel {
  final double width, height;
  final Random rng;

  // 플레이어 (깨비) 상태
  double playerX = 60, playerY = 100;
  double playerVx = 0, playerVy = 0;
  bool playerFacingLeft = false;
  bool playerOnGround = false;
  double shootCooldown = 0;
  double invulnerableTimer = 0;

  int score = 0;
  int lives = 3;
  int stage = 1;
  static const int maxStages = 5;
  bool gameOver = false;
  bool cleared = false;

  final List<GamePlatform> platforms = [];
  final List<BubbleEntity> bubbles = [];
  final List<MonsterEntity> monsters = [];
  final List<FruitItem> items = [];

  static const double gravity = 820.0;
  static const double moveSpeed = 165.0;
  static const double jumpSpeed = -410.0;

  BubbleBobbleModel({
    required this.width,
    required this.height,
    Random? random,
  }) : rng = random ?? Random() {
    _buildStagePlatforms();
    _spawnStageMonsters();
  }

  void _buildStagePlatforms() {
    platforms.clear();
    // 바닥 플랫폼 (중앙 구멍 뚫림 -> 뽀글뽀글 특유의 바닥 낙하 시 천장 워프)
    const floorH = 14.0;
    final floorY = height - 42.0;
    platforms.add(GamePlatform(0, floorY, width * 0.42, floorH));
    platforms.add(GamePlatform(width * 0.58, floorY, width * 0.42, floorH));

    // 1단 플랫폼 (좌/우)
    final y1 = height * 0.72;
    platforms.add(GamePlatform(24, y1, width * 0.38, 12));
    platforms.add(GamePlatform(width * 0.62 - 24, y1, width * 0.38, 12));

    // 2단 플랫폼 (중앙 브릿지)
    final y2 = height * 0.48;
    platforms.add(GamePlatform(width * 0.22, y2, width * 0.56, 12));

    // 3단 플랫폼 (상단 좌/우/중앙)
    final y3 = height * 0.26;
    platforms.add(GamePlatform(20, y3, width * 0.28, 12));
    platforms.add(GamePlatform(width * 0.40, y3 - 16, width * 0.20, 12));
    platforms.add(GamePlatform(width * 0.72 - 20, y3, width * 0.28, 12));
  }

  void _spawnStageMonsters() {
    monsters.clear();
    bubbles.clear();
    items.clear();
    playerX = width * 0.2;
    playerY = height * 0.65;
    playerVx = 0;
    playerVy = 0;

    final count = min(2 + stage, 6);
    for (var i = 0; i < count; i++) {
      final type = i == 0
          ? MonsterType.walker
          : (i == 1 ? MonsterType.jumper : (stage >= 3 ? MonsterType.dasher : MonsterType.walker));
      final spawnX = (width * 0.35 + (i * 50)) % (width - 60) + 30;
      final spawnY = height * (0.2 + (i % 3) * 0.22);
      monsters.add(MonsterEntity(
        x: spawnX,
        y: spawnY,
        type: type,
        facingLeft: i.isEven,
      ));
    }
  }

  void moveLeft() {
    playerVx = -moveSpeed;
    playerFacingLeft = true;
  }

  void moveRight() {
    playerVx = moveSpeed;
    playerFacingLeft = false;
  }

  void stopMove() {
    playerVx = 0;
  }

  void jump() {
    if (playerOnGround) {
      playerVy = jumpSpeed;
      playerOnGround = false;
      try {
        HapticFeedback.lightImpact();
      } catch (_) {}
    }
  }

  void shootBubble() {
    if (shootCooldown > 0 || gameOver || cleared) return;
    shootCooldown = 0.32;
    final dir = playerFacingLeft ? -1.0 : 1.0;
    bubbles.add(BubbleEntity(
      x: playerX + (playerFacingLeft ? -14 : 14),
      y: playerY - 4,
      vx: dir * 300.0,
      vy: -20.0,
    ));
    try {
      HapticFeedback.selectionClick();
    } catch (_) {}
  }

  /// 한 틱 업데이트. 반환: 터진 방울/몬스터 이벤트 목록
  int update(double dt) {
    if (gameOver || cleared) return 0;

    var poppedCount = 0;
    shootCooldown = max(0, shootCooldown - dt);
    invulnerableTimer = max(0, invulnerableTimer - dt);

    // 1. 플레이어 물리 & 플랫폼 충돌
    playerVy += gravity * dt;
    playerX += playerVx * dt;
    playerY += playerVy * dt;

    // 좌우 화면 워프 (Wrapping)
    if (playerX < -12) playerX = width + 10;
    if (playerX > width + 12) playerX = -10;

    // 바닥 구멍 낙하 시 천장 위에서 재등장 (Bubble Bobble 고유 기믹)
    if (playerY > height + 20) {
      playerY = -15;
      playerVy = 120;
    }

    // 플랫폼 착지 검사 (하강 중일 때만 위에서 밟음)
    playerOnGround = false;
    if (playerVy >= 0) {
      for (final plat in platforms) {
        if (playerX + 10 > plat.x &&
            playerX - 10 < plat.x + plat.w &&
            playerY >= plat.y &&
            playerY - playerVy * dt <= plat.y + 6) {
          playerY = plat.y;
          playerVy = 0;
          playerOnGround = true;
          break;
        }
      }
    }

    // 2. 버블 물리 & 몬스터 포획
    for (final b in bubbles) {
      b.age += dt;
      if (!b.isFloating) {
        b.x += b.vx * dt;
        b.y += b.vy * dt;
        b.vx *= 0.90; // 발사 감속
        if (b.vx.abs() < 30 || b.age > 0.35) {
          b.isFloating = true;
          b.vy = -38.0; // 천천히 부유
          b.vx = sin(b.age * 3) * 15;
        }
      } else {
        b.y += b.vy * dt;
        b.x += sin(b.age * 2.5) * 20 * dt;
        // 천장 도달 시 상단에 머무름
        if (b.y < 35) {
          b.y = 35;
          b.vy = 0;
        }
      }

      // 좌우 화면 워프
      if (b.x < -10) b.x = width + 8;
      if (b.x > width + 10) b.x = -8;

      // 몬스터 포획 검사 (빈 방울일 때)
      if (b.trapped == null) {
        for (final m in monsters) {
          if (!m.isTrapped && !m.dead) {
            final dist = (Offset(b.x, b.y) - Offset(m.x, m.y)).distance;
            if (dist < 22) {
              m.isTrapped = true;
              b.trapped = m.type;
              b.isFloating = true;
              b.vy = -45.0;
              break;
            }
          }
        }
      }

      // 플레이어와 버블 상호작용 (터뜨리기 또는 버블 점프)
      final pDist = (Offset(playerX, playerY - 10) - Offset(b.x, b.y)).distance;
      if (pDist < 26) {
        // 위에서 밟으면 버블 점프!
        if (playerVy > 50 && playerY < b.y) {
          playerVy = jumpSpeed * 0.92;
          playerOnGround = false;
        }

        // 갇힌 몬스터 방울 터뜨리기 (POP!)
        if (b.trapped != null) {
          b.dead = true;
          poppedCount++;
          score += 200;
          // 과일/보석 드랍
          final itemTypes = ItemType.values;
          final it = itemTypes[rng.nextInt(itemTypes.length)];
          items.add(FruitItem(
            x: b.x,
            y: b.y,
            type: it,
            scoreValue: switch (it) {
              ItemType.apple => 100,
              ItemType.banana => 200,
              ItemType.grape => 300,
              ItemType.diamond => 500,
              ItemType.crown => 1000,
            },
            vx: (rng.nextDouble() - 0.5) * 120,
            vy: -220,
          ));
        } else if (b.age > 0.6) {
          // 일반 빈 방울 터뜨림
          b.dead = true;
          score += 10;
        }
      }

      // 수명 만료 (9초 후 자연 파열)
      if (b.age > 9.0) {
        b.dead = true;
      }
    }
    bubbles.removeWhere((b) => b.dead);

    // 3. 몬스터 인공지능 & 이동
    for (final m in monsters) {
      if (m.isTrapped || m.dead) continue;

      m.vy += gravity * dt;
      m.x += m.vx * dt;
      m.y += m.vy * dt;

      // 화면 좌우 반사
      if (m.x < 16) {
        m.x = 16;
        m.vx = m.vx.abs();
        m.facingLeft = false;
      }
      if (m.x > width - 16) {
        m.x = width - 16;
        m.vx = -m.vx.abs();
        m.facingLeft = true;
      }

      // 바닥 워프
      if (m.y > height + 20) {
        m.y = -10;
        m.vy = 80;
      }

      // 플랫폼 착지
      m.onGround = false;
      if (m.vy >= 0) {
        for (final plat in platforms) {
          if (m.x + 8 > plat.x &&
              m.x - 8 < plat.x + plat.w &&
              m.y >= plat.y &&
              m.y - m.vy * dt <= plat.y + 6) {
            m.y = plat.y;
            m.vy = 0;
            m.onGround = true;
            break;
          }
        }
      }

      // 점핑/돌진 행동 패턴
      m.jumpTimer -= dt;
      if (m.jumpTimer <= 0 && m.onGround) {
        m.jumpTimer = 1.2 + rng.nextDouble() * 2.0;
        if (m.type == MonsterType.jumper) {
          m.vy = jumpSpeed * 0.85;
        } else if (m.type == MonsterType.dasher) {
          m.vx = (playerX < m.x ? -130.0 : 130.0);
          m.facingLeft = m.vx < 0;
        }
      }

      // 플레이어와 충돌 (데미지)
      if (invulnerableTimer <= 0) {
        final dist = (Offset(playerX, playerY - 12) - Offset(m.x, m.y - 10)).distance;
        if (dist < 20) {
          lives--;
          invulnerableTimer = 2.2;
          playerVy = -260;
          playerVx = playerX > m.x ? 120 : -120;
          if (lives <= 0) {
            gameOver = true;
          }
        }
      }
    }
    monsters.removeWhere((m) => m.isTrapped && bubbles.every((b) => b.trapped == null || (Offset(b.x, b.y) - Offset(m.x, m.y)).distance > 2));

    // 4. 아이템 물리 & 획득
    for (final it in items) {
      it.vy += gravity * dt;
      it.x += it.vx * dt;
      it.y += it.vy * dt;
      it.vx *= 0.96;

      // 플랫폼 착지
      if (it.vy >= 0) {
        for (final plat in platforms) {
          if (it.x + 8 > plat.x &&
              it.x - 8 < plat.x + plat.w &&
              it.y >= plat.y &&
              it.y - it.vy * dt <= plat.y + 6) {
            it.y = plat.y;
            it.vy = -it.vy * 0.4; // 통통 튐
            if (it.vy.abs() < 30) it.vy = 0;
            break;
          }
        }
      }

      // 플레이어 아이템 획득
      final dist = (Offset(playerX, playerY - 12) - Offset(it.x, it.y - 8)).distance;
      if (dist < 22) {
        it.dead = true;
        score += it.scoreValue;
        try {
          SoundService().playCoinJangle();
        } catch (_) {}
      }
    }
    items.removeWhere((it) => it.dead || it.y > height + 40);

    // 5. 스테이지 클리어 체크 (모든 몬스터 처치 완료)
    if (monsters.isEmpty && bubbles.every((b) => b.trapped == null)) {
      if (stage < maxStages) {
        stage++;
        score += 500;
        _spawnStageMonsters();
      } else {
        cleared = true;
      }
    }

    return poppedCount;
  }
}

/// 🫧 게임 5: 깨비 뽀글뽀글 메인 화면
class KkaebiBubbleGame extends StatefulWidget {
  const KkaebiBubbleGame({super.key});

  static const String gameId = 'bubble';

  @override
  State<KkaebiBubbleGame> createState() => _KkaebiBubbleGameState();
}

class _KkaebiBubbleGameState extends State<KkaebiBubbleGame>
    with GameLoopMixin {
  BubbleBobbleModel? model;
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
        mq.size.height - mq.padding.top - mq.padding.bottom - 165,
      );
      setState(() {
        model = BubbleBobbleModel(width: _field.width, height: _field.height);
      });
    });
  }

  @override
  void onUpdate(double dt) {
    if (_finished || model == null || model!.width == 0) return;
    final popped = model!.update(dt);
    if (popped > 0) {
      shake.add(0.3 * popped);
      SoundService().playSuccessChime();
    }

    if (model!.gameOver || model!.cleared) {
      _finished = true;
      if (model!.cleared) {
        shake.add(0.6);
        particles.burst(
          x: _field.width / 2,
          y: _field.height / 2,
          color: const Color(0xFFFFD700),
          count: 60,
          speed: 320,
          size: 6,
        );
      }
      finishGame(
        context,
        gameId: KkaebiBubbleGame.gameId,
        title: '깨비 뽀글뽀글',
        score: model!.score,
        cleared: model!.cleared,
        onRetry: () => Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const KkaebiBubbleGame()),
        ),
      );
    }
  }

  @override
  void onPaint(Canvas canvas, Size size) {
    // 배경: 레트로 아케이드 밤하늘
    canvas.drawRect(
      Offset.zero & size,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF10192A), Color(0xFF090E18)],
        ).createShader(Offset.zero & size),
    );

    if (model == null || model!.width == 0) return;

    // 1. 플랫폼 렌더링 (한지 목재 블록)
    for (final plat in model!.platforms) {
      final rect = plat.rect;
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, const Radius.circular(5)),
        Paint()..color = const Color(0xFF2C394F),
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, const Radius.circular(5)),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.4
          ..color = const Color(0xFF38BDF8).withOpacity(0.6),
      );
      // 상단 잔디/금빛 라인
      canvas.drawLine(
        rect.topLeft + const Offset(2, 1),
        rect.topRight + const Offset(-2, 1),
        Paint()
          ..strokeWidth = 2
          ..color = const Color(0xFF00E676),
      );
    }

    // 2. 버블 렌더링 (신비한 도깨비 무지개 방울)
    for (final b in model!.bubbles) {
      final isTrapped = b.trapped != null;
      final bubbleColor = isTrapped ? const Color(0xFF00E676) : const Color(0xFF38BDF8);

      // 발광 오라
      canvas.drawCircle(
        Offset(b.x, b.y),
        16,
        Paint()
          ..color = bubbleColor.withOpacity(0.35)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5),
      );
      // 방울 본체
      canvas.drawCircle(
        Offset(b.x, b.y),
        14,
        Paint()..color = bubbleColor.withOpacity(0.45),
      );
      canvas.drawCircle(
        Offset(b.x, b.y),
        14,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.8
          ..color = bubbleColor,
      );
      // 하이라이트 반사광
      canvas.drawCircle(
        Offset(b.x - 4, b.y - 4),
        3.5,
        Paint()..color = Colors.white.withOpacity(0.8),
      );

      // 갇힌 몬스터 이모지/표시
      if (isTrapped) {
        final tp = TextPainter(
          text: const TextSpan(text: '👾', style: TextStyle(fontSize: 14)),
          textDirection: TextDirection.ltr,
        )..layout();
        tp.paint(canvas, Offset(b.x - tp.width / 2, b.y - tp.height / 2));
      }
    }

    // 3. 몬스터 렌더링
    for (final m in model!.monsters) {
      if (m.isTrapped || m.dead) continue;
      final (icon, color) = switch (m.type) {
        MonsterType.walker => ('👹', const Color(0xFFFF5252)),
        MonsterType.jumper => ('👾', const Color(0xFFB388FF)),
        MonsterType.dasher => ('👺', const Color(0xFFFF9100)),
      };

      // 몬스터 하단 그림자
      canvas.drawOval(
        Rect.fromCenter(center: Offset(m.x, m.y + 2), width: 18, height: 6),
        Paint()..color = Colors.black45,
      );

      final tp = TextPainter(
        text: TextSpan(
          text: icon,
          style: TextStyle(fontSize: 20, color: color),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(m.x - tp.width / 2, m.y - tp.height));
    }

    // 4. 드랍 아이템 (과일, 보석)
    for (final it in model!.items) {
      final icon = switch (it.type) {
        ItemType.apple => '🍎',
        ItemType.banana => '🍌',
        ItemType.grape => '🍇',
        ItemType.diamond => '💎',
        ItemType.crown => '👑',
      };
      final tp = TextPainter(
        text: TextSpan(text: icon, style: const TextStyle(fontSize: 16)),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(it.x - tp.width / 2, it.y - tp.height));
    }

    // 5. 플레이어 (깨비) 렌더링
    if (model!.invulnerableTimer <= 0 || (model!.invulnerableTimer * 10).floor().isEven) {
      // 깨비 발밑 그림자
      canvas.drawOval(
        Rect.fromCenter(center: Offset(model!.playerX, model!.playerY + 2), width: 22, height: 6),
        Paint()..color = Colors.black45,
      );

      // 깨비 캐릭터 (도깨비 요정)
      final kkaebiIcon = model!.playerFacingLeft ? '👺' : '👺';
      final charTp = TextPainter(
        text: TextSpan(
          text: kkaebiIcon,
          style: const TextStyle(fontSize: 24),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      charTp.paint(canvas, Offset(model!.playerX - charTp.width / 2, model!.playerY - charTp.height + 2));
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
            // 상단 통합 HUD
            GameHud(
              title: isKo ? '깨비 뽀글뽀글' : 'Kkaebi Bubble Bobble',
              score: model?.score ?? 0,
              rightLabel: 'STAGE ${model?.stage ?? 1} · $hearts',
              onQuit: () => Navigator.of(context).pop(),
              accent: const Color(0xFF00E676),
            ),

            // 게임 캔버스 뷰포트
            Expanded(
              child: gameCanvas(overlayBuilder: () => const SizedBox.expand()),
            ),

            // 🎮 하단 아케이드 양손 게임패드 (왼손: 좌/우, 오른손: 버블발사/점프)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: const BoxDecoration(
                color: Color(0xFF101622),
                border: Border(top: BorderSide(color: Color(0xFF28354D), width: 1.5)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // [왼손 엄지 영역: 좌 / 우 이동]
                  Row(
                    children: [
                      _HoldBtn(
                        icon: Icons.arrow_back_rounded,
                        label: isKo ? '좌' : 'Left',
                        color: const Color(0xFF38BDF8),
                        onDown: () => model?.moveLeft(),
                        onUp: () => model?.stopMove(),
                      ),
                      const SizedBox(width: 10),
                      _HoldBtn(
                        icon: Icons.arrow_forward_rounded,
                        label: isKo ? '우' : 'Right',
                        color: const Color(0xFF38BDF8),
                        onDown: () => model?.moveRight(),
                        onUp: () => model?.stopMove(),
                      ),
                    ],
                  ),

                  // [오른손 엄지 영역: 버블 발사 & 점프]
                  Row(
                    children: [
                      // 🫧 버블 발사
                      _ActionBtn(
                        icon: Icons.bubble_chart_rounded,
                        label: isKo ? '버블 발사' : 'Bubble',
                        color: const Color(0xFF00E676),
                        onTap: () => model?.shootBubble(),
                      ),
                      const SizedBox(width: 10),
                      // ⬆ 점프
                      _ActionBtn(
                        icon: Icons.arrow_upward_rounded,
                        label: isKo ? '점프' : 'Jump',
                        color: const Color(0xFFFFD700),
                        isPrimary: true,
                        onTap: () => model?.jump(),
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

/// 누르고 있는 동안 이동을 유지하는 홀드 버튼
class _HoldBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onDown;
  final VoidCallback onUp;

  const _HoldBtn({
    required this.icon,
    required this.label,
    required this.color,
    required this.onDown,
    required this.onUp,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) {
        HapticFeedback.selectionClick();
        onDown();
      },
      onTapUp: (_) => onUp(),
      onTapCancel: () => onUp(),
      child: Container(
        width: 62,
        height: 52,
        decoration: BoxDecoration(
          color: const Color(0xFF1E283C),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withOpacity(0.7), width: 1.4),
          boxShadow: const [
            BoxShadow(color: Colors.black38, blurRadius: 4, offset: Offset(0, 2)),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 22, color: color),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: color),
            ),
          ],
        ),
      ),
    );
  }
}

/// 단타 액션 버튼 (버블 발사, 점프)
class _ActionBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  final bool isPrimary;

  const _ActionBtn({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
    this.isPrimary = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: Container(
        width: isPrimary ? 68 : 64,
        height: 52,
        decoration: BoxDecoration(
          color: isPrimary ? const Color(0xFF332712) : const Color(0xFF132A22),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isPrimary ? const Color(0xFFFFD700) : color,
            width: isPrimary ? 2.0 : 1.4,
          ),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.25),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 22, color: color),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w900,
                color: isPrimary ? const Color(0xFFFFE66D) : color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
