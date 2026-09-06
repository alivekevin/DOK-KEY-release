import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/daily_quote_engine.dart';
import '../core/sound_service.dart';
import '../core/theme.dart';
import '../models/dokkey_models.dart';
import '../providers/dokkey_provider.dart';
import 'kkaebi_3d_mascot_widget.dart';
import 'quote_poster_dialog.dart';
import 'screen_emotion_fx_overlay.dart';

/// 📜 1순위 히어로 섹션 (v4.7.0 Wisdom-First)
/// 오늘의 명언 + 3D 턴테이블 깨비 + 감정 매칭 FX + 깨비의 한마디 + 액션 3종.
class QuoteHeroSection extends StatelessWidget {
  const QuoteHeroSection({super.key});

  static const List<(String, EmotionType, String)> _showcase = [
    (' rage ', EmotionType.rage, '💢 분노'),
    (' joy ', EmotionType.joy, '✨ 환희'),
    (' normal ', EmotionType.normal, '❄️ 침착'),
    (' shock ', EmotionType.shock, '👻 경악'),
    (' curious ', EmotionType.curious, '🌀 궁금'),
    (' sad ', EmotionType.sad, '💧 슬픔'),
    (' shy ', EmotionType.shy, '💖 설렘'),
    (' fire ', EmotionType.fire, '⚡ 각성'),
  ];

  void _playFx(BuildContext context, EmotionType emotion) {
    ScreenEmotionFxOverlay.show(context, emotion);
    final sound = SoundService();
    switch (emotion) {
      case EmotionType.rage:
      case EmotionType.fire:
        sound.playGong();
        break;
      case EmotionType.joy:
        sound.playCoinJangle();
        break;
      case EmotionType.shy:
      case EmotionType.normal:
        sound.playSuccessChime();
        break;
      case EmotionType.sad:
      case EmotionType.curious:
      case EmotionType.shock:
        sound.playRiddleWrong();
        break;
    }
  }

  void _showEmotionShowcase(BuildContext context) {
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
                  Icon(Icons.theater_comedy_rounded, color: DokkeyTheme.gold, size: 20),
                  SizedBox(width: 8),
                  Text(
                    '깨비 감정 쇼케이스 (8대 감정)',
                    style: TextStyle(
                      color: DokkeyTheme.goldLight,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _showcase.map((e) {
                  return OutlinedButton(
                    onPressed: () {
                      Navigator.of(sheetCtx).pop();
                      _playFx(context, e.$2);
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: DokkeyTheme.goldLight,
                      side: BorderSide(color: DokkeyTheme.gold),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    ),
                    child: Text(e.$3, style: const TextStyle(fontSize: 12.5)),
                  );
                }).toList(),
              ),
              const SizedBox(height: 8),
              Center(
                child: Text(
                  '버튼을 누르면 화면 전체가 반응하는 풀스크린 FX를 재생합니다',
                  style: TextStyle(color: DokkeyTheme.textMuted, fontSize: 10.5),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<DokkeyProvider>();
    final quote = provider.todayQuote;
    if (quote == null) return const SizedBox.shrink();

    final fxKey = DailyQuoteEngine.fxEmotionOf(quote);
    final fxEmotion = EmotionType.values.firstWhere(
      (e) => e.name == fxKey,
      orElse: () => EmotionType.normal,
    );
    final isBookmarked = provider.bookmarkedQuoteIds.contains(quote.id);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF2A2214), DokkeyTheme.cardDark, DokkeyTheme.cardDark],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: DokkeyTheme.gold.withOpacity(0.7), width: 1.8),
        boxShadow: [
          BoxShadow(color: DokkeyTheme.gold.withOpacity(0.18), blurRadius: 24, spreadRadius: 2),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header row: badge + showcase button
          Row(
            children: [
              Icon(Icons.auto_stories_rounded, color: DokkeyTheme.gold, size: 18),
              const SizedBox(width: 6),
              Text(
                provider.lang == 'ko'
                    ? '오늘의 명언'
                    : (provider.lang == 'ja' ? '今日の名言' : (provider.lang == 'zh' ? '今日名言' : (provider.lang == 'hi' ? 'आज का सुवचन' : (provider.lang == 'de' ? 'Tageszitat' : "Today's Quote")))),
                style: TextStyle(
                  color: DokkeyTheme.gold,
                  fontWeight: FontWeight.w900,
                  fontSize: 13,
                  letterSpacing: 1.0,
                ),
              ),
              const Spacer(),
              // 감정 배지 (탭 → 풀스크린 FX)
              GestureDetector(
                onTap: () => _playFx(context, fxEmotion),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: DokkeyTheme.dokFire.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: DokkeyTheme.dokFire.withOpacity(0.5)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.bolt_rounded, size: 12, color: DokkeyTheme.dokFire),
                      const SizedBox(width: 3),
                      Text(
                        quote.emotion,
                        style: TextStyle(
                          color: DokkeyTheme.dokFire,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // 감정 쇼케이스 버튼 (8대 감정 원클릭 패널)
              GestureDetector(
                onTap: () => _showEmotionShowcase(context),
                child: Padding(
                  padding: const EdgeInsets.only(left: 6),
                  child: Icon(Icons.theater_comedy_rounded,
                      size: 18, color: DokkeyTheme.textMuted),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Quote body
          Text(
            '"${quote.text}"',
            style: TextStyle(
              color: DokkeyTheme.textMain,
              fontSize: 16.5,
              height: 1.55,
              fontWeight: FontWeight.w600,
              fontStyle: FontStyle.italic,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '- ${quote.authorLabel}${quote.source.trim().isNotEmpty ? " <${quote.source}>" : ""}',
            style: TextStyle(color: DokkeyTheme.goldLight, fontSize: 12),
          ),
          const SizedBox(height: 12),

          // 3D turntable Kkaebi + speech bubble (깨비의 한마디)
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(
                width: 104,
                height: 116,
                child: Kkaebi3DMascotWidget(
                  size: 104,
                  initialEmotion: fxEmotion,
                  enableInteraction: true,
                  showSpeechBubble: false,
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: DokkeyTheme.surfaceDark,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: DokkeyTheme.borderDark),
                  ),
                  child: Text(
                    quote.hasKkaebiComment
                        ? '💬 ${quote.kkaebiComment}'
                        : '💬 ${quote.text}',
                    style: TextStyle(
                      color: DokkeyTheme.textMain,
                      fontSize: 12.5,
                      height: 1.5,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Actions: 저장 / 공유
          Row(
            children: [
              Expanded(
                child: _HeroAction(
                  icon: isBookmarked ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                  label: isBookmarked
                      ? (provider.lang == 'ko' ? '저장됨' : 'Saved')
                      : (provider.lang == 'ko' ? '마음에 저장' : 'Save'),
                  color: isBookmarked ? DokkeyTheme.dokFire : DokkeyTheme.gold,
                  onTap: () async {
                    await provider.bookmarkQuote(quote.id);
                    if (!isBookmarked) {
                      SoundService().playSuccessChime();
                    }
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _HeroAction(
                  icon: Icons.ios_share_rounded,
                  label: provider.lang == 'ko' ? '부적 카드' : 'Card',
                  color: DokkeyTheme.gold,
                  onTap: () {
                    SoundService().playSuccessChime();
                    QuotePosterDialog.show(context, quote);
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeroAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _HeroAction({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: DokkeyTheme.surfaceDark,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withOpacity(0.5)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
