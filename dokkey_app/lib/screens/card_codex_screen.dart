import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/theme.dart';
import '../core/sound_service.dart';
import '../core/codex_service.dart';
import '../models/codex_models.dart';
import '../models/talisman_model.dart';
import '../providers/dokkey_provider.dart';
import '../widgets/dokkaebi_fire_particles.dart';
import '../widgets/rotating_key_home_button.dart';
import '../widgets/pro_pass_dialog.dart';
import 'keybox_screen.dart';

String _t(String lang, {
  required String ko,
  required String en,
  required String ja,
  required String zh,
  required String de,
  required String hi,
}) {
  switch (lang) {
    case 'en': return en;
    case 'ja': return ja;
    case 'zh': return zh;
    case 'de': return de;
    case 'hi': return hi;
    default: return ko;
  }
}

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
    _tabController = TabController(length: 4, vsync: this);
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
    final lang = provider.lang;
    final cardName = card.localizedName(lang);

    SoundService().playCardFlip();

    showDialog(
      context: context,
      builder: (ctx) => _CodexDetailDialog(
        card: card,
        cardName: cardName,
        isUnlocked: isUnlocked,
        lang: lang,
      ),
    );
  }

  void _showCustomCardDialog(BuildContext context, CustomCodexCard customCard) {
    final lang = context.read<DokkeyProvider>().lang;
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
              Expanded(
                child: Text(
                  _t(lang,
                    ko: 'MY 커스텀 슬롯 #${customCard.slotIndex + 1}',
                    en: 'MY Custom Slot #${customCard.slotIndex + 1}',
                    ja: 'MY カスタムスロット #${customCard.slotIndex + 1}',
                    zh: '我的专属卡槽 #${customCard.slotIndex + 1}',
                    de: 'Mein Custom-Slot #${customCard.slotIndex + 1}',
                    hi: 'माई कस्टम स्लॉट #${customCard.slotIndex + 1}',
                  ),
                  style: TextStyle(color: DokkeyTheme.goldLight, fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _t(lang,
                    ko: '스마트폰 앨범에서 사진을 선택하면 400×600 카드 규격으로 자동 최적화됩니다 (기기 로컬 안전 보관)',
                    en: 'Select a photo from your album. It will be optimized to 400×600 (safely stored locally)',
                    ja: 'アルバムから写真を選択すると400×600規格に最適化されます（端末ローカル保存）',
                    zh: '从相册选择照片后将自动优化为400×600标准卡片规格（安全保存在本地）',
                    de: 'Foto auswählen; wird automatisch auf 400×600 optimiert (sicher lokal gespeichert)',
                    hi: 'एल्बम से फ़ोटो चुनें, यह 400×600 में अनुकूलित होगी (सुरक्षित स्थानीय भंडारण)',
                  ),
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
                              currentLocalUri,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => _buildSelectPhotoPlaceholder(lang),
                            )
                          else
                            _buildSelectPhotoPlaceholder(lang),

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
                                    currentImageBase64 != null
                                        ? _t(lang, ko: '사진 변경', en: 'Change Photo', ja: '写真変更', zh: '更换照片', de: 'Foto ändern', hi: 'फ़ोटो बदलें')
                                        : _t(lang, ko: '사진 선택', en: 'Select Photo', ja: '写真選択', zh: '选择照片', de: 'Foto wählen', hi: 'फ़ोटो चुनें'),
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
                  label: Text(
                    _t(lang,
                      ko: '📷 앨범에서 사진 선택 (400×600 자동 크롭)',
                      en: '📷 Pick Photo from Album (400×600 Auto Crop)',
                      ja: '📷 アルバムから写真選択 (400×600自動調整)',
                      zh: '📷 从相册选取照片 (400×600自动裁剪)',
                      de: '📷 Foto aus Album wählen (400×600 Auto-Crop)',
                      hi: '📷 एल्बम से फ़ोटो चुनें (400×600 स्वतः क्रॉप)',
                    ),
                    style: const TextStyle(fontSize: 12),
                  ),
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
                    labelText: _t(lang,
                      ko: '카드 이름 / 소원 제목',
                      en: 'Card Name / Wish Title',
                      ja: 'カード名 / 願い事のタイトル',
                      zh: '卡片名称 / 许愿标题',
                      de: 'Kartenname / Wunschtitel',
                      hi: 'कार्ड का नाम / इच्छा का शीर्षक',
                    ),
                    hintText: _t(lang,
                      ko: '예: 우리집 복덩이 초코 🐶',
                      en: 'e.g., Lucky Puppy Choco 🐶',
                      ja: '例: 我が家の福招きチョコ 🐶',
                      zh: '例：我家的福气小狗可可 🐶',
                      de: 'z. B. Mein Glücksbringer Choco 🐶',
                      hi: 'उदा: हमारे घर का लकी पपी 🐶',
                    ),
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
                    labelText: _t(lang,
                      ko: '나만의 한마디 / 소원 다짐',
                      en: 'My Note / Wish Oath',
                      ja: 'ひとこと / 願いの誓い',
                      zh: '我的心语 / 许愿誓言',
                      de: 'Persönliche Notiz / Schwur',
                      hi: 'मेरा संदेश / संकल्प',
                    ),
                    hintText: _t(lang,
                      ko: '예: 매일매일 웃으며 살기!',
                      en: 'e.g., Smile every single day!',
                      ja: '例: 毎日笑顔で過ごす！',
                      zh: '例：每天都要开开心心！',
                      de: 'z. B. Jeden Tag mit einem Lächeln leben!',
                      hi: 'उदा: हर दिन मुस्कुराते हुए जीना!',
                    ),
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
                child: Text(
                  _t(lang, ko: '삭제 (비우기)', en: 'Delete (Clear)', ja: '削除（クリア）', zh: '删除（清空）', de: 'Löschen', hi: 'हटाएं'),
                  style: const TextStyle(color: Colors.redAccent),
                ),
              ),
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: Text(
                _t(lang, ko: '취소', en: 'Cancel', ja: 'キャンセル', zh: '取消', de: 'Abbrechen', hi: 'रद्द करें'),
                style: TextStyle(color: DokkeyTheme.textMuted),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: DokkeyTheme.gold,
                foregroundColor: DokkeyTheme.bgDark,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () async {
                final defaultTitle = _t(lang,
                  ko: 'MY 소원 카드 #${customCard.slotIndex + 1}',
                  en: 'MY Wish Card #${customCard.slotIndex + 1}',
                  ja: 'MY 願い事カード #${customCard.slotIndex + 1}',
                  zh: '我的许愿卡片 #${customCard.slotIndex + 1}',
                  de: 'Meine Wunschkarte #${customCard.slotIndex + 1}',
                  hi: 'माई विश कार्ड #${customCard.slotIndex + 1}',
                );
                final title = titleCtrl.text.trim().isEmpty ? defaultTitle : titleCtrl.text.trim();
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
              child: Text(
                _t(lang, ko: '🪄 저장 뚝딱!', en: '🪄 Save!', ja: '🪄 保存する！', zh: '🪄 保存完成！', de: '🪄 Speichern!', hi: '🪄 सहेजें!'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSelectPhotoPlaceholder(String lang) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.add_photo_alternate_rounded, size: 38, color: DokkeyTheme.gold.withOpacity(0.7)),
        const SizedBox(height: 6),
        Text(
          _t(lang, ko: '사진 선택', en: 'Select Photo', ja: '写真選択', zh: '选择照片', de: 'Foto wählen', hi: 'फ़ोटो चुनें'),
          style: TextStyle(color: DokkeyTheme.goldLight, fontSize: 12, fontWeight: FontWeight.bold),
        ),
        Text(
          _t(lang, ko: '400×600 크롭', en: '400×600 Crop', ja: '400×600 クロップ', zh: '400×600 裁剪', de: '400×600 Crop', hi: '400×600 क्रॉप'),
          style: TextStyle(color: DokkeyTheme.textMuted, fontSize: 10),
        ),
      ],
    );
  }

  void _showCustomCardDetail(BuildContext context, CustomCodexCard customCard) {
    final provider = context.read<DokkeyProvider>();
    SoundService().playCardFlip();
    showDialog(
      context: context,
      builder: (ctx) => _CustomCardDetailDialog(
        card: customCard,
        lang: provider.lang,
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
    final lang = provider.lang;
    final isKo = lang == 'ko';
    final isJa = lang == 'ja';

    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: Text(_t(lang, ko: '99 그랜드 도감', en: '99 Grand Codex', ja: '99 グランド図鑑', zh: '99 宏伟图鉴', de: '99 Grand Codex', hi: '99 ग्रैंड कोडेक्स'))),
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
            Text(_t(lang, ko: '99 그랜드 도감', en: '99 Grand Codex', ja: '99 グランド図鑑', zh: '99 宏伟图鉴', de: '99 Grand Codex', hi: '99 ग्रैंड कोडेक्स')),
            Text(
              'DOK-KEY : TTOOK-TTAK!',
              style: TextStyle(color: DokkeyTheme.gold, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.2),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.vpn_key_outlined, color: DokkeyTheme.gold),
            tooltip: _t(lang, ko: '황금열쇠 보관함', en: 'Keybox Vault', ja: '鍵保管箱', zh: '黄金钥匙金库', de: 'Schlüsseltresor', hi: 'कुंजी तिजोरी'),
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
          isScrollable: true,
          tabs: [
            Tab(text: _t(lang,
              ko: '신수 ($zodiacUnlockedCount/33)',
              en: 'Beasts ($zodiacUnlockedCount/33)',
              ja: '神獣 ($zodiacUnlockedCount/33)',
              zh: '神兽 ($zodiacUnlockedCount/33)',
              de: 'Bestien ($zodiacUnlockedCount/33)',
              hi: 'दिव्य पशु ($zodiacUnlockedCount/33)',
            )),
            Tab(text: _t(lang,
              ko: '신격 ($mythUnlockedCount/33)',
              en: 'Gods ($mythUnlockedCount/33)',
              ja: '神格 ($mythUnlockedCount/33)',
              zh: '神祇 ($mythUnlockedCount/33)',
              de: 'Gottheiten ($mythUnlockedCount/33)',
              hi: 'देवता ($mythUnlockedCount/33)',
            )),
            Tab(text: _t(lang,
              ko: '🎴 부적 (33슬롯)',
              en: '🎴 Talismans (33)',
              ja: '🎴 御札 (33枠)',
              zh: '🎴 灵符 (33格)',
              de: '🎴 Talismane (33)',
              hi: '🎴 ताबीज (33)',
            )),
            Tab(text: _t(lang,
              ko: 'MY 커스텀 ($customFilledCount/33)',
              en: 'MY Custom ($customFilledCount/33)',
              ja: 'MY カスタム ($customFilledCount/33)',
              zh: '专属卡槽 ($customFilledCount/33)',
              de: 'MY Custom ($customFilledCount/33)',
              hi: 'माई कस्टम ($customFilledCount/33)',
            )),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildCardGrid(context, zodiacList, 'zodiac'),
          _buildCardGrid(context, mythList, 'myth'),
          _buildTalismanGrid(context),
          _buildCustomGrid(context, customList),
        ],
      ),
    );
  }

  Widget _buildTalismanGrid(BuildContext context) {
    final provider = context.watch<DokkeyProvider>();
    final lang = provider.lang;
    final isKo = lang == 'ko';
    final talismans = TalismanRegistry.items;
    final customCards = _codexService.customCards;

    return GridView.builder(
      padding: const EdgeInsets.all(14),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 0.65,
        crossAxisSpacing: 10,
        mainAxisSpacing: 12,
      ),
      itemCount: 33, // 1~18: 공식 부적 18종, 19~33: MY 커스텀 부적 15종
      itemBuilder: (ctx, idx) {
        if (idx < talismans.length) {
          // 1 ~ 18번: 공식 18종 전통 부적 (발급된 부적만 컬러, 미발급은 실루엣)
          final t = talismans[idx];
          final name = t.localizedName(lang);
          final collected = provider.isTalismanCollected(t.id);

          return GestureDetector(
            onTap: () => _showTalismanDetail(context, t),
            child: Container(
              decoration: BoxDecoration(
                color: DokkeyTheme.cardDark,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: collected ? DokkeyTheme.gold : DokkeyTheme.borderDark,
                  width: collected ? 1.5 : 1.0,
                ),
                boxShadow: collected
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
                    Opacity(
                      opacity: collected ? 1.0 : 0.28,
                      child: Image.asset(
                        t.imagePath,
                        fit: BoxFit.cover,
                      ),
                    ),
                    if (!collected)
                      Center(
                        child: Icon(Icons.lock_outline_rounded,
                            color: DokkeyTheme.textMuted, size: 30),
                      ),
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
                        color: Colors.black.withOpacity(0.75),
                        child: Text(
                          collected
                              ? '#${t.index} $name'
                              : '#${t.index} ???',
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: collected
                                ? DokkeyTheme.goldLight
                                : DokkeyTheme.textMuted,
                            fontSize: 10.5,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    if (collected)
                      Positioned(
                        top: 4,
                        right: 4,
                        child: Icon(Icons.verified_rounded,
                            size: 16, color: DokkeyTheme.gold),
                      ),
                  ],
                ),
              ),
            ),
          );
        } else {
          // 19 ~ 33번: 15종 MY 커스텀 부적 슬롯 (무료는 19~20번 2개 슬롯만 체험, 21~33번은 PRO 전용)
          final customSlotIdx = idx - talismans.length; // 0 ~ 14
          final isLockedForFree = !provider.isProUser && customSlotIdx >= 2;
          final customCard = customSlotIdx < customCards.length
              ? customCards[customSlotIdx]
              : CustomCodexCard(slotIndex: customSlotIdx, isEmpty: true);
          final isEmpty = customCard.isEmpty;

          return GestureDetector(
            onTap: () {
              if (isLockedForFree) {
                ProPassDialog.show(context);
                return;
              }
              if (isEmpty) {
                _showCustomCardDialog(context, customCard);
              } else {
                _showCustomCardDetail(context, customCard);
              }
            },
            child: Container(
              decoration: BoxDecoration(
                color: DokkeyTheme.cardDark,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isLockedForFree
                      ? DokkeyTheme.borderDark
                      : (!isEmpty ? DokkeyTheme.gold : DokkeyTheme.gold.withOpacity(0.4)),
                  width: !isEmpty ? 1.5 : 1.0,
                ),
                boxShadow: !isEmpty && !isLockedForFree
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
                    if (!isEmpty)
                      if (customCard.imageBase64 != null)
                        Image.memory(
                          base64Decode(customCard.imageBase64!),
                          fit: BoxFit.cover,
                        )
                      else
                        Image.asset(
                          customCard.localImageUri ?? 'assets/images/kkaebi_mascot.png',
                          fit: BoxFit.cover,
                        )
                    else
                      Container(
                        color: const Color(0xFF1B140B),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              isLockedForFree ? Icons.lock_outline_rounded : Icons.auto_fix_high_rounded,
                              size: 26,
                              color: isLockedForFree ? DokkeyTheme.gold.withOpacity(0.4) : DokkeyTheme.gold.withOpacity(0.7),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              '#${idx + 1}',
                              style: TextStyle(
                                color: isLockedForFree ? DokkeyTheme.textMuted : DokkeyTheme.goldLight,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              isLockedForFree
                                  ? _t(lang, ko: 'PRO 잠금', en: 'PRO Lock', ja: 'PROロック', zh: 'PRO锁定', de: 'PRO-Gesperrt', hi: 'PRO लॉक')
                                  : _t(lang, ko: 'MY 부적 등록', en: 'MY Charm', ja: 'MY お守り登録', zh: '登记专属灵符', de: 'MY Talisman', hi: 'माई ताबीज'),
                              style: TextStyle(
                                color: isLockedForFree ? DokkeyTheme.gold.withOpacity(0.6) : DokkeyTheme.textMuted,
                                fontSize: 9.5,
                                fontWeight: isLockedForFree ? FontWeight.bold : FontWeight.normal,
                              ),
                            ),
                          ],
                        ),
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
                            '#${idx + 1} ${customCard.title ?? _t(lang, ko: "나만의 부적", en: "Custom Charm", ja: "マイお守り", zh: "专属灵符", de: "Mein Talisman", hi: "कस्टम ताबीज")}',
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: DokkeyTheme.goldLight,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          );
        }
      },
    );
  }

  void _showTalismanDetail(BuildContext context, TalismanItem item) {
    final provider = context.read<DokkeyProvider>();
    final lang = provider.lang;
    final isKo = lang == 'ko';

    SoundService().playCardFlip();

    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFF2A1C0A), Color(0xFF141822), Color(0xFF0F1116)],
            ),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: DokkeyTheme.gold, width: 2.0),
            boxShadow: [
              BoxShadow(
                color: DokkeyTheme.gold.withOpacity(0.4),
                blurRadius: 25,
                spreadRadius: 3,
              ),
            ],
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    height: 280,
                    decoration: BoxDecoration(
                      border: Border.all(color: DokkeyTheme.gold, width: 1.5),
                    ),
                    child: Image.asset(item.imagePath, fit: BoxFit.cover),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  item.localizedName(lang),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: DokkeyTheme.goldLight,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  item.localizedTitle(lang),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: DokkeyTheme.gold,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: DokkeyTheme.borderDark),
                  ),
                  child: Text(
                    item.localizedDesc(lang),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Color(0xFFE0D8C3),
                      fontSize: 13,
                      height: 1.5,
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                ElevatedButton.icon(
                  onPressed: () => Navigator.of(ctx).pop(),
                  icon: const Icon(Icons.check_circle_outline, size: 18),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: DokkeyTheme.gold,
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                  ),
                  label: Text(
                    _t(
                      lang,
                      ko: '확인 및 보관',
                      en: 'Confirm & Keep',
                      ja: '確認・保管',
                      zh: '确认并保存',
                      de: 'Bestätigen & Behalten',
                      hi: 'पुष्टि करें और सहेजें',
                    ),
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
        ),
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
    final lang = context.watch<DokkeyProvider>().lang;
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
                          '#${idx + 1} ${_t(lang, ko: '등록', en: 'Add', ja: '登録', zh: '登记', de: 'Neu', hi: 'जोड़ें')}',
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
                          card.title ?? _t(lang, ko: '나만의 카드', en: 'My Custom Card', ja: 'マイカード', zh: '我的专属卡片', de: 'Meine Wunschkarte', hi: 'मेरी कस्टम कार्ड'),
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
  final String lang;

  const _CodexDetailDialog({
    required this.card,
    required this.cardName,
    required this.isUnlocked,
    required this.lang,
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
              _t(
                widget.lang,
                ko: '💡 카드를 탭하면 앞/뒤 3D로 뒤집어집니다!',
                en: '💡 Tap the card to flip front/back in 3D!',
                ja: '💡 カードをタップすると表裏が3D反転します！',
                zh: '💡 点击卡片可在正面/反面3D翻转！',
                de: '💡 Tippe auf die Karte, um sie in 3D zu drehen!',
                hi: '💡 कार्ड को 3D में पलटने के लिए टैप करें!',
              ),
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
              child: Text(
                _t(
                  widget.lang,
                  ko: '닫기',
                  en: 'Close',
                  ja: '閉じる',
                  zh: '关闭',
                  de: 'Schließen',
                  hi: 'बंद करें',
                ),
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
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
                          ? widget.card.localizedTitle(widget.lang)
                          : _t(
                              widget.lang,
                              ko: '🔒 미수집 카드',
                              en: '🔒 Locked Card',
                              ja: '🔒 未収集カード',
                              zh: '🔒 未解锁卡片',
                              de: '🔒 Gesperrte Karte',
                              hi: '🔒 अनलॉक नहीं हुआ',
                            ),
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
                      ? widget.card.localizedTitle(widget.lang)
                      : _t(
                          widget.lang,
                          ko: '열쇠 번호를 모아 해금',
                          en: 'Collect key numbers to unlock',
                          ja: '鍵番号を集めて解除',
                          zh: '收集钥匙号码解锁',
                          de: 'Schlüsselnummern sammeln zum Freischalten',
                          hi: 'अनलॉक करने के लिए कुंजी नंबर एकत्र करें',
                        ),
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
                        ? widget.card.localizedDesc(widget.lang)
                        : _t(
                            widget.lang,
                            ko: '🔒 아직 수집되지 않은 비밀 도감 카드입니다.\n행운의 번호 뽑기, 수수께끼 퀴즈, 깨비 대화로 숫자를 모으면 도감이 해금됩니다깨비!',
                            en: '🔒 This secret codex card is currently locked.\nCollect numbers via Lucky Draw, Riddles, or chatting with Kkaebi to unlock it!',
                            ja: '🔒 まだ収集されていない秘密の図鑑カードです。\n運勢の数字引き、クイズ、対話で数字を集めると解除されますケビ！',
                            zh: '🔒 尚未收集的神秘图鉴卡片。\n通过幸运抽签、灯谜问答或与吉鬼对话收集数字即可解锁！',
                            de: '🔒 Diese geheime Kodex-Karte ist noch gesperrt.\nSammle Zahlen beim Glücksziehen, bei Rätseln oder im Chat mit Kkaebi!',
                            hi: '🔒 यह गुप्त कोडेक्स कार्ड वर्तमान में बंद है।\nलकी ड्रा, पहेलियों या कैबी से बातचीत करके नंबर एकत्र करें और इसे अनलॉक करें!',
                          ),
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
  final String lang;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _CustomCardDetailDialog({
    required this.card,
    required this.lang,
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
              _t(
                widget.lang,
                ko: '💡 카드를 탭하면 앞/뒤 3D로 뒤집어집니다!',
                en: '💡 Tap the card to flip front/back in 3D!',
                ja: '💡 カードをタップすると表裏が3D反転します！',
                zh: '💡 点击卡片可在正面/反面3D翻转！',
                de: '💡 Tippe auf die Karte, um sie in 3D zu drehen!',
                hi: '💡 कार्ड को 3D में पलटने के लिए टैप करें!',
              ),
              textAlign: TextAlign.center,
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
                  label: Text(
                    _t(
                      widget.lang,
                      ko: '삭제',
                      en: 'Delete',
                      ja: '削除',
                      zh: '删除',
                      de: 'Löschen',
                      hi: 'हटाएं',
                    ),
                  ),
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
                  label: Text(
                    _t(
                      widget.lang,
                      ko: '수정',
                      en: 'Edit',
                      ja: '編集',
                      zh: '编辑',
                      de: 'Bearbeiten',
                      hi: 'संपादित करें',
                    ),
                  ),
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
                  child: Text(
                    _t(
                      widget.lang,
                      ko: '닫기',
                      en: 'Close',
                      ja: '閉じる',
                      zh: '关闭',
                      de: 'Schließen',
                      hi: 'बंद करें',
                    ),
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
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
                  widget.card.title ??
                      _t(
                        widget.lang,
                        ko: '나만의 소원 카드',
                        en: 'My Wish Card',
                        ja: 'マイ願いカード',
                        zh: '我的心愿卡',
                        de: 'Meine Wunschkarte',
                        hi: 'मेरा इच्छा कार्ड',
                      ),
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
                  widget.card.title ??
                      _t(
                        widget.lang,
                        ko: '나만의 소원 카드',
                        en: 'My Wish Card',
                        ja: 'マイ願いカード',
                        zh: '我的心愿卡',
                        de: 'Meine Wunschkarte',
                        hi: 'मेरा इच्छा कार्ड',
                      ),
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
                        hasMemo
                            ? memo
                            : _t(
                                widget.lang,
                                ko: '소원을 향해 한 걸음씩 나아가면\n황금 열쇠의 문이 열립니다!',
                                en: 'Step by step toward your wish,\nthe Golden Key door will open!',
                                ja: '願いに向かって一歩ずつ進めば、\n黄金の鍵の扉が開かれます！',
                                zh: '向着心愿迈出每一步，\n金钥匙之门终将开启！',
                                de: 'Schritt für Schritt zum Wunsch,\ndas Tor des Goldenen Schlüssels öffnet sich!',
                                hi: 'अपनी इच्छा की ओर एक-एक कदम बढ़ें,\nस्वर्ण कुंजी का द्वार खुलेगा!',
                              ),
                        textAlign: TextAlign.center,
                        style: TextStyle(color: DokkeyTheme.textMain, fontSize: 11, height: 1.35),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        _t(
                          widget.lang,
                          ko: '✨ 소원이 이루어진다깨비! 🔮',
                          en: '✨ Your wish will come true! 🔮',
                          ja: '✨ 願いが叶うケビ！ 🔮',
                          zh: '✨ 心愿必定成真鬼！ 🔮',
                          de: '✨ Dein Wunsch wird wahr! 🔮',
                          hi: '✨ आपकी इच्छा पूरी होगी! 🔮',
                        ),
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
