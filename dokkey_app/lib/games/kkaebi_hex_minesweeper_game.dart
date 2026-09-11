import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../core/sound_service.dart';
import '../core/theme.dart';
import '../providers/dokkey_provider.dart';
import 'core/game_shell.dart';

/// 💣 깨비 육각 벌집 지뢰찾기 (Hexagon Minesweeper)
/// 6방향 벌집 구조를 가진 모바일 친화적 도깨비 함정 추리 퍼즐.
class HexTile {
  final int r, c;
  bool isMine = false;
  bool isRevealed = false;
  bool isFlagged = false;
  int neighborMines = 0;

  HexTile({required this.r, required this.c});
}

class HexMinesweeperModel {
  final int rows;
  final int cols;
  final int totalMines;

  late List<List<HexTile>> board;
  bool firstTap = true;
  bool isGameOver = false;
  bool isCleared = false;
  int score = 0;
  int flagsPlaced = 0;

  HexMinesweeperModel({this.rows = 8, this.cols = 7, this.totalMines = 8}) {
    board = List.generate(rows, (r) => List.generate(cols, (c) => HexTile(r: r, c: c)));
  }

  // 육각 좌표계 (odd-r 수평 오프셋)의 6방향 이웃
  List<Point<int>> getNeighbors(int r, int c) {
    final isOdd = r % 2 == 1;
    final deltas = isOdd
        ? [
            const Point(-1, 0),
            const Point(-1, 1),
            const Point(0, -1),
            const Point(0, 1),
            const Point(1, 0),
            const Point(1, 1),
          ]
        : [
            const Point(-1, -1),
            const Point(-1, 0),
            const Point(0, -1),
            const Point(0, 1),
            const Point(1, -1),
            const Point(1, 0),
          ];

    final result = <Point<int>>[];
    for (final d in deltas) {
      final nr = r + d.x;
      final nc = c + d.y;
      if (nr >= 0 && nr < rows && nc >= 0 && nc < cols) {
        result.add(Point(nr, nc));
      }
    }
    return result;
  }

  void _placeMines(int safeR, int safeC, Random rng) {
    final safeSet = <String>{'$safeR,$safeC'};
    for (final n in getNeighbors(safeR, safeC)) {
      safeSet.add('${n.x},${n.y}');
    }

    final allCoords = <Point<int>>[];
    for (var r = 0; r < rows; r++) {
      for (var c = 0; c < cols; c++) {
        if (!safeSet.contains('$r,$c')) {
          allCoords.add(Point(r, c));
        }
      }
    }
    allCoords.shuffle(rng);

    final mineCount = min(totalMines, allCoords.length);
    for (var i = 0; i < mineCount; i++) {
      final p = allCoords[i];
      board[p.x][p.y].isMine = true;
    }

    // 인접 지뢰 수 계산
    for (var r = 0; r < rows; r++) {
      for (var c = 0; c < cols; c++) {
        if (board[r][c].isMine) continue;
        var count = 0;
        for (final n in getNeighbors(r, c)) {
          if (board[n.x][n.y].isMine) count++;
        }
        board[r][c].neighborMines = count;
      }
    }
  }

  bool reveal(int r, int c, {Random? random}) {
    if (isGameOver || isCleared) return false;
    final tile = board[r][c];
    if (tile.isFlagged || tile.isRevealed) return false;

    if (firstTap) {
      firstTap = false;
      _placeMines(r, c, random ?? Random());
    }

    tile.isRevealed = true;

    if (tile.isMine) {
      isGameOver = true;
      // 전체 지뢰 공개
      for (var row in board) {
        for (var t in row) {
          if (t.isMine) t.isRevealed = true;
        }
      }
      return false;
    }

    score += 50;

    // 0이면 연쇄 오픈 (Flood Fill)
    if (tile.neighborMines == 0) {
      final queue = <Point<int>>[Point(r, c)];
      while (queue.isNotEmpty) {
        final cur = queue.removeLast();
        for (final n in getNeighbors(cur.x, cur.y)) {
          final neighbor = board[n.x][n.y];
          if (!neighbor.isRevealed && !neighbor.isFlagged && !neighbor.isMine) {
            neighbor.isRevealed = true;
            score += 20;
            if (neighbor.neighborMines == 0) {
              queue.add(n);
            }
          }
        }
      }
    }

    _checkCleared();
    return true;
  }

  void toggleFlag(int r, int c) {
    if (isGameOver || isCleared) return;
    final tile = board[r][c];
    if (tile.isRevealed) return;

    tile.isFlagged = !tile.isFlagged;
    flagsPlaced += tile.isFlagged ? 1 : -1;
    _checkCleared();
  }

  void _checkCleared() {
    var unrevealedSafe = 0;
    for (var row in board) {
      for (var t in row) {
        if (!t.isMine && !t.isRevealed) {
          unrevealedSafe++;
        }
      }
    }
    if (unrevealedSafe == 0) {
      isCleared = true;
      score += 800;
    }
  }
}

