import 'kkaebi_chat_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/theme.dart';
import '../models/dokkey_models.dart';
import '../providers/dokkey_provider.dart';
import '../widgets/card_flip_widget.dart';
import '../widgets/dokkaebi_fire_particles.dart';
import '../widgets/rotating_key_home_button.dart';
import '../widgets/share_card_dialog.dart';
import '../widgets/kkaebi_calendar_dialog.dart';

class ResultScreen extends StatelessWidget {
  final DrawResult result;

  const ResultScreen({super.key, required this.result});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<DokkeyProvider>();
    final isKo = provider.lang == 'ko';
    final isJa = provider.lang == 'ja';
    final toneColor = DokkeyTheme.parseHex(result.tone.color);

    return Scaffold(
      appBar: AppBar(
        title: Text(isKo ? '오늘의 잠금 해제' : 'Unlocked Day'),
        actions: [
          IconButton(
            onPressed: () {
              showDialog(
                context: context,
                builder: (_) => ShareCardDialog(result: result),
              );
            },
            icon: Icon(Icons.share_rounded, color: DokkeyTheme.gold),
            tooltip: isKo ? '공유 카드 생성' : 'Share Card',
          ),
          const RotatingKeyHomeButton(),
          const SizedBox(width: 4),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. Interactive 3D Card Art Centerpiece
              Center(
                child: DokkaebiFireParticles(
                  baseColor: toneColor,
                  child: CardFlipWidget(
                    card: result.card,
                    number: result.number,
                    tone: result.tone,
                    initialFront: true,
                    width: 220,
                    height: 330,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Center(
                child: Text(
                  isKo ? '카드를 탭하여 3D로 뒤집어보세요' : 'Tap card to flip in 3D',
                  style: TextStyle(color: DokkeyTheme.textMuted, fontSize: 11),
                ),
              ),
              const SizedBox(height: 24),

              // 2. Core Meta Bar (Tone & Timeslot Tags)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: DokkeyTheme.cardDark,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: toneColor.withOpacity(0.5)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _DetailTag(
                      icon: Icons.palette_outlined,
                      label: '${isKo ? "톤" : "Tone"}: ${result.tone.name}',
                      color: toneColor,
                    ),
                    Container(width: 1, height: 24, color: DokkeyTheme.borderDark),
                    _DetailTag(
                      icon: Icons.schedule_rounded,
                      label: '${result.timeslot.emoji} ${result.timeslot.name} (${result.timeslot.meaningAxis})',
                      color: DokkeyTheme.gold,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // 2.5 Shichen bridge (시辰 브릿지)
              Builder(builder: (context) {
                final shichen = provider.shichen;
                final resonant = provider.isShichenResonant;
                if (shichen['id'] == '') return const SizedBox.shrink();
                final line = isKo
                    ? (resonant
                        ? '지금은 ${shichen['hanja']}시(시辰) — ${result.card.name}의 시간이다. 이건 우연이 아니야!'
                        : '지금은 ${shichen['hanja']}시(시辰), ${result.timeslot.name}의 결이 흐르는 중')
                    : (isJa
                        ? (resonant
                            ? '今は${shichen['hanja']}時(時辰) — ${result.card.name}の時間だ。これは偶然じゃない!'
                            : '今は${shichen['hanja']}時(時辰)、${result.timeslot.name}の流れの中')
                        : (resonant
                            ? 'It is the ${shichen['hanja']} hour — the hour of ${result.card.name}. No coincidence!'
                            : 'The ${shichen['hanja']} hour flows in ${result.timeslot.name} light'));
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: DokkeyTheme.surfaceDark,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: DokkeyTheme.gold.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      const Text('🔭', style: TextStyle(fontSize: 14)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          line,
                          style: TextStyle(
                            color: DokkeyTheme.textMuted,
                            fontSize: 12,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }),
              const SizedBox(height: 16),

              // 3. Headline Card
              Container(
                padding: const EdgeInsets.all(20),
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
                        Icon(Icons.auto_awesome, color: DokkeyTheme.gold, size: 16),
                        const SizedBox(width: 6),
                        Text(
                          isKo ? '깨비의 통찰' : "Kkaebi's Headline",
                          style: TextStyle(
                            color: DokkeyTheme.gold,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.0,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '“${result.headline}”',
                      style: TextStyle(
                        color: DokkeyTheme.textMain,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // 4. Body Interpretation
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: DokkeyTheme.cardDark,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: DokkeyTheme.borderDark),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isKo ? '오늘의 해석' : 'Today’s Reading',
                      style: TextStyle(
                        color: DokkeyTheme.textMuted,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.0,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      result.body,
                      style: TextStyle(
                        color: DokkeyTheme.textMain,
                        fontSize: 15,
                        height: 1.6,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // 5. Action Tip
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: DokkeyTheme.surfaceDark,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: DokkeyTheme.mintCalm.withOpacity(0.5)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('💡', style: TextStyle(fontSize: 18)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isKo ? '오늘의 실천 팁' : 'Actionable Tip',
                            style: TextStyle(
                              color: DokkeyTheme.mintCalm,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            result.tip,
                            style: TextStyle(
                              color: DokkeyTheme.textMain,
                              fontSize: 14,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Fortune Calendar Recorded Indicator
              InkWell(
                onTap: () => KkaebiCalendarDialog.show(context),
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                  decoration: BoxDecoration(
                    color: DokkeyTheme.surfaceDark.withValues(alpha: 0.8),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: DokkeyTheme.gold.withValues(alpha: 0.35)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.calendar_month_rounded, color: DokkeyTheme.gold, size: 16),
                      const SizedBox(width: 8),
                      Text(
                        isKo ? '오늘의 운세가 캘린더에 기록되었습니다 📅' : (isJa ? '今日の運勢がカレンダーに記録されました 📅' : 'Recorded in your Fortune Calendar 📅'),
                        style: TextStyle(color: DokkeyTheme.goldLight, fontSize: 12, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(width: 4),
                      Icon(Icons.chevron_right_rounded, color: DokkeyTheme.goldLight, size: 16),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // 6. Bottom Buttons
                            ElevatedButton.icon(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (_) => ShareCardDialog(result: result),
                  );
                },
                icon: const Icon(Icons.photo_library_outlined, size: 20),
                label: Text(isKo ? '인스타/SNS 공유 카드 만들기' : 'Generate Shareable Card'),
              ),
              // Zero-Friction Kkaebi Quick Ask Chips
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: DokkeyTheme.surfaceDark,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: DokkeyTheme.gold.withOpacity(0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Text('😈', style: TextStyle(fontSize: 14)),
                        const SizedBox(width: 6),
                        Text(
                          isKo ? '깨비에게 바로 물어보기' : (isJa ? 'クケビにすぐ聞く' : 'Quick Ask Kkaebi'),
                          style: TextStyle(
                            color: DokkeyTheme.goldLight,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        ActionChip(
                          avatar: const Text('💰', style: TextStyle(fontSize: 13)),
                          label: Text(
                            isKo ? '로또·행운수 어때?' : (isJa ? 'ロト・幸運の数字は？' : 'Lotto & Numbers?'),
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                          ),
                          backgroundColor: DokkeyTheme.cardDark,
                          side: BorderSide(color: DokkeyTheme.borderDark),
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => const KkaebiChatScreen(initialTopicId: 'lotto'),
                              ),
                            );
                          },
                        ),
                        ActionChip(
                          avatar: const Text('🔮', style: TextStyle(fontSize: 13)),
                          label: Text(
                            isKo ? '오늘의 비장의 팁은?' : (isJa ? '今日の秘訣は？' : 'Secret Advice?'),
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                          ),
                          backgroundColor: DokkeyTheme.cardDark,
                          side: BorderSide(color: DokkeyTheme.borderDark),
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => const KkaebiChatScreen(initialTopicId: 'interview'),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: DokkeyTheme.gold,
                  side: BorderSide(color: DokkeyTheme.gold),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const KkaebiChatScreen()),
                  );
                },
                icon: const Icon(Icons.chat_bubble_outline_rounded, size: 18),
                label: Text(isKo ? '깨비에게 더 물어보기 (1:1 문답)' : (isJa ? 'クケビに相談する (1:1 対話)' : 'Ask Kkaebi More')),
              ),
              const SizedBox(height: 12),
              OutlinedButton(
                style: OutlinedButton.styleFrom(
                  foregroundColor: DokkeyTheme.textMain,
                  side: BorderSide(color: DokkeyTheme.borderDark),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                onPressed: () => Navigator.of(context).pop(),
                child: Text(isKo ? '홈으로 돌아가기' : 'Back to Home'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DetailTag extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _DetailTag({required this.icon, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            color: color,
            fontSize: 13,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}