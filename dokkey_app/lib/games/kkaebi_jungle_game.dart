import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../core/sound_service.dart';
import '../core/theme.dart';
import '../providers/dokkey_provider.dart';
import 'core/game_shell.dart';

/// 🏛️ 게임 7: 깨비 고대 유적 (탑다운 미로 탐험 & 거대 굴림 바위 탈출)
/// 횃불 조명 + 은/금 2중 열쇠 + 보물 수집 + 인디아나 존스식 거대 굴림 바위(Boulder) 트랩

enum Direction { none, up, down, left, right }
enum TileType { floor, wall, silverDoor, goldDoor, exitGate, spikeTrap, switchTile }
enum GemType { ruby, emerald, diamond }

class GemItem {
  final int col, row;
  final GemType type;
  final int points;
  bool collected = false;

  GemItem({required this.col, required this.row, required this.type})
      : points = switch (type) {
          GemType.ruby => 100,
          GemType.emerald => 250,
          GemType.diamond => 500,
        };
}

class KeyItem {
  final int col, row;
  final bool isGold; // false = Silver, true = Gold
  bool collected = false;

  KeyItem({required this.col, required this.row, required this.isGold});
}

class RollingBoulder {
  double x, y;
  double vx, vy;
  double radius;
  double rotation = 0.0;
  bool active = false;

  RollingBoulder({
    required this.x,
    required this.y,
    required this.vx,
    required this.vy,
    this.radius = 18.0,
  });
}

/// 🏛️ 고대 유적 미로 순수 로직 모델
class RuinsMazeModel {
  final double width, height;
  final Random rng;

  static const int cols = 11;
  static const int rows = 15;

  late double tileSize;
  late double offsetX;
  late double offsetY;

  int stage = 1;
  static const int maxStages = 5;
  int score = 0;
  int lives = 3;
  bool gameOver = false;
  bool cleared = false;

  // 플레이어 상태
  int playerCol = 1, playerRow = 1;
  double renderX = 0, renderY = 0; // 부드러운 이동 보간 좌표
  Direction facing = Direction.down;
  bool hasSilverKey = false;
  bool hasGoldKey = false;
  bool exitOpen = false;

  // 대시 (질주) 부스터
  double dashTimer = 0.0;
  double dashCooldown = 0.0;
  bool get isDashing => dashTimer > 0;

  // 타일맵 & 엔티티
  late List<List<TileType>> grid;
  final List<GemItem> gems = [];
  final List<KeyItem> keys = [];
  final List<RollingBoulder> boulders = [];
  double spikeTimer = 0.0;
  bool spikeActive = false;
  bool boulderAlarm = false;

  RuinsMazeModel({
    required this.width,
    required this.height,
    Random? random,
  }) : rng = random ?? Random() {
    _calcDimensions();
    _loadStage(1);
  }

  void _calcDimensions() {
    final availableW = width - 16;
    final availableH = height - 16;
    tileSize = min(availableW / cols, availableH / rows).clamp(24.0, 48.0);
    offsetX = (width - cols * tileSize) / 2;
    offsetY = (height - rows * tileSize) / 2;
  }

  void _loadStage(int st) {
    stage = st;
    hasSilverKey = false;
    hasGoldKey = false;
    exitOpen = false;
    boulderAlarm = false;
    gems.clear();
    keys.clear();
    boulders.clear();
    playerCol = 1;
    playerRow = 1;
    renderX = offsetX + playerCol * tileSize + tileSize / 2;
    renderY = offsetY + playerRow * tileSize + tileSize / 2;

    // 맵 템플릿 생성 (11x15)
    grid = List.generate(rows, (r) => List.generate(cols, (c) {
      // 테두리는 모두 벽
      if (r == 0 || r == rows - 1 || c == 0 || c == cols - 1) return TileType.wall;
      return TileType.floor;
    }));

    // 스테이지별 고대 미로 구조
    _buildStageLayout(st);
  }

