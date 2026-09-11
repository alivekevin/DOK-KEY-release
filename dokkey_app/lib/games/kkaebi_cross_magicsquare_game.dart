import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../core/sound_service.dart';
import '../core/theme.dart';
import '../providers/dokkey_provider.dart';
import 'core/game_shell.dart';

/// 🧮 깨비 음양 크로스 마방진 (Yin-Yang Cross Magic Square)
/// 3x3 십자(+) 및 다이아몬드 형태로 교차하는 신비로운 동양 도깨비 마법진.
/// 가로 라인, 세로 라인, 그리고 중심을 교차하는 라인의 합이 모두 목표 마법수(15)와 일치해야 합니다.
class CrossMagicSquareModel {
  static const int targetSum = 15;
  // 3x3 그리드 중 십자(Top, Left, Center, Right, Bottom) 및 코너
  late List<List<int>> grid;
  late List<List<bool>> isInitial;
  late List<List<int>> solution;

  int? selectedR;
  int? selectedC;
  int score = 0;
  bool isCleared = false;

  CrossMagicSquareModel({Random? random}) {
    final rng = random ?? Random();
    _init(rng);
  }

  void _init(Random rng) {
    // 3x3 기본 로슈 마방진 8가지 회전/반전 변형 중 하나 선택
    final base = [
      [8, 1, 6],
      [3, 5, 7],
      [4, 9, 2],
    ];

    // 무작위 회전
    final rot = rng.nextInt(4);
    var rotated = base;
    for (var i = 0; i < rot; i++) {
      rotated = [
        [rotated[2][0], rotated[1][0], rotated[0][0]],
        [rotated[2][1], rotated[1][1], rotated[0][1]],
        [rotated[2][2], rotated[1][2], rotated[0][2]],
      ];
    }
    if (rng.nextBool()) {
      // 좌우 반전
      rotated = rotated.map((row) => row.reversed.toList()).toList();
    }

    solution = rotated;
    grid = List.generate(3, (r) => List.from(solution[r]));
    isInitial = List.generate(3, (_) => List.filled(3, true));

    // 4~5개 빈칸 생성
    final holes = [
      [0, 1],
      [1, 0],
      [1, 2],
      [2, 1],
      [1, 1],
    ]..shuffle(rng);

    for (var i = 0; i < 4; i++) {
      final r = holes[i][0];
      final c = holes[i][1];
      grid[r][c] = 0;
      isInitial[r][c] = false;
    }
  }

  // 사용 가능한 숫자 목록 (1~9 중 아직 그리드에 없는 수)
  List<int> get availableNumbers {
    final used = <int>{};
    for (var r = 0; r < 3; r++) {
      for (var c = 0; c < 3; c++) {
        if (grid[r][c] > 0) used.add(grid[r][c]);
      }
    }
    return List.generate(9, (i) => i + 1).where((n) => !used.contains(n)).toList();
  }

  int rowSum(int r) => grid[r][0] + grid[r][1] + grid[r][2];
  int colSum(int c) => grid[0][c] + grid[1][c] + grid[2][c];
  int diag1Sum() => grid[0][0] + grid[1][1] + grid[2][2];
  int diag2Sum() => grid[0][2] + grid[1][1] + grid[2][0];

  bool inputNumber(int num) {
    if (selectedR == null || selectedC == null || isCleared) return false;
    final r = selectedR!;
    final c = selectedC!;
    if (isInitial[r][c]) return false;

    grid[r][c] = num;
    _checkCleared();
    return true;
  }

  void erase() {
    if (selectedR == null || selectedC == null || isCleared) return;
    final r = selectedR!;
    final c = selectedC!;
    if (!isInitial[r][c]) {
      grid[r][c] = 0;
    }
  }

  void _checkCleared() {
    for (var r = 0; r < 3; r++) {
      if (rowSum(r) != targetSum) return;
    }
    for (var c = 0; c < 3; c++) {
      if (colSum(c) != targetSum) return;
    }
    if (diag1Sum() != targetSum || diag2Sum() != targetSum) return;

    isCleared = true;
    score = 1000;
  }
}

class KkaebiCrossMagicSquareGame extends StatefulWidget {
  const KkaebiCrossMagicSquareGame({super.key});

  static const String gameId = 'cross_magic';

  @override
  State<KkaebiCrossMagicSquareGame> createState() => _KkaebiCrossMagicSquareGameState();
}

class _KkaebiCrossMagicSquareGameState extends State<KkaebiCrossMagicSquareGame> {
  late CrossMagicSquareModel model;
  bool _finished = false;

  @override
  void initState() {
    super.initState();
    _startNewGame();
  }

  void _startNewGame() {
    setState(() {
      model = CrossMagicSquareModel();
      _finished = false;
    });
  }

  void _onCellTap(int r, int c) {
    HapticFeedback.selectionClick();
    setState(() {
      model.selectedR = r;
      model.selectedC = c;
    });
  }

  void _onNumTap(int num) {
    final ok = model.inputNumber(num);
    if (ok) {
      SoundService().playCoinJangle();
      HapticFeedback.lightImpact();
    }
    setState(() {});

    if (!_finished && model.isCleared) {
      _finished = true;
      finishGame(
        context,
        gameId: KkaebiCrossMagicSquareGame.gameId,
        title: '음양 크로스 마방진 완성!',
        score: model.score,
        cleared: true,
        onRetry: _startNewGame,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isKo = context.watch<DokkeyProvider>().lang == 'ko';

    return Scaffold(
      backgroundColor: const Color(0xFF140D24),
      body: SafeArea(
        child: Column(
          children: [
            GameHud(
              title: isKo ? '음양 크로스 마방진' : 'Cross Magic Square',
              score: model.score,
              rightLabel: '목표합 15',
              onQuit: () => Navigator.of(context).pop(),
              accent: const Color(0xFFE040FB),
            ),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFF7C4DFF).withOpacity(0.18),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFB388FF).withOpacity(0.6)),
                ),
                child: Row(
                  children: [
                    const Text('☯️', style: TextStyle(fontSize: 16)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        isKo
                            ? '가로·세로·대각선 모든 라인의 합을 15로 완성하세요!'
                            : 'Make all rows, cols & diagonals sum to 15!',
                        style: const TextStyle(color: Color(0xFFE1BEE7), fontSize: 11.5, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Grid with Sum Indicators
            Expanded(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: AspectRatio(
                    aspectRatio: 1.0,
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF221538),
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(color: const Color(0xFFAB47BC), width: 2),
                        boxShadow: [
                          BoxShadow(color: const Color(0xFF7C4DFF).withOpacity(0.3), blurRadius: 16),
                        ],
                      ),
                      child: Column(
                        children: [
                          for (var r = 0; r < 3; r++)
                            Expanded(
                              child: Row(
                                children: [
                                  for (var c = 0; c < 3; c++)
                                    Expanded(
                                      child: Padding(
                                        padding: const EdgeInsets.all(4),
                                        child: _buildCell(r, c),
                                      ),
                                    ),
                                  // Row sum badge
                                  _buildSumBadge(model.rowSum(r)),
                                ],
                              ),
                            ),
                          // Bottom Col Sum Badges
                          Row(
                            children: [
                              for (var c = 0; c < 3; c++)
                                Expanded(
                                  child: Center(
                                    child: _buildSumBadge(model.colSum(c)),
                                  ),
                                ),
                              const SizedBox(width: 32),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // Number Selection Tray
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: const BoxDecoration(
                color: Color(0xFF0F081C),
                border: Border(top: BorderSide(color: Color(0xFF311B92))),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      for (var n = 1; n <= 9; n++)
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 2),
                            child: ElevatedButton(
                              onPressed: () => _onNumTap(n),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF311B92),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 10),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                side: const BorderSide(color: Color(0xFFAB47BC)),
                              ),
                              child: Text('', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton.icon(
                        onPressed: () {
                          HapticFeedback.selectionClick();
                          setState(() => model.erase());
                        },
                        icon: const Icon(Icons.backspace_outlined, size: 16, color: Colors.white70),
                        label: Text(isKo ? '지우기' : 'Erase', style: const TextStyle(color: Colors.white70)),
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

  Widget _buildCell(int r, int c) {
    final val = model.grid[r][c];
    final isInit = model.isInitial[r][c];
    final isSel = model.selectedR == r && model.selectedC == c;
    final isCenter = r == 1 && c == 1;

    return GestureDetector(
      onTap: () => _onCellTap(r, c),
      child: Container(
        decoration: BoxDecoration(
          color: isSel
              ? const Color(0xFFAB47BC).withOpacity(0.5)
              : (isCenter ? const Color(0xFF3E2764) : const Color(0xFF2C1C47)),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSel
                ? const Color(0xFFFFD54F)
                : (isCenter ? const Color(0xFFE040FB) : const Color(0xFF7C4DFF).withOpacity(0.5)),
            width: isSel ? 2.5 : 1.5,
          ),
        ),
        child: Center(
          child: Text(
            val > 0 ? '' : '',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w900,
              color: isInit ? Colors.white70 : const Color(0xFFFFD54F),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSumBadge(int sum) {
    final isMatch = sum == CrossMagicSquareModel.targetSum;
    return Container(
      width: 32,
      height: 24,
      margin: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
      decoration: BoxDecoration(
        color: isMatch ? const Color(0xFF00E676).withOpacity(0.25) : Colors.black45,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: isMatch ? const Color(0xFF00E676) : Colors.white24),
      ),
      child: Center(
        child: Text(
          '',
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.bold,
            color: isMatch ? const Color(0xFF00E676) : Colors.white60,
          ),
        ),
      ),
    );
  }
}
