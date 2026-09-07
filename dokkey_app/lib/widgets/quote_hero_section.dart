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

/// 📜 1순위: 컴팩트 오늘의 명언 티커 (v4.7.1)
/// 약 120dp 골드 글래스 카드 — 좌측 미니 3D 깨비 / 중앙 명언 1~2줄 / 우측 미니 액션.
/// 카드 탭 시 상세 팝업(부적 카드)이 열린다.
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
    final isKo = provider.lang == 'ko';

    return GestureDetector(
      onTap: () => QuotePosterDialog.show(context, quote),
      child: Container(
        height: 124,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF2A2214), DokkeyTheme.cardDark, DokkeyTheme.cardDark],
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: DokkeyTheme.gold.withOpacity(0.7), width: 1.5),
          boxShadow: [
            BoxShadow(color: DokkeyTheme.gold.withOpacity(0.14), blurRadius: 18, spreadRadius: 1),
          ],
        ),
        child: Row(
          children: [
            // 좌측: 미니 3D 깨비 (감정 동기화)
            SizedBox(
              width: 64,
              height: 72,
              child: Kkaebi3DMascotWidget(
                size: 62,
                initialEmotion: fxEmotion,
                enableInteraction: false,
                enableAutoFloat: true,
              ),
            ),
            const SizedBox(width: 10),

            // 중앙: 명언 1~2줄 + 저자
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Row(
                    children: [
                      Icon(Icons.auto_stories_rounded, color: DokkeyTheme.gold, size: 13),
                      const SizedBox(width: 4),
                      Text(
                        isKo ? '오늘의 명언' : (provider.lang == 'ja' ? '今日の名言' : (provider.lang == 'zh' ? '今日名言' : (provider.lang == 'hi' ? 'आज का सुवचन' : (provider.lang == 'de' ? 'Tageszitat' : "Today's Quote")))),
                        style: TextStyle(
                          color: DokkeyTheme.gold,
                          fontWeight: FontWeight.w900,
                          fontSize: 11,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 5),
                  Text(
                    '"${quote.text}"',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: DokkeyTheme.textMain,
                      fontSize: 13.5,
                      height: 1.35,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '- ${quote.authorLabel}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: DokkeyTheme.goldLight, fontSize: 10.5),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 6),

            // 우측: 미니 액션 아이콘 (공유 / 저장 / 감정)
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _MiniIcon(
                  icon: Icons.ios_share_rounded,
                  onTap: () {
                    SoundService().playSuccessChime();
                    QuotePosterDialog.show(context, quote);
                  },
                ),
                const SizedBox(height: 6),
                _MiniIcon(
                  icon: isBookmarked ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                  color: isBookmarked ? DokkeyTheme.dokFire : DokkeyTheme.textMuted,
                  onTap: () async {
                    await provider.bookmarkQuote(quote.id);
                    if (!isBookmarked) SoundService().playSuccessChime();
                  },
                ),
                const SizedBox(height: 6),
                _MiniIcon(
                  icon: Icons.theater_comedy_rounded,
                  onTap: () => _showEmotionShowcase(context),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _MiniIcon extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final Color color;

  const _MiniIcon({
    super.key,
    required this.icon,
    required this.onTap,
    this.color = const Color(0xFFD4AF37),
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 30,
        height: 30,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: DokkeyTheme.surfaceDark,
          border: Border.all(color: color.withOpacity(0.5)),
        ),
        child: Icon(icon, size: 15, color: color),
      ),
    );
  }
}