  void _buildStageLayout(int st) {
    // 내부 미로 벽 배치
    for (var r = 2; r < rows - 2; r += 2) {
      for (var c = 2; c < cols - 2; c += 2) {
        grid[r][c] = TileType.wall;
        // 가지 뻗기
        final dir = rng.nextInt(4);
        if (dir == 0 && r > 1) grid[r - 1][c] = TileType.wall;
        if (dir == 1 && r < rows - 2) grid[r + 1][c] = TileType.wall;
        if (dir == 2 && c > 1) grid[r][c - 1] = TileType.wall;
        if (dir == 3 && c < cols - 2) grid[r][c + 1] = TileType.wall;
      }
    }

    // 통로 확정 및 장애물/문 배치
    playerCol = 1;
    playerRow = 1;
    grid[1][1] = TileType.floor;
    grid[1][2] = TileType.floor;
    grid[2][1] = TileType.floor;

    // 출구 석문 (우측 하단)
    grid[rows - 2][cols - 2] = TileType.exitGate;

    // 은문 & 금문 배치
    grid[rows - 4][cols - 2] = TileType.goldDoor;
    if (st >= 2) {
      grid[rows ~/ 2][cols ~/ 2] = TileType.silverDoor;
    }

    // 열쇠 배치
    keys.add(KeyItem(col: cols - 2, row: 2, isGold: true));
    if (st >= 2) {
      keys.add(KeyItem(col: 2, row: rows - 3, isGold: false));
    }

    // 가시 함정 배치
    if (st >= 2) {
      grid[rows ~/ 2][2] = TileType.spikeTrap;
      grid[rows ~/ 2][cols - 3] = TileType.spikeTrap;
    }

    // 보석 보물 배치
    final gemTypes = [GemType.ruby, GemType.emerald, GemType.diamond];
    for (var i = 0; i < 4 + st; i++) {
      final gr = 2 + rng.nextInt(rows - 4);
      final gc = 2 + rng.nextInt(cols - 4);
      if (grid[gr][gc] == TileType.floor) {
        gems.add(GemItem(col: gc, row: gr, type: gemTypes[i % gemTypes.length]));
      }
    }

    // 8번 병합: 거대 굴림 바위 트랩 (스테이지 3부터 등장!)
    if (st >= 3) {
      final bx = offsetX + (cols - 2) * tileSize + tileSize / 2;
      final by = offsetY + 1 * tileSize + tileSize / 2;
      boulders.add(RollingBoulder(
        x: bx,
        y: by,
        vx: 0,
        vy: 165.0 + st * 15.0, // 아래로 맹렬하게 굴러옴
        radius: tileSize * 0.44,
      ));
    }
  }

  /// 4방향 이동 명령
  bool move(Direction dir) {
    if (gameOver || cleared) return false;
    facing = dir;

    var nextC = playerCol;
    var nextR = playerRow;

    switch (dir) {
      case Direction.up:
        nextR--;
        break;
      case Direction.down:
        nextR++;
        break;
      case Direction.left:
        nextC--;
        break;
      case Direction.right:
        nextC++;
        break;
      case Direction.none:
        return false;
    }

    if (nextC < 0 || nextC >= cols || nextR < 0 || nextR >= rows) return false;

    final targetTile = grid[nextR][nextC];
    // 1. 벽 충돌
    if (targetTile == TileType.wall) return false;

    // 2. 은문 충돌 & 해제
    if (targetTile == TileType.silverDoor) {
      if (hasSilverKey) {
        grid[nextR][nextC] = TileType.floor;
        score += 150;
        try {
          SoundService().playCoinJangle();
          HapticFeedback.mediumImpact();
        } catch (_) {}
      } else {
        return false; // 은 열쇠 필요
      }
    }

    // 3. 금문 충돌 & 해제
    if (targetTile == TileType.goldDoor) {
      if (hasGoldKey) {
        grid[nextR][nextC] = TileType.floor;
        score += 300;
        try {
          SoundService().playCoinJangle();
          HapticFeedback.heavyImpact();
        } catch (_) {}
      } else {
        return false; // 황금 열쇠 필요
      }
    }

    // 4. 이동 확정
    playerCol = nextC;
    playerRow = nextR;

    // 보석 아이템 획득 검사
    for (final gem in gems) {
      if (!gem.collected && gem.col == playerCol && gem.row == playerRow) {
        gem.collected = true;
        score += gem.points;
        try {
          SoundService().playCoinJangle();
          HapticFeedback.lightImpact();
        } catch (_) {}
      }
    }

    // 열쇠 획득 검사 & 바위 트랩 발동!
    for (final k in keys) {
      if (!k.collected && k.col == playerCol && k.row == playerRow) {
        k.collected = true;
        if (k.isGold) {
          hasGoldKey = true;
          score += 500;
          // 🪨 황금 열쇠 획득 시 거대 굴림 바위 발동!!
          for (final b in boulders) {
            b.active = true;
          }
          boulderAlarm = true;
        } else {
          hasSilverKey = true;
          score += 250;
        }
        try {
          SoundService().playSuccessChime();
          HapticFeedback.heavyImpact();
        } catch (_) {}
      }
    }

    // 출구 석문 도달 검사
    if (grid[playerRow][playerCol] == TileType.exitGate) {
      if (hasGoldKey) {
        _stageClear();
      }
    }

    return true;
  }

