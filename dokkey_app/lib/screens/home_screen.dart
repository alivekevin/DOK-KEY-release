import 'kkaebi_chat_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../core/theme.dart';
import '../core/sound_service.dart';
import '../providers/dokkey_provider.dart';
import '../widgets/riddle_dialog.dart';
import '../widgets/dream_dialog.dart';
import '../widgets/codex_master_dialog.dart';
import '../games/kkaebi_arcade_hub.dart';
import '../widgets/draw_cinematic_dialog.dart';
import '../widgets/shop_dialog.dart';
import '../widgets/settings_dialog.dart';
import '../widgets/kkaebi_mascot.dart';
import 'keybox_screen.dart';
import 'card_codex_screen.dart';
import '../widgets/kkaebi_floating_mascot.dart';
import '../widgets/kkaebi_cinematic_dialog.dart';
import '../widgets/seasonal_ambient_background.dart';
import '../core/codex_service.dart';
import '../widgets/quote_hero_section.dart';
import '../widgets/kkaebi_calendar_dialog.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animCtrl;
  bool _isDrawing = false;
  int codexZodiacUnlocked = 0;
  int codexMythUnlocked = 0;
  int codexCustomFilled = 0;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();

    // v4.7.0 4순위: 도감 탭별 수집 카운트 로드
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      final codex = CodexService();
      await codex.init();
      if (!mounted) return;
      var z = 0, m = 0, c = 0;
      for (var slot = 1; slot <= 33; slot++) {
        if (codex.isCardUnlocked('zodiac', slot)) z++;
        if (codex.isCardUnlocked('myth', slot)) m++;
      }
      c = codex.customCards.where((card) => !card.isEmpty).length;
      setState(() {
        codexZodiacUnlocked = z;
        codexMythUnlocked = m;
        codexCustomFilled = c;
      });
    });

    // PHASE 6: 도감 완성 업적 축하 & 웰컴 선물 & 인트로 사운드
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final provider = context.read<DokkeyProvider>();

      // 앱 초기 진입 챠링~ 환영음 및 앰비언스 사운드
      SoundService().playWelcomeIntro();
      SoundService().startAmbient();

      // 신규 사용자 웰컴 보너스 팝업
      if (provider.pendingWelcomeNumbers != null && provider.pendingWelcomeNumbers!.isNotEmpty) {
        _showWelcomeBonusDialog(context, provider.pendingWelcomeNumbers!);
        provider.clearPendingWelcome();
      } else if (provider.pendingCodexMasterCelebration) {
        CodexMasterDialog.show(context);
      }
    });
  }

  void _showWelcomeBonusDialog(BuildContext context, List<int> numbers) {
    SoundService().playAlchemyFanfare();
    showDialog(
      context: context,
      builder: (ctx) {
        final provider = context.read<DokkeyProvider>();
        final isKo = provider.lang == 'ko';
        final isJa = provider.lang == 'ja';

        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: Container(
            padding: const EdgeInsets.all(24),
            constraints: const BoxConstraints(maxWidth: 400),
            decoration: BoxDecoration(
              color: DokkeyTheme.cardDark,
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: DokkeyTheme.gold, width: 2),
              boxShadow: [
                BoxShadow(
                  color: DokkeyTheme.gold.withOpacity(0.35),
                  blurRadius: 28,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 90,
                  height: 90,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [DokkeyTheme.gold.withOpacity(0.35), DokkeyTheme.cardDark],
                    ),
                    border: Border.all(color: DokkeyTheme.gold, width: 2),
                  ),
                  child: ClipOval(
                    child: Image.asset(
                      'assets/images/kkaebi_face/face_02.webp',
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Image.asset('assets/images/kkaebi_mascot.png'),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  isKo ? '🎁 깨비의 첫 만남 웰컴 선물!' : (isJa ? '🎁 クケビの初対面ギフト！' : '🎁 Welcome Gift from Kkaebi!'),
                  style: TextStyle(
                    color: DokkeyTheme.goldLight,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 10),
                Text(
                  isKo
                      ? 'DOK-KEY에 오신 것을 환영합니다깨비!\n보관함과 도감에 바로 사용할 수 있는\n행운의 열쇠 3개를 선물로 뚝딱 드려요!'
                      : (isJa
                          ? 'DOK-KEYへようこそケビ！\n保管箱と図鑑で使える\n幸運の鍵3個をプレゼントするよ！'
                          : 'Welcome to DOK-KEY!\nHere are 3 lucky starter keys for your Vault and Codex!'),
                  style: TextStyle(color: DokkeyTheme.textMuted, fontSize: 13, height: 1.4),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 18),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: numbers.map((n) {
                    final numStr = n.toString().padLeft(2, '0');
                    return Container(
                      margin: const EdgeInsets.symmetric(horizontal: 6),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [DokkeyTheme.gold, DokkeyTheme.goldLight],
                        ),
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: DokkeyTheme.gold.withOpacity(0.4),
                            blurRadius: 8,
                          ),
                        ],
                      ),
                      child: Text(
                        '#$numStr',
                        style: const TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.w900,
                          fontSize: 18,
                          letterSpacing: 1.0,
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),
                Text(
                  isKo
                      ? '💡 보관함(01~99 서랍)과 도감에서 방금 해금된 카드를 확인하세요!'
                      : (isJa ? '💡 保管箱と図鑑で解除されたカードを確認しよう！' : '💡 Check out your unlocked cards in Vault and Codex!'),
                  style: TextStyle(color: DokkeyTheme.gold.withOpacity(0.85), fontSize: 11),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: DokkeyTheme.gold,
                    foregroundColor: DokkeyTheme.bgDark,
                    padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: Text(
                    isKo ? '고마워, 깨비야! 🗝️' : (isJa ? 'ありがとう、クケビ！🗝️' : 'Thank you, Kkaebi! 🗝️'),
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    super.dispose();
  }

  /// 6개국어 즉시 전환 시트 (홈 앱바 🌐 버튼)
  void _showLanguageSheet(BuildContext context) {
    final provider = context.read<DokkeyProvider>();
    const options = [
      ('ko', '한국어', '🇰🇷'),
      ('en', 'English', '🇺🇸'),
      ('ja', '日本語', '🇯🇵'),
      ('zh', '中文', '🇨🇳'),
      ('hi', 'हिन्दी', '🇮🇳'),
      ('de', 'Deutsch', '🇩🇪'),
    ];

    showModalBottomSheet(
      context: context,
      backgroundColor: DokkeyTheme.cardDark,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetCtx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Icon(Icons.translate_rounded, color: DokkeyTheme.gold, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    provider.lang == 'ko'
                        ? '언어 선택'
                        : (provider.lang == 'ja' ? '言語選択' : (provider.lang == 'zh' ? '选择语言' : (provider.lang == 'hi' ? 'भाषा चुनें' : (provider.lang == 'de' ? 'Sprache wählen' : 'Select Language')))),
                    style: TextStyle(
                      color: DokkeyTheme.goldLight,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ...options.map((o) {
                final active = provider.lang == o.$1;
                return ListTile(
                  dense: true,
                  leading: Text(o.$3, style: const TextStyle(fontSize: 20)),
                  title: Text(
                    o.$2,
                    style: TextStyle(
                      color: active ? DokkeyTheme.gold : DokkeyTheme.textMain,
                      fontWeight: active ? FontWeight.bold : FontWeight.normal,
                      fontSize: 14,
                    ),
                  ),
                  trailing: active
                      ? Icon(Icons.check_circle_rounded, color: DokkeyTheme.gold, size: 20)
                      : null,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  onTap: () {
                    provider.setLanguage(o.$1);
                    Navigator.of(sheetCtx).pop();
                  },
                );
              }),
            ],
          ),
        ),
      ),
    );
  }

  void _onDrawPressed(BuildContext context) async {
    final provider = context.read<DokkeyProvider>();
    if (provider.keys <= 0) {
      final isKo = provider.lang == 'ko';
      final isJa = provider.lang == 'ja';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isKo
                ? '오늘의 무료 열쇠를 모두 사용했습니다! 만물상에서 보너스 열쇠를 획득하세요 🗝️'
                : (isJa
                    ? '今日の無料キーを使い切りました! 万物店でボーナスキーをゲット 🗝️'
                    : 'No keys left! Get bonus keys at Kkaebi’s Shop 🗝️'),
          ),
          backgroundColor: DokkeyTheme.cardDark,
          action: SnackBarAction(
            label: isKo ? '만물상 가기' : (isJa ? '万物店' : 'Shop'),
            textColor: DokkeyTheme.gold,
            onPressed: () => ShopDialog.show(context),
          ),
        ),
      );
      return;
    }

    SoundService().playKeyTurn();
    setState(() => _isDrawing = true);
    final result = await provider.executeDraw();
    if (!mounted) return;
    setState(() => _isDrawing = false);

    // 1단계: 깨비의 "금 나와라 뚝딱!" 2D 시네마틱 애니메이션 재생
    KkaebiCinematicDialog.show(
      context,
      onComplete: () {
        if (!mounted) return;
        // 2단계: 황금 카드 오픈 및 운세 공개
        DrawCinematicDialog.show(context, result);
      },
    );
  }


  @override
  Widget build(BuildContext context) {
    final provider = context.watch<DokkeyProvider>();
    final isKo = provider.lang == 'ko';
    final isJa = provider.lang == 'ja';
    final slotName = provider.todayResult?.timeslot.name;

    if (!provider.isInitialized) {
      return Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: DokkeyTheme.gold),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 20,
        centerTitle: false,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: DokkeyTheme.gold, width: 1.2),
                boxShadow: [
                  BoxShadow(
                    color: DokkeyTheme.gold.withOpacity(0.3),
                    blurRadius: 4,
                  ),
                ],
              ),
              child: ClipOval(
                child: Image.asset(
                  'assets/images/kkaebi_face/face_05.webp',
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Icon(Icons.vpn_key_rounded, color: DokkeyTheme.gold, size: 18),
                ),
              ),
            ),
            const SizedBox(width: 8),
            const Text(
              'DOK-KEY',
              style: TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 18,
                letterSpacing: 1.0,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            visualDensity: const VisualDensity(horizontal: -3, vertical: -3),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 34, minHeight: 34),
            onPressed: () => KkaebiCalendarDialog.show(context),
            icon: Icon(Icons.calendar_month_rounded, color: DokkeyTheme.gold, size: 20),
            tooltip: isKo ? '깨비 운세 캘린더' : (isJa ? '運勢カレンダー' : 'Fortune Calendar'),
          ),
          IconButton(
            visualDensity: const VisualDensity(horizontal: -3, vertical: -3),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 34, minHeight: 34),
            onPressed: () => ShopDialog.show(context),
            icon: Icon(Icons.storefront_outlined, color: DokkeyTheme.gold, size: 20),
            tooltip: isKo ? '깨비의 만물상' : (isJa ? '万物店' : 'Shop'),
          ),
          // v4.8.0: 깨비 오락실 허브
          IconButton(
            visualDensity: const VisualDensity(horizontal: -3, vertical: -3),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 34, minHeight: 34),
            onPressed: () => KkaebiArcadeHubDialog.show(context),
            icon: Icon(Icons.sports_esports_rounded, color: DokkeyTheme.dokFire, size: 20),
            tooltip: isKo ? '깨비 오락실 (9게임)' : (isJa ? 'ゲームセンター' : 'Kkaebi Arcade'),
          ),
          IconButton(
            visualDensity: const VisualDensity(horizontal: -3, vertical: -3),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 34, minHeight: 34),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const CardCodexScreen()),
              );
            },
            icon: Icon(Icons.menu_book_rounded, color: DokkeyTheme.goldLight, size: 20),
            tooltip: isKo ? '99 그랜드 도감' : (isJa ? '99 グランド図鑑' : '99 Grand Codex'),
          ),
          IconButton(
            visualDensity: const VisualDensity(horizontal: -3, vertical: -3),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 34, minHeight: 34),
            onPressed: () => SettingsDialog.show(context),
            icon: Icon(Icons.settings_outlined, color: DokkeyTheme.textMuted, size: 20),
            tooltip: isKo ? '설정' : (isJa ? '設定' : 'Settings'),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: InkWell(
              borderRadius: BorderRadius.circular(8),
              onTap: () => _showLanguageSheet(context),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                decoration: BoxDecoration(
                  color: DokkeyTheme.gold.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: DokkeyTheme.gold.withOpacity(0.4), width: 1.0),
                ),
                child: Text(
                  provider.lang.toUpperCase(),
                  style: TextStyle(
                    color: DokkeyTheme.gold,
                    fontWeight: FontWeight.bold,
                    fontSize: 11,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SeasonalAmbientBackground(
        child: SafeArea(
          child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Top Status Row (Keys & Streak Calendar & KeyBox)
              Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: () => ShopDialog.show(context),
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                        decoration: BoxDecoration(
                          color: DokkeyTheme.cardDark,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: DokkeyTheme.borderDark),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.key_rounded, color: DokkeyTheme.gold, size: 18),
                            const SizedBox(width: 8),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  isKo ? '보유 열쇠' : (isJa ? '所持鍵' : 'Keys'),
                                  style: TextStyle(fontSize: 10, color: DokkeyTheme.textMuted),
                                ),
                                Text(
                                  '${provider.keys} Key',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: DokkeyTheme.gold,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: InkWell(
                      onTap: () => KkaebiCalendarDialog.show(context),
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                        decoration: BoxDecoration(
                          color: DokkeyTheme.surfaceDark,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: DokkeyTheme.dokFire.withValues(alpha: 0.5)),
                        ),
                        child: Row(
                          children: [
                            const Text('🔥', style: TextStyle(fontSize: 16)),
                            const SizedBox(width: 8),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  isKo ? '출석 스트릭' : (isJa ? '出席記録' : 'Streak'),
                                  style: TextStyle(fontSize: 10, color: DokkeyTheme.textMuted),
                                ),
                                Text(
                                  '${provider.streak}${isKo ? "일차" : (isJa ? "日" : "d")}',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: DokkeyTheme.goldLight,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  InkWell(
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const KeyBoxScreen()),
                      );
                    },
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                      decoration: BoxDecoration(
                        color: DokkeyTheme.surfaceDark,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: DokkeyTheme.gold.withValues(alpha: 0.4)),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.archive_outlined, color: DokkeyTheme.gold, size: 18),
                          const SizedBox(width: 6),
                          Text(
                            isKo ? '보관함' : (isJa ? '保管箱' : 'Key Box'),
                            style: TextStyle(
                              color: DokkeyTheme.textMain,
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 30),

              // v4.7.0 1순위: 오늘의 명언 히어로 (Wisdom-First)
              QuoteHeroSection(),
              const SizedBox(height: 20),

              // Zero-Delay 맥락 인사 + 시간대 태그
              if (provider.greeting.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: DokkeyTheme.cardDark.withOpacity(0.8),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: DokkeyTheme.gold.withOpacity(0.25)),
                  ),
                  child: Row(
                    children: [
                      KkaebiMascot(size: 52, expression: KkaebiExpression.neutral, accent: DokkeyTheme.gold),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          provider.greeting,
                          style: TextStyle(
                            color: DokkeyTheme.goldLight,
                            fontSize: 12.5,
                            height: 1.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              if (provider.greeting.isNotEmpty) const SizedBox(height: 24),
              // Center Gate & Draw Orb
              Center(
                child: Column(
                  children: [
                    Text(
                      isKo
                          ? (slotName != null
                              ? '명언의 흐름을 확인하는 오늘의 운세 · ${provider.todayResult?.timeslot.emoji ?? ''} $slotName'
                              : '명언의 흐름을 확인하는 오늘의 운세')
                          : (isJa
                              ? (slotName != null
                                  ? '今日一日を開く、たった一つの鍵 · ${provider.todayResult?.timeslot.emoji ?? ''} $slotName'
                                  : '今日一日を開く、たった一つの鍵')
                              : (slotName != null
                                  ? 'Unlock your day · ${provider.todayResult?.timeslot.emoji ?? ''} $slotName'
                                  : 'Unlock your day with a single draw')),
                      style: TextStyle(
                        fontSize: 14,
                        color: DokkeyTheme.textMuted,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 24),

                    GestureDetector(
                      onTap: _isDrawing ? null : () => _onDrawPressed(context),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          RotationTransition(
                            turns: _animCtrl,
                            child: Container(
                              width: 220,
                              height: 220,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: SweepGradient(
                                  colors: [
                                    DokkeyTheme.gold.withOpacity(0.0),
                                    DokkeyTheme.dokFire.withOpacity(0.4),
                                    DokkeyTheme.gold.withOpacity(0.8),
                                    DokkeyTheme.gold.withOpacity(0.0),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          Container(
                            width: 180,
                            height: 180,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: RadialGradient(
                                colors: [
                                  DokkeyTheme.surfaceDark,
                                  DokkeyTheme.cardDark,
                                  DokkeyTheme.bgDark,
                                ],
                              ),
                              border: Border.all(color: DokkeyTheme.gold, width: 2.5),
                              boxShadow: [
                                BoxShadow(
                                  color: DokkeyTheme.gold.withOpacity(0.25),
                                  blurRadius: 28,
                                  spreadRadius: 6,
                                ),
                              ],
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.lock_open_rounded,
                                  color: DokkeyTheme.gold,
                                  size: 42,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  isKo ? '열쇠 돌리기' : (isJa ? '鍵を回す' : 'DOK-KEY DRAW'),
                                  style: TextStyle(
                                    color: DokkeyTheme.goldLight,
                                    fontWeight: FontWeight.w900,
                                    fontSize: 16,
                                    letterSpacing: 1.2,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  isKo ? '1 Draw = 1 Key' : 'Tap to Unlock',
                                  style: TextStyle(
                                    color: DokkeyTheme.textMuted,
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 30),

              // 99종 도감 진행 현황 (3줄 진행바)
              InkWell(
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const CardCodexScreen()),
                  );
                },
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: DokkeyTheme.cardDark,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: DokkeyTheme.borderDark),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.auto_awesome, color: DokkeyTheme.gold, size: 18),
                          const SizedBox(width: 8),
                          Text(
                            isKo ? '99종 신수 · 신격 도감' : (isJa ? '99種図鑑' : '99 Codex'),
                            style: TextStyle(
                              color: DokkeyTheme.textMain,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            '${(provider.codexMasterProgress / 66 * 100).toStringAsFixed(0)}%',
                            style: TextStyle(
                              color: DokkeyTheme.gold,
                              fontWeight: FontWeight.w900,
                              fontSize: 12,
                            ),
                          ),
                          Icon(Icons.arrow_forward_ios_rounded, size: 12, color: DokkeyTheme.textMuted),
                        ],
                      ),
                      const SizedBox(height: 10),
                      _CodexProgressLine(label: isKo ? '신수' : (isJa ? '신수' : 'Zodiac'), color: DokkeyTheme.gold, value: codexZodiacUnlocked, total: 33),
                      const SizedBox(height: 6),
                      _CodexProgressLine(label: isKo ? '신격' : (isJa ? '신격' : 'Myth'), color: DokkeyTheme.mintCalm, value: codexMythUnlocked, total: 33),
                      const SizedBox(height: 6),
                      _CodexProgressLine(label: isKo ? '커스텀' : (isJa ? '커스텀' : 'Custom'), color: DokkeyTheme.dokFire, value: codexCustomFilled, total: 33),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 14),

              // 깨비의 수수께끼 풀기 (99신수 아래 배치)
              InkWell(
                onTap: () {
                  final riddle = provider.getTodayRiddle();
                  showDialog(
                    context: context,
                    builder: (_) => RiddleDialog(riddle: riddle),
                  );
                },
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        DokkeyTheme.dokFire.withOpacity(0.15),
                        DokkeyTheme.cardDark,
                      ],
                    ),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: DokkeyTheme.dokFire.withOpacity(0.5)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: DokkeyTheme.dokFire.withOpacity(0.2),
                        ),
                        child: const Text('🧩', style: TextStyle(fontSize: 20)),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              isKo ? '깨비의 수수께끼 풀기' : (isJa ? 'クケビのなぞなぞ' : "Solve Kkaebi's Riddle"),
                              style: TextStyle(
                                color: DokkeyTheme.textMain,
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              isKo ? '정답을 맞히면 보너스 열쇠를 드려요!' : 'Get bonus keys by solving riddles!',
                              style: TextStyle(
                                color: DokkeyTheme.textMuted,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(Icons.arrow_forward_ios_rounded, size: 14, color: DokkeyTheme.dokFire),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 14),

              // v4.7.0 5순위: 행운 숫자 연성소 배너
              InkWell(
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const KeyBoxScreen()),
                  );
                },
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [DokkeyTheme.gold.withOpacity(0.10), DokkeyTheme.cardDark],
                    ),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: DokkeyTheme.gold.withOpacity(0.4)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: DokkeyTheme.gold.withOpacity(0.18),
                        ),
                        child: const Text('🔢', style: TextStyle(fontSize: 18)),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              isKo ? '행운 숫자 연성소' : (isJa ? '幸運ナンバー錬成所' : 'Lucky Number Forge'),
                              style: TextStyle(
                                color: DokkeyTheme.textMain,
                                fontWeight: FontWeight.bold,
                                fontSize: 13.5,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              isKo
                                  ? '원천 ${provider.sourceNumbers.length}개 · 조합 ${provider.combinedKeys.length}/${provider.maxCombinedSlots} 슬롯'
                                  : '${provider.sourceNumbers.length} sources · ${provider.combinedKeys.length}/${provider.maxCombinedSlots} keys',
                              style: TextStyle(color: DokkeyTheme.textMuted, fontSize: 11.5),
                            ),
                          ],
                        ),
                      ),
                      Icon(Icons.arrow_forward_ios_rounded, size: 12, color: DokkeyTheme.gold),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 14),

              // Dream Interpretation Banner (꿈풀이)
              InkWell(
                onTap: () => DreamDialog.show(context),
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        DokkeyTheme.mintCalm.withOpacity(0.15),
                        DokkeyTheme.cardDark,
                      ],
                    ),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: DokkeyTheme.mintCalm.withOpacity(0.5)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: DokkeyTheme.mintCalm.withOpacity(0.2),
                        ),
                        child: const Text('🌙', style: TextStyle(fontSize: 20)),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              isKo ? '깨비의 꿈풀이' : (isJa ? 'クケビの夢占い' : "Kkaebi's Dream Reading"),
                              style: TextStyle(
                                color: DokkeyTheme.textMain,
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              isKo
                                  ? '어젯밤 꿈의 상징으로 오늘을 읽어보세요'
                                  : (isJa ? '昨夜の夢の象徴で今日を読もう' : 'Read today through your dream symbols'),
                              style: TextStyle(
                                color: DokkeyTheme.textMuted,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(Icons.arrow_forward_ios_rounded, size: 14, color: DokkeyTheme.mintCalm),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

            ],
          ),
        ),
      ),
    ),
      floatingActionButton: const KkaebiFloatingMascot(),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }
}

class _CodexProgressLine extends StatelessWidget {
  final String label;
  final Color color;
  final int value;
  final int total;

  const _CodexProgressLine({
    required this.label,
    required this.color,
    required this.value,
    required this.total,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 52,
          child: Text(
            label,
            style: TextStyle(color: DokkeyTheme.textMuted, fontSize: 11),
          ),
        ),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: value / total,
              minHeight: 5,
              backgroundColor: DokkeyTheme.borderDark,
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          '$value/$total',
          style: TextStyle(
            color: DokkeyTheme.textMain,
            fontSize: 11,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
