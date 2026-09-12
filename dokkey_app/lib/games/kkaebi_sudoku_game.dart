import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../core/sound_service.dart';
import '../core/theme.dart';
import '../providers/dokkey_provider.dart';
import 'core/game_shell.dart';

/// 🔢 게임 2: 깨비 스도쿠 — 4x4(초급) · 6x6(중급) · 9x9(고급)
/// 한지 미학 · 충돌 하이라이트 · 연필 메모 · 깨비 지혜 힌트 · 남은 빈칸 현황
class SudokuPuzzle {
  final int size; // 4, 6, 또는 9
  final int boxW; // 박스 가로폭 (4:2, 6:3, 9:3)
  final int boxH; // 박스 세로높이 (4:2, 6:2, 9:3)
  late List<List<int>> solution;
  late List<List<int>> board; // 0 = 빈칸
  late List<List<bool>> given;

  SudokuPuzzle({required this.size, int? holes, Random? rng})
      : boxW = size == 4 ? 2 : 3,
        boxH = size == 6 ? 2 : (size == 4 ? 2 : 3) {
    final r = rng ?? Random();
    solution = _generateFull(r);
    board = [for (final row in solution) [...row]];
    
    // 난이도별 구멍 개수
    final targetHoles = holes ?? (size == 4 ? 6 : (size == 6 ? 16 : 40));
    final cells = [
      for (var y = 0; y < size; y++)
        for (var x = 0; x < size; x++) (x, y)
    ]..shuffle(r);
    final removeCount = min(targetHoles, size * size - (size == 4 ? 4 : (size == 6 ? 10 : 17)));
    var removed = 0;
    for (final (x, y) in cells) {
      if (removed >= removeCount) break;
      board[y][x] = 0;
      removed++;
    }
    given = [
      for (var y = 0; y < size; y++)
        [for (var x = 0; x < size; x++) board[y][x] != 0]
    ];
  }

  bool _isValid(List<List<int>> g, int x, int y, int v) {
    for (var i = 0; i < size; i++) {
      if (g[y][i] == v || g[i][x] == v) return false;
    }
    final bx = (x ~/ boxW) * boxW;
    final by = (y ~/ boxH) * boxH;
    for (var dy = 0; dy < boxH; dy++) {
      for (var dx = 0; dx < boxW; dx++) {
        if (g[by + dy][bx + dx] == v) return false;
      }
    }
    return true;
  }

  List<List<int>> _generateFull(Random r) {
    final g = [for (var y = 0; y < size; y++) List<int>.filled(size, 0)];
    bool fill(int pos) {
      if (pos >= size * size) return true;
      final x = pos % size;
      final y = pos ~/ size;
      final vals = [for (var v = 1; v <= size; v++) v]..shuffle(r);
      for (final v in vals) {
        if (_isValid(g, x, y, v)) {
          g[y][x] = v;
          if (fill(pos + 1)) return true;
          g[y][x] = 0;
        }
      }
      return false;
    }

    fill(0);
    return g;
  }

  /// 특정 셀 값이 규칙에 어긋나는지 (충돌 하이라이트)
  bool isConflict(int x, int y) {
    final v = board[y][x];
    if (v == 0) return false;
    for (var i = 0; i < size; i++) {
      if (i != x && board[y][i] == v) return true;
      if (i != y && board[i][x] == v) return true;
    }
    final bx = (x ~/ boxW) * boxW;
    final by = (y ~/ boxH) * boxH;
    for (var dy = 0; dy < boxH; dy++) {
      for (var dx = 0; dx < boxW; dx++) {
        final px = bx + dx;
        final py = by + dy;
        if ((px != x || py != y) && board[py][px] == v) return true;
      }
    }
    return false;
  }

  int get emptyCount {
    var count = 0;
    for (var y = 0; y < size; y++) {
      for (var x = 0; x < size; x++) {
        if (board[y][x] == 0) count++;
      }
    }
    return count;
  }

  bool get isSolved {
    for (var y = 0; y < size; y++) {
      for (var x = 0; x < size; x++) {
        if (board[y][x] == 0 || board[y][x] != solution[y][x]) return false;
      }
    }
    return true;
  }