  /// 긴급 대시 (부스터 질주)
  bool triggerDash() {
    if (dashCooldown > 0 || gameOver || cleared) return false;
    dashTimer = 1.4;
    dashCooldown = 3.2;
    try {
      HapticFeedback.heavyImpact();
    } catch (_) {}
    return true;
  }

  void _stageClear() {
    score += 1000 + stage * 200;
    if (stage < maxStages) {
      _loadStage(stage + 1);
    } else {
      cleared = true;
    }
  }

  void _takeDamage() {
    lives--;
    try {
      HapticFeedback.heavyImpact();
    } catch (_) {}
    if (lives <= 0) {
      gameOver = true;
    } else {
      // 시작 지점으로 리스폰
      playerCol = 1;
      playerRow = 1;
      renderX = offsetX + playerCol * tileSize + tileSize / 2;
      renderY = offsetY + playerRow * tileSize + tileSize / 2;
    }
  }

  /// 매 프레임 업데이트
  void update(double dt, {void Function(Offset pos, Color color)? onDust}) {
    if (gameOver || cleared) return;

    dashTimer = max(0.0, dashTimer - dt);
    dashCooldown = max(0.0, dashCooldown - dt);

    // 1. 플레이어 렌더 좌표 부드러운 보간 (Interpolation)
    final targetX = offsetX + playerCol * tileSize + tileSize / 2;
    final targetY = offsetY + playerRow * tileSize + tileSize / 2;
    final lerpSpeed = isDashing ? 28.0 : 16.0;
    renderX += (targetX - renderX) * min(1.0, dt * lerpSpeed);
    renderY += (targetY - renderY) * min(1.0, dt * lerpSpeed);

    // 2. 가시 함정 주기적 작동
    spikeTimer += dt;
    spikeActive = (spikeTimer % 2.4) > 1.2;
    if (spikeActive && grid[playerRow][playerCol] == TileType.spikeTrap) {
      _takeDamage();
    }

    // 3. 거대 굴림 바위 물리 & 플레이어 압살 검사
    for (final b in boulders) {
      if (!b.active) continue;

      b.x += b.vx * dt;
      b.y += b.vy * dt;
      b.rotation += dt * 6.5;

      onDust?.call(Offset(b.x, b.y), const Color(0xFF8D6E63));

      // 벽이나 맵 끝에 부딪히면 정지/반사
      if (b.y > offsetY + (rows - 1) * tileSize) {
        b.y = offsetY + (rows - 1) * tileSize;
        b.vy = 0;
      }

      // 플레이어와 충돌 시 압살 (데미지)
      final dist = (Offset(renderX, renderY) - Offset(b.x, b.y)).distance;
      if (dist < b.radius + tileSize * 0.35) {
        _takeDamage();
        b.active = false; // 1회 피격 후 소멸
      }
    }
  }
}

/// 🏛️ 깨비 고대 유적 메인 화면
class KkaebiJungleGame extends StatefulWidget {
  const KkaebiJungleGame({super.key});

  static const String gameId = 'jungle';

  @override
  State<KkaebiJungleGame> createState() => _KkaebiJungleGameState();
}

