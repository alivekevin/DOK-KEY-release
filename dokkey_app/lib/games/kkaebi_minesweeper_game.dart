import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../core/sound_service.dart';
import '../core/theme.dart';
import '../providers/dokkey_provider.dart';
import 'core/game_shell.dart';

/// 💣 게임 3: 깨비 지뢰찾기 (Kkaebi Minesweeper)
/// 8x8(초급/지뢰10) · 10x10(중급/지뢰18) · 12x14(상급/지뢰30)
/// 첫 탭 세이프 보장 · 부적 깃발 꽂기 · 연쇄 타일 오픈 · 도깨비 함정 탐지

class MineCell {
  final int x, y;
  bool isMine = false;
  int neighborMines = 0;
  bool isOpen = false;
  bool isFlagged = false;
  bool exploded = false;

  MineCell({required this.x, required this.y});
}

class MinesweeperModel {
  final int cols, rows;
  final int totalMines;
  final Random rng;

  late List<List<MineCell>> grid;
  bool firstTapDone = false;
  bool gameOver = false;
  bool cleared = false;
  int flagsPlaced = 0;

  MinesweeperModel({
    required this.cols,
    required this.rows,
    required this.totalMines,
    Random? random,
  }) : rng = random ?? Random() {
    grid = List.generate(
      rows,
      (y) => List.generate(cols, (x) => MineCell(x: x, y: y)),
    );
  }

  void _populateMines(int safeX, int safeY) {
    // 첫 탭 셀과 인접 8칸은 지뢰 배치에서 제외
    final safeZone = <(int, int)>{};
    for (var dy = -1; dy <= 1; dy++) {
      for (var dx = -1; dx <= 1; dx++) {
        final nx = safeX + dx;
        final ny = safeY + dy;
        if (nx >= 0 && nx < cols && ny >= 0 && ny < rows) {
          safeZone.add((nx, ny));
        }
      }
    }

    final candidates = <(int, int)>[];
    for (var y = 0; y < rows; y++) {
      for (var x = 0; x < cols; x++) {
        if (!safeZone.contains((x, y))) {
          candidates.add((x, y));
        }
      }
    }
    candidates.shuffle(rng);

    final placeCount = min(totalMines, candidates.length);
    for (var i = 0; i < placeCount; i++) {
      final (x, y) = candidates[i];
      grid[y][x].isMine = true;
    }

    // 인접 지뢰 수 계산
    for (var y = 0; y < rows; y++) {
      for (var x = 0; x < cols; x++) {
        if (grid[y][x].isMine) continue;
        var count = 0;
        for (var dy = -1; dy <= 1; dy++) {
          for (var dx = -1; dx <= 1; dx++) {
            if (dx == 0 && dy == 0) continue;
            final nx = x + dx;
            final ny = y + dy;
            if (nx >= 0 && nx < cols && ny >= 0 && ny < rows) {
              if (grid[ny][nx].isMine) count++;
            }
          }
        }
        grid[y][x].neighborMines = count;
      }
    }
  }

  bool openCell(int x, int y) {
    if (gameOver || cleared) return false;
    final cell = grid[y][x];
    if (cell.isOpen || cell.isFlagged) return false;

    if (!firstTapDone) {
      firstTapDone = true;
      _populateMines(x, y);
    }

    if (cell.isMine) {
      cell.isOpen = true;
      cell.exploded = true;
      gameOver = true;
      _revealAllMines();
      return true;
    }

    _floodOpen(x, y);
    _checkWin();
    return true;
  }

  void _floodOpen(int startX, int startY) {
    final queue = <(int, int)>[(startX, startY)];
    grid[startY][startX].isOpen = true;

    while (queue.isNotEmpty) {
      final (cx, cy) = queue.removeLast();
      final cell = grid[cy][cx];

      if (cell.neighborMines == 0) {
        for (var dy = -1; dy <= 1; dy++) {
          for (var dx = -1; dx <= 1; dx++) {
            if (dx == 0 && dy == 0) continue;
            final nx = cx + dx;
            final ny = cy + dy;
            if (nx >= 0 && nx < cols && ny >= 0 && ny < rows) {
              final neighbor = grid[ny][nx];
              if (!neighbor.isOpen && !neighbor.isFlagged && !neighbor.isMine) {
                neighbor.isOpen = true;
                if (neighbor.neighborMines == 0) {
                  queue.add((nx, ny));
                }
              }
            }
          }
        }
      }
    }
  }

