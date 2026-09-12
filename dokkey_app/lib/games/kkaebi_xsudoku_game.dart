import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../core/sound_service.dart';
import '../providers/dokkey_provider.dart';
import 'core/game_shell.dart';

/// 🔢 깨비 대각선 X-스도쿠 (Diagonal X-Sudoku)
/// 일반 행/열/박스 고유성에 더해 메인 두 대각선(X자)에도 숫자가 중복되지 않아야 하는 고난도 두뇌 퍼즐.
class XSudokuModel {
  final int size; // 4 (2x2) or 9 (3x3)
  late int blockSize;
  late List<List<int>> solution;
  late List<List<int>> initial;
  late List<List<int>> current;
  late List<List<bool>> isInitial;

  int? selectedRow;
  int? selectedCol;
  int mistakes = 0;
  static const int maxMistakes = 3;
  int score = 0;
  bool isCleared = false;
  bool isGameOver = false;

  XSudokuModel({this.size = 4, int holes = 6, Random? random}) {
    blockSize = size == 4 ? 2 : 3;
    final rng = random ?? Random();
    _generate(holes, rng);
  }

  bool isMainDiagonal(int r, int c) => r == c;
  bool isAntiDiagonal(int r, int c) => r + c == size - 1;
  bool isDiagonal(int r, int c) => isMainDiagonal(r, c) || isAntiDiagonal(r, c);

  void _generate(int holes, Random rng) {
    solution = List.generate(size, (_) => List.filled(size, 0));
    _solve(0, 0, rng);

    initial = List.generate(size, (r) => List.from(solution[r]));
    current = List.generate(size, (r) => List.from(solution[r]));
    isInitial = List.generate(size, (r) => List.filled(size, true));

    final positions = <Point<int>>[];
    for (var r = 0; r < size; r++) {
      for (var c = 0; c < size; c++) {
        positions.add(Point(r, c));
      }
    }
    positions.shuffle(rng);

    final holesCount = holes.clamp(1, size * size - 2);
    for (var i = 0; i < holesCount && i < positions.length; i++) {
      final p = positions[i];
      initial[p.x][p.y] = 0;
      current[p.x][p.y] = 0;
      isInitial[p.x][p.y] = false;
    }
  }

  bool _isValid(List<List<int>> board, int row, int col, int val) {
    // 1. 행 검사
    for (var c = 0; c < size; c++) {
      if (c != col && board[row][c] == val) return false;
    }
    // 2. 열 검사
    for (var r = 0; r < size; r++) {
      if (r != row && board[r][col] == val) return false;
    }
    // 3. 블록 검사
    final br = (row ~/ blockSize) * blockSize;
    final bc = (col ~/ blockSize) * blockSize;
    for (var r = br; r < br + blockSize; r++) {
      for (var c = bc; c < bc + blockSize; c++) {
        if ((r != row || c != col) && board[r][c] == val) return false;
      }
    }
    // 4. 주 대각선 (Top-Left -> Bottom-Right)
    if (row == col) {
      for (var i = 0; i < size; i++) {
        if (i != row && board[i][i] == val) return false;
      }
    }
    // 5. 부 대각선 (Top-Right -> Bottom-Left)
    if (row + col == size - 1) {
      for (var r = 0; r < size; r++) {
        final c = size - 1 - r;
        if (r != row && board[r][c] == val) return false;
      }
    }
    return true;
  }

  bool _solve(int r, int c, Random rng) {
    if (r == size) return true;
    final nextR = (c == size - 1) ? r + 1 : r;
    final nextC = (c == size - 1) ? 0 : c + 1;

    final numbers = List.generate(size, (i) => i + 1)..shuffle(rng);
    for (final num in numbers) {
      if (_isValid(solution, r, c, num)) {
        solution[r][c] = num;
        if (_solve(nextR, nextC, rng)) return true;
        solution[r][c] = 0;
      }
    }
    return false;
  }

  bool inputNumber(int num) {
    if (selectedRow == null || selectedCol == null || isCleared || isGameOver) return false;
    final r = selectedRow!;
    final c = selectedCol!;
    if (isInitial[r][c]) return false;

    if (solution[r][c] == num) {
      current[r][c] = num;
      score += 150;
      _checkCleared();
      return true;
    } else {
      mistakes++;
      if (mistakes >= maxMistakes) {
        isGameOver = true;
      }
      return false;
    }
  }

  void erase() {
    if (selectedRow == null || selectedCol == null || isCleared || isGameOver) return;
    final r = selectedRow!;
    final c = selectedCol!;
    if (!isInitial[r][c]) {
      current[r][c] = 0;
    }
  }

  void _checkCleared() {
    for (var r = 0; r < size; r++) {
      for (var c = 0; c < size; c++) {
        if (current[r][c] != solution[r][c]) return;
      }
    }
    isCleared = true;
    score += (maxMistakes - mistakes) * 300 + 500;
  }
}

class KkaebiXSudokuGame extends StatefulWidget {
  const KkaebiXSudokuGame({super.key});

  static const String gameId = 'xsudoku';

  @override
  State<KkaebiXSudokuGame> createState() => _KkaebiXSudokuGameState();
}

class _KkaebiXSudokuGameState extends State<KkaebiXSudokuGame> {
  late XSudokuModel model;
  int _difficultySize = 4; // 4 or 9
  bool _finished = false;

