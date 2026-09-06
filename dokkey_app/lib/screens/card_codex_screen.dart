import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/theme.dart';
import '../core/sound_service.dart';
import '../core/codex_service.dart';
import '../models/codex_models.dart';
import '../providers/dokkey_provider.dart';
import '../widgets/dokkaebi_fire_particles.dart';
import '../widgets/rotating_key_home_button.dart';
import 'keybox_screen.dart';

class CardCodexScreen extends StatefulWidget {
  const CardCodexScreen({super.key});

  @override
  State<CardCodexScreen> createState() => _CardCodexScreenState();
}

class _CardCodexScreenState extends State<CardCodexScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _codexService = CodexService();
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadData();
  }

  Future<void> _loadData() async {
    await _codexService.init();
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _showCardDetail(BuildContext context, CodexCardItem card, bool isUnlocked) {
    final provider = context.read<DokkeyProvider>();
    final isKo = provider.lang == 'ko';
    final isJa = provider.lang == 'ja';
    final cardName = card.localizedName(provider.lang);

    SoundService().playCardFlip();

    showDialog(
      context: context,
      builder: (ctx) => _CodexDetailDialog(
        card: card,
        cardName: cardName,
        isUnlocked: isUnlocked,
        isKo: isKo,
        isJa: isJa,
      ),
    );
  }

  void _showCustomCardDialog(BuildContext context, CustomCodexCard customCard) {
    final titleCtrl = TextEditingController(text: customCard.title ?? '');
    final memoCtrl = TextEditingController(text: customCard.memo ?? '');
    String? currentImageBase64 = customCard.imageBase64;
    String? currentLocalUri = customCard.localImageUri;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: DokkeyTheme.cardDark,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
            side: BorderSide(color: DokkeyTheme.gold.withOpacity(0.6), width: 1.5),
          ),
          title: Row(
            children: [
              Icon(Icons.photo_library_rounded, color: DokkeyTheme.gold),
              const SizedBox(width: 8),
              Text(
                'MY 커스텀 슬롯 #${customCard.slotIndex + 1}',
                style: TextStyle(color: DokkeyTheme.goldLight, fontSize: 17, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '스마트폰 앨범에서 사진을 선택하면 400×600 카드 규격으로 자동 최적화됩니다 (기기 로컬 안전 보관)',
                  style: TextStyle(color: DokkeyTheme.textMuted, fontSize: 11.5),
                ),
                const SizedBox(height: 14),

                // 400x600 카드 미리보기 & 사진 선택 버튼
                GestureDetector(
                  onTap: () async {
                    final croppedBase64 = await _codexService.pickAndCropCardImage();
                    if (croppedBase64 != null) {
                      setDialogState(() {
                        currentImageBase64 = croppedBase64;
                      });
                    }
                  },
                  child: Container(
                    width: 150,
                    height: 225, // 2:3 비율 (150x225)
                    decoration: BoxDecoration(
                      color: DokkeyTheme.surfaceDark,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: currentImageBase64 != null ? DokkeyTheme.gold : DokkeyTheme.borderDark,
                        width: 2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: (currentImageBase64 != null ? DokkeyTheme.gold : Colors.black).withOpacity(0.3),
                          blurRadius: 10,
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          if (currentImageBase64 != null)
                            Image.memory(
                              base64Decode(currentImageBase64!),
                              fit: BoxFit.cover,
                            )
                          else if (currentLocalUri != null && currentLocalUri.isNotEmpty)
                            Image.asset(
                              currentLocalUri!,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => _buildSelectPhotoPlaceholder(),
                            )
                          else
                            _buildSelectPhotoPlaceholder(),

                          Positioned(
                            bottom: 0,
                            left: 0,
                            right: 0,
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 4),
                              color: Colors.black.withOpacity(0.75),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.camera_alt_rounded, size: 12, color: DokkeyTheme.goldLight),
                                  const SizedBox(width: 4),
                                  Text(
                                    currentImageBase64 != null ? '사진 변경' : '사진 선택',
                                    style: TextStyle(color: DokkeyTheme.goldLight, fontSize: 10.5, fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // 사진 선택 전용 버튼
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: DokkeyTheme.surfaceDark,
                    foregroundColor: DokkeyTheme.goldLight,
                    side: BorderSide(color: DokkeyTheme.gold.withOpacity(0.5)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  ),
                  icon: const Icon(Icons.add_photo_alternate_rounded, size: 18),
                  label: const Text('📷 앨범에서 사진 선택 (400×600 자동 크롭)', style: TextStyle(fontSize: 12)),
                  onPressed: () async {
                    final croppedBase64 = await _codexService.pickAndCropCardImage();
                    if (croppedBase64 != null) {
                      setDialogState(() {
                        currentImageBase64 = croppedBase64;
                      });
                    }
                  },
                ),

                const SizedBox(height: 14),

                TextField(
                  controller: titleCtrl,
                  style: TextStyle(color: DokkeyTheme.textMain),
                  decoration: InputDecoration(
                    labelText: '카드 이름 / 소원 제목',
                    hintText: '예: 우리집 복덩이 초코 🐶',
                    hintStyle: TextStyle(color: DokkeyTheme.textMuted.withOpacity(0.5), fontSize: 12),
                    labelStyle: TextStyle(color: DokkeyTheme.gold),
                    filled: true,
                    fillColor: DokkeyTheme.surfaceDark,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: memoCtrl,
                  maxLines: 2,
                  style: TextStyle(color: DokkeyTheme.textMain),
                  decoration: InputDecoration(
                    labelText: '나만의 한마디 / 소원 다짐',
                    hintText: '예: 매일매일 웃으며 살기!',
                    hintStyle: TextStyle(color: DokkeyTheme.textMuted.withOpacity(0.5), fontSize: 12),
                    labelStyle: TextStyle(color: DokkeyTheme.gold),
                    filled: true,
                    fillColor: DokkeyTheme.surfaceDark,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            if (!customCard.isEmpty)
              TextButton(
                onPressed: () async {
                  await _codexService.deleteCustomCard(customCard.slotIndex);
                  if (mounted) setState(() {});
                  Navigator.of(ctx).pop();
                },
                child: const Text('삭제 (비우기)', style: TextStyle(color: Colors.redAccent)),
              ),
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: Text('취소', style: TextStyle(color: DokkeyTheme.textMuted)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: DokkeyTheme.gold,
                foregroundColor: DokkeyTheme.bgDark,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () async {
                final title = titleCtrl.text.trim().isEmpty ? 'MY 소원 카드 #${customCard.slotIndex + 1}' : titleCtrl.text.trim();
                await _codexService.saveCustomCard(
                  customCard.slotIndex,
                  imageBase64: currentImageBase64,
                  localUri: currentImageBase64 == null ? (currentLocalUri ?? 'assets/images/kkaebi_mascot.png') : null,
                  title: title,
                  memo: memoCtrl.text.trim(),
                );
                if (mounted) setState(() {});
                Navigator.of(ctx).pop();
              },
              child: const Text('🪄 저장 뚝딱!'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSelectPhotoPlaceholder() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.add_photo_alternate_rounded, size: 38, color: DokkeyTheme.gold.withOpacity(0.7)),
        const SizedBox(height: 6),
        Text('사진 선택', style: TextStyle(color: DokkeyTheme.goldLight, fontSize: 12, fontWeight: FontWeight.bold)),
        Text('400×600 크롭', style: TextStyle(color: DokkeyTheme.textMuted, fontSize: 10)),
      ],
    );
  }

  void _showCustomCardDetail(BuildContext context, CustomCodexCard customCard) {
    SoundService().playCardFlip();
    showDialog(
      context: context,
      builder: (ctx) => _CustomCardDetailDialog(
        card: customCard,
        onEdit: () {
          Navigator.of(ctx).pop();
          _showCustomCardDialog(context, customCard);
        },
        onDelete: () async {
          await _codexService.deleteCustomCard(customCard.slotIndex);
          if (mounted) setState(() {});
          Navigator.of(ctx).pop();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<DokkeyProvider>();
    final isKo = provider.lang == 'ko';
    final isJa = provider.lang == 'ja';

    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: Text(isKo ? '99 그랜드 도감' : (isJa ? '99 グランド図鑑' : '99 Grand Codex'))),
        body: Center(child: CircularProgressIndicator(color: DokkeyTheme.gold)),
      );
    }

    final zodiacList = _codexService.zodiacCards.where((c) => c.isRegular).toList();
    final mythList = _codexService.mythCards.where((c) => c.isRegular).toList();
    final customList = _codexService.customCards;

    final zodiacUnlockedCount = _codexService.getUnlockedCount('zodiac');
    final mythUnlockedCount = _codexService.getUnlockedCount('myth');
    final customFilledCount = customList.where((c) => !c.isEmpty).length;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          children: [
            Text(isKo ? '99 그랜드 도감' : (isJa ? '99 グランド図鑑' : '99 Grand Codex')),
            Text(
              'DOK-KEY : TTOOK-TTAK!',
              style: TextStyle(color: DokkeyTheme.gold, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.2),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.vpn_key_outlined, color: DokkeyTheme.gold),
            tooltip: isKo ? '황금열쇠 보관함' : (isJa ? '鍵保管箱' : 'Keybox Vault'),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const KeyBoxScreen()),
              );
            },
          ),
          const RotatingKeyHomeButton(),
          const SizedBox(width: 6),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: DokkeyTheme.gold,
          labelColor: DokkeyTheme.gold,
          unselectedLabelColor: DokkeyTheme.textMuted,
          tabs: [
            Tab(text: isKo ? '신수 ($zodiacUnlockedCount/33)' : (isJa ? '神獣 ($zodiacUnlockedCount/33)' : 'Beasts ($zodiacUnlockedCount/33)')),
            Tab(text: isKo ? '신격 ($mythUnlockedCount/33)' : (isJa ? '神格 ($mythUnlockedCount/33)' : 'Gods ($mythUnlockedCount/33)')),
            Tab(text: isKo ? 'MY 커스텀 ($customFilledCount/33)' : (isJa ? 'MY カスタム' : 'MY Custom ($customFilledCount/33)')),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildCardGrid(context, zodiacList, 'zodiac'),
          _buildCardGrid(context, mythList, 'myth'),
          _buildCustomGrid(context, customList),
        ],
      ),
    );
  }

  Widget _buildCardGrid(
    BuildContext context,
    List<CodexCardItem> cards,
    String tabKey,
  ) {
    final provider = context.watch<DokkeyProvider>();
    final lang = provider.lang;

    return GridView.builder(
      padding: const EdgeInsets.all(14),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 0.68,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
      ),
      itemCount: cards.length,
      itemBuilder: (ctx, idx) {
        final card = cards[idx];
        final isUnlocked = _codexService.isCardUnlocked(tabKey, card.slot);
        final cardName = card.localizedName(lang);

        return GestureDetector(
          onTap: () => _showCardDetail(context, card, isUnlocked),
          child: Container(
            decoration: BoxDecoration(
              color: DokkeyTheme.cardDark,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isUnlocked ? DokkeyTheme.gold : DokkeyTheme.borderDark,
                width: isUnlocked ? 1.5 : 1.0,
              ),
              boxShadow: isUnlocked
                  ? [
                      BoxShadow(
                        color: DokkeyTheme.gold.withOpacity(0.25),
                        blurRadius: 8,
                        spreadRadius: 1,
                      ),
                    ]
                  : null,
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(15),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // 고화질 도감 일러스트 (WebP) — 미해금 시 실루엣/흑백 처리
                  ColorFiltered(
                    colorFilter: isUnlocked
                        ? const ColorFilter.mode(Colors.transparent, BlendMode.multiply)
                        : const ColorFilter.matrix(<double>[
                            0.2126, 0.7152, 0.0722, 0, 0,
                            0.2126, 0.7152, 0.0722, 0, 0,
                            0.2126, 0.7152, 0.0722, 0, 0,
                            0, 0, 0, 0.35, 0,
                          ]),
                    child: Image.asset(
                      card.imagePath,
                      fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) => Image.asset(
                        'assets/images/kkaebi_mascot.png',
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),

                  // 미해금 시 반투명 신비로운 오버레이 & 황금 자물쇠 표시
                  if (!isUnlocked)
                    Container(
                      color: Colors.black.withOpacity(0.65),
                      child: Center(
                        child: Container(
                          padding: const EdgeInsets.all(7),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.75),
                            shape: BoxShape.circle,
                            border: Border.all(color: DokkeyTheme.gold.withOpacity(0.6), width: 1.2),
                          ),
                          child: Icon(Icons.lock_rounded, size: 20, color: DokkeyTheme.gold),
                        ),
                      ),
                    ),

                  Positioned(
                    top: 6,
                    left: 6,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.7),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: isUnlocked ? DokkeyTheme.gold.withOpacity(0.6) : Colors.white24,
                          width: 0.8,
                        ),
                      ),
                      child: Text(
                        card.id,
                        style: TextStyle(
                          color: isUnlocked ? DokkeyTheme.goldLight : DokkeyTheme.textMuted,
                          fontSize: 9.5,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),

                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
                      color: Colors.black.withOpacity(0.75),
                      child: Text(
                        cardName,
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: isUnlocked ? DokkeyTheme.goldLight : Colors.white70,
                          fontSize: 10.5,
                          fontWeight: isUnlocked ? FontWeight.bold : FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildCustomGrid(BuildContext context, List<CustomCodexCard> customCards) {
    return GridView.builder(
      padding: const EdgeInsets.all(14),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 0.68,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
      ),
      itemCount: customCards.length,
      itemBuilder: (ctx, idx) {
        final card = customCards[idx];
        final isEmpty = card.isEmpty;

        return GestureDetector(
          onTap: () {
            if (isEmpty) {
              _showCustomCardDialog(context, card);
            } else {
              _showCustomCardDetail(context, card);
            }
          },
          child: Container(
            decoration: BoxDecoration(
              color: DokkeyTheme.cardDark,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: !isEmpty ? DokkeyTheme.gold : DokkeyTheme.borderDark,
                width: !isEmpty ? 1.5 : 1.0,
              ),
              boxShadow: !isEmpty
                  ? [BoxShadow(color: DokkeyTheme.gold.withOpacity(0.25), blurRadius: 8)]
                  : null,
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(15),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (!isEmpty)
                    if (card.imageBase64 != null)
                      Image.memory(
                        base64Decode(card.imageBase64!),
                        fit: BoxFit.cover,
                      )
                    else
                      Image.asset(
                        card.localImageUri ?? 'assets/images/kkaebi_mascot.png',
                        fit: BoxFit.contain,
                        errorBuilder: (_, __, ___) => Image.asset('assets/images/kkaebi_mascot.png', fit: BoxFit.contain),
                      )
                  else
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.add_photo_alternate_rounded, size: 28, color: DokkeyTheme.gold.withOpacity(0.6)),
                        const SizedBox(height: 6),
                        Text(
                          '#${idx + 1} 등록',
                          style: TextStyle(color: DokkeyTheme.textMuted, fontSize: 11),
                        ),
                      ],
                    ),

                  if (!isEmpty)
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
                        color: Colors.black.withOpacity(0.75),
                        child: Text(
                          card.title ?? '나만의 카드',
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(color: DokkeyTheme.goldLight, fontSize: 10.5, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

/// 3D Flip Card Detail Dialog for Standard Codex
class _CodexDetailDialog extends StatefulWidget {
  final CodexCardItem card;
  final String cardName;
  final bool isUnlocked;
  final bool isKo;
  final bool isJa;

  const _CodexDetailDialog({
    required this.card,
    required this.cardName,
    required this.isUnlocked,
    required this.isKo,
    required this.isJa,
  });

  @override
  State<_CodexDetailDialog> createState() => _CodexDetailDialogState();
}

class _CodexDetailDialogState extends State<_CodexDetailDialog>
    with SingleTickerProviderStateMixin {
  late AnimationController _flipCtrl;
  late Animation<double> _flipAnim;
  bool _isBack = false;

  @override
  void initState() {
    super.initState();
    _flipCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _flipAnim = Tween<double>(begin: 0.0, end: 3.141592).animate(
      CurvedAnimation(parent: _flipCtrl, curve: Curves.easeInOutBack),
    );
  }

  @override
  void dispose() {
    _flipCtrl.dispose();
    super.dispose();
  }

  void _flip() {
    if (_isBack) {
      _flipCtrl.reverse();
      setState(() => _isBack = false);
    } else {
      _flipCtrl.forward();
      setState(() => _isBack = true);
    }
    SoundService().playCardFlip();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 380),
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          color: DokkeyTheme.cardDark,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(
            color: widget.isUnlocked ? DokkeyTheme.gold : DokkeyTheme.borderDark,
            width: 1.8,
          ),
          boxShadow: [
            BoxShadow(
              color: (widget.isUnlocked ? DokkeyTheme.gold : Colors.black).withOpacity(0.3),
              blurRadius: 30,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            GestureDetector(
              onTap: _flip,
              child: AnimatedBuilder(
                animation: _flipAnim,
                builder: (ctx, child) {
                  final angle = _flipAnim.value;
                  final isUnder = angle > 1.570796;

                  return Transform(
                    transform: Matrix4.identity()
                      ..setEntry(3, 2, 0.0015)
                      ..rotateY(angle),
                    alignment: Alignment.center,
                    child: isUnder
                        ? Transform(
                            transform: Matrix4.identity()..rotateY(3.141592),
                            alignment: Alignment.center,
                            child: _buildCardBack(),
                          )
                        : _buildCardFront(),
                  );
                },
              ),
            ),

            const SizedBox(height: 18),
            Text(
              '💡 카드를 탭하면 앞/뒤 3D로 뒤집어집니다!',
              style: TextStyle(color: DokkeyTheme.textMuted, fontSize: 11.5),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: DokkeyTheme.gold,
                foregroundColor: DokkeyTheme.bgDark,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 10),
              ),
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('닫기', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCardFront() {
    return Container(
      width: 220,
      height: 330,
      decoration: BoxDecoration(
        color: DokkeyTheme.surfaceDark,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: widget.isUnlocked ? DokkeyTheme.gold : DokkeyTheme.borderDark, width: 2),
        boxShadow: [
          BoxShadow(
            color: widget.isUnlocked ? DokkeyTheme.gold.withOpacity(0.3) : Colors.black45,
            blurRadius: 16,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Stack(
          fit: StackFit.expand,
          children: [
            ColorFiltered(
              colorFilter: widget.isUnlocked
                  ? const ColorFilter.mode(Colors.transparent, BlendMode.multiply)
                  : const ColorFilter.matrix(<double>[
                      0.2126, 0.7152, 0.0722, 0, 0,
                      0.2126, 0.7152, 0.0722, 0, 0,
                      0.2126, 0.7152, 0.0722, 0, 0,
                      0, 0, 0, 0.35, 0,
                    ]),
              child: DokkaebiFireParticles(
                child: Image.asset(
                  widget.card.imagePath,
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => Image.asset(
                    'assets/images/kkaebi_mascot.png',
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ),

            if (!widget.isUnlocked)
              Container(
                color: Colors.black.withOpacity(0.6),
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.8),
                      shape: BoxShape.circle,
                      border: Border.all(color: DokkeyTheme.gold.withOpacity(0.8), width: 1.5),
                    ),
                    child: Icon(Icons.lock_rounded, size: 28, color: DokkeyTheme.gold),
                  ),
                ),
              ),

            Positioned(
              top: 10,
              left: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.7),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: widget.isUnlocked ? DokkeyTheme.gold.withOpacity(0.5) : Colors.white24),
                ),
                child: Text(
                  widget.card.id,
                  style: TextStyle(
                    color: widget.isUnlocked ? DokkeyTheme.goldLight : DokkeyTheme.textMuted,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),

            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
                color: Colors.black.withOpacity(0.8),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      widget.cardName,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: widget.isUnlocked ? DokkeyTheme.goldLight : Colors.white70,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      widget.isUnlocked
                          ? widget.card.title
                          : (widget.isKo ? '🔒 미수집 카드' : (widget.isJa ? '🔒 未収集カード' : '🔒 Locked Card')),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: widget.isUnlocked ? DokkeyTheme.textMuted : DokkeyTheme.gold.withOpacity(0.8),
                        fontSize: 10.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCardBack() {
    return Container(
      width: 220,
      height: 330,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: DokkeyTheme.surfaceDark,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: widget.isUnlocked ? DokkeyTheme.gold : DokkeyTheme.borderDark,
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: (widget.isUnlocked ? DokkeyTheme.gold : Colors.black).withOpacity(0.35),
            blurRadius: 18,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Opacity(
              opacity: widget.isUnlocked ? 0.15 : 0.05,
              child: Image.asset(widget.card.imagePath, fit: BoxFit.cover),
            ),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 58,
                  height: 58,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: widget.isUnlocked ? DokkeyTheme.gold : DokkeyTheme.borderDark,
                      width: 1.5,
                    ),
                    color: DokkeyTheme.cardDark,
                  ),
                  child: ClipOval(
                    child: widget.isUnlocked
                        ? Image.asset('assets/images/kkaebi_mascot.png', fit: BoxFit.contain)
                        : Icon(Icons.lock_clock_rounded, size: 28, color: DokkeyTheme.gold),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  widget.cardName,
                  style: TextStyle(
                    color: widget.isUnlocked ? DokkeyTheme.gold : Colors.white70,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
                Text(
                  widget.isUnlocked
                      ? widget.card.title
                      : (widget.isKo ? '열쇠 번호를 모아 해금' : (widget.isJa ? '鍵番号を集めて解除' : 'Collect Key to Unlock')),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: widget.isUnlocked ? DokkeyTheme.goldLight.withOpacity(0.8) : DokkeyTheme.textMuted,
                    fontSize: 11,
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: DokkeyTheme.cardDark.withOpacity(0.85),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: widget.isUnlocked ? DokkeyTheme.gold.withOpacity(0.3) : Colors.white12,
                    ),
                  ),
                  child: Text(
                    widget.isUnlocked
                        ? widget.card.desc
                        : (widget.isKo
                            ? '🔒 아직 수집되지 않은 비밀 도감 카드입니다.\n행운의 번호 뽑기, 수수께끼 퀴즈, 깨비 대화로 숫자를 모으면 도감이 해금됩니다깨비!'
                            : (widget.isJa
                                ? '🔒 まだ収集されていない秘密の図鑑カードです。\n運勢の数字引き、クイズ、対話で数字を集めると解除されますケビ！'
                                : '🔒 This card is currently locked.\nCollect fortune numbers, solve riddles, or chat with Kkaebi to unlock!')),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: widget.isUnlocked ? DokkeyTheme.textMain : DokkeyTheme.textMuted,
                      fontSize: 11,
                      height: 1.35,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// 3D Flip Card Detail Dialog for MY Custom Codex
class _CustomCardDetailDialog extends StatefulWidget {
  final CustomCodexCard card;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _CustomCardDetailDialog({
    required this.card,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  State<_CustomCardDetailDialog> createState() => _CustomCardDetailDialogState();
}

class _CustomCardDetailDialogState extends State<_CustomCardDetailDialog>
    with SingleTickerProviderStateMixin {
  late AnimationController _flipCtrl;
  late Animation<double> _flipAnim;
  bool _isBack = false;

  @override
  void initState() {
    super.initState();
    _flipCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _flipAnim = Tween<double>(begin: 0.0, end: 3.141592).animate(
      CurvedAnimation(parent: _flipCtrl, curve: Curves.easeInOutBack),
    );
  }

  @override
  void dispose() {
    _flipCtrl.dispose();
    super.dispose();
  }

  void _flip() {
    if (_isBack) {
      _flipCtrl.reverse();
      setState(() => _isBack = false);
    } else {
      _flipCtrl.forward();
      setState(() => _isBack = true);
    }
    SoundService().playCardFlip();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 380),
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          color: DokkeyTheme.cardDark,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: DokkeyTheme.gold, width: 1.8),
          boxShadow: [
            BoxShadow(
              color: DokkeyTheme.gold.withOpacity(0.3),
              blurRadius: 30,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            GestureDetector(
              onTap: _flip,
              child: AnimatedBuilder(
                animation: _flipAnim,
                builder: (ctx, child) {
                  final angle = _flipAnim.value;
                  final isUnder = angle > 1.570796;

                  return Transform(
                    transform: Matrix4.identity()
                      ..setEntry(3, 2, 0.0015)
                      ..rotateY(angle),
                    alignment: Alignment.center,
                    child: isUnder
                        ? Transform(
                            transform: Matrix4.identity()..rotateY(3.141592),
                            alignment: Alignment.center,
                            child: _buildCardBack(),
                          )
                        : _buildCardFront(),
                  );
                },
              ),
            ),

            const SizedBox(height: 18),
            Text(
              '💡 카드를 탭하면 앞/뒤 3D로 뒤집어집니다!',
              style: TextStyle(color: DokkeyTheme.textMuted, fontSize: 11.5),
            ),
            const SizedBox(height: 14),

            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.redAccent,
                    side: const BorderSide(color: Colors.redAccent),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  icon: const Icon(Icons.delete_outline_rounded, size: 16),
                  label: const Text('삭제'),
                  onPressed: widget.onDelete,
                ),
                const SizedBox(width: 10),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: DokkeyTheme.surfaceDark,
                    foregroundColor: DokkeyTheme.goldLight,
                    side: BorderSide(color: DokkeyTheme.gold.withOpacity(0.6)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  icon: const Icon(Icons.edit_rounded, size: 16),
                  label: const Text('수정'),
                  onPressed: widget.onEdit,
                ),
                const SizedBox(width: 10),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: DokkeyTheme.gold,
                    foregroundColor: DokkeyTheme.bgDark,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('닫기', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCardFront() {
    return Container(
      width: 220,
      height: 330,
      decoration: BoxDecoration(
        color: DokkeyTheme.surfaceDark,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: DokkeyTheme.gold, width: 2),
        boxShadow: [
          BoxShadow(color: DokkeyTheme.gold.withOpacity(0.3), blurRadius: 16),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (widget.card.imageBase64 != null)
              Image.memory(
                base64Decode(widget.card.imageBase64!),
                fit: BoxFit.cover,
              )
            else
              Image.asset(
                widget.card.localImageUri ?? 'assets/images/kkaebi_mascot.png',
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => Image.asset('assets/images/kkaebi_mascot.png', fit: BoxFit.contain),
              ),

            Positioned(
              top: 10,
              left: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.7),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: DokkeyTheme.gold.withOpacity(0.5)),
                ),
                child: Text(
                  'MY #${widget.card.slotIndex + 1}',
                  style: TextStyle(color: DokkeyTheme.goldLight, fontSize: 11, fontWeight: FontWeight.bold),
                ),
              ),
            ),

            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
                color: Colors.black.withOpacity(0.8),
                child: Text(
                  widget.card.title ?? '나만의 소원 카드',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: DokkeyTheme.goldLight, fontSize: 14, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCardBack() {
    final memo = widget.card.memo;
    final hasMemo = memo != null && memo.trim().isNotEmpty;

    return Container(
      width: 220,
      height: 330,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: DokkeyTheme.surfaceDark,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: DokkeyTheme.gold, width: 2),
        boxShadow: [
          BoxShadow(color: DokkeyTheme.gold.withOpacity(0.35), blurRadius: 18),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (widget.card.imageBase64 != null)
              Opacity(
                opacity: 0.15,
                child: Image.memory(
                  base64Decode(widget.card.imageBase64!),
                  fit: BoxFit.cover,
                ),
              ),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 54,
                  height: 54,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: DokkeyTheme.gold, width: 1.5),
                    color: DokkeyTheme.cardDark,
                  ),
                  child: ClipOval(
                    child: Image.asset('assets/images/kkaebi_mascot.png', fit: BoxFit.contain),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  widget.card.title ?? '나만의 소원 카드',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: DokkeyTheme.gold, fontWeight: FontWeight.bold, fontSize: 14),
                ),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: DokkeyTheme.cardDark.withOpacity(0.85),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: DokkeyTheme.gold.withOpacity(0.3)),
                  ),
                  child: Column(
                    children: [
                      Text(
                        hasMemo ? memo! : '소원을 향해 한 걸음씩 나아가면\n황금 열쇠의 문이 열립니다!',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: DokkeyTheme.textMain, fontSize: 11, height: 1.35),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '✨ 소원이 이루어진다깨비! 🔮',
                        style: TextStyle(color: DokkeyTheme.goldLight, fontSize: 10, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