  void toggleFlag(int x, int y) {
    if (gameOver || cleared) return;
    final cell = grid[y][x];
    if (cell.isOpen) return;

    cell.isFlagged = !cell.isFlagged;
    flagsPlaced += cell.isFlagged ? 1 : -1;
    _checkWin();
  }

  void chord(int x, int y) {
    if (gameOver || cleared) return;
    final cell = grid[y][x];
    if (!cell.isOpen || cell.neighborMines == 0) return;

    var adjacentFlags = 0;
    for (var dy = -1; dy <= 1; dy++) {
      for (var dx = -1; dx <= 1; dx++) {
        if (dx == 0 && dy == 0) continue;
        final nx = x + dx;
        final ny = y + dy;
        if (nx >= 0 && nx < cols && ny >= 0 && ny < rows) {
          if (grid[ny][nx].isFlagged) adjacentFlags++;
        }
      }
    }

    if (adjacentFlags == cell.neighborMines) {
      for (var dy = -1; dy <= 1; dy++) {
        for (var dx = -1; dx <= 1; dx++) {
          if (dx == 0 && dy == 0) continue;
          final nx = x + dx;
          final ny = y + dy;
          if (nx >= 0 && nx < cols && ny >= 0 && ny < rows) {
            final neighbor = grid[ny][nx];
            if (!neighbor.isOpen && !neighbor.isFlagged) {
              openCell(nx, ny);
            }
          }
        }
      }
    }
  }

  void _revealAllMines() {
    for (var y = 0; y < rows; y++) {
      for (var x = 0; x < cols; x++) {
        final cell = grid[y][x];
        if (cell.isMine) cell.isOpen = true;
      }
    }
  }

  void _checkWin() {
    var unopenedCount = 0;
    for (var y = 0; y < rows; y++) {
      for (var x = 0; x < cols; x++) {
        if (!grid[y][x].isOpen) unopenedCount++;
      }
    }

    if (unopenedCount == totalMines) {
      cleared = true;
      for (var y = 0; y < rows; y++) {
        for (var x = 0; x < cols; x++) {
          final cell = grid[y][x];
          if (cell.isMine) cell.isFlagged = true;
        }
      }
      flagsPlaced = totalMines;
    }
  }
}

// ---------------------------------------------------------------------------
// 💣 깨비 지뢰찾기 위젯
// ---------------------------------------------------------------------------

class KkaebiMinesweeperGame extends StatefulWidget {
  static const String gameId = 'minesweeper';

  const KkaebiMinesweeperGame({super.key});

  @override
  State<KkaebiMinesweeperGame> createState() => _KkaebiMinesweeperGameState();
}

