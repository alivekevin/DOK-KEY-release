import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/theme.dart';
import '../core/sound_service.dart';
import '../providers/dokkey_provider.dart';
import '../screens/kkaebi_chat_screen.dart';
import 'kkaebi_3d_mascot_widget.dart';
import 'screen_emotion_fx_overlay.dart';

/// 깨비 친밀도 레벨 & 혜택 상세 모달 다이얼로그 (3순위)
class KkaebiAffectionDialog extends StatefulWidget {
  const KkaebiAffectionDialog({super.key});

  static void show(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => const KkaebiAffectionDialog(),
    );
  }

  @override
  State<KkaebiAffectionDialog> createState() => _KkaebiAffectionDialogState();
}

class _KkaebiAffectionDialogState extends State<KkaebiAffectionDialog>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseCtrl;
  late Animation<double> _pulseAnim;
  String? _lastTouchMessage;
  final GlobalKey<Kkaebi3DMascotWidgetState> _mascotKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 0.96, end: 1.04).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOutSine),
    );
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    super.dispose();
  }

  void _onPokeKkaebi() async {
    final provider = context.read<DokkeyProvider>();
    SoundService().playSuccessChime();
    final res = await provider.touchKkaebiMascot();
    if (!mounted) return;
    final isLevelUp = res['level_up'] == true;
    final isDailyMax = res['daily_max'] == true;

    setState(() {
      _lastTouchMessage = res['reaction'] as String?;
    });

    if (isLevelUp) {
      _mascotKey.currentState?.triggerEmotion(
        EmotionType.joy,
        triggerScreenFx: true,
        message: _lastTouchMessage,
      );
    } else if (isDailyMax) {
      _mascotKey.currentState?.triggerEmotion(
        EmotionType.curious,
        triggerScreenFx: false,
        message: _lastTouchMessage,
      );
    } else {
      _mascotKey.currentState?.triggerEmotion(
        EmotionType.shy,
        triggerScreenFx: false,
        message: _lastTouchMessage,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<DokkeyProvider>();
    final isKo = provider.lang == 'ko';
    final isJa = provider.lang == 'ja';
    final isZh = provider.lang == 'zh';
    final isDe = provider.lang == 'de';

    final level = provider.kkaebiLevel;
    final title = provider.kkaebiTitle;
    final subtitle = provider.kkaebiSubtitle;
    final quote = provider.kkaebiQuote;
    final progress = provider.kkaebiLevelProgress;
    final curExp = provider.kkaebiCurrentLevelExp;
    final reqExp = provider.kkaebiNextLevelRequiredExp;
    final totalExp = provider.kkaebiAffectionExp;
    final dailyEarned = provider.dailyAffectionEarned;
    final dailyCap = DokkeyProvider.dailyAffectionCap;

    String headerTitle = isKo
        ? '깨비와의 인연 (친밀도)'
        : (isJa
            ? 'クケビとの縁 (親密度)'
            : (isZh
                ? '与小妖的羁绊 (亲密度)'
                : (isDe ? 'Kkaebi-Zuneigung' : 'Kkaebi Intimacy')));

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 440, maxHeight: 680),
        decoration: BoxDecoration(
          color: DokkeyTheme.bgDark,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: DokkeyTheme.gold.withValues(alpha: 0.6), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: DokkeyTheme.gold.withValues(alpha: 0.2),
              blurRadius: 28,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Column(
          children: [
            // 1. 헤더 바
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: DokkeyTheme.borderDark)),
              ),
              child: Row(
                children: [
                  const Text('💖', style: TextStyle(fontSize: 18)),
                  const SizedBox(width: 8),
                  Text(
                    headerTitle,
                    style: TextStyle(
                      color: DokkeyTheme.gold,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, size: 20, color: Colors.white70),
                    onPressed: () => Navigator.of(context).pop(),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ),

            // 2. 스크롤 본문
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(18),
                child: Column(
                  children: [
                    // 3D 인터랙티브 깨비 마스코트 (수평 360도 턴테이블 회전 & 터치 감정 반응)
                    Container(
                      height: 140,
                      alignment: Alignment.center,
                      child: Kkaebi3DMascotWidget(
                        key: _mascotKey,
                        size: 130,
                        enableInteraction: true,
                        enableAutoFloat: true,
                        showSpeechBubble: false,
                        onTap: _onPokeKkaebi,
                      ),
                    ),
                    const SizedBox(height: 8),

                    // 현재 레벨 뱃지 및 칭호
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            DokkeyTheme.dokFire.withValues(alpha: 0.3),
                            DokkeyTheme.gold.withValues(alpha: 0.3),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: DokkeyTheme.gold, width: 1.2),
                      ),
                      child: Text(
                        'Lv.$level $title',
                        style: TextStyle(
                          color: DokkeyTheme.goldLight,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ),
                    if (subtitle.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: TextStyle(color: DokkeyTheme.textMuted, fontSize: 12),
                        textAlign: TextAlign.center,
                      ),
                    ],
                    const SizedBox(height: 14),

                    // 깨비의 한마디 말풍선
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: DokkeyTheme.cardDark,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: DokkeyTheme.borderDark),
                      ),
                      child: Column(
                        children: [
                          Text(
                            '“${_lastTouchMessage ?? quote}”',
                            style: TextStyle(
                              color: DokkeyTheme.goldLight,
                              fontSize: 13,
                              height: 1.4,
                              fontStyle: FontStyle.italic,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          if (_lastTouchMessage != null) ...[
                            const SizedBox(height: 4),
                            Text(
                              isKo ? '(방금 콕 찌른 깨비의 반응)' : '(Reaction)',
                              style: TextStyle(color: DokkeyTheme.dokFire, fontSize: 10),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // 호감도 게이지 바
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: DokkeyTheme.surfaceDark,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: DokkeyTheme.borderDark),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                isKo ? '호감도 진행 상황' : 'Affection Progress',
                                style: TextStyle(
                                  color: DokkeyTheme.textMain,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12.5,
                                ),
                              ),
                              Text(
                                level >= 5
                                    ? 'MAX (총 $totalExp EXP)'
                                    : '$curExp / $reqExp EXP (총 $totalExp)',
                                style: TextStyle(
                                  color: DokkeyTheme.gold,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 11.5,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: LinearProgressIndicator(
                              value: progress,
                              minHeight: 10,
                              backgroundColor: DokkeyTheme.bgDark,
                              valueColor: AlwaysStoppedAnimation<Color>(DokkeyTheme.gold),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                isKo
                                    ? '오늘 획득: $dailyEarned / $dailyCap EXP'
                                    : 'Today: $dailyEarned / $dailyCap EXP',
                                style: TextStyle(color: DokkeyTheme.textMuted, fontSize: 11),
                              ),
                              Text(
                                isKo
                                    ? '매일 운세·대화·퀴즈로 획득'
                                    : 'Earn via Draws & Chats',
                                style: TextStyle(color: DokkeyTheme.textMuted, fontSize: 10.5),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),

                    // 5단계 레벨별 혜택 로드맵
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        isKo ? '📜 레벨별 혜택 및 해금' : 'Perks & Milestones',
                        style: TextStyle(
                          color: DokkeyTheme.goldLight,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    ...List.generate(5, (idx) {
                      final lvl = idx + 1;
                      final isUnlocked = level >= lvl;
                      final isCurrent = level == lvl;
                      final lvlData = provider.engine.getAffectionLevelData(provider.lang, lvl);
                      final lvlTitle = lvlData['title'] as String? ?? 'Lv.$lvl';
                      final perks = (lvlData['perks'] as List<dynamic>? ?? []).map((e) => e.toString()).toList();

                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: isCurrent
                              ? DokkeyTheme.gold.withValues(alpha: 0.12)
                              : (isUnlocked ? DokkeyTheme.cardDark : DokkeyTheme.bgDark),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isCurrent
                                ? DokkeyTheme.gold
                                : (isUnlocked ? DokkeyTheme.borderDark : DokkeyTheme.borderDark.withValues(alpha: 0.4)),
                            width: isCurrent ? 1.4 : 1.0,
                          ),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: isUnlocked ? DokkeyTheme.gold : DokkeyTheme.surfaceDark,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                'Lv.$lvl',
                                style: TextStyle(
                                  color: isUnlocked ? DokkeyTheme.bgDark : DokkeyTheme.textMuted,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Text(
                                        lvlTitle,
                                        style: TextStyle(
                                          color: isUnlocked ? DokkeyTheme.textMain : DokkeyTheme.textMuted,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12.5,
                                        ),
                                      ),
                                      if (isCurrent) ...[
                                        const SizedBox(width: 6),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                                          decoration: BoxDecoration(
                                            color: DokkeyTheme.dokFire,
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                          child: Text(
                                            isKo ? '현재 단계' : 'Current',
                                            style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                  const SizedBox(height: 3),
                                  ...perks.map((p) => Text(
                                    '• $p',
                                    style: TextStyle(
                                      color: isUnlocked ? DokkeyTheme.textMuted : DokkeyTheme.textMuted.withValues(alpha: 0.5),
                                      fontSize: 11,
                                    ),
                                  )),
                                ],
                              ),
                            ),
                            Icon(
                              isUnlocked ? Icons.check_circle_rounded : Icons.lock_outline_rounded,
                              size: 16,
                              color: isUnlocked ? DokkeyTheme.gold : DokkeyTheme.textMuted.withValues(alpha: 0.4),
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ),

            // 3. 하단 액션 버튼 바
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: DokkeyTheme.surfaceDark,
                border: Border(top: BorderSide(color: DokkeyTheme.borderDark)),
                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(24)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: DokkeyTheme.dokFire,
                        side: BorderSide(color: DokkeyTheme.dokFire.withValues(alpha: 0.6)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: _onPokeKkaebi,
                      icon: const Text('👉', style: TextStyle(fontSize: 15)),
                      label: Text(
                        isKo ? '깨비 콕 찌르기' : 'Poke Kkaebi',
                        style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: DokkeyTheme.gold,
                        foregroundColor: DokkeyTheme.bgDark,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () {
                        Navigator.of(context).pop();
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const KkaebiChatScreen()),
                        );
                      },
                      icon: const Icon(Icons.chat_bubble_outline_rounded, size: 16),
                      label: Text(
                        isKo ? '대화방 가기' : 'Talk with Kkaebi',
                        style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