class KkaebiHexMinesweeperGame extends StatefulWidget {
  const KkaebiHexMinesweeperGame({super.key});

  static const String gameId = 'hex_mines';

  @override
  State<KkaebiHexMinesweeperGame> createState() => _KkaebiHexMinesweeperGameState();
}

class _KkaebiHexMinesweeperGameState extends State<KkaebiHexMinesweeperGame> {
  late HexMinesweeperModel model;
  bool _flagMode = false;
  bool _finished = false;

  @override
  void initState() {
    super.initState();
    _startNewGame();
  }

  void _startNewGame() {
    setState(() {
      model = HexMinesweeperModel(rows: 8, cols: 6, totalMines: 7);
      _finished = false;
      _flagMode = false;
    });
  }

  void _onTileTap(int r, int c) {
    if (_flagMode) {
      HapticFeedback.selectionClick();
      setState(() => model.toggleFlag(r, c));
      return;
    }

    final ok = model.reveal(r, c);
    if (ok) {
      SoundService().playCoinJangle();
      HapticFeedback.lightImpact();
    } else if (model.isGameOver) {
      SoundService().playRiddleWrong();
      HapticFeedback.heavyImpact();
    }
    setState(() {});

    if (!_finished && (model.isCleared || model.isGameOver)) {
      _finished = true;
      finishGame(
        context,
        gameId: KkaebiHexMinesweeperGame.gameId,
        title: model.isCleared ? '육각 벌집 지뢰찾기 클리어!' : '육각 벌집 지뢰찾기',
        score: model.score,
        cleared: model.isCleared,
        onRetry: _startNewGame,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isKo = context.watch<DokkeyProvider>().lang == 'ko';
    final remainingMines = (model.totalMines - model.flagsPlaced).clamp(0, 99);

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: SafeArea(
        child: Column(
          children: [
            GameHud(
              title: isKo ? '육각 벌집 지뢰찾기' : 'Hex Minesweeper',
              score: model.score,
              rightLabel: '💣 ',
              onQuit: () => Navigator.of(context).pop(),
              accent: const Color(0xFFFFD54F),
            ),

            // Mode indicator & toggle
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  Text(
                    isKo ? '⬡ 6방향 벌집 탐지' : '⬡ 6-Direction Radar',
                    style: const TextStyle(color: Color(0xFFFFD54F), fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                  const Spacer(),
                  FilterChip(
                    avatar: Text(_flagMode ? '🚩' : '⛏️', style: const TextStyle(fontSize: 12)),
                    label: Text(
                      _flagMode ? (isKo ? '부적 깃발 모드' : 'Flag Mode') : (isKo ? '탐색(파기) 모드' : 'Dig Mode'),
                      style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold),
                    ),
                    selected: _flagMode,
                    selectedColor: const Color(0xFFFF5252).withOpacity(0.3),
                    checkmarkColor: Colors.white,
                    onSelected: (val) {
                      HapticFeedback.selectionClick();
                      setState(() => _flagMode = val);
                    },
                  ),
                ],
              ),
            ),

            // Hexagon Grid Board
            Expanded(
              child: Center(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          for (var r = 0; r < model.rows; r++)
                            Transform.translate(
                              offset: Offset(r % 2 == 1 ? 22 : 0, 0),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  for (var c = 0; c < model.cols; c++)
                                    _buildHexTile(r, c),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHexTile(int r, int c) {
    final tile = model.board[r][c];

    Color tileBg = const Color(0xFF1E293B);
    Widget content = const SizedBox.shrink();

    if (tile.isRevealed) {
      if (tile.isMine) {
        tileBg = const Color(0xFFFF1744);
        content = const Text('💣', style: TextStyle(fontSize: 16));
      } else {
        tileBg = const Color(0xFF334155);
        if (tile.neighborMines > 0) {
          final nColors = [
            Colors.cyanAccent,
            Colors.greenAccent,
            Colors.amberAccent,
            Colors.orangeAccent,
            Colors.purpleAccent,
            Colors.redAccent,
          ];
          content = Text(
            '',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w900,
              color: nColors[(tile.neighborMines - 1).clamp(0, 5)],
            ),
          );
        }
      }
    } else if (tile.isFlagged) {
      tileBg = const Color(0xFF475569);
      content = const Text('🚩', style: TextStyle(fontSize: 16));
    }

    return GestureDetector(
      onTap: () => _onTileTap(r, c),
      child: Container(
        width: 44,
        height: 48,
        margin: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          color: tileBg,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: tile.isRevealed ? const Color(0xFF64748B) : const Color(0xFFFFD54F).withOpacity(0.6),
            width: 1.4,
          ),
          boxShadow: [
            if (!tile.isRevealed)
              BoxShadow(
                color: Colors.black.withOpacity(0.4),
                blurRadius: 3,
                offset: const Offset(1, 2),
              ),
          ],
        ),
        child: Center(child: content),
      ),
    );
  }
}