class _KkaebiMinesweeperGameState extends State<KkaebiMinesweeperGame> {
  int _diff = 0; // 0=8x8(10), 1=10x10(18), 2=12x14(30)
  late MinesweeperModel _model;
  bool _flagMode = false;
  int _seconds = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startNewGame(0);
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startNewGame(int diff) {
    _diff = diff;
    _flagMode = false;
    _seconds = 0;
    _timer?.cancel();

    final (cols, rows, mines) = switch (diff) {
      1 => (10, 10, 18),
      2 => (12, 14, 30),
      _ => (8, 8, 10),
    };

    _model = MinesweeperModel(
      cols: cols,
      rows: rows,
      totalMines: mines,
    );

    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_model.firstTapDone && !_model.gameOver && !_model.cleared) {
        setState(() => _seconds++);
      }
    });

    setState(() {});
  }

  void _onCellTap(int x, int y) {
    if (_model.gameOver || _model.cleared) return;

    if (_flagMode) {
      _model.toggleFlag(x, y);
      SoundService().playCardFlip();
      HapticFeedback.lightImpact();
    } else {
      final cell = _model.grid[y][x];
      if (cell.isOpen) {
        _model.chord(x, y);
      } else {
        _model.openCell(x, y);
      }
      SoundService().playKeyTurn();
      HapticFeedback.selectionClick();
    }

    if (_model.gameOver) {
      SoundService().playRiddleWrong();
      HapticFeedback.heavyImpact();
      _onGameFinished(false);
    } else if (_model.cleared) {
      SoundService().playSuccessChime();
      HapticFeedback.heavyImpact();
      _onGameFinished(true);
    }
    setState(() {});
  }

  void _onCellLongPress(int x, int y) {
    if (_model.gameOver || _model.cleared) return;
    _model.toggleFlag(x, y);
    SoundService().playCardFlip();
    HapticFeedback.mediumImpact();
    if (_model.cleared) {
      _onGameFinished(true);
    }
    setState(() {});
  }

  Future<void> _onGameFinished(bool cleared) async {
    final score = cleared
        ? max(150, (1200 * (_diff + 1) - _seconds * 4)).clamp(150, 6000)
        : max(20, (_seconds * 2));

    await dispatchGameReward(
      context,
      gameId: KkaebiMinesweeperGame.gameId,
      score: score,
      cleared: cleared,
    );
    if (!mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => GameResultDialog(
        gameId: KkaebiMinesweeperGame.gameId,
        title: cleared ? '💣 함정 해체 성공!' : '💥 도깨비 함정 폭발!',
        score: score,
        best: score,
        cleared: cleared,
        onRetry: () {
          Navigator.of(context).pop();
          _startNewGame(_diff);
        },
        onExit: () {
          Navigator.of(context).pop();
          Navigator.of(context).pop();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isKo = context.watch<DokkeyProvider>().lang == 'ko';
    final minesLeft = _model.totalMines - _model.flagsPlaced;

    return Scaffold(
      backgroundColor: const Color(0xFF0F151B),
      appBar: AppBar(
        backgroundColor: const Color(0xFF18232D),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('💣', style: TextStyle(fontSize: 20)),
            const SizedBox(width: 8),
            Text(
              isKo ? '깨비 지뢰찾기' : 'Minesweeper',
              style: TextStyle(
                color: DokkeyTheme.goldLight,
                fontWeight: FontWeight.w900,
                fontSize: 17,
              ),
            ),
          ],
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Colors.cyanAccent),
            tooltip: isKo ? '다시 시작' : 'Restart',
            onPressed: () => _startNewGame(_diff),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // 1. 난이도 선택 탭
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  _buildDiffTab(0, isKo ? '초급 (8x8)' : 'Easy (8x8)'),
                  const SizedBox(width: 6),
                  _buildDiffTab(1, isKo ? '중급 (10x10)' : 'Med (10x10)'),
                  const SizedBox(width: 6),
                  _buildDiffTab(2, isKo ? '상급 (12x14)' : 'Hard (12x14)'),
                ],
              ),
            ),

            // 2. 상단 HUD 대시보드 (지뢰 잔여 수 · 깨비 페이스 리셋 · 타이머)
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFF1B2834),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFF37474F), width: 1.5),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.4),
                    blurRadius: 6,
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // 남은 지뢰
                  Row(
                    children: [
                      const Text('🚩', style: TextStyle(fontSize: 16)),
                      const SizedBox(width: 6),
                      Text(
                        '$minesLeft',
                        style: const TextStyle(
                          color: Colors.redAccent,
                          fontWeight: FontWeight.w900,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),

                  // 깨비 상태 페이스 (탭 시 리셋)
                  GestureDetector(
                    onTap: () => _startNewGame(_diff),
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: const Color(0xFF263238),
                        shape: BoxShape.circle,
                        border: Border.all(color: DokkeyTheme.gold, width: 1.5),
                      ),
                      child: Text(
                        _model.gameOver
                            ? '💥'
                            : (_model.cleared ? '😎' : (_flagMode ? '🚩' : '😈')),
                        style: const TextStyle(fontSize: 20),
                      ),
                    ),
                  ),

                  // 타이머
                  Row(
                    children: [
                      const Icon(Icons.timer_outlined, color: Colors.cyanAccent, size: 16),
                      const SizedBox(width: 4),
                      Text(
                        '${_seconds}s',
                        style: const TextStyle(
                          color: Colors.cyanAccent,
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // 3. 지뢰찾기 타일 보드 그리드
            Expanded(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final maxCellW = (constraints.maxWidth - 24) / _model.cols;
                      final maxCellH = (constraints.maxHeight - 24) / _model.rows;
                      final cellSize = min(maxCellW, maxCellH).clamp(22.0, 44.0);

                      return Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: const Color(0xFF131D26),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: const Color(0xFF263238), width: 2),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            for (var y = 0; y < _model.rows; y++)
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  for (var x = 0; x < _model.cols; x++)
                                    _buildMineCell(x, y, cellSize),
                                ],
                              ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),

            // 4. 하단 모드 토글 바 (타일 열기 🔍 vs 부적 깃발 🚩)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
              child: Row(
                children: [
                  Expanded(
                    child: _buildModeButton(
                      isFlag: false,
                      icon: Icons.touch_app_rounded,
                      label: isKo ? '타일 열기 모드' : 'Open Mode',
                      active: !_flagMode,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildModeButton(
                      isFlag: true,
                      icon: Icons.flag_rounded,
                      label: isKo ? '부적 깃발 모드' : 'Flag Mode',
                      active: _flagMode,
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

  Widget _buildDiffTab(int diff, String label) {
    final active = _diff == diff;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          if (_diff != diff) _startNewGame(diff);
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 6),
          decoration: BoxDecoration(
            color: active ? const Color(0xFF00838F).withOpacity(0.3) : const Color(0xFF18232D),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: active ? Colors.cyanAccent : const Color(0xFF37474F),
              width: 1.2,
            ),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                color: active ? Colors.cyanAccent : Colors.white60,
                fontSize: 11,
                fontWeight: active ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMineCell(int x, int y, double size) {
    final cell = _model.grid[y][x];

    Color bgColor;
    Widget content;

    if (!cell.isOpen) {
      bgColor = const Color(0xFF2E3D49);
      if (cell.isFlagged) {
        content = const Text('🚩', style: TextStyle(fontSize: 14));
      } else {
        content = const SizedBox();
      }
    } else {
      if (cell.isMine) {
        bgColor = cell.exploded ? Colors.redAccent : const Color(0xFF455A64);
        content = const Text('💣', style: TextStyle(fontSize: 14));
      } else if (cell.neighborMines == 0) {
        bgColor = const Color(0xFF1C2730);
        content = const SizedBox();
      } else {
        bgColor = const Color(0xFF1C2730);
        final numColor = switch (cell.neighborMines) {
          1 => const Color(0xFF4FC3F7),
          2 => const Color(0xFF81C784),
          3 => const Color(0xFFFFB74D),
          4 => const Color(0xFFBA68C8),
          5 => const Color(0xFFE57373),
          _ => const Color(0xFF4DB6AC),
        };
        content = Text(
          '${cell.neighborMines}',
          style: TextStyle(
            color: numColor,
            fontWeight: FontWeight.w900,
            fontSize: size * 0.52,
          ),
        );
      }
    }

    return GestureDetector(
      onTap: () => _onCellTap(x, y),
      onLongPress: () => _onCellLongPress(x, y),
      child: Container(
        width: size,
        height: size,
        margin: const EdgeInsets.all(1),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(
            color: cell.isOpen ? const Color(0xFF263238) : const Color(0xFF455A64),
            width: 1,
          ),
          boxShadow: !cell.isOpen
              ? [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    offset: const Offset(1, 1),
                    blurRadius: 1,
                  ),
                ]
              : null,
        ),
        child: Center(child: content),
      ),
    );
  }

  Widget _buildModeButton({
    required bool isFlag,
    required IconData icon,
    required String label,
    required bool active,
  }) {
    return GestureDetector(
      onTap: () {
        setState(() => _flagMode = isFlag);
        HapticFeedback.selectionClick();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: active
                ? (isFlag
                    ? [const Color(0xFFB71C1C), const Color(0xFF7F0000)]
                    : [const Color(0xFF00838F), const Color(0xFF006064)])
                : [const Color(0xFF1E2832), const Color(0xFF141C24)],
          ),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: active
                ? (isFlag ? Colors.redAccent : Colors.cyanAccent)
                : const Color(0xFF37474F),
            width: 1.5,
          ),
          boxShadow: active
              ? [
                  BoxShadow(
                    color: (isFlag ? Colors.redAccent : Colors.cyanAccent).withOpacity(0.35),
                    blurRadius: 8,
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 18,
              color: active ? Colors.white : Colors.white54,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: active ? Colors.white : Colors.white60,
                fontSize: 13,
                fontWeight: active ? FontWeight.w900 : FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
