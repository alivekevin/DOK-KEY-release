import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../core/sound_service.dart';
import '../core/theme.dart';
import '../providers/dokkey_provider.dart';
import 'core/game_shell.dart';

/// 🧱 게임 3: 클래식 테트리스 — 순수 로직 모델
class TetrisModel {
  static const int cols = 10;
  static const int rows = 20;

  final List<List<int>> board; // 0 = 빈칸, 1~7 = 색상 ID
  late List<List<int>> piece; // 현재 조각 모양
  int pieceX = 3, pieceY = 0;
  int pieceId = 1;
  int nextId = 1;
  final Random rng;

  int score = 0;
  int lines = 0;
  int combo = 0;
  int level = 1;
  bool gameOver = false;

  static const List<Color> pieceColors = [
    Color(0xFF00E5FF), // I - 시안
    Color(0xFFFFD600), // O - 옐로우
    Color(0xFFB26BFF), // T - 퍼플
    Color(0xFF00E676), // S - 그린
    Color(0xFFFF4081), // Z - 핑크/레드
    Color(0xFF2979FF), // J - 블루
    Color(0xFFFF9100), // L - 오렌지
  ];

  static const List<List<List<int>>> shapes = [
    [[1, 1, 1, 1]], // I
    [[1, 1], [1, 1]], // O
    [[0, 1, 0], [1, 1, 1]], // T
    [[1, 0, 0], [1, 1, 1]], // J
    [[0, 0, 1], [1, 1, 1]], // L
    [[0, 1, 1], [1, 1, 0]], // S
    [[1, 1, 0], [0, 1, 1]], // Z
  ];

  TetrisModel({Random? random})
      : rng = random ?? Random(),
        board = List.generate(rows, (_) => List.filled(cols, 0)) {
    pieceId = rng.nextInt(7);
    nextId = rng.nextInt(7);
    piece = cloneShape(shapes[pieceId]);
    spawnPiece();
  }

  static List<List<int>> cloneShape(List<List<int>> s) =>
      [for (final row in s) [...row]];

  void spawnPiece() {
    piece = cloneShape(shapes[pieceId]);
    pieceX = (cols - piece[0].length) ~/ 2;
    pieceY = -1;
    if (_collides(piece, pieceX, pieceY + 1) && pieceY < 0) {
      gameOver = true;
    }
  }

  bool _collides(List<List<int>> shape, int px, int py) {
    for (var y = 0; y < shape.length; y++) {
      for (var x = 0; x < shape[y].length; x++) {
        if (shape[y][x] == 0) continue;
        final bx = px + x;
        final by = py + y;
        if (bx < 0 || bx >= cols || by >= rows) return true;
        if (by >= 0 && board[by][bx] != 0) return true;
      }
    }
    return false;
  }

  bool move(int dx, int dy) {
    if (gameOver) return false;
    if (!_collides(piece, pieceX + dx, pieceY + dy)) {
      pieceX += dx;
      pieceY += dy;
      return true;
    }
    return false;
  }

  /// 회전 (경계 킥 시도)
  bool rotate() {
    if (gameOver || pieceId == 1) return false; // O는 회전 불필요
    final rotated = List.generate(
        piece[0].length, (y) => List.generate(piece.length, (x) => piece[piece.length - 1 - x][y]));
    for (final kick in [0, -1, 1, -2, 2]) {
      if (!_collides(rotated, pieceX + kick, pieceY)) {
        piece = rotated;
        pieceX += kick;
        return true;
      }
    }
    return false;
  }

  /// 한 틱 하강. 바닥에 닿으면 고정 & 줄 삭제. 반환: 삭제된 줄 수
  int tick() {
    if (gameOver) return 0;
    if (move(0, 1)) return 0;
    return lockAndClear();
  }

  void hardDrop() {
    if (gameOver) return;
    while (move(0, 1)) {
      score += 2;
    }
    lockAndClear();
  }