  /// 깨비 지혜 힌트: 빈 칸 중 하나를 정답으로 채운다
  (int, int)? revealOneHint(Random r) {
    final empties = <(int, int)>[];
    for (var y = 0; y < size; y++) {
      for (var x = 0; x < size; x++) {
        if (board[y][x] == 0) empties.add((x, y));
      }
    }
    if (empties.isEmpty) return null;
    final (x, y) = empties[r.nextInt(empties.length)];
    board[y][x] = solution[y][x];
    return (x, y);
  }
}

class KkaebiSudokuGame extends StatefulWidget {
  final int initialSize;

  const KkaebiSudokuGame({super.key, this.initialSize = 4});

  static const String gameId = 'sudoku';

  @override
  State<KkaebiSudokuGame> createState() => _KkaebiSudokuGameState();
}

class _KkaebiSudokuGameState extends State<KkaebiSudokuGame>
    with GameLoopMixin {
  late int currentSize;
  late SudokuPuzzle puzzle;
  int selectedX = -1, selectedY = -1;
  bool notesMode = false;
  late List<List<Set<int>>> notes;
  int _score = 0;
  int _hintsLeft = 1;
  int _mistakes = 0;
  bool _finished = false;
  Timer? _timer;
  int _elapsed = 0;

  @override
  void initState() {
    super.initState();
    currentSize = widget.initialSize;
    _startNewGame(currentSize);
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!_finished && mounted) setState(() => _elapsed++);
    });
  }

  void _startNewGame(int size) {
    currentSize = size;
    puzzle = SudokuPuzzle(size: size);
    notes = [
      for (var y = 0; y < size; y++)
        [for (var x = 0; x < size; x++) <int>{}]
    ];
    _hintsLeft = 1;
    _mistakes = 0;
    _elapsed = 0;
    _finished = false;
    selectedX = -1;
    selectedY = -1;

    // 첫 번째 입력 가능한 빈칸을 기본 선택
    for (var y = 0; y < size; y++) {
      for (var x = 0; x < size; x++) {
        if (!puzzle.given[y][x]) {
          selectedX = x;
          selectedY = y;
          break;
        }
      }
      if (selectedX >= 0) break;
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _switchDifficulty(int size) {
    if (_finished) return;
    setState(() {
      _startNewGame(size);
    });
  }

  void _place(int v) {
    if (_finished || selectedX < 0 || selectedY < 0) return;
    if (puzzle.given[selectedY][selectedX]) return;
    setState(() {
      if (notesMode) {
        final set = notes[selectedY][selectedX];
        if (set.contains(v)) {
          set.remove(v);
        } else {
          set.add(v);
        }
        HapticFeedback.selectionClick();
        return;
      }
      puzzle.board[selectedY][selectedX] = v;
      notes[selectedY][selectedX].clear();
      if (puzzle.board[selectedY][selectedX] != puzzle.solution[selectedY][selectedX]) {
        _mistakes++;
        _score = max(0, _score - 30);
        SoundService().playRiddleWrong();
        HapticFeedback.mediumImpact();
      } else {
        _score += 60;
        SoundService().playSuccessChime();
        HapticFeedback.lightImpact();
      }
      _checkSolved();
    });
  }

  void _erase() {
    if (_finished || selectedX < 0 || selectedY < 0) return;
    if (puzzle.given[selectedY][selectedX]) return;
    setState(() {
      puzzle.board[selectedY][selectedX] = 0;
      notes[selectedY][selectedX].clear();
    });
    HapticFeedback.lightImpact();
  }

  void _useHint() {
    if (_finished || _hintsLeft <= 0) return;
    final revealed = puzzle.revealOneHint(Random());
    if (revealed != null) {
      final (hx, hy) = revealed;
      setState(() {
        _hintsLeft--;
        _score = max(0, _score - 50);
        selectedX = hx;
        selectedY = hy;
      });
      SoundService().playSuccessChime();
      _checkSolved();
    }
  }

  void _checkSolved() {
    if (!puzzle.isSolved || _finished) return;
    _finished = true;
    _timer?.cancel();
    _score += 500 + (600 - _elapsed * 2).clamp(0, 600) + (_mistakes == 0 ? 300 : 0);
    finishGame(
      context,
      gameId: KkaebiSudokuGame.gameId,
      title: currentSize == 4 ? '스도쿠 4×4' : (currentSize == 6 ? '스도쿠 6×6' : '스도쿠 9×9'),
      score: _score,
      cleared: true,
      onRetry: () => Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => KkaebiSudokuGame(initialSize: currentSize)),
      ),
    );
  }

  @override
  void onUpdate(double dt) {}

  @override
  void onPaint(Canvas canvas, Size size) {
    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = DokkeyTheme.bgDark,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isKo = context.watch<DokkeyProvider>().lang == 'ko';
    final screenWidth = MediaQuery.of(context).size.width;

    // 모바일 가로폭에 맞춰 동적 셀 크기 계산 (완벽 중앙 정렬)
    final maxBoardWidth = min(screenWidth - 24, 380.0);
    const boardPadding = 10.0;
    final gridWidth = maxBoardWidth - (boardPadding * 2);
    final cellSize = (gridWidth / puzzle.size).floorToDouble();
    final actualBoardInnerWidth = cellSize * puzzle.size;

    return Scaffold(
      backgroundColor: DokkeyTheme.bgDark,
      body: gameCanvas(
        overlayBuilder: () => SafeArea(
          child: Column(
            children: [
              GameHud(
                title: isKo
                    ? '깨비 스도쿠 ($currentSize×$currentSize)'
                    : 'Sudoku ($currentSize×$currentSize)',
                score: _score,
                rightLabel: '⏱ ${_elapsed}s · ✗$_mistakes',
                onQuit: () => Navigator.of(context).pop(),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Column(
                    children: [
                      // 1. 난이도 선택 탭 (4x4 초급, 6x6 중급, 9x9 고급)
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1B2230),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: const Color(0xFF334155), width: 1.2),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            _buildDifficultyTab(size: 4, label: isKo ? '4×4 초급' : '4×4 Easy'),
                            _buildDifficultyTab(size: 6, label: isKo ? '6×6 중급' : '6×6 Medium'),
                            _buildDifficultyTab(size: 9, label: isKo ? '9×9 고급' : '9×9 Hard'),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      // 2. 남은 빈칸 & 가이드 현황 배지
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                        decoration: BoxDecoration(
                          color: notesMode ? const Color(0xFF004D25).withOpacity(0.85) : const Color(0xFF1E2638),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: notesMode ? const Color(0xFF00E676) : const Color(0xFF3B4861),
                            width: 1.2,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              notesMode ? Icons.edit_note_rounded : Icons.grid_on_rounded,
                              size: 18,
                              color: notesMode ? const Color(0xFF00E676) : const Color(0xFFFFD700),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              notesMode
                                  ? (isKo ? '✏️ 메모 모드 (후보 번호 기록)' : '✏️ Memo Active')
                                  : (isKo ? '🎯 남은 빈칸: ${puzzle.emptyCount}개' : '🎯 Empty: ${puzzle.emptyCount}'),
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: notesMode ? const Color(0xFF00E676) : const Color(0xFFFFE66D),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),
                      // 3. 한지 나무판 스도쿠 보드 (완벽한 중앙 정렬)
                      Center(
                        child: Container(
                          width: actualBoardInnerWidth + (boardPadding * 2),
                          padding: const EdgeInsets.all(boardPadding),
                          decoration: BoxDecoration(
                            color: const Color(0xFF2E2012).withOpacity(0.85),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: DokkeyTheme.gold.withOpacity(0.8), width: 2.2),
                            boxShadow: const [
                              BoxShadow(
                                color: Colors.black54,
                                blurRadius: 10,
                                offset: Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: List.generate(puzzle.size, (y) {
                              return Row(
                                mainAxisSize: MainAxisSize.min,
                                children: List.generate(puzzle.size, (x) {
                                  final given = puzzle.given[y][x];
                                  final value = puzzle.board[y][x];
                                  final conflict = puzzle.isConflict(x, y);
                                  final selected = selectedX == x && selectedY == y;
                                  final boldRight =
                                      (x + 1) % puzzle.boxW == 0 && x != puzzle.size - 1;
                                  final boldBottom =
                                      (y + 1) % puzzle.boxH == 0 && y != puzzle.size - 1;
                                  return GestureDetector(
                                    onTap: () => setState(() {
                                      selectedX = x;
                                      selectedY = y;
                                    }),
                                    child: Container(
                                      width: cellSize,
                                      height: cellSize,
                                      decoration: BoxDecoration(
                                        color: selected
                                            ? DokkeyTheme.gold.withOpacity(0.32)
                                            : DokkeyTheme.surfaceDark.withOpacity(0.85),
                                        border: Border(
                                          right: BorderSide(
                                            color: boldRight
                                                ? const Color(0xFFFFD700)
                                                : const Color(0xFF4A5568),
                                            width: boldRight ? 2.2 : 0.8,
                                          ),
                                          bottom: BorderSide(
                                            color: boldBottom
                                                ? const Color(0xFFFFD700)
                                                : const Color(0xFF4A5568),
                                            width: boldBottom ? 2.2 : 0.8,
                                          ),
                                        ),
                                      ),
                                      child: Center(
                                        child: value != 0
                                            ? Text(
                                                '$value',
                                                style: TextStyle(
                                                  fontSize: currentSize == 4
                                                      ? 28
                                                      : (currentSize == 6 ? 22 : 16.5),
                                                  fontWeight: given
                                                      ? FontWeight.w900
                                                      : FontWeight.w700,
                                                  color: conflict
                                                      ? DokkeyTheme.dokFire
                                                      : (given
                                                          ? const Color(0xFFFFD700)
                                                          : const Color(0xFF00E676)),
                                                ),
                                              )
                                            : (notes[y][x].isNotEmpty
                                                ? Padding(
                                                    padding: const EdgeInsets.all(2),
                                                    child: Wrap(
                                                      alignment: WrapAlignment.center,
                                                      spacing: 2,
                                                      children: (notes[y][x].toList()..sort())
                                                          .map((n) => Text(
                                                                '$n',
                                                                style: TextStyle(
                                                                  fontSize: currentSize == 4
                                                                      ? 12
                                                                      : (currentSize == 6 ? 10 : 8),
                                                                  fontWeight: FontWeight.bold,
                                                                  color: const Color(0xFF38BDF8),
                                                                ),
                                                              ))
                                                          .toList(),
                                                    ),
                                                  )
                                                : null),
                                      ),
                                    ),
                                  );
                                }),
                              );
                            }),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      // 4. 숫자 패드 (9x9 대형 2줄 패드 / 선명한 골드 버튼)
                      _buildNumberKeypad(screenWidth),
                      const SizedBox(height: 18),
                      // 5. 하단 액션 버튼 그룹 (메모, 힌트, 지우기)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // ✏️ 연필 메모 토글
                          ElevatedButton.icon(
                            onPressed: () => setState(() => notesMode = !notesMode),
                            icon: Icon(
                              Icons.edit_note_rounded,
                              size: 19,
                              color: notesMode ? const Color(0xFF00E676) : Colors.white70,
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: notesMode ? const Color(0xFF004D25) : const Color(0xFF222B3D),
                              foregroundColor: Colors.white,
                              side: BorderSide(
                                color: notesMode ? const Color(0xFF00E676) : const Color(0xFF64748B),
                                width: 1.5,
                              ),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
                            ),
                            label: Text(
                              notesMode
                                  ? (isKo ? '메모: ON' : 'Memo: ON')
                                  : (isKo ? '메모: OFF' : 'Memo: OFF'),
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: notesMode ? const Color(0xFF00E676) : Colors.white,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          // 👺 깨비 지혜 힌트
                          ElevatedButton.icon(
                            onPressed: _hintsLeft > 0 ? _useHint : null,
                            icon: const Text('👺', style: TextStyle(fontSize: 15)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF3B2B15),
                              foregroundColor: const Color(0xFFFFD700),
                              disabledBackgroundColor: const Color(0xFF222B3D).withOpacity(0.5),
                              side: BorderSide(
                                color: _hintsLeft > 0 ? const Color(0xFFFFD700) : const Color(0xFF4A5568),
                                width: 1.5,
                              ),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
                            ),
                            label: Text(
                              isKo ? '지혜 힌트 ($_hintsLeft)' : 'Hint ($_hintsLeft)',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w900,
                                color: _hintsLeft > 0 ? const Color(0xFFFFE66D) : const Color(0xFF94A3B8),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          // ⌫ 지우기 버튼
                          ElevatedButton.icon(
                            onPressed: _erase,
                            icon: const Icon(Icons.backspace_rounded, size: 16, color: Color(0xFFFF8A80)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF2B2024),
                              foregroundColor: const Color(0xFFFF8A80),
                              side: const BorderSide(color: Color(0xFFEF4444), width: 1.3),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
                            ),
                            label: Text(
                              isKo ? '지우기' : 'Erase',
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFFFF8A80),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      // 6. 📜 스도쿠 규칙 및 클리어 안내 카드
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFF141A24),
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: const Color(0xFF3B4861), width: 1.5),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Text('📜', style: TextStyle(fontSize: 18)),
                                const SizedBox(width: 8),
                                Text(
                                  isKo ? '깨비 스도쿠 게임 규칙 & 종료 안내' : 'Sudoku Rules & Goal',
                                  style: const TextStyle(
                                    color: Color(0xFFFFD700),
                                    fontWeight: FontWeight.w900,
                                    fontSize: 15,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Text(
                              isKo
                                  ? '• [기본 룰]: 가로줄, 세로줄, 굵은 테두리 상자 안에 각 번호가 중복 없이 딱 한 번씩만 들어가야 합니다.\n  - 4×4: 1~4 숫자 / 2×2 상자\n  - 6×6: 1~6 숫자 / 3×2 상자\n  - 9×9: 1~9 숫자 / 3×3 상자\n• [종료 시점]: 화면의 모든 빈칸(🎯 남은 빈칸: 0)을 오류 없이 채우면 즉시 스테이지 클리어 및 리워드(코인·친밀도·열쇠)가 지급됩니다!\n• [팁]: 확실치 않은 숫자는 [메모: ON] 상태에서 후보 숫자로 적어두며 추리할 수 있습니다.'
                                  : '• Rules: Every row, column, and bold box must contain unique numbers without duplicates.\n• Goal: Fill all empty cells correctly to clear the stage and win rewards!\n• Tip: Use [Memo: ON] to write down candidate numbers.',
                              style: const TextStyle(
                                color: Color(0xFFE2E8F0),
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                height: 1.6,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDifficultyTab({required int size, required String label}) {
    final isSelected = currentSize == size;
    return Expanded(
      child: GestureDetector(
        onTap: () => _switchDifficulty(size),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          margin: const EdgeInsets.symmetric(horizontal: 3),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFFB45309) : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSelected ? const Color(0xFFFFD700) : Colors.transparent,
              width: 1.5,
            ),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : const Color(0xFF94A3B8),
                fontWeight: isSelected ? FontWeight.w900 : FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNumberKeypad(double screenWidth) {
    final availableWidth = min(screenWidth - 32, 380.0);

    if (currentSize == 9) {
      // 9x9의 경우 2줄(1~5, 6~9)로 분할하여 모바일 터치에 충분한 대형 크기(54px+) 확보
      final buttonW = ((availableWidth - (4 * 8)) / 5).floorToDouble().clamp(52.0, 68.0);
      const buttonH = 50.0;
      const fontSize = 21.0;

      return Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (var v = 1; v <= 5; v++) ...[
                if (v > 1) const SizedBox(width: 8),
                _buildKeyButton(v, buttonW, buttonH, fontSize),
              ],
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (var v = 6; v <= 9; v++) ...[
                if (v > 6) const SizedBox(width: 8),
                _buildKeyButton(v, buttonW, buttonH, fontSize),
              ],
            ],
          ),
        ],
      );
    } else if (currentSize == 6) {
      final buttonW = ((availableWidth - (5 * 8)) / 6).floorToDouble().clamp(46.0, 58.0);
      const buttonH = 50.0;
      const fontSize = 21.0;

      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          for (var v = 1; v <= 6; v++) ...[
            if (v > 1) const SizedBox(width: 8),
            _buildKeyButton(v, buttonW, buttonH, fontSize),
          ],
        ],
      );
    } else {
      // 4x4
      final buttonW = ((availableWidth - (3 * 10)) / 4).floorToDouble().clamp(64.0, 80.0);
      const buttonH = 54.0;
      const fontSize = 24.0;

      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          for (var v = 1; v <= 4; v++) ...[
            if (v > 1) const SizedBox(width: 10),
            _buildKeyButton(v, buttonW, buttonH, fontSize),
          ],
        ],
      );
    }
  }

  Widget _buildKeyButton(int v, double w, double h, double fontSize) {
    return ElevatedButton(
      onPressed: () => _place(v),
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF222B3D),
        foregroundColor: const Color(0xFFFFD700),
        minimumSize: Size(w, h),
        padding: EdgeInsets.zero,
        elevation: 3,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: Color(0xFFFFD700), width: 1.5),
        ),
      ),
      child: Text(
        '$v',
        style: TextStyle(
          fontSize: fontSize,
          fontWeight: FontWeight.w900,
          color: const Color(0xFFFFE66D),
        ),
      ),
    );
  }
}