  @override
  void initState() {
    super.initState();
    _startNewGame(_difficultySize);
  }

  void _startNewGame(int size) {
    _difficultySize = size;
    final holes = size == 4 ? 6 : 32;
    setState(() {
      model = XSudokuModel(size: size, holes: holes);
      _finished = false;
    });
  }

  void _onCellTap(int r, int c) {
    HapticFeedback.selectionClick();
    setState(() {
      model.selectedRow = r;
      model.selectedCol = c;
    });
  }

  void _onNumTap(int num) {
    final success = model.inputNumber(num);
    if (success) {
      SoundService().playCoinJangle();
      HapticFeedback.lightImpact();
    } else {
      SoundService().playRiddleWrong();
      HapticFeedback.heavyImpact();
    }
    setState(() {});

    if (!_finished && (model.isCleared || model.isGameOver)) {
      _finished = true;
      finishGame(
        context,
        gameId: KkaebiXSudokuGame.gameId,
        title: model.isCleared ? '대각선 X-스도쿠 클리어!' : '대각선 X-스도쿠',
        score: model.score,
        cleared: model.isCleared,
        onRetry: () => _startNewGame(_difficultySize),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isKo = context.watch<DokkeyProvider>().lang == 'ko';
    final hearts = List.generate(
      XSudokuModel.maxMistakes,
      (i) => i < (XSudokuModel.maxMistakes - model.mistakes) ? '❤️' : '🖤',
    ).join(' ');

    return Scaffold(
      backgroundColor: const Color(0xFF0D131F),
      body: SafeArea(
        child: Column(
          children: [
            GameHud(
              title: isKo ? '대각선 X-스도쿠' : 'Diagonal X-Sudoku',
              score: model.score,
              rightLabel: hearts,
              onQuit: () => Navigator.of(context).pop(),
              accent: const Color(0xFF00E5FF),
            ),

            // Mode Selector (4x4 or 9x9)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              child: Row(
                children: [
                  Text(
                    isKo ? '✨ 두 대각선(X)도 중복 없음!' : '✨ Diagonals (X) must be unique!',
                    style: const TextStyle(color: Color(0xFF00E5FF), fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                  const Spacer(),
                  ChoiceChip(
                    label: const Text('4x4', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                    selected: model.size == 4,
                    selectedColor: const Color(0xFF00E5FF),
                    onSelected: (_) => _startNewGame(4),
                  ),
                  const SizedBox(width: 6),
                  ChoiceChip(
                    label: const Text('9x9', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                    selected: model.size == 9,
                    selectedColor: const Color(0xFF00E5FF),
                    onSelected: (_) => _startNewGame(9),
                  ),
                ],
              ),
            ),

            // Sudoku Grid
            Expanded(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: AspectRatio(
                    aspectRatio: 1.0,
                    child: Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFF151E2E),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFF00E5FF).withOpacity(0.6), width: 2),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(14),
                        child: GridView.builder(
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: model.size,
                          ),
                          itemCount: model.size * model.size,
                          itemBuilder: (ctx, idx) {
                            final r = idx ~/ model.size;
                            final c = idx % model.size;
                            final val = model.current[r][c];
                            final isInit = model.isInitial[r][c];
                            final isSel = model.selectedRow == r && model.selectedCol == c;
                            final isDiag = model.isDiagonal(r, c);

                            Color cellBg = const Color(0xFF151E2E);
                            if (isSel) {
                              cellBg = const Color(0xFF00E5FF).withOpacity(0.35);
                            } else if (isDiag) {
                              cellBg = const Color(0xFF00E5FF).withOpacity(0.12);
                            }

                            final rightBorder = (c + 1) % model.blockSize == 0 && c != model.size - 1;
                            final bottomBorder = (r + 1) % model.blockSize == 0 && r != model.size - 1;

                            return GestureDetector(
                              onTap: () => _onCellTap(r, c),
                              child: Container(
                                decoration: BoxDecoration(
                                  color: cellBg,
                                  border: Border(
                                    right: BorderSide(
                                      color: rightBorder ? const Color(0xFF00E5FF).withOpacity(0.6) : Colors.white12,
                                      width: rightBorder ? 2.0 : 0.6,
                                    ),
                                    bottom: BorderSide(
                                      color: bottomBorder ? const Color(0xFF00E5FF).withOpacity(0.6) : Colors.white12,
                                      width: bottomBorder ? 2.0 : 0.6,
                                    ),
                                  ),
                                ),
                                child: Center(
                                  child: Text(
                                    val > 0 ? '' : '',
                                    style: TextStyle(
                                      color: isInit ? Colors.white70 : const Color(0xFFFFD54F),
                                      fontSize: model.size == 4 ? 26 : 17,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // Number Pad
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: const BoxDecoration(
                color: Color(0xFF0A101C),
                border: Border(top: BorderSide(color: Color(0xFF1E2D48))),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  for (var i = 1; i <= model.size; i++)
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 3),
                        child: ElevatedButton(
                          onPressed: () => _onNumTap(i),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF1E2D48),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            side: const BorderSide(color: Color(0xFF00E5FF), width: 1.2),
                          ),
                          child: Text('', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ),
                  const SizedBox(width: 4),
                  IconButton(
                    onPressed: () {
                      HapticFeedback.selectionClick();
                      setState(() => model.erase());
                    },
                    icon: const Icon(Icons.backspace_outlined, color: Colors.white70),
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
