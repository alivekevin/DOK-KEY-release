import 'dart:async';
import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../core/sound_service.dart';
import '../core/theme.dart';
import '../providers/dokkey_provider.dart';
import 'core/game_shell.dart';

/// 🧮 게임 2: 깨비 마방진 (Kkaebi Magic Square)
/// 3x3(초급, 합=15) · 4x4(중급, 합=34) · 5x5(상급, 합=65)
/// 신비로운 룬 마법진 연출 · 실시간 가로/세로/대각선 합계 가이드 · 직관적 듀얼 터치 패드

class MagicSquarePuzzle {
  final int size; // 3, 4, 5
  final int targetSum;
  late List<List<int>> solution;
  late List<List<int>> board; // 0 = 빈칸
  late List<List<bool>> given;

  MagicSquarePuzzle({required this.size, int? holes, Random? rng})
      : targetSum = (size * (size * size + 1)) ~/ 2 {
    final r = rng ?? Random();
    solution = _generateMagicSquare(size, r);
    board = [for (final row in solution) [...row]];

    final totalCells = size * size;
    final defaultHoles = switch (size) {
      3 => 4, // 3x3: 4개 빈칸 (5개 주어짐)
      4 => 8, // 4x4: 8개 빈칸 (8개 주어짐)
      _ => 14, // 5x5: 14개 빈칸 (11개 주어짐)
    };
    final removeCount = (holes ?? defaultHoles).clamp(0, totalCells - 1);

    final cells = [
      for (var y = 0; y < size; y++)
        for (var x = 0; x < size; x++) (x, y)
    ]..shuffle(r);

    for (var i = 0; i < removeCount; i++) {
      final (x, y) = cells[i];
      board[y][x] = 0;
    }

    given = [
      for (var y = 0; y < size; y++)
        [for (var x = 0; x < size; x++) board[y][x] != 0]
    ];
  }

  static List<List<int>> _generateMagicSquare(int n, Random r) {
    List<List<int>> sq;
    if (n % 2 == 1) {
      sq = _siameseMethod(n);
    } else if (n == 4) {
      sq = _durer4x4();
    } else {
      sq = _siameseMethod(3);
    }

    // 8가지 회전/반전 대칭 변환
    final rot = r.nextInt(4);
    for (var i = 0; i < rot; i++) {
      sq = _rotate90(sq, n);
    }
    if (r.nextBool()) {
      sq = [for (final row in sq) row.reversed.toList()];
    }
    if (r.nextBool()) {
      sq = sq.reversed.toList();
    }

    return sq;
  }

  static List<List<int>> _siameseMethod(int n) {
    final grid = List.generate(n, (_) => List.filled(n, 0));
    var r = 0;
    var c = n ~/ 2;
    for (var num = 1; num <= n * n; num++) {
      grid[r][c] = num;
      var nextR = (r - 1 + n) % n;
      var nextC = (c + 1) % n;
      if (grid[nextR][nextC] != 0) {
        nextR = (r + 1) % n;
        nextC = c;
      }
      r = nextR;
      c = nextC;
    }
    return grid;
  }

  static List<List<int>> _durer4x4() {
    return [
      [16, 3, 2, 13],
      [5, 10, 11, 8],
      [9, 6, 7, 12],
      [4, 15, 14, 1],
    ];
  }

  static List<List<int>> _rotate90(List<List<int>> m, int n) {
    final res = List.generate(n, (_) => List.filled(n, 0));
    for (var r = 0; r < n; r++) {
      for (var c = 0; c < n; c++) {
        res[c][n - 1 - r] = m[r][c];
      }
    }
    return res;
  }

  int rowSum(int y) => board[y].fold(0, (a, b) => a + b);
  int colSum(int x) => [for (var y = 0; y < size; y++) board[y][x]].fold(0, (a, b) => a + b);

