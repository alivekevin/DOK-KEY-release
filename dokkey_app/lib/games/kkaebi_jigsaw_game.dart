import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../core/sound_service.dart';
import '../core/theme.dart';
import '../providers/dokkey_provider.dart';
import 'core/game_shell.dart';

/// 🧩 깨비 신수·신격 도감 직소 퍼즐 (Kkaebi Divine Card Jigsaw Puzzle)
/// 도감에 등록된 신비로운 십이지신 & 신화/신수 카드의 조각을 맞춰 완성하는 두뇌 힐링 게임.
class JigsawTile {
  final int originalIdx;
  int currentIdx;

  JigsawTile({required this.originalIdx, required this.currentIdx});
}

class JigsawPuzzleModel {
  final int gridSize; // 3 (3x3) or 4 (4x4)
  final String cardAssetPath;
  final String cardName;

  late List<JigsawTile> tiles;
  int? selectedTileIndex;
  int moves = 0;
  bool isCleared = false;
  int score = 0;

  JigsawPuzzleModel({
    this.gridSize = 3,
    required this.cardAssetPath,
    required this.cardName,
    Random? random,
  }) {
    final rng = random ?? Random();
    _init(rng);
  }

  int get totalTiles => gridSize * gridSize;

  void _init(Random rng) {
    tiles = List.generate(totalTiles, (i) => JigsawTile(originalIdx: i, currentIdx: i));
    
    // 무작위 셔플 (완성 상태 방지)
    var shuffleCount = 0;
    while (shuffleCount < 5 || _isAllMatched()) {
      tiles.shuffle(rng);
      for (var i = 0; i < totalTiles; i++) {
        tiles[i].currentIdx = i;
      }
      shuffleCount++;
    }
  }

  bool _isAllMatched() {
    for (var i = 0; i < totalTiles; i++) {
      if (tiles[i].originalIdx != i) return false;
    }
    return true;
  }

  bool swapWithSelected(int targetIdx) {
    if (isCleared) return false;
    if (selectedTileIndex == null) {
      selectedTileIndex = targetIdx;
      return false;
    }

    final first = selectedTileIndex!;
    if (first == targetIdx) {
      selectedTileIndex = null;
      return false;
    }

    // 두 타일 스왑
    final temp = tiles[first];
    tiles[first] = tiles[targetIdx];
    tiles[targetIdx] = temp;

    tiles[first].currentIdx = first;
    tiles[targetIdx].currentIdx = targetIdx;

    selectedTileIndex = null;
    moves++;

    if (_isAllMatched()) {
      isCleared = true;
      score = max(300, 1200 - moves * 20);
    }
    return true;
  }
}

class KkaebiJigsawGame extends StatefulWidget {
  final String? customCardAsset;
  final String? customCardName;

  const KkaebiJigsawGame({
    super.key,
    this.customCardAsset,
    this.customCardName,
  });

  static const String gameId = 'jigsaw';

  @override
  State<KkaebiJigsawGame> createState() => _KkaebiJigsawGameState();
}

class _KkaebiJigsawGameState extends State<KkaebiJigsawGame> {
  late JigsawPuzzleModel model;
  int _gridSize = 3; // 3(하) / 4(중) / 5(상)
  int? initCardIndex;
  bool _finished = false;
  bool _showOriginal = false;

  final List<Map<String, String>> _defaultCards = const [
    {'path': 'assets/images/kkaebi_mascot.png', 'name': '깨비 (도깨비 키 마스코트)'},
    {'path': 'assets/cards/myth/01_samjoko.webp', 'name': '삼족오 (태양의 신조)'},
    {'path': 'assets/cards/myth/02_haetae.webp', 'name': '해태 (정의의 신수)'},
    {'path': 'assets/cards/myth/03_cheongryong.webp', 'name': '청룡 (동방의 수호자)'},
    {'path': 'assets/cards/zodiac/01_rat.webp', 'name': '자(子) - 번영의 쥐'},
    {'path': 'assets/cards/zodiac/05_dragon.webp', 'name': '진(辰) - 승천하는 용'},
    {'path': 'assets/cards/zodiac/12_pig.webp', 'name': '해(亥) - 풍요의 돼지'},
  ];

  @override
  void initState() {
    super.initState();
    _startNewPuzzle(_gridSize);
  }

  void _startNewPuzzle(int size) {
    _gridSize = size;
    final card = widget.customCardAsset != null
        ? {'path': widget.customCardAsset!, 'name': widget.customCardName ?? '비밀 신수 카드'}
        : (initCardIndex != null ? _defaultCards[initCardIndex! % _defaultCards.length] : _defaultCards[0]);

    setState(() {
      model = JigsawPuzzleModel(
        gridSize: size,
        cardAssetPath: card['path']!,
        cardName: card['name']!,
      );
      _finished = false;
      _showOriginal = false;
    });
  }

