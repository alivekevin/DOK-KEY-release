import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../core/theme.dart';
import '../core/sound_service.dart';
import '../games/kkaebi_arcade_hub.dart';
import '../games/kkaebi_breakout_game.dart';
import '../games/kkaebi_bubble_game.dart';
import '../games/kkaebi_cave_game.dart';
import '../games/kkaebi_jungle_game.dart';
import '../games/kkaebi_magic_square_game.dart';
import '../games/kkaebi_minesweeper_game.dart';
import '../games/kkaebi_shooter_game.dart';
import '../games/kkaebi_sudoku_game.dart';
import '../games/kkaebi_tetris_game.dart';
import '../games/kkaebi_trivia_game.dart';
import '../games/kkaebi_xsudoku_game.dart';
import '../games/kkaebi_cross_magicsquare_game.dart';
import '../games/kkaebi_hex_minesweeper_game.dart';
import '../games/kkaebi_jigsaw_game.dart';
import '../providers/dokkey_provider.dart';
import '../widgets/kkaebi_face_widget.dart';
import '../widgets/profile_onboarding_sheet.dart';
import '../widgets/rotating_key_home_button.dart';
import '../widgets/kkaebi_affection_dialog.dart';
import '../widgets/kkaebi_lore_help_dialog.dart';
import 'keybox_screen.dart';

class KkaebiChatScreen extends StatefulWidget {
  final String? initialTopicId;

  const KkaebiChatScreen({super.key, this.initialTopicId});

  @override
  State<KkaebiChatScreen> createState() => _KkaebiChatScreenState();
}

class _KkaebiChatScreenState extends State<KkaebiChatScreen> {
  int _gameSuggestStep = 0;