  int diag1Sum() => [for (var i = 0; i < size; i++) board[i][i]].fold(0, (a, b) => a + b);
  int diag2Sum() => [for (var i = 0; i < size; i++) board[i][size - 1 - i]].fold(0, (a, b) => a + b);

  bool isRowFilled(int y) => board[y].every((v) => v != 0);
  bool isColFilled(int x) => [for (var y = 0; y < size; y++) board[y][x]].every((v) => v != 0);
  bool isDiag1Filled() => [for (var i = 0; i < size; i++) board[i][i]].every((v) => v != 0);
  bool isDiag2Filled() => [for (var i = 0; i < size; i++) board[i][size - 1 - i]].every((v) => v != 0);

  bool isRowComplete(int y) => isRowFilled(y) && rowSum(y) == targetSum;
  bool isColComplete(int x) => isColFilled(x) && colSum(x) == targetSum;
  bool isDiag1Complete() => isDiag1Filled() && diag1Sum() == targetSum;
  bool isDiag2Complete() => isDiag2Filled() && diag2Sum() == targetSum;

  bool isNumberUsed(int val) {
    for (var y = 0; y < size; y++) {
      for (var x = 0; x < size; x++) {
        if (board[y][x] == val) return true;
      }
    }
    return false;
  }

  Set<int> get usedNumbers {
    final s = <int>{};
    for (final row in board) {
      for (final v in row) {
        if (v != 0) s.add(v);
      }
    }
    return s;
  }

  bool get isCleared {
    final maxNum = size * size;
    final used = usedNumbers;
    if (used.length != maxNum) return false;
    for (var i = 1; i <= maxNum; i++) {
      if (!used.contains(i)) return false;
    }
    for (var y = 0; y < size; y++) {
      if (rowSum(y) != targetSum) return false;
    }
    for (var x = 0; x < size; x++) {
      if (colSum(x) != targetSum) return false;
    }
    if (diag1Sum() != targetSum || diag2Sum() != targetSum) return false;
    return true;
  }
}

// ---------------------------------------------------------------------------
// 🧮 깨비 마방진 화면 위젯
// ---------------------------------------------------------------------------

class KkaebiMagicSquareGame extends StatefulWidget {
  static const String gameId = 'magic_square';

  const KkaebiMagicSquareGame({super.key});

  @override
  State<KkaebiMagicSquareGame> createState() => _KkaebiMagicSquareGameState();
}

