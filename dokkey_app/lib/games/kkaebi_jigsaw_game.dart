import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../core/codex_service.dart';
import '../core/sound_service.dart';
import '../core/theme.dart';
import '../models/codex_models.dart';
import '../providers/dokkey_provider.dart';
import 'core/game_shell.dart';

/// 🧩 깨비 신수·신격 도감 직소 퍼즐 (Kkaebi Divine Card Jigsaw Puzzle)
/// 도감에 등록된 신비로운 십이지신 & 신화/신수 카드 및 내 사진을 조각 맞춰 완성하는 두뇌 힐링 게임.
class JigsawTile {
  final int originalIdx;
  int currentIdx;

  JigsawTile({required this.originalIdx, required this.currentIdx});
}

class JigsawPuzzleModel {
  final int gridSize; // 3 (3x3), 4 (4x4), 5 (5x5)
  final String? cardAssetPath;
  final Uint8List? customImageBytes;
  final String cardName;

  late List<JigsawTile> tiles;
  int? selectedTileIndex;
  int moves = 0;
  bool isCleared = false;
  int score = 0;

  JigsawPuzzleModel({
    this.gridSize = 3,
    this.cardAssetPath,
    this.customImageBytes,
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
  bool _finished = false;
  bool _showOriginal = false;

  String? _currentAssetPath;
  Uint8List? _currentCustomBytes;
  String _currentCardName = '깨비 (마스코트)';

  @override
  void initState() {
    super.initState();
    _currentAssetPath = widget.customCardAsset ?? 'assets/images/kkaebi_mascot.png';
    _currentCardName = widget.customCardName ?? '깨비 (마스코트)';
    _initPuzzle();
    CodexService().init();
  }

  void _initPuzzle() {
    setState(() {
      model = JigsawPuzzleModel(
        gridSize: _gridSize,
        cardAssetPath: _currentAssetPath,
        customImageBytes: _currentCustomBytes,
        cardName: _currentCardName,
      );
      _finished = false;
      _showOriginal = false;
    });
  }

  void _startWithAsset(String assetPath, String name) {
    _currentAssetPath = assetPath;
    _currentCustomBytes = null;
    _currentCardName = name;
    _initPuzzle();
  }

  void _startWithBytes(Uint8List bytes, String name) {
    _currentAssetPath = null;
    _currentCustomBytes = bytes;
    _currentCardName = name;
    _initPuzzle();
  }

  Future<void> _pickImageFromGallery(BuildContext context) async {
    final isKo = context.read<DokkeyProvider>().lang == 'ko';
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 85,
      );
      if (picked != null) {
        final bytes = await picked.readAsBytes();
        _startWithBytes(bytes, isKo ? '내 앨범 사진' : 'My Photo');
        SoundService().playSuccessChime();
        if (context.mounted) {
          Navigator.of(context).pop();
        }
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isKo ? '사진을 불러오는 중 오류가 발생했습니다.' : 'Failed to pick image.'),
            backgroundColor: DokkeyTheme.cardDark,
          ),
        );
      }
    }
  }

  void _showImagePickerSheet(BuildContext context) {
    final isKo = context.read<DokkeyProvider>().lang == 'ko';
    final codex = CodexService();

    final zodiacs = codex.zodiacCards;
    final myths = codex.mythCards;

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1F1610),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return DraggableScrollableSheet(
          initialChildSize: 0.72,
          minChildSize: 0.45,
          maxChildSize: 0.92,
          expand: false,
          builder: (_, scrollController) {
            return Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Drag Handle
                  Center(
                    child: Container(
                      width: 42,
                      height: 4.5,
                      decoration: BoxDecoration(
                        color: Colors.white24,
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Text('🖼️', style: TextStyle(fontSize: 20)),
                          const SizedBox(width: 8),
                          Text(
                            isKo ? '퍼즐 이미지 선택' : 'Choose Puzzle Image',
                            style: const TextStyle(
                              color: Color(0xFFFFD54F),
                              fontWeight: FontWeight.w900,
                              fontSize: 16.5,
                            ),
                          ),
                        ],
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded, color: Colors.white70, size: 20),
                        onPressed: () => Navigator.of(ctx).pop(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // 1. Pick from Gallery Button
                  InkWell(
                    onTap: () => _pickImageFromGallery(context),
                    borderRadius: BorderRadius.circular(14),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF8D6E63), Color(0xFF4E342E)],
                        ),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFFFFD54F).withValues(alpha: 0.8), width: 1.5),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.3),
                            blurRadius: 6,
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: const BoxDecoration(
                              color: Color(0xFFFFD54F),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.add_photo_alternate_rounded, color: Colors.black87, size: 20),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  isKo ? '📸 내 앨범에서 사진 가져오기' : '📸 Import Photo from Album',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  isKo ? '자동 512px 경량 최적화 (가볍고 빠르게 실행)' : 'Auto 512px optimized (Light & fast)',
                                  style: const TextStyle(color: Colors.white70, fontSize: 10.5),
                                ),
                              ],
                            ),
                          ),
                          const Icon(Icons.chevron_right_rounded, color: Color(0xFFFFD54F)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // 2. Official Codex Cards Grid
                  Expanded(
                    child: ListView(
                      controller: scrollController,
                      children: [
                        // Kkaebi Mascot
                        _buildSectionTitle(isKo ? '👑 대표 마스코트' : '👑 Mascot'),
                        _buildCardTile(
                          path: 'assets/images/kkaebi_mascot.png',
                          name: isKo ? '깨비 (마스코트)' : 'Kkaebi Mascot',
                          onTap: () {
                            _startWithAsset('assets/images/kkaebi_mascot.png', isKo ? '깨비 (마스코트)' : 'Kkaebi Mascot');
                            Navigator.of(ctx).pop();
                          },
                        ),
                        const SizedBox(height: 12),

                        // Zodiac (12 Cards)
                        _buildSectionTitle(isKo ? '🐉 십이지신 신수 카드 (12종)' : '🐉 Zodiac Deities (12)'),
                        _buildCardGrid(zodiacs, isKo, ctx),
                        const SizedBox(height: 12),

                        // Mythic Deities (21 Cards)
                        _buildSectionTitle(isKo ? '✨ 신화 & 신격 카드 (21종)' : '✨ Mythic Gods (21)'),
                        _buildCardGrid(myths, isKo, ctx),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Text(
        title,
        style: const TextStyle(
          color: Color(0xFFFFD54F),
          fontSize: 12.5,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildCardTile({required String path, required String name, required VoidCallback onTap}) {
    final isSelected = _currentAssetPath == path;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFFFD54F).withValues(alpha: 0.2) : Colors.black26,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? const Color(0xFFFFD54F) : Colors.white12,
            width: isSelected ? 2.0 : 1.0,
          ),
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: SizedBox(
                width: 48,
                height: 48,
                child: Image.asset(path, fit: BoxFit.cover),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                name,
                style: TextStyle(
                  color: isSelected ? const Color(0xFFFFD54F) : Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ),
            if (isSelected)
              const Icon(Icons.check_circle_rounded, color: Color(0xFFFFD54F), size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildCardGrid(List<CodexCardItem> list, bool isKo, BuildContext ctx) {
    if (list.isEmpty) {
      return Container(
        height: 60,
        alignment: Alignment.center,
        child: Text(
          isKo ? '도감 카드를 불러오는 중입니다...' : 'Loading cards...',
          style: const TextStyle(color: Colors.white54, fontSize: 11),
        ),
      );
    }
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 0.72,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: list.length,
      itemBuilder: (_, idx) {
        final card = list[idx];
        final isSelected = _currentAssetPath == card.imagePath;
        return InkWell(
          onTap: () {
            _startWithAsset(card.imagePath, card.name);
            Navigator.of(ctx).pop();
          },
          borderRadius: BorderRadius.circular(10),
          child: Container(
            decoration: BoxDecoration(
              color: isSelected ? const Color(0xFFFFD54F).withValues(alpha: 0.25) : Colors.black38,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isSelected ? const Color(0xFFFFD54F) : Colors.white12,
                width: isSelected ? 2.0 : 1.0,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(9)),
                    child: Image.asset(
                      card.imagePath,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const Center(
                        child: Icon(Icons.auto_awesome, color: Color(0xFFFFD54F), size: 24),
                      ),
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 3, horizontal: 4),
                  color: Colors.black54,
                  child: Text(
                    card.name,
                    style: TextStyle(
                      color: isSelected ? const Color(0xFFFFD54F) : Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
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
        onRetry: () => _initPuzzle(),
      );
    }
  }

  Widget _buildImageView({required BoxFit fit}) {
    if (model.customImageBytes != null) {
      return Image.memory(model.customImageBytes!, fit: fit);
    }
    return Image.asset(
      model.cardAssetPath ?? 'assets/images/kkaebi_mascot.png',
      fit: fit,
      errorBuilder: (_, __, ___) => const Center(
        child: Icon(Icons.auto_awesome, color: Color(0xFFFFD54F), size: 48),
      ),
    );
  }

  Widget _buildTileSlice(JigsawTile tile, int idx) {
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
                : (isMatch ? const Color(0xFF00E676).withValues(alpha: 0.4) : Colors.white24),
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
            child: _buildImageView(fit: BoxFit.cover),
          ),
        ),
      ),
    );
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

            // Top Control Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              child: Row(
                children: [
                  // Image Picker Trigger Button
                  InkWell(
                    onTap: () {
                      SoundService().playCardFlip();
                      _showImagePickerSheet(context);
                    },
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFD54F).withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFFFFD54F).withValues(alpha: 0.8), width: 1.2),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.photo_library_rounded, color: Color(0xFFFFD54F), size: 14),
                          const SizedBox(width: 4),
                          Text(
                            isKo ? '그림 변경' : 'Change',
                            style: const TextStyle(
                              color: Color(0xFFFFD54F),
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),

                  Expanded(
                    child: Text(
                      model.cardName,
                      style: const TextStyle(color: Colors.white, fontSize: 12.5, fontWeight: FontWeight.bold),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  ChoiceChip(
                    label: Text(isKo ? '3x3' : '3x3', style: const TextStyle(fontSize: 10.5)),
                    selected: model.gridSize == 3,
                    selectedColor: const Color(0xFFFFD54F),
                    onSelected: (_) {
                      _gridSize = 3;
                      _initPuzzle();
                    },
                  ),
                  const SizedBox(width: 4),
                  ChoiceChip(
                    label: Text(isKo ? '4x4' : '4x4', style: const TextStyle(fontSize: 10.5)),
                    selected: model.gridSize == 4,
                    selectedColor: const Color(0xFFFFD54F),
                    onSelected: (_) {
                      _gridSize = 4;
                      _initPuzzle();
                    },
                  ),
                  const SizedBox(width: 4),
                  ChoiceChip(
                    label: Text(isKo ? '5x5' : '5x5', style: const TextStyle(fontSize: 10.5)),
                    selected: model.gridSize == 5,
                    selectedColor: const Color(0xFFFFD54F),
                    onSelected: (_) {
                      _gridSize = 5;
                      _initPuzzle();
                    },
                  ),
                  const SizedBox(width: 4),
                  IconButton(
                    tooltip: isKo ? '원본 보기' : 'View Original',
                    icon: Icon(
                      _showOriginal ? Icons.visibility : Icons.visibility_outlined,
                      color: const Color(0xFFFFD54F),
                      size: 20,
                    ),
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
                  padding: const EdgeInsets.all(14),
                  child: AspectRatio(
                    aspectRatio: 3 / 4,
                    child: Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFF241910),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: const Color(0xFFFFD54F).withValues(alpha: 0.8), width: 2),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFFFD54F).withValues(alpha: 0.25),
                            blurRadius: 16,
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: _showOriginal || model.isCleared
                            ? _buildImageView(fit: BoxFit.cover)
                            : GridView.builder(
                                physics: const NeverScrollableScrollPhysics(),
                                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: model.gridSize,
                                  childAspectRatio: 3 / 4,
                                ),
                                itemCount: model.totalTiles,
                                itemBuilder: (ctx, idx) => _buildTileSlice(model.tiles[idx], idx),
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
                    ? '💡 상단 [그림 변경]으로 도감 카드나 내 사진을 골라 힐링 퍼즐을 맞춰보세요!'
                    : '💡 Tap [Change] to pick divine cards or your photo and restore the puzzle!',
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