class _KkaebiJungleGameState extends State<KkaebiJungleGame> with GameLoopMixin {
  RuinsMazeModel? model;
  bool _finished = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final size = MediaQuery.of(context).size;
      final playHeight = size.height - MediaQuery.of(context).padding.top - MediaQuery.of(context).padding.bottom - 170;
      setState(() {
        model = RuinsMazeModel(
          width: size.width,
          height: playHeight,
        );
      });
    });
  }

  @override
  void onUpdate(double dt) {
    if (_finished || model == null || model!.width == 0) return;

    model!.update(dt, onDust: (pos, color) {
      particles.burst(
        x: pos.dx,
        y: pos.dy,
        color: color,
        count: 2,
        speed: 80,
      );
    });

    if (model!.boulderAlarm) {
      model!.boulderAlarm = false;
      shake.add(0.5);
    }

    if (model!.gameOver || model!.cleared) {
      _finished = true;
      if (model!.cleared) {
        shake.add(0.6);
        particles.burst(
          x: model!.width / 2,
          y: model!.height / 2,
          color: const Color(0xFFFFD700),
          count: 50,
          speed: 300,
        );
      }
      finishGame(
        context,
        gameId: KkaebiJungleGame.gameId,
        title: '깨비 고대 유적',
        score: model!.score,
        cleared: model!.cleared,
        onRetry: () => Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const KkaebiJungleGame()),
        ),
      );
    }
  }

  @override
  void onPaint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) return;
    if (model == null || model!.width <= 10) {
      model = RuinsMazeModel(width: size.width, height: size.height);
    }
    final m = model!;

    // 1. 고대 유적 바닥 배경
    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = const Color(0xFF1D1712),
    );

    // 2. 미로 타일맵 렌더링
    for (var r = 0; r < RuinsMazeModel.rows; r++) {
      for (var c = 0; c < RuinsMazeModel.cols; c++) {
        final x = m.offsetX + c * m.tileSize;
        final y = m.offsetY + r * m.tileSize;
        final rect = Rect.fromLTWH(x, y, m.tileSize, m.tileSize);

        switch (m.grid[r][c]) {
          case TileType.wall:
            // 선명하고 묵직한 고대 석조 벽돌 (하이라이트 베벨 적용)
            canvas.drawRRect(
              RRect.fromRectAndRadius(rect.deflate(0.5), const Radius.circular(5)),
              Paint()..color = const Color(0xFF8D6E63),
            );
            canvas.drawRRect(
              RRect.fromRectAndRadius(rect.deflate(1.8), const Radius.circular(4)),
              Paint()..color = const Color(0xFF5D4037),
            );
            canvas.drawRRect(
              RRect.fromRectAndRadius(rect.deflate(3.2), const Radius.circular(3)),
              Paint()..color = const Color(0xFF4E342E),
            );
            break;

          case TileType.floor:
            // 밝고 선명한 고대 석판 바닥
            canvas.drawRect(rect, Paint()..color = const Color(0xFF3E2F26));
            canvas.drawRect(rect, Paint()..color = const Color(0xFF2B2019)..style = PaintingStyle.stroke..strokeWidth = 1.0);
            break;

          case TileType.silverDoor:
            // 은문 (Silver Door)
            canvas.drawRRect(
              RRect.fromRectAndRadius(rect.deflate(2), const Radius.circular(4)),
              Paint()..color = const Color(0xFFB0BEC5),
            );
            final tp = TextPainter(
              text: const TextSpan(text: '🔒', style: TextStyle(fontSize: 14)),
              textDirection: TextDirection.ltr,
            )..layout();
            tp.paint(canvas, Offset(x + (m.tileSize - tp.width) / 2, y + (m.tileSize - tp.height) / 2));
            break;

          case TileType.goldDoor:
            // 금문 (Gold Door)
            canvas.drawRRect(
              RRect.fromRectAndRadius(rect.deflate(2), const Radius.circular(4)),
              Paint()..color = const Color(0xFFFFD54F),
            );
            final tp = TextPainter(
              text: const TextSpan(text: '🔐', style: TextStyle(fontSize: 14)),
              textDirection: TextDirection.ltr,
            )..layout();
            tp.paint(canvas, Offset(x + (m.tileSize - tp.width) / 2, y + (m.tileSize - tp.height) / 2));
            break;

          case TileType.exitGate:
            // 최종 고대 탈출 석문
            final gateColor = m.hasGoldKey ? const Color(0xFF00E676) : const Color(0xFF6D4C41);
            canvas.drawRRect(
              RRect.fromRectAndRadius(rect.deflate(1), const Radius.circular(6)),
              Paint()..color = gateColor,
            );
            final tp = TextPainter(
              text: TextSpan(text: m.hasGoldKey ? '🚪' : '⛩️', style: const TextStyle(fontSize: 16)),
              textDirection: TextDirection.ltr,
            )..layout();
            tp.paint(canvas, Offset(x + (m.tileSize - tp.width) / 2, y + (m.tileSize - tp.height) / 2));
            break;

          case TileType.spikeTrap:
            // 가시 함정
            canvas.drawRect(rect, Paint()..color = const Color(0xFF2D1F17));
            if (m.spikeActive) {
              final sp = Paint()..color = const Color(0xFFFF5252);
              canvas.drawCircle(rect.center, m.tileSize * 0.35, sp);
            } else {
              canvas.drawCircle(rect.center, m.tileSize * 0.2, Paint()..color = Colors.black45);
            }
            break;

          case TileType.switchTile:
            break;
        }
      }
    }

    // 3. 보석 아이템
    for (final gem in m.gems) {
      if (gem.collected) continue;
      final gx = m.offsetX + gem.col * m.tileSize + m.tileSize / 2;
      final gy = m.offsetY + gem.row * m.tileSize + m.tileSize / 2;
      final gemColor = switch (gem.type) {
        GemType.ruby => const Color(0xFFFF1744),
        GemType.emerald => const Color(0xFF00E676),
        GemType.diamond => const Color(0xFF00E5FF),
      };
      canvas.drawCircle(Offset(gx, gy), m.tileSize * 0.28, Paint()..color = gemColor);
      canvas.drawCircle(Offset(gx - 2, gy - 2), m.tileSize * 0.1, Paint()..color = Colors.white.withOpacity(0.8));
    }

    // 4. 열쇠 아이템
    for (final k in m.keys) {
      if (k.collected) continue;
      final kx = m.offsetX + k.col * m.tileSize + m.tileSize / 2;
      final ky = m.offsetY + k.row * m.tileSize + m.tileSize / 2;
      final keyIcon = k.isGold ? '🔑' : '🗝️';
      final tp = TextPainter(
        text: TextSpan(text: keyIcon, style: TextStyle(fontSize: m.tileSize * 0.6)),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(kx - tp.width / 2, ky - tp.height / 2));
    }

    // 5. 거대 굴림 바위 (8번 병합 기믹)
    for (final b in m.boulders) {
      if (!b.active) continue;
      canvas.save();
      canvas.translate(b.x, b.y);
      canvas.rotate(b.rotation);

      // 바위 텍스처 원체
      canvas.drawCircle(Offset.zero, b.radius, Paint()..color = const Color(0xFF8D6E63));
      canvas.drawCircle(Offset.zero, b.radius, Paint()..color = const Color(0xFF3E2723)..style = PaintingStyle.stroke..strokeWidth = 2.5);

      // 바위 표면 크랙/줄무늬
      final crackPaint = Paint()..color = const Color(0xFF4E342E)..strokeWidth = 2.0;
      canvas.drawLine(Offset(-b.radius * 0.6, -b.radius * 0.3), Offset(b.radius * 0.5, b.radius * 0.4), crackPaint);
      canvas.drawLine(Offset(0, -b.radius * 0.7), Offset(-b.radius * 0.3, b.radius * 0.5), crackPaint);
      canvas.restore();
    }

    // 6. 플레이어 깨비
    final kkaebiPaint = Paint()..color = m.isDashing ? const Color(0xFFFFD54F) : DokkeyTheme.mintCalm;
    canvas.drawCircle(Offset(m.renderX, m.renderY), m.tileSize * 0.36, kkaebiPaint);
    // 도깨비 뿔
    canvas.drawCircle(Offset(m.renderX - 4, m.renderY - m.tileSize * 0.32), 3.5, kkaebiPaint);
    canvas.drawCircle(Offset(m.renderX + 4, m.renderY - m.tileSize * 0.32), 3.5, kkaebiPaint);
    // 도깨비 눈
    canvas.drawCircle(Offset(m.renderX - 3, m.renderY - 1), 2.2, Paint()..color = Colors.black87);
    canvas.drawCircle(Offset(m.renderX + 3, m.renderY - 1), 2.2, Paint()..color = Colors.black87);

    // 7. 동적 횃불 조명 (넓고 선명한 시야 확보 + 부드러운 외곽 비네트)
    final torchGradient = ui.Gradient.radial(
      Offset(m.renderX, m.renderY),
      m.tileSize * 7.5,
      [
        Colors.transparent,
        Colors.transparent,
        Colors.black.withOpacity(0.35),
        Colors.black.withOpacity(0.70),
      ],
      [0.0, 0.55, 0.82, 1.0],
    );
    canvas.drawRect(Offset.zero & size, Paint()..shader = torchGradient);

    // 은은한 횃불 웜톤 오라
    final warmGlow = ui.Gradient.radial(
      Offset(m.renderX, m.renderY),
      m.tileSize * 3.5,
      [
        const Color(0xFFFFD54F).withOpacity(0.14),
        Colors.transparent,
      ],
    );
    canvas.drawRect(Offset.zero & size, Paint()..shader = warmGlow);

    particles.paint(canvas);
  }

  @override
  Widget build(BuildContext context) {
    final isKo = context.watch<DokkeyProvider>().lang == 'ko';
    final hearts = List.generate(3, (i) => i < (model?.lives ?? 3) ? '❤️' : '🖤').join(' ');

    return Scaffold(
      backgroundColor: const Color(0xFF140F0B),
      body: SafeArea(
        child: Column(
          children: [
            // 상단 통합 HUD
            GameHud(
              title: isKo ? '깨비 고대 유적' : 'Ancient Ruins',
              score: model?.score ?? 0,
              rightLabel: 'STAGE ${model?.stage ?? 1} · $hearts',
              onQuit: () => Navigator.of(context).pop(),
              accent: const Color(0xFFFFD54F),
            ),

            // 게임 캔버스 뷰포트 (스와이프 제스처 내장)
            Expanded(
              child: Stack(
                children: [
                  Positioned.fill(
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onHorizontalDragEnd: (details) {
                        if (model == null) return;
                        if (details.primaryVelocity! > 100) {
                          model!.move(Direction.right);
                        } else if (details.primaryVelocity! < -100) {
                          model!.move(Direction.left);
                        }
                      },
                      onVerticalDragEnd: (details) {
                        if (model == null) return;
                        if (details.primaryVelocity! > 100) {
                          model!.move(Direction.down);
                        } else if (details.primaryVelocity! < -100) {
                          model!.move(Direction.up);
                        }
                      },
                      child: gameCanvas(overlayBuilder: () => const SizedBox.expand()),
                    ),
                  ),

                  // 열쇠 획득 인디케이터
                  if (model != null)
                    Positioned(
                      top: 10,
                      left: 14,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.6),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFFFD54F).withOpacity(0.4)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(model!.hasSilverKey ? '🗝️ SILVER' : '🗝️ --',
                                style: TextStyle(color: model!.hasSilverKey ? Colors.white : Colors.white24, fontSize: 10, fontWeight: FontWeight.bold)),
                            const SizedBox(width: 8),
                            Text(model!.hasGoldKey ? '🔑 GOLD' : '🔑 --',
                                style: TextStyle(color: model!.hasGoldKey ? const Color(0xFFFFD54F) : Colors.white24, fontSize: 10, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // 🎮 하단 미로 컨트롤러 (왼쪽: 십자 D-Pad, 오른쪽: DASH 부스터)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: const BoxDecoration(
                color: Color(0xFF1B130E),
                border: Border(top: BorderSide(color: Color(0xFF3E2723), width: 1.5)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // 십자 D-Pad
                  SizedBox(
                    width: 120,
                    height: 90,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // 위
                        Positioned(
                          top: 0,
                          child: _dpadBtn(Icons.arrow_upward_rounded, () => model?.move(Direction.up)),
                        ),
                        // 아래
                        Positioned(
                          bottom: 0,
                          child: _dpadBtn(Icons.arrow_downward_rounded, () => model?.move(Direction.down)),
                        ),
                        // 좌
                        Positioned(
                          left: 0,
                          child: _dpadBtn(Icons.arrow_back_rounded, () => model?.move(Direction.left)),
                        ),
                        // 우
                        Positioned(
                          right: 0,
                          child: _dpadBtn(Icons.arrow_forward_rounded, () => model?.move(Direction.right)),
                        ),
                      ],
                    ),
                  ),

                  // 오른쪽: DASH ⚡ 부스터 버튼 (바위 긴급 회피)
                  GestureDetector(
                    onTapDown: (_) {
                      if (model != null && model!.triggerDash()) {
                        try {
                          HapticFeedback.heavyImpact();
                        } catch (_) {}
                      }
                    },
                    child: Container(
                      width: 72,
                      height: 64,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: (model?.dashCooldown ?? 0) <= 0
                              ? [const Color(0xFFFFD54F), const Color(0xFFFF8F00)]
                              : [Colors.grey.shade700, Colors.grey.shade900],
                        ),
                        border: Border.all(color: Colors.white, width: 2),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFFFD54F).withOpacity(0.4),
                            blurRadius: 8,
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.bolt_rounded, size: 24, color: Colors.black87),
                          Text(
                            (model?.dashCooldown ?? 0) > 0 ? '${model!.dashCooldown.toStringAsFixed(1)}s' : 'DASH ⚡',
                            style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.w900, fontSize: 11),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _dpadBtn(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: const Color(0xFF332219),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFFFFD54F).withOpacity(0.6), width: 1.4),
        ),
        child: Icon(icon, color: const Color(0xFFFFD54F), size: 22),
      ),
    );
  }
}