  void _onDirectQuizPressed() {
    HapticFeedback.selectionClick();
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const KkaebiTriviaGame()),
    );
  }

  void _onAskLoreHelp() async {
    if (_isTyping) return;
    final provider = context.read<DokkeyProvider>();
    final isKo = provider.lang == 'ko';
    final isJa = provider.lang == 'ja';

    setState(() {
      _messages.add(_ChatMessage(
        isUser: true,
        text: isKo
            ? '깨비야, 넌 누구고 DOK-KEY는 어떤 앱이야?'
            : (isJa ? 'クケビ、君は誰でDOK-KEYってどんなアプリ？' : 'Kkaebi, who are you and what is DOK-KEY?'),
      ));
      _isTyping = true;
    });
    _scrollToBottom();

    await Future.delayed(const Duration(milliseconds: 600));
    if (!mounted) return;

    SoundService().playSuccessChime();

    final response = isKo
        ? '내가 누구냐고? 푸하하! 나는 한국 설화 속에서 천 년 동안 사람들의 소원과 고민을 지켜봐 온 시간과 문의 수호 도깨비, "깨비"란다! ✨\n\n'
          '도깨비의 \'독(DOK)\'과 행운을 여는 \'열쇠(KEY)\'가 만나 네 일상을 지키는 DOK-KEY가 탄생했지! 내 이야기와 앱 가이드북을 자세히 볼래?'
        : (isJa
            ? '僕が誰かって？ふふっ！僕は韓国の説話からやってきた守護トッケビ「クケビ」だよ！✨\n\n'
              'トッケビの「DOK」と幸運を開く「KEY」が融合してDOK-KEYが誕生したんだ！詳しい物語とガイドを見てみる？'
            : 'Who am I? Haha! I am "Kkaebi", the guardian Dokkaebi from Korean folklore who has watched over people’s hopes and dreams for a thousand years! ✨\n\n'
              'Combining “DOK” (Dokkaebi) and “KEY” (unlocking your day), DOK-KEY was born! Would you like to read my story & the full app guide?');

    final actionLabel = isKo
        ? '📖 깨비 이야기 & 가이드북 열기'
        : (isJa ? '📖 クケビ物語 ＆ ガイドを見る' : '📖 Open Lore & Guidebook');

    setState(() {
      _isTyping = false;
      _messages.add(_ChatMessage(
        isUser: false,
        text: response,
        actionLabel: actionLabel,
        onAction: () => KkaebiLoreHelpDialog.show(context),
      ));
    });
    _scrollToBottom();
  }

  void _onAskGameSuggestion() async {
    if (_isTyping) return;
    final step = _gameSuggestStep++;

    setState(() {
      _messages.add(_ChatMessage(
        isUser: true,
        text: '게임해볼까?',
      ));
      _isTyping = true;
    });
    _scrollToBottom();

    await Future.delayed(const Duration(milliseconds: 550));
    if (!mounted) return;

    SoundService().playSuccessChime();

    final (kkaebiMsg, btnLabel, onPlay) = _getGameSuggestion(step % 14);

    setState(() {
      _isTyping = false;
      _messages.add(_ChatMessage(
        isUser: false,
        text: kkaebiMsg,
        actionLabel: btnLabel,
        onAction: onPlay,
      ));
    });
    _scrollToBottom();
  }

  (String, String, VoidCallback) _getGameSuggestion(int index) {
    switch (index) {
      case 0:
        return (
          '좋아! 이건 오락실에도 없는 비밀 서당의 그림 맞추기 퍼즐인데... 도감 신수·신격 카드의 조각을 맞춰볼래? 🧩✨',
          '🧩 신수 도감 직소 퍼즐',
          () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const KkaebiJigsawGame()),
              ),
        );
      case 1:
        return (
          '그럼, 스도쿠 게임은 어때? 4x4부터 9x9까지 숫자 퍼즐로 뇌를 깨워보자구! 🔢',
          '🔢 깨비 스도쿠 하러가기',
          () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const KkaebiSudokuGame()),
              ),
        );
      case 2:
        return (
          '그럼, 마방진 게임은 어때? 가로·세로·대각선 합을 맞추는 신비한 마법진 퍼즐이야! 🧮',
          '🧮 깨비 마방진 하러가기',
          () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const KkaebiMagicSquareGame()),
              ),
        );
      case 3:
        return (
          '그럼, 지뢰찾기는 어때? 도깨비 함정을 쏙쏙 피해서 부적 깃발을 꽂아봐! 💣',
          '💣 깨비 지뢰찾기 하러가기',
          () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const KkaebiMinesweeperGame()),
              ),
        );
      case 4:
        return (
          '그럼, 대각선 X-스도쿠는 어때? 두 대각선까지 겹치지 않아야 하는 인기 두뇌 챌린지야! 🔢✨',
          '🔢 X-스도쿠 하러가기',
          () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const KkaebiXSudokuGame()),
              ),
        );
      case 5:
        return (
          '그럼, 음양 크로스 마방진은 어때? 십자와 대각선이 교차하는 신비한 마법진이야! ☯️',
          '☯️ 크로스 마방진 하러가기',
          () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const KkaebiCrossMagicSquareGame()),
              ),
        );
      case 6:
        return (
          '그럼, 육각 벌집 지뢰찾기는 어때? 6방향 벌집 레이더로 함정을 간파해봐! ⬡💣',
          '⬡ 육각 지뢰찾기 하러가기',
          () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const KkaebiHexMinesweeperGame()),
              ),
        );
      case 7:
        return (
          '그럼, 테트리스는 어때? 떨어지는 블록들을 싹 정리해보자구! 🧱',
          '🧱 깨비 테트리스 하러가기',
          () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const KkaebiTetrisGame()),
              ),
        );
      case 8:
        return (
          '그럼, 벽돌깨기는 어때? 시원하게 공을 튕겨서 3D 벽돌을 박살내보자! 💥',
          '💥 깨비 벽돌깨기 하러가기',
          () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const KkaebiBreakoutGame()),
              ),
        );
      case 9:
        return (
          '그럼, 깨비 뽀글뽀글은 어때? 방울을 쏴서 몬스터를 가두고 터뜨려봐! 🫧',
          '🫧 깨비 뽀글뽀글 하러가기',
          () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const KkaebiBubbleGame()),
              ),
        );
      case 10:
        return (
          '그럼, 깨비 X-RION 슈팅은 어때? 트윈 레이저와 폭탄으로 우주를 정복해봐! 🚀',
          '🚀 깨비 X-RION 하러가기',
          () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const KkaebiShooterGame()),
              ),
        );
      case 11:
        return (
          '그럼, 깨비 고대유적은 어때? 은/금 열쇠를 찾고 굴러오는 거대 바위를 피해봐! 🏛️',
          '🏛️ 깨비 고대유적 하러가기',
          () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const KkaebiJungleGame()),
              ),
        );
      case 12:
        return (
          '그럼, 깨비 윈드서퍼는 어때? 파도를 타고 더블 점프와 공중 스턴트 트릭을 펼쳐봐! 🏄',
          '🏄 깨비 윈드서퍼 하러가기',
          () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const KkaebiCaveGame()),
              ),
        );
      default:
        return (
          '오락실에 있는 모든 명작 게임들을 전부 둘러볼래? 🕹️✨',
          '🕹️ 깨비 오락실 허브 열기',
          () => KkaebiArcadeHubDialog.show(context),
        );
    }
  }

  final List<_ChatMessage> _messages = [];
  final ScrollController _scrollCtrl = ScrollController();
  final Map<String, int> _topicStepCounts = {};
  bool _isTyping = false;

  @override
  void initState() {
    super.initState();
    // Initial Greeting from Kkaebi
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final provider = context.read<DokkeyProvider>();
      final isJa = provider.lang == 'ja';
      final isKo = provider.lang == 'ko';

      // Check if newly leveled up
      if (provider.pendingAffectionLevelUp != null) {
        final upLvl = provider.pendingAffectionLevelUp!;
        final lvlTitle = provider.kkaebiTitle;
        final levelUpText = isKo
            ? '🎉 뚝딱! 우리 인연이 깊어져서 [Lv.$upLvl $lvlTitle]로 레벨업했느니라! 앞으로도 내 복을 듬뿍 받아가거라! 💖✨'
            : (isJa
                ? '🎉 やったな！オレたちの絆が深まって【Lv.$upLvl $lvlTitle】にレベルアップしたぞ！これからもよろしくな！💖✨'
                : '🎉 Hooray! Our bond has deepened to [Lv.$upLvl $lvlTitle]! May great fortune be yours! 💖✨');
        provider.clearPendingAffectionLevelUp();
        setState(() {
          _messages.add(_ChatMessage(isUser: false, text: levelUpText));
        });
      }

      // Zero-Delay 맥락 인사(시간대 × 방문이력 × 닉네임) 우선, 없으면 기본 인사
      String welcome = provider.greeting.isNotEmpty
          ? provider.greeting
          : '안녕! 나는 천 년 묵은 도깨비 깨비다! 오늘 하루에 대해 궁금한 게 있느냐? 무엇이든 물어보거라! 😈✨';
      if (provider.greeting.isEmpty) {
        if (isJa) {
          welcome = 'やあ！オレは千年生きたトッケビのクケビだ！今日の一日について気になることがあるかい？何でも聞いてみな！😈✨';
        } else if (provider.lang == 'en') {
          welcome = "Greetings! I'm Kkaebi, the thousand-year-old goblin! Curious about your day? Ask me anything! 😈✨";
        }
      }

      setState(() {
        // v4.7.0 Wisdom-First (A7): 명언 + 깨비의 한마디로 대화방 개시
        final quote = provider.todayQuote;
        if (quote != null) {
          final isKoQ = provider.lang == 'ko';
          final isJaQ = provider.lang == 'ja';
          final quoteHeader = isKoQ
              ? '📜 오늘의 명언'
              : (isJaQ ? '📜 今日の名言' : "📜 Today's Quote");
          final commentLabel = isKoQ ? '깨비의 한마디' : (isJaQ ? 'クケビの一言' : "Kkaebi says");
          final quoteText = quote.hasKkaebiComment
              ? '$quoteHeader\n"${quote.text}"\n\n💬 $commentLabel: ${quote.kkaebiComment}'
              : '$quoteHeader\n"${quote.text}"';
          _messages.add(_ChatMessage(isUser: false, text: quoteText));
        }
        _messages.add(_ChatMessage(isUser: false, text: welcome));
      });

      // 1-Tap 숏컷: initialTopicId가 전달되었을 때 즉시 첫 질문 실행
      if (widget.initialTopicId != null) {
        final topics = provider.getKkaebiTopics();
        final match = topics.firstWhere(
          (t) => t['id'] == widget.initialTopicId,
          orElse: () => topics.isNotEmpty ? topics.first : <String, dynamic>{},
        );
        if (match.isNotEmpty) {
          await Future.delayed(const Duration(milliseconds: 300));
          if (mounted) _onTopicSelected(match);
        }
      }
    });
  }

  void _onTopicSelected(Map<String, dynamic> topic) async {
    if (_isTyping) return;

    final topicId = topic['id'] as String;
    final currentStep = (_topicStepCounts[topicId] ?? 0) + 1;
    _topicStepCounts[topicId] = currentStep;

    final provider = context.read<DokkeyProvider>();
    final isKo = provider.lang == 'ko';
    final isJa = provider.lang == 'ja';

    // Progressive User Questions based on step count
    String userQ;
    if (currentStep == 1) {
      userQ = topic['user_question'] as String? ?? topic['chip_title'] as String;
    } else if (currentStep == 2) {
      userQ = isKo
          ? '깨비야, 정말 그게 다야? 더 솔직하게 말해줘!'
          : (isJa ? 'クケビ、本当にそれだけ？もっと本音を教えて！' : 'Kkaebi, is that really all? Tell me the honest truth!');
    } else if (currentStep == 3) {
      userQ = isKo
          ? '오늘 내 운세의 숨겨진 비장의 비법은 뭐야?'
          : (isJa ? '今日の運勢に隠された特別な秘訣は何？' : 'What is the secret advice hidden in my fortune?');
    } else if (currentStep == 4) {
      userQ = isKo
          ? '나 아직 조금 불안해... 한 번만 더 팁을 줘!'
          : (isJa ? 'まだ少し不安なんだ... もう一言アドバイスを！' : 'I still feel uncertain... give me one more tip!');
    } else if (currentStep == 5) {
      userQ = isKo
          ? '깨비의 마지막 결론과 확신의 조언을 듣고 싶어!'
          : (isJa ? 'クケビの最後の結論と確信の言葉を聞かせて！' : 'I want to hear your final conclusion, Kkaebi!');
    } else {
      userQ = isKo
          ? '깨비야, 한 번만 더 알려주라! 제발~'
          : (isJa ? 'クケビ、もう一回だけ教えて！頼むよ〜' : 'Kkaebi, tell me just one more time, please!');
    }

    setState(() {
      _messages.add(_ChatMessage(isUser: true, text: userQ));
      _isTyping = true;
    });
    _scrollToBottom();

    // Simulated thinking delay
    await Future.delayed(const Duration(milliseconds: 650));

    if (!mounted) return;
    final answer = provider.getKkaebiAnswer(topicId, currentStep);

    SoundService().playSuccessChime();

    setState(() {
      _isTyping = false;
      _messages.add(_ChatMessage(isUser: false, text: answer));
    });
    _scrollToBottom();

    // 친밀도 경험치 획득
    await provider.addKkaebiAffection(10, reason: 'chat');

    // 🌟 오늘 너무 지쳤어(healing) 5단계 완료 시 특별 감성 위로 & 보너스 보상
    if (topicId == 'healing' && currentStep == 5) {
      await provider.addKkaebiAffection(30, reason: 'healing_comfort');
      await provider.addBonusKeys(1);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: const Color(0xFF2A1C0A),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
              side: const BorderSide(color: Color(0xFFFFD54F), width: 1.5),
            ),
            content: Row(
              children: [
                const Text('🌟', style: TextStyle(fontSize: 18)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    isKo
                        ? '깨비의 따뜻한 위로! 친밀도 +30 & 보너스 황금 열쇠 1개 획득 🔑'
                        : (isJa
                            ? 'クケビの温かい慰め！親密度 +30 & ボーナス鍵 +1 獲得 🔑'
                            : "Kkaebi's warm comfort! Affection +30 & Bonus Key +1 earned 🔑"),
                    style: const TextStyle(color: Color(0xFFFFE082), fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                ),
              ],
            ),
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<DokkeyProvider>();
    final isKo = provider.lang == 'ko';
    final isJa = provider.lang == 'ja';
    final topics = provider.getKkaebiTopics();
    final today = provider.todayResult;

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: Row(
          children: [
            const SizedBox(width: 4),
            KkaebiFaceWidget(
              size: 32,
              mode: _isTyping ? KkaebiFaceMode.talking : KkaebiFaceMode.greeting,
              enableGlow: true,
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                isKo ? '깨비의 속마음 문답' : (isJa ? 'クケビのお悩み相談' : "Talk with Kkaebi"),
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        actions: [
          // [💖 친밀도 레벨 뱃지]
          GestureDetector(
            onTap: () => KkaebiAffectionDialog.show(context),
            child: Container(
              margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 2),
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3.5),
              decoration: BoxDecoration(
                color: DokkeyTheme.dokFire.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: DokkeyTheme.gold.withValues(alpha: 0.6)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('💖', style: TextStyle(fontSize: 11)),
                  const SizedBox(width: 3),
                  Text(
                    'Lv.${provider.kkaebiLevel}',
                    style: TextStyle(
                      color: DokkeyTheme.goldLight,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
          // [📖 깨비 이야기 & DOK-KEY 도움말]
          IconButton(
            icon: Icon(Icons.help_outline_rounded, color: DokkeyTheme.goldLight, size: 22),
            tooltip: isKo ? '깨비 이야기 & 도움말' : (isJa ? '物語＆ヘルプ' : 'Lore & Guide'),
            onPressed: () => KkaebiLoreHelpDialog.show(context),
            constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
            padding: const EdgeInsets.all(6),
          ),
          // [🔑 보관함 바로가기]
          IconButton(
            icon: Icon(Icons.inventory_2_rounded, color: DokkeyTheme.goldLight, size: 22),
            tooltip: isKo ? '보관함 바로가기' : (isJa ? '保管箱へ移動' : 'Go to Vault'),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const KeyBoxScreen()),
              );
            },
            constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
            padding: const EdgeInsets.all(6),
          ),
          // [⋮ 더보기 메뉴 (프로필 수정 / 홈 이동)]
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert_rounded, color: Colors.white70, size: 22),
            tooltip: isKo ? '더보기' : 'More',
            color: DokkeyTheme.surfaceDark,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
              side: BorderSide(color: DokkeyTheme.borderDark),
            ),
            onSelected: (val) {
              if (val == 'profile') {
                showDialog(
                  context: context,
                  builder: (_) => const ProfileOnboardingSheet(),
                );
              } else if (val == 'home') {
                Navigator.of(context).popUntil((route) => route.isFirst);
              }
            },
            itemBuilder: (ctx) => [
              PopupMenuItem(
                value: 'profile',
                child: Row(
                  children: [
                    const Icon(Icons.badge_outlined, size: 18, color: Colors.white70),
                    const SizedBox(width: 10),
                    Text(
                      isKo ? '내 프로필 수정' : (isJa ? 'プロフィール編集' : 'Edit Profile'),
                      style: const TextStyle(fontSize: 13, color: Colors.white),
                    ),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'home',
                child: Row(
                  children: [
                    Icon(Icons.home_rounded, size: 18, color: DokkeyTheme.goldLight),
                    const SizedBox(width: 10),
                    Text(
                      isKo ? '홈으로 돌아가기' : (isJa ? 'ホームに戻る' : 'Go Home'),
                      style: const TextStyle(fontSize: 13, color: Colors.white),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: Column(
        children: [
          // Top Mini Meta Bar (Today's Fortune Card)
          if (today != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              color: DokkeyTheme.surfaceDark,
              child: Row(
                children: [
                  Icon(Icons.auto_awesome, color: DokkeyTheme.gold, size: 16),
                  const SizedBox(width: 8),
                  Text(
                    isKo ? '오늘의 수호 카드:' : (isJa ? '今日の守護カード:' : "Today's Card:"),
                    style: TextStyle(color: DokkeyTheme.textMuted, fontSize: 12),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '${today.card.name} (#${today.number.toString().padLeft(2, '0')})',
                    style: TextStyle(color: DokkeyTheme.goldLight, fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: DokkeyTheme.parseHex(today.tone.color).withOpacity(0.2),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      today.tone.name,
                      style: TextStyle(
                        color: DokkeyTheme.parseHex(today.tone.color),
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),

          // Message List
          Expanded(
            child: ListView.builder(
              controller: _scrollCtrl,
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length + (_isTyping ? 1 : 0),
              itemBuilder: (ctx, idx) {
                if (idx == _messages.length && _isTyping) {
                  return _buildTypingIndicator();
                }
                final msg = _messages[idx];
                return _buildMessageBubble(msg);
              },
            ),
          ),

          // Bottom Quick Questions Bar
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
            decoration: BoxDecoration(
              color: DokkeyTheme.cardDark,
              border: Border(top: BorderSide(color: DokkeyTheme.borderDark)),
            ),
            child: SafeArea(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(left: 6, bottom: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          isKo ? '깨비에게 물어보기 (연속 대화 가능):' : (isJa ? 'クケビに質問する (連続対話可能):' : 'Ask Kkaebi:'),
                          style: TextStyle(color: DokkeyTheme.gold, fontSize: 11, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          isKo ? '5단계 티키타카' : (isJa ? '5段階ストーリー' : '5-Step Story'),
                          style: TextStyle(color: DokkeyTheme.textMuted, fontSize: 10),
                        ),
                      ],
                    ),
                  ),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        // 1순위: [❓ 상식/과학 퀴즈] — 1-Tap 즉시 상식/과학 퀴즈 게임 구동
                        Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ActionChip(
                            backgroundColor: const Color(0xFF003D45),
                            side: const BorderSide(
                              color: Color(0xFF00E5FF),
                              width: 1.4,
                            ),
                            label: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Text('❓', style: TextStyle(fontSize: 13)),
                                const SizedBox(width: 5),
                                Text(
                                  isKo ? '상식/과학 퀴즈' : (isJa ? '常識・科学クイズ' : 'Trivia Quiz'),
                                  style: const TextStyle(
                                    color: Color(0xFF00E5FF),
                                    fontSize: 12,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ],
                            ),
                            onPressed: _isTyping ? null : _onDirectQuizPressed,
                          ),
                        ),

                        // 2순위: [🕹️ 게임해볼까?] — 깨비 대화형 순환 추천 & 인라인 플레이 액션 (도깨비불 네온 테마)
                        Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ActionChip(
                            backgroundColor: const Color(0xFF281845),
                            side: const BorderSide(
                              color: Color(0xFFB388FF),
                              width: 1.4,
                            ),
                            label: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Text('🕹️', style: TextStyle(fontSize: 13)),
                                const SizedBox(width: 5),
                                Text(
                                  isKo ? '게임해볼까?' : (isJa ? 'ゲームしようか?' : 'Play Games?'),
                                  style: const TextStyle(
                                    color: Color(0xFFE040FB),
                                    fontSize: 12,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ],
                            ),
                            onPressed: _isTyping ? null : _onAskGameSuggestion,
                          ),
                        ),

                        // 기존 운세/고민 대화 주제 칩들
                        ...topics.map((t) {
                        final topicId = t['id'] as String;
                        final count = _topicStepCounts[topicId] ?? 0;
                        final isExhausted = count >= 5;

                        String stepBadge = '';
                        if (count > 0 && count < 5) {
                          stepBadge = ' (${count + 1}/5)';
                        } else if (isExhausted) {
                          stepBadge = ' (완료)';
                        }

                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ActionChip(
                            backgroundColor: isExhausted ? DokkeyTheme.surfaceDark.withOpacity(0.5) : DokkeyTheme.surfaceDark,
                            side: BorderSide(
                              color: isExhausted ? DokkeyTheme.borderDark : DokkeyTheme.gold,
                              width: 1,
                            ),
                            label: Text(
                              '${t['chip_title']}$stepBadge',
                              style: TextStyle(
                                color: isExhausted ? DokkeyTheme.textMuted : DokkeyTheme.textMain,
                                fontSize: 12,
                                fontWeight: isExhausted ? FontWeight.normal : FontWeight.w600,
                              ),
                            ),
                            onPressed: _isTyping ? null : () => _onTopicSelected(t),
                          ),
                        );
                      }).toList(),

                      // 신설: [📖 깨비는 누구? & 도움말] — 도깨비 유래, 세계관 & DOK-KEY 완벽 가이드북
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ActionChip(
                          backgroundColor: const Color(0xFF1B2338),
                          side: BorderSide(
                            color: DokkeyTheme.goldLight.withValues(alpha: 0.85),
                            width: 1.4,
                          ),
                          label: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Text('📖', style: TextStyle(fontSize: 13)),
                              const SizedBox(width: 5),
                              Text(
                                isKo ? '깨비는 누구? & 도움말' : (isJa ? 'クケビとは？＆ヘルプ' : 'Who is Kkaebi? & Help'),
                                style: TextStyle(
                                  color: DokkeyTheme.goldLight,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          onPressed: _isTyping ? null : _onAskLoreHelp,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(_ChatMessage msg) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: msg.isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!msg.isUser) ...[
            Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: DokkeyTheme.dokFire.withOpacity(0.15),
                border: Border.all(color: DokkeyTheme.gold.withOpacity(0.5), width: 1.2),
              ),
              child: const KkaebiFaceWidget(size: 34, mode: KkaebiFaceMode.greeting),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: msg.isUser ? DokkeyTheme.gold : DokkeyTheme.cardDark,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(18),
                  topRight: const Radius.circular(18),
                  bottomLeft: Radius.circular(msg.isUser ? 18 : 4),
                  bottomRight: Radius.circular(msg.isUser ? 4 : 18),
                ),
                border: Border.all(
                  color: msg.isUser ? DokkeyTheme.gold : DokkeyTheme.borderDark,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    msg.text,
                    style: TextStyle(
                      color: msg.isUser ? Colors.black : DokkeyTheme.textMain,
                      fontSize: 14,
                      height: 1.45,
                      fontWeight: msg.isUser ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                  if (msg.actionLabel != null && msg.onAction != null) ...[
                    const SizedBox(height: 10),
                    ElevatedButton.icon(
                      onPressed: () {
                        HapticFeedback.selectionClick();
                        msg.onAction!();
                      },
                      icon: const Icon(Icons.play_arrow_rounded, size: 16, color: Colors.black87),
                      label: Text(
                        msg.actionLabel!,
                        style: const TextStyle(
                          color: Colors.black87,
                          fontWeight: FontWeight.w900,
                          fontSize: 13,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: DokkeyTheme.gold,
                        foregroundColor: Colors.black87,
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: DokkeyTheme.dokFire.withOpacity(0.15),
              border: Border.all(color: DokkeyTheme.gold.withOpacity(0.5), width: 1.2),
            ),
            child: const KkaebiFaceWidget(size: 34, mode: KkaebiFaceMode.talking),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: DokkeyTheme.cardDark,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: DokkeyTheme.borderDark),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '깨비가 방망이를 고르는 중...',
                  style: TextStyle(color: DokkeyTheme.gold, fontSize: 12, fontStyle: FontStyle.italic),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ChatMessage {
  final bool isUser;
  final String text;
  final String? actionLabel;
  final VoidCallback? onAction;

  _ChatMessage({
    required this.isUser,
    required this.text,
    this.actionLabel,
    this.onAction,
  });
}