import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/theme.dart';
import '../core/sound_service.dart';
import '../providers/dokkey_provider.dart';
import '../widgets/kkaebi_face_widget.dart';
import '../widgets/profile_onboarding_sheet.dart';
import '../widgets/rotating_key_home_button.dart';
import '../widgets/kkaebi_affection_dialog.dart';
import 'keybox_screen.dart';

class KkaebiChatScreen extends StatefulWidget {
  final String? initialTopicId;

  const KkaebiChatScreen({super.key, this.initialTopicId});

  @override
  State<KkaebiChatScreen> createState() => _KkaebiChatScreenState();
}

class _KkaebiChatScreenState extends State<KkaebiChatScreen> {
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
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            KkaebiFaceWidget(
              size: 34,
              mode: _isTyping ? KkaebiFaceMode.talking : KkaebiFaceMode.greeting,
              enableGlow: true,
            ),
            const SizedBox(width: 10),
            Text(
              isKo ? '깨비의 속마음 문답' : (isJa ? 'クケビのお悩み相談' : "Talk with Kkaebi"),
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ],
        ),
        actions: [
          // [💖 친밀도 레벨 뱃지]
          GestureDetector(
            onTap: () => KkaebiAffectionDialog.show(context),
            child: Container(
              margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: DokkeyTheme.dokFire.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: DokkeyTheme.gold.withValues(alpha: 0.6)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('💖', style: TextStyle(fontSize: 11)),
                  const SizedBox(width: 4),
                  Text(
                    'Lv.${provider.kkaebiLevel}',
                    style: TextStyle(
                      color: DokkeyTheme.goldLight,
                      fontSize: 11.5,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
          // [🔑 보관함 바로가기]
          IconButton(
            icon: Icon(Icons.inventory_2_rounded, color: DokkeyTheme.goldLight),
            tooltip: isKo ? '보관함 바로가기' : (isJa ? '保管箱へ移動' : 'Go to Vault'),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const KeyBoxScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.badge_outlined),
            tooltip: isKo ? '내 프로필 수정' : (isJa ? 'プロフィール編集' : 'Edit Profile'),
            onPressed: () {
              showDialog(
                context: context,
                builder: (_) => const ProfileOnboardingSheet(),
              );
            },
          ),
          const RotatingKeyHomeButton(),
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
                      children: topics.map((t) {
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
              child: Text(
                msg.text,
                style: TextStyle(
                  color: msg.isUser ? Colors.black : DokkeyTheme.textMain,
                  fontSize: 14,
                  height: 1.45,
                  fontWeight: msg.isUser ? FontWeight.w600 : FontWeight.normal,
                ),
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

  _ChatMessage({required this.isUser, required this.text});
}