  void _onTileTap(int idx) {
    HapticFeedback.selectionClick();
    final wasCleared = model.isCleared;
    final swapped = model.swapWithSelected(idx);

    if (swapped) {
      SoundService().playCoinJangle();
    }
    setState(() {});

    if (!wasCleared && model.isCleared && !_finished) {
      _finished = true;
      SoundService().playSuccessChime();
      finishGame(
        context,
        gameId: KkaebiJigsawGame.gameId,
        title: '${model.cardName} 퍼즐 완성!',
        score: model.score,
        cleared: true,
        onRetry: () => _startNewPuzzle(_gridSize),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isKo = context.watch<DokkeyProvider>().lang == 'ko';

    return Scaffold(
      backgroundColor: const Color(0xFF140F0A),
      body: SafeArea(
        child: Column(
          children: [
            GameHud(
              title: isKo ? '깨비 신수 도감 퍼즐' : 'Kkaebi Deity Puzzle',
              score: model.score,
              rightLabel: '${model.moves} 이동',
              onQuit: () => Navigator.of(context).pop(),
              accent: const Color(0xFFFFD54F),
            ),

            // Top Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      '🖼️ ${model.cardName}',
                      style: const TextStyle(color: Color(0xFFFFD54F), fontSize: 13, fontWeight: FontWeight.bold),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  ChoiceChip(
                    label: Text(isKo ? '하 3x3' : '3x3', style: const TextStyle(fontSize: 11)),
                    selected: model.gridSize == 3,
                    selectedColor: const Color(0xFFFFD54F),
                    onSelected: (_) => _startNewPuzzle(3),
                  ),
                  const SizedBox(width: 6),
                  ChoiceChip(
                    label: Text(isKo ? '중 4x4' : '4x4', style: const TextStyle(fontSize: 11)),
                    selected: model.gridSize == 4,
                    selectedColor: const Color(0xFFFFD54F),
                    onSelected: (_) => _startNewPuzzle(4),
                  ),
                  const SizedBox(width: 6),
                  ChoiceChip(
                    label: Text(isKo ? '상 5x5' : '5x5', style: const TextStyle(fontSize: 11)),
                    selected: model.gridSize == 5,
                    selectedColor: const Color(0xFFFFD54F),
                    onSelected: (_) => _startNewPuzzle(5),
                  ),
                  const SizedBox(width: 6),
                  IconButton(
                    tooltip: isKo ? '원본 보기' : 'View Original',
                    icon: Icon(_showOriginal ? Icons.visibility : Icons.visibility_outlined, color: const Color(0xFFFFD54F)),
                    onPressed: () {
                      setState(() => _showOriginal = !_showOriginal);
                    },
                  ),
                ],
              ),
            ),

            // Puzzle Grid or Full Preview
            Expanded(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: AspectRatio(
                    aspectRatio: 3 / 4,
                    child: Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFF241910),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: const Color(0xFFFFD54F).withOpacity(0.8), width: 2),
                        boxShadow: [
                          BoxShadow(color: const Color(0xFFFFD54F).withOpacity(0.25), blurRadius: 16),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: _showOriginal || model.isCleared
                            ? Image.asset(
                                model.cardAssetPath,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => const Center(
                                  child: Icon(Icons.auto_awesome, color: Color(0xFFFFD54F), size: 48),
                                ),
                              )
                            : GridView.builder(
                                physics: const NeverScrollableScrollPhysics(),
                                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: model.gridSize,
                                  childAspectRatio: 3 / 4,
                                ),
                                itemCount: model.totalTiles,
                                itemBuilder: (ctx, idx) {
                                  final tile = model.tiles[idx];
                                  final isSelected = model.selectedTileIndex == idx;
                                  final isMatch = tile.originalIdx == idx;

                                  final origR = tile.originalIdx ~/ model.gridSize;
                                  final origC = tile.originalIdx % model.gridSize;

                                  return GestureDetector(
                                    onTap: () => _onTileTap(idx),
                                    child: Container(
                                      margin: const EdgeInsets.all(1.5),
                                      decoration: BoxDecoration(
                                        border: Border.all(
                                          color: isSelected
                                              ? Colors.amberAccent
                                              : (isMatch ? const Color(0xFF00E676).withOpacity(0.4) : Colors.white24),
                                          width: isSelected ? 2.5 : 1.0,
                                        ),
                                      ),
                                      child: ClipRect(
                                        child: FractionallySizedBox(
                                          widthFactor: model.gridSize.toDouble(),
                                          heightFactor: model.gridSize.toDouble(),
                                          alignment: FractionalOffset(
                                            origC / (model.gridSize - 1),
                                            origR / (model.gridSize - 1),
                                          ),
                                          child: Image.asset(
                                            model.cardAssetPath,
                                            fit: BoxFit.cover,
                                            errorBuilder: (_, __, ___) => Center(
                                              child: Text('${tile.originalIdx + 1}',
                                                  style: const TextStyle(color: Colors.white70)),
                                            ),
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

            // Footer Guide
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 14),
              child: Text(
                isKo
                    ? '💡 두 조각을 차례로 터치하여 위치를 바꾸고 신수/신격 카드를 완성하세요!'
                    : '💡 Tap two tiles in turn to swap and restore the divine card!',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white70, fontSize: 11.5),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