  int lockAndClear() {
    // 조각을 보드에 고정
    for (var y = 0; y < piece.length; y++) {
      for (var x = 0; x < piece[y].length; x++) {
        if (piece[y][x] == 0) continue;
        final by = pieceY + y;
        final bx = pieceX + x;
        if (by >= 0) board[by][bx] = pieceId + 1;
      }
    }
    // 줄 삭제
    var cleared = 0;
    for (var y = rows - 1; y >= 0; y--) {
      if (board[y].every((c) => c != 0)) {
        board.removeAt(y);
        board.insert(0, List.filled(cols, 0));
        cleared++;
        y++;
      }
    }
    if (cleared > 0) {
      combo++;
      lines += cleared;
      score += [0, 100, 300, 500, 800][cleared] * level + combo * 50;
      level = 1 + lines ~/ 5;
    } else {
      combo = 0;
    }
    pieceId = nextId;
    nextId = rng.nextInt(7);
    spawnPiece();
    return cleared;
  }

  /// 고스트 피스 Y 위치
  int ghostY() {
    var gy = pieceY;
    while (!_collides(piece, pieceX, gy + 1)) {
      gy++;
    }
    return gy;
  }
}

/// 🧱 게임 3: 대화면 풀스크린 테트리스 화면
class KkaebiTetrisGame extends StatefulWidget {
  const KkaebiTetrisGame({super.key});

  static const String gameId = 'tetris';

  @override
  State<KkaebiTetrisGame> createState() => _KkaebiTetrisGameState();
}