class _KkaebiMagicSquareGameState extends State<KkaebiMagicSquareGame>
    with SingleTickerProviderStateMixin {
  int _size = 3; // 3, 4, 5
  late MagicSquarePuzzle _puzzle;
  int _selX = -1;
  int _selY = -1;
  int? _preSelectedNumber; // 숫자 트레이에서 먼저 선택한 숫자 (Quick Place 모드)
  int _hintsLeft = 3;
  int _moveCount = 0;
  int _seconds = 0;
  bool _cleared = false;
  Timer? _timer;

  late AnimationController _runeAnimCtrl;
  final List<List<List<int>>> _history = [];

  @override
  void initState() {
    super.initState();
    _runeAnimCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 40),
    )..repeat();
    _startNewGame(3);
  }

  @override
  void dispose() {
    _runeAnimCtrl.dispose();
    _timer?.cancel();
    super.dispose();
  }

  void _startNewGame(int size) {
    _size = size;
    _puzzle = MagicSquarePuzzle(size: size);
    _selX = -1;
    _selY = -1;
    _preSelectedNumber = null;
    _hintsLeft = 3;
    _moveCount = 0;
    _seconds = 0;
    _cleared = false;
    _history.clear();

    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!_cleared && mounted) {
        setState(() => _seconds++);
      }
    });

    setState(() {});
  }

  void _pushHistory() {
    _history.add([for (final r in _puzzle.board) [...r]]);
    if (_history.length > 20) _history.removeAt(0);
  }

  void _undo() {
    if (_history.isEmpty || _cleared) return;
    _puzzle.board = _history.removeLast();
    SoundService().playCardFlip();
    HapticFeedback.lightImpact();
    setState(() {});
  }

  void _onCellTapped(int x, int y) {
    if (_cleared) return;
    final isGiven = _puzzle.given[y][x];

    // 만약 숫자 트레이에서 숫자를 먼저 골랐다면 즉시 배치
    if (_preSelectedNumber != null) {
      if (!isGiven) {
        _pushHistory();
        _puzzle.board[y][x] = _preSelectedNumber!;
        _moveCount++;
        _preSelectedNumber = null;
        SoundService().playKeyTurn();
        HapticFeedback.selectionClick();

        if (_puzzle.isCleared) {
          _onGameCleared();
        }
      }
      setState(() {
        _selX = x;
        _selY = y;
      });
      return;
    }

    // 일반 셀 선택
    setState(() {
      if (_selX == x && _selY == y && !isGiven && _puzzle.board[y][x] != 0) {
        // 동일 셀 재탭 시 지우기
        _pushHistory();
        _puzzle.board[y][x] = 0;
        SoundService().playCardFlip();
      } else {
        _selX = x;
        _selY = y;
        SoundService().playCardFlip();
        HapticFeedback.selectionClick();
      }
    });
  }

  void _onNumberPadTapped(int numVal) {
    if (_cleared) return;

    // 1. 이미 셀이 선택되어 있다면 바로 입력
    if (_selX >= 0 && _selY >= 0 && !_puzzle.given[_selY][_selX]) {
      _pushHistory();
      _puzzle.board[_selY][_selX] = numVal;
      _moveCount++;
      _preSelectedNumber = null;
      SoundService().playKeyTurn();
      HapticFeedback.selectionClick();

      if (_puzzle.isCleared) {
        _onGameCleared();
      }
      setState(() {});
      return;
    }

    // 2. 셀이 선택되어 있지 않다면 Quick Place용 프리셀렉트 토글
    setState(() {
      if (_preSelectedNumber == numVal) {
        _preSelectedNumber = null;
      } else {
        _preSelectedNumber = numVal;
        SoundService().playCardFlip();
        HapticFeedback.lightImpact();
      }
    });
  }

  void _clearSelectedCell() {
    if (_selX < 0 || _selY < 0 || _cleared) return;
    if (_puzzle.given[_selY][_selX]) return;

    _pushHistory();
    _puzzle.board[_selY][_selX] = 0;
    SoundService().playCardFlip();
    HapticFeedback.lightImpact();
    setState(() {});
  }

  void _useHint() {
    if (_hintsLeft <= 0 || _cleared) return;

    final empties = <(int, int)>[];
    for (var y = 0; y < _size; y++) {
      for (var x = 0; x < _size; x++) {
        if (!_puzzle.given[y][x] && _puzzle.board[y][x] != _puzzle.solution[y][x]) {
          empties.add((x, y));
        }
      }
    }

    if (empties.isEmpty) return;
    empties.shuffle();
    final (hx, hy) = empties.first;

    _pushHistory();
    _puzzle.board[hy][hx] = _puzzle.solution[hy][hx];
    _hintsLeft--;
    _selX = hx;
    _selY = hy;
    _preSelectedNumber = null;
    SoundService().playSuccessChime();
    HapticFeedback.heavyImpact();

    if (_puzzle.isCleared) {
      _onGameCleared();
    }
    setState(() {});
  }

  void _showRulesDialog() {
    final isKo = context.read<DokkeyProvider>().lang == 'ko';
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF1F170C),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: DokkeyTheme.gold, width: 1.5),
        ),
        title: Row(
          children: [
            const Text('🧮', style: TextStyle(fontSize: 22)),
            const SizedBox(width: 8),
            Text(
              isKo ? '깨비 마방진의 비법' : 'Magic Square Secrets',
              style: TextStyle(
                color: DokkeyTheme.goldLight,
                fontWeight: FontWeight.w900,
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
              Text(
                isKo
                  ? '마방진(魔方陣)은 가로, 세로, 두 대각선의 모든 숫자 합이 정확히 일치하도록 1부터 N²까지의 숫자를 겹치지 않게 채우는 고대 신비의 숫자 퍼즐입니다.'
                  : 'A Magic Square is an ancient puzzle where all rows, columns, and diagonals sum to the exact same magic constant using numbers 1 to N² without duplicates.',
                style: const TextStyle(color: Colors.white70, fontSize: 13, height: 1.5),
              ),
              const SizedBox(height: 12),
              _buildRuleBadge(
                '3x3 (낙서 마방진)',
                '1~9 숫자 사용 · 목표 합: 15',
                Colors.amberAccent,
              ),
              const SizedBox(height: 6),
              _buildRuleBadge(
                '4x4 (뒤러 마방진)',
                '1~16 숫자 사용 · 목표 합: 34',
                Colors.cyanAccent,
              ),
              const SizedBox(height: 6),
              _buildRuleBadge(
                '5x5 (천원 마방진)',
                '1~25 숫자 사용 · 목표 합: 65',
                Colors.pinkAccent,
              ),
              const SizedBox(height: 12),
              Text(
                isKo
                  ? '💡 팁: 합이 완성된 행/열/대각선은 초록색으로 빛나며, 하단 숫자패드에서 남은 숫자를 확인하고 배치할 수 있습니다.'
                  : '💡 Tip: Completed rows/cols glow green. Use the number tray below to track remaining numbers.',
                style: TextStyle(color: DokkeyTheme.goldLight, fontSize: 12, height: 1.4),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              isKo ? '알겠어!' : 'Got it!',
              style: TextStyle(color: DokkeyTheme.gold, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRuleBadge(String title, String desc, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Row(
        children: [
          Icon(Icons.check_circle_outline_rounded, color: color, size: 14),
          const SizedBox(width: 6),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12)),
                Text(desc, style: const TextStyle(color: Colors.white70, fontSize: 11)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _onGameCleared() async {
    _cleared = true;
    _timer?.cancel();
    final score = max(100, (1000 * _size - _seconds * 3 - _moveCount * 5)).clamp(100, 5000);
    SoundService().playSuccessChime();

    final reward = await dispatchGameReward(
      context,
      gameId: KkaebiMagicSquareGame.gameId,
      score: score,
      cleared: true,
    );
    if (!mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => GameResultDialog(
        gameId: KkaebiMagicSquareGame.gameId,
        title: '🧮 신비의 마방진 완성!',
        score: score,
        best: score,
        cleared: true,
        onRetry: () {
          Navigator.of(context).pop();
          _startNewGame(_size);
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
    final maxNum = _size * _size;

    return Scaffold(
      backgroundColor: const Color(0xFF140F07),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1F170C),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('🧮', style: TextStyle(fontSize: 20)),
            const SizedBox(width: 8),
            Text(
              isKo ? '깨비 마방진' : 'Magic Square',
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
            icon: const Icon(Icons.help_outline_rounded, color: Colors.amberAccent, size: 22),
            tooltip: isKo ? '규칙 설명' : 'Rules',
            onPressed: _showRulesDialog,
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Colors.amberAccent, size: 22),
            tooltip: isKo ? '다시 시작' : 'Restart',
            onPressed: () => _startNewGame(_size),
          ),
        ],
      ),
      body: SafeArea(
        child: Stack(
          children: [
            // 0. 배경 은은한 룬 마법진 회전 캔버스
            Positioned.fill(
              child: AnimatedBuilder(
                animation: _runeAnimCtrl,
                builder: (context, _) => CustomPaint(
                  painter: _RuneCirclePainter(angle: _runeAnimCtrl.value * 2 * pi),
                ),
              ),
            ),

            // 1. 메인 게임 UI 레이아웃
            Column(
              children: [
                // 1. 난이도 탭 & 목표 합계 배지 & 타이머
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  child: Row(
                    children: [
                      _buildDiffTab(3, isKo ? '3x3 초급' : '3x3 Easy'),
                      const SizedBox(width: 5),
                      _buildDiffTab(4, isKo ? '4x4 중급' : '4x4 Med'),
                      const SizedBox(width: 5),
                      _buildDiffTab(5, isKo ? '5x5 상급' : '5x5 Hard'),
                      const Spacer(),
                      // 타이머
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.5),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: DokkeyTheme.borderDark),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.timer_outlined, color: Colors.amberAccent, size: 13),
                            const SizedBox(width: 3),
                            Text(
                              '${_seconds}s',
                              style: const TextStyle(
                                color: Colors.amberAccent,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 6),
                      // 목표 합계 뱃지
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF6A4E1D), Color(0xFF3E2D11)],
                          ),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: DokkeyTheme.gold, width: 1.3),
                          boxShadow: [
                            BoxShadow(
                              color: DokkeyTheme.gold.withOpacity(0.25),
                              blurRadius: 6,
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.auto_awesome_rounded, color: Colors.amber, size: 13),
                            const SizedBox(width: 3),
                            Text(
                              '합: ${_puzzle.targetSum}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // 2. 대각선 합 & 마방진 메인 보드 그리드
                Expanded(
                  child: Center(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // 상단 대각선 2 합계 인디케이터
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              _buildDiagBadge(
                                '↘ 대각선',
                                _puzzle.diag1Sum(),
                                _puzzle.isDiag1Complete(),
                              ),
                              const SizedBox(width: 14),
                              _buildDiagBadge(
                                '↙ 대각선',
                                _puzzle.diag2Sum(),
                                _puzzle.isDiag2Complete(),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),

                          // 보드 & 행/열 합계 표시
                          _buildMagicBoard(),
                        ],
                      ),
                    ),
                  ),
                ),

                // 3. 하단 도구 바 (되돌리기, 지우기, 힌트)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildToolBtn(
                        icon: Icons.undo_rounded,
                        label: isKo ? '되돌리기' : 'Undo',
                        onTap: _history.isNotEmpty ? _undo : null,
                      ),
                      _buildToolBtn(
                        icon: Icons.backspace_outlined,
                        label: isKo ? '지우기' : 'Erase',
                        onTap: (_selX >= 0 && !_puzzle.given[_selY][_selX]) ? _clearSelectedCell : null,
                      ),
                      _buildToolBtn(
                        icon: Icons.auto_fix_high_rounded,
                        label: isKo ? '깨비 힌트 ($_hintsLeft)' : 'Hint ($_hintsLeft)',
                        highlight: _hintsLeft > 0,
                        onTap: _hintsLeft > 0 ? _useHint : null,
                      ),
                    ],
                  ),
                ),

                // 4. 숫자 트레이 (Number Pad Tray)
                Container(
                  padding: const EdgeInsets.fromLTRB(10, 8, 10, 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E170E).withOpacity(0.95),
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                    border: Border(top: BorderSide(color: DokkeyTheme.gold.withOpacity(0.4), width: 1.5)),
                  ),
                  child: _buildNumberPad(maxNum),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDiffTab(int size, String label) {
    final active = _size == size;
    return GestureDetector(
      onTap: () {
        if (_size != size) _startNewGame(size);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
        decoration: BoxDecoration(
          color: active ? DokkeyTheme.dokFire.withOpacity(0.35) : DokkeyTheme.surfaceDark,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: active ? DokkeyTheme.dokFire : DokkeyTheme.borderDark,
            width: 1.2,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: active ? Colors.amberAccent : DokkeyTheme.textMuted,
            fontSize: 11,
            fontWeight: active ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildDiagBadge(String label, int sum, bool complete) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: complete ? const Color(0xFF1B5E20) : const Color(0xFF2C2214),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: complete ? Colors.greenAccent : DokkeyTheme.borderDark,
          width: 1,
        ),
        boxShadow: complete
            ? [
                BoxShadow(
                  color: Colors.greenAccent.withOpacity(0.35),
                  blurRadius: 6,
                ),
              ]
            : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label, style: const TextStyle(color: Colors.amberAccent, fontSize: 11)),
          const SizedBox(width: 5),
          Text(
            '$sum/${_puzzle.targetSum}',
            style: TextStyle(
              color: complete ? Colors.greenAccent : Colors.white70,
              fontSize: 11,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMagicBoard() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final availableSize = min(constraints.maxWidth, 340.0);
        final cellSize = (availableSize - 44) / _size;

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var y = 0; y < _size; y++)
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  for (var x = 0; x < _size; x++)
                    _buildCell(x, y, cellSize),

                  const SizedBox(width: 6),
                  // 행(Row) 합계 인디케이터
                  _buildSumBadge(
                    _puzzle.rowSum(y),
                    _puzzle.isRowComplete(y),
                  ),
                ],
              ),

            const SizedBox(height: 6),
            // 하단 열(Col) 합계 인디케이터 행
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (var x = 0; x < _size; x++)
                  Container(
                    width: cellSize,
                    alignment: Alignment.center,
                    child: _buildSumBadge(
                      _puzzle.colSum(x),
                      _puzzle.isColComplete(x),
                    ),
                  ),
                const SizedBox(width: 32),
              ],
            ),
          ],
        );
      },
    );
  }

  Widget _buildCell(int x, int y, double size) {
    final val = _puzzle.board[y][x];
    final isGiven = _puzzle.given[y][x];
    final isSel = _selX == x && _selY == y;

    return GestureDetector(
      onTap: () => _onCellTapped(x, y),
      child: Container(
        width: size,
        height: size,
        margin: const EdgeInsets.all(2.5),
        decoration: BoxDecoration(
          color: isSel
              ? DokkeyTheme.gold.withOpacity(0.35)
              : (isGiven ? const Color(0xFF2B2114) : const Color(0xFF3B2C19)),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSel
                ? DokkeyTheme.gold
                : (isGiven ? const Color(0xFF5D4037) : const Color(0xFF8D6E63)),
            width: isSel ? 2.2 : 1.2,
          ),
          boxShadow: isSel
              ? [
                  BoxShadow(
                    color: DokkeyTheme.gold.withOpacity(0.45),
                    blurRadius: 8,
                    spreadRadius: 1,
                  ),
                ]
              : null,
        ),
        child: Center(
          child: Text(
            val == 0 ? '' : '$val',
            style: TextStyle(
              color: isGiven
                  ? Colors.amber.shade200
                  : (isSel ? Colors.amberAccent : const Color(0xFFFFF9C4)),
              fontSize: size * 0.44,
              fontWeight: isGiven ? FontWeight.bold : FontWeight.w900,
              shadows: isGiven
                  ? [const Shadow(color: Colors.black, blurRadius: 4)]
                  : [const Shadow(color: Color(0xFFFFB300), blurRadius: 6)],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSumBadge(int sum, bool complete) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 3),
      decoration: BoxDecoration(
        color: complete ? const Color(0xFF1B5E20) : const Color(0xFF231B0F),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: complete ? Colors.greenAccent : DokkeyTheme.borderDark,
          width: 1,
        ),
        boxShadow: complete
            ? [
                BoxShadow(
                  color: Colors.greenAccent.withOpacity(0.3),
                  blurRadius: 4,
                ),
              ]
            : null,
      ),
      child: Text(
        '$sum',
        style: TextStyle(
          color: complete ? Colors.greenAccent : Colors.white60,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildToolBtn({
    required IconData icon,
    required String label,
    required VoidCallback? onTap,
    bool highlight = false,
  }) {
    return TextButton.icon(
      onPressed: onTap,
      icon: Icon(
        icon,
        size: 16,
        color: onTap == null
            ? Colors.white24
            : (highlight ? Colors.amberAccent : DokkeyTheme.goldLight),
      ),
      label: Text(
        label,
        style: TextStyle(
          color: onTap == null
              ? Colors.white24
              : (highlight ? Colors.amberAccent : DokkeyTheme.goldLight),
          fontSize: 12,
          fontWeight: highlight ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      ),
    );
  }

  Widget _buildNumberPad(int maxNum) {
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      alignment: WrapAlignment.center,
      children: List.generate(maxNum, (idx) {
        final numVal = idx + 1;
        final isUsed = _puzzle.isNumberUsed(numVal);
        final isPreSelected = _preSelectedNumber == numVal;

        return GestureDetector(
          onTap: isUsed ? null : () => _onNumberPadTapped(numVal),
          child: Opacity(
            opacity: isUsed ? 0.28 : 1.0,
            child: Container(
              width: maxNum > 16 ? 34 : 44,
              height: maxNum > 16 ? 34 : 44,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: isPreSelected
                      ? [const Color(0xFFFFB300), const Color(0xFFF57C00)]
                      : (isUsed
                          ? [const Color(0xFF2C2214), const Color(0xFF1A140B)]
                          : [const Color(0xFF6A4E1D), const Color(0xFF3E2D11)]),
                ),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isPreSelected
                      ? Colors.white
                      : (isUsed ? Colors.transparent : DokkeyTheme.gold),
                  width: isPreSelected ? 2 : 1.2,
                ),
                boxShadow: isPreSelected
                    ? [
                        BoxShadow(
                          color: Colors.amberAccent.withOpacity(0.6),
                          blurRadius: 8,
                          spreadRadius: 1,
                        ),
                      ]
                    : (isUsed
                        ? null
                        : [
                            BoxShadow(
                              color: DokkeyTheme.gold.withOpacity(0.2),
                              blurRadius: 4,
                            ),
                          ]),
              ),
              child: Center(
                child: Text(
                  '$numVal',
                  style: TextStyle(
                    color: isPreSelected
                        ? Colors.black87
                        : (isUsed ? Colors.white30 : Colors.white),
                    fontSize: maxNum > 16 ? 12 : 16,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ),
          ),
        );
      }),
    );
  }
}

// ---------------------------------------------------------------------------
// 🎨 신비로운 룬 마법진 배경 페인터
// ---------------------------------------------------------------------------

class _RuneCirclePainter extends CustomPainter {
  final double angle;

  _RuneCirclePainter({required this.angle});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height * 0.42);
    final radius = min(size.width, size.height) * 0.42;

    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(angle);

    final runePaint = Paint()
      ..color = const Color(0xFFFFD54F).withOpacity(0.04)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    // 외곽 동심원 3중 링
    canvas.drawCircle(Offset.zero, radius, runePaint);
    canvas.drawCircle(Offset.zero, radius * 0.88, runePaint);
    canvas.drawCircle(Offset.zero, radius * 0.72, runePaint);

    // 8각 룬 마법진 별
    final starPath = Path();
    final numPoints = 8;
    for (var i = 0; i < numPoints; i++) {
      final a = (i * pi / 4);
      final p1 = Offset(cos(a) * radius * 0.88, sin(a) * radius * 0.88);
      final nextA = ((i + 3) * pi / 4);
      final p2 = Offset(cos(nextA) * radius * 0.88, sin(nextA) * radius * 0.88);
      starPath.moveTo(p1.dx, p1.dy);
      starPath.lineTo(p2.dx, p2.dy);
    }
    canvas.drawPath(starPath, runePaint);

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _RuneCirclePainter oldDelegate) =>
      oldDelegate.angle != angle;
}