class _KkaebiTetrisGameState extends State<KkaebiTetrisGame>
    with GameLoopMixin {
  late TetrisModel model;
  double _fallTimer = 0;
  bool _finished = false;
  Offset? _panStart;
  int _lastCleared = 0;

  // 동적 계산되는 셀 크기
  double _cell = 24.0;
  double _boardLeft = 0;
  double _boardTop = 0;

  @override
  void initState() {
    super.initState();
    model = TetrisModel();
  }

  @override
  void onUpdate(double dt) {
    if (_finished) return;
    final fallSpeed = max(0.10, 0.60 - model.level * 0.045);
    _fallTimer += dt;
    if (_fallTimer >= fallSpeed) {
      _fallTimer = 0;
      _lastCleared = model.tick();
      if (_lastCleared > 0) {
        // 줄 삭제 콤보: 화려한 폭발 파티클 & 쉐이크
        shake.add(0.25 + _lastCleared * 0.12);
        particles.burst(
          x: _boardLeft + (TetrisModel.cols * _cell) / 2,
          y: _boardTop + (TetrisModel.rows * _cell) * 0.7,
          color: const Color(0xFFFFE66D),
          count: 18 * _lastCleared,
          speed: 280,
          size: 5,
        );
        particles.burst(
          x: _boardLeft + (TetrisModel.cols * _cell) / 2,
          y: _boardTop + (TetrisModel.rows * _cell) * 0.7,
          color: const Color(0xFFFF5252),
          count: 12 * _lastCleared,
          speed: 220,
        );
        SoundService().playCoinJangle();
        HapticFeedback.mediumImpact();
      }
      if (model.gameOver) {
        _finish();
      }
    }
  }

  void _finish() {
    if (_finished) return;
    _finished = true;
    finishGame(
      context,
      gameId: KkaebiTetrisGame.gameId,
      title: '깨비 테트리스',
      score: model.score,
      cleared: false,
      onRetry: () => Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const KkaebiTetrisGame()),
      ),
    );
  }

  @override
  void onPaint(Canvas canvas, Size size) {
    // 배경: 짙은 사이버 스페이스 그라데이션
    canvas.drawRect(
      Offset.zero & size,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF0F141F), Color(0xFF0A0D14)],
        ).createShader(Offset.zero & size),
    );

    // 네뷸라 별무리
    final rng = Random(13);
    final starPaint = Paint();
    for (var i = 0; i < 35; i++) {
      final sy = ((rng.nextDouble() * size.height) + gameTime * 20 * (0.5 + i / 35)) %
          size.height;
      starPaint.color = Colors.white.withOpacity(0.06 + (i % 4) * 0.03);
      canvas.drawCircle(Offset(rng.nextDouble() * size.width, sy), 1.2, starPaint);
    }

    // 📱 화면 크기에 맞춰 최대 크기(Full-screen)로 동적 계산
    // 상단 HUD/미리보기(약 60px) + 하단 조작 패널(약 100px) 제외한 영역을 꽉 채움
    final availableW = size.width - 20;
    final availableH = size.height - 155;
    _cell = min(availableW / TetrisModel.cols, availableH / TetrisModel.rows).floorToDouble();
    _cell = _cell.clamp(18.0, 36.0);

    final boardW = TetrisModel.cols * _cell;
    final boardH = TetrisModel.rows * _cell;
    _boardLeft = (size.width - boardW) / 2;
    _boardTop = 50.0;

    // 보드 외곽 네온 테두리 & 배경
    final boardRect = Rect.fromLTWH(_boardLeft, _boardTop, boardW, boardH);
    canvas.drawRRect(
      RRect.fromRectAndRadius(boardRect.inflate(3), const Radius.circular(10)),
      Paint()..color = const Color(0xFF131A29),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(boardRect.inflate(3), const Radius.circular(10)),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0
        ..color = const Color(0xFFFFD700).withOpacity(0.6),
    );

    // 보드 내부 가이드 그리드 라인 (은은한 격자망)
    final gridPaint = Paint()
      ..color = const Color(0xFF222C3F).withOpacity(0.5)
      ..strokeWidth = 0.5;
    for (var x = 1; x < TetrisModel.cols; x++) {
      final gx = _boardLeft + x * _cell;
      canvas.drawLine(Offset(gx, _boardTop), Offset(gx, _boardTop + boardH), gridPaint);
    }
    for (var y = 1; y < TetrisModel.rows; y++) {
      final gy = _boardTop + y * _cell;
      canvas.drawLine(Offset(_boardLeft, gy), Offset(_boardLeft + boardW, gy), gridPaint);
    }

    // 블록 렌더링 헬퍼 (입체 베벨 광택 효과)
    void drawCell(double px, double py, int colorId, {bool ghost = false}) {
      final rect = Rect.fromLTWH(
        _boardLeft + px * _cell + 1.2,
        _boardTop + py * _cell + 1.2,
        _cell - 2.4,
        _cell - 2.4,
      );
      final baseColor = TetrisModel.pieceColors[colorId - 1];

      if (ghost) {
        canvas.drawRRect(
          RRect.fromRectAndRadius(rect, const Radius.circular(4)),
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.4
            ..color = baseColor.withOpacity(0.45),
        );
        return;
      }

      // 채색 블록 본체
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, const Radius.circular(4)),
        Paint()..color = baseColor,
      );

      // 입체 하이라이트 (상단/좌측 밝은 베벨)
      final highlightPaint = Paint()
        ..color = Colors.white.withOpacity(0.4)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5;
      canvas.drawLine(rect.topLeft + const Offset(1, 1), rect.topRight + const Offset(-1, 1), highlightPaint);
      canvas.drawLine(rect.topLeft + const Offset(1, 1), rect.bottomLeft + const Offset(1, -1), highlightPaint);

      // 음영 (하단/우측 어두운 베벨)
      final shadowPaint = Paint()
        ..color = Colors.black.withOpacity(0.35)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5;
      canvas.drawLine(rect.bottomLeft + const Offset(1, -1), rect.bottomRight + const Offset(-1, -1), shadowPaint);
      canvas.drawLine(rect.topRight + const Offset(-1, 1), rect.bottomRight + const Offset(-1, -1), shadowPaint);
    }

    // 1. 고스트 피스 (도착 예상 지점)
    final gy = model.ghostY();
    for (var y = 0; y < model.piece.length; y++) {
      for (var x = 0; x < model.piece[y].length; x++) {
        if (model.piece[y][x] == 0) continue;
        drawCell((model.pieceX + x).toDouble(), (gy + y).toDouble(), model.pieceId + 1, ghost: true);
      }
    }

    // 2. 바닥에 쌓인 고정 블록
    for (var y = 0; y < TetrisModel.rows; y++) {
      for (var x = 0; x < TetrisModel.cols; x++) {
        if (model.board[y][x] != 0) {
          drawCell(x.toDouble(), y.toDouble(), model.board[y][x]);
        }
      }
    }

    // 3. 현재 떨어지는 조각
    for (var y = 0; y < model.piece.length; y++) {
      for (var x = 0; x < model.piece[y].length; x++) {
        if (model.piece[y][x] == 0) continue;
        if (model.pieceY + y >= 0) {
          drawCell((model.pieceX + x).toDouble(), (model.pieceY + y).toDouble(), model.pieceId + 1);
        }
      }
    }

    // 파티클
    particles.paint(canvas);
  }

  @override
  Widget build(BuildContext context) {
    final isKo = context.watch<DokkeyProvider>().lang == 'ko';

    return Scaffold(
      backgroundColor: DokkeyTheme.bgDark,
      body: SafeArea(
        child: gameCanvas(
          overlayBuilder: () => Column(
            children: [
              // 상단 통합 HUD & 다음 조각 미리보기
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: const BoxDecoration(
                  color: Color(0xFF141C2A),
                  border: Border(bottom: BorderSide(color: Color(0xFF2E3A52), width: 1)),
                ),
                child: Row(
                  children: [
                    // 나가기 버튼
                    IconButton(
                      icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 18),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                    const SizedBox(width: 8),
                    // 점수 / 레벨 / 줄수 정보
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isKo ? '깨비 테트리스' : 'Kkaebi Tetris',
                          style: const TextStyle(color: Color(0xFFFFD700), fontWeight: FontWeight.w900, fontSize: 14),
                        ),
                        Text(
                          '점수: ${model.score} · LV.${model.level} · 🧱${model.lines}줄',
                          style: const TextStyle(color: Color(0xFFCBD5E1), fontSize: 11.5, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const Spacer(),
                    // 다음 조각(NEXT) 미리보기 박스
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E283C),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFFFFD700).withOpacity(0.5), width: 1.2),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            isKo ? '다음 ' : 'NEXT ',
                            style: const TextStyle(color: Color(0xFFFFD700), fontSize: 10.5, fontWeight: FontWeight.w900),
                          ),
                          const SizedBox(width: 4),
                          ..._nextPreview(),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // 중앙 대형 게임 캔버스 터치 영역 (스와이프 / 더블탭 제스처 지원)
              Expanded(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onPanStart: (d) => _panStart = d.globalPosition,
                  onPanUpdate: (d) {
                    if (_panStart == null) return;
                    final dx = d.globalPosition.dx - _panStart!.dx;
                    if (dx.abs() > _cell * 0.9) {
                      model.move(dx > 0 ? 1 : -1, 0);
                      _panStart = d.globalPosition;
                      HapticFeedback.selectionClick();
                    }
                  },
                  onPanEnd: (d) {
                    if ((d.velocity.pixelsPerSecond.dy) > 350) {
                      model.hardDrop();
                      HapticFeedback.mediumImpact();
                    }
                    _panStart = null;
                  },
                  onTap: () {
                    // 캔버스 터치 시 회전
                    if (model.rotate()) {
                      HapticFeedback.lightImpact();
                      SoundService().playSuccessChime();
                    }
                  },
                  child: const SizedBox.expand(),
                ),
              ),

              // 🎮 하단 아케이드 양손 게임패드 컨트롤러 (왼손: 방향/하강, 오른손: 회전/하드드롭)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: const BoxDecoration(
                  color: Color(0xFF111724),
                  border: Border(top: BorderSide(color: Color(0xFF2A364F), width: 1.5)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // [왼손 엄지 영역: 좌 / 우 / 하강]
                    Expanded(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: _GamepadBtn(
                                  icon: Icons.arrow_back_rounded,
                                  label: isKo ? '좌' : 'Left',
                                  color: const Color(0xFF38BDF8),
                                  height: 46,
                                  onTap: () => model.move(-1, 0),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: _GamepadBtn(
                                  icon: Icons.arrow_forward_rounded,
                                  label: isKo ? '우' : 'Right',
                                  color: const Color(0xFF38BDF8),
                                  height: 46,
                                  onTap: () => model.move(1, 0),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          _GamepadBtn(
                            icon: Icons.arrow_downward_rounded,
                            label: isKo ? '소프트 하강' : 'Down',
                            color: const Color(0xFF4ADE80),
                            height: 38,
                            onTap: () => model.move(0, 1),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(width: 14),

                    // [오른손 엄지 영역: 회전 / 즉시 낙하]
                    Expanded(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _GamepadBtn(
                            icon: Icons.rotate_right_rounded,
                            label: isKo ? '블록 회전' : 'Rotate',
                            color: const Color(0xFFFFD700),
                            height: 46,
                            isPrimary: true,
                            onTap: () => model.rotate(),
                          ),
                          const SizedBox(height: 6),
                          _GamepadBtn(
                            icon: Icons.keyboard_double_arrow_down_rounded,
                            label: isKo ? '즉시 낙하' : 'Drop',
                            color: const Color(0xFFFF5252),
                            height: 38,
                            isAccent: true,
                            onTap: model.hardDrop,
                          ),
                        ],
                      ),
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

  List<Widget> _nextPreview() {
    final shape = TetrisModel.shapes[model.nextId];
    final color = TetrisModel.pieceColors[model.nextId];
    return [
      Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var y = 0; y < shape.length; y++)
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (var x = 0; x < shape[y].length; x++)
                  Container(
                    width: 7.5,
                    height: 7.5,
                    margin: const EdgeInsets.all(0.6),
                    decoration: BoxDecoration(
                      color: shape[y][x] == 1 ? color : Colors.transparent,
                      borderRadius: BorderRadius.circular(1.5),
                    ),
                  ),
              ],
            ),
        ],
      ),
    ];
  }
}

/// 아케이드 양손 게임패드 버튼 위젯 (고시인성 & 손가락 터치 최적화)
class _GamepadBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  final double height;
  final bool isPrimary;
  final bool isAccent;

  const _GamepadBtn({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
    this.height = 44,
    this.isPrimary = false,
    this.isAccent = false,
  });

  @override
  Widget build(BuildContext context) {
    Color bg = const Color(0xFF1E2638);
    Color borderColor = color.withOpacity(0.65);
    double borderWidth = 1.3;

    if (isPrimary) {
      bg = const Color(0xFF332712);
      borderColor = const Color(0xFFFFD700);
      borderWidth = 2.0;
    } else if (isAccent) {
      bg = const Color(0xFF33161C);
      borderColor = const Color(0xFFFF5252);
      borderWidth = 1.5;
    }

    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: Container(
        height: height,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: borderColor, width: borderWidth),
          boxShadow: [
            BoxShadow(
              color: isPrimary
                  ? const Color(0xFFFFD700).withOpacity(0.25)
                  : (isAccent ? const Color(0xFFFF5252).withOpacity(0.2) : Colors.black26),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: isPrimary ? 20 : 17, color: color),
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(
                fontSize: isPrimary ? 12.5 : 11,
                fontWeight: FontWeight.w900,
                color: isPrimary
                    ? const Color(0xFFFFE66D)
                    : (isAccent ? const Color(0xFFFF8A80) : color),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
