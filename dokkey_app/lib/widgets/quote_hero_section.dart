import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/daily_quote_engine.dart';
import '../core/sound_service.dart';
import '../core/theme.dart';
import '../providers/dokkey_provider.dart';
import 'kkaebi_3d_mascot_widget.dart';
import 'quote_poster_dialog.dart';
import 'screen_emotion_fx_overlay.dart';

/// 📜 1순위: 컴팩트 오늘의 명언 티커 (v4.7.1)
/// 약 124dp 골드 글래스 카드 — 좌측 미니 3D 깨비 / 중앙 선명한 명언 2줄+저자 / 우측 미니 액션 3종.
/// 카드 탭 시 부적 카드 상세 팝업이 열린다.
class QuoteHeroSection extends StatelessWidget {
  const QuoteHeroSection({super.key});

  static String _t(String lang, {
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

  static List<(String, EmotionType, String)> _getShowcase(String lang) => [
    ('rage', EmotionType.rage, _t(lang, ko: '💢 분노 (지진)', en: '💢 Rage (Quake)', ja: '💢 怒り (地震)', zh: '💢 愤怒 (地震)', de: '💢 Wut (Beben)', hi: '💢 क्रोध (भूकंप)')),
    ('joy', EmotionType.joy, _t(lang, ko: '✨ 환희 (폭죽)', en: '✨ Joy (Fireworks)', ja: '✨ 歓喜 (花火)', zh: '✨ 欢喜 (烟花)', de: '✨ Freude (Feuerwerk)', hi: '✨ आनंद (पटाखे)')),
    ('normal', EmotionType.normal, _t(lang, ko: '❄️ 온화 (평온)', en: '❄️ Calm (Serenity)', ja: '❄️ 温和 (平穏)', zh: '❄️ 温和 (宁静)', de: '❄️ Sanft (Ruhe)', hi: '❄️ शांत (सुकून)')),
    ('shock', EmotionType.shock, _t(lang, ko: '⚡ 경악 (충격)', en: '⚡ Shock (Thunder)', ja: '⚡ 驚愕 (衝撃)', zh: '⚡ 震惊 (冲击)', de: '⚡ Schock (Blitz)', hi: '⚡ झटका (बिजली)')),
    ('curious', EmotionType.curious, _t(lang, ko: '🌀 궁금 (호기심)', en: '🌀 Curious (Wonder)', ja: '🌀 好奇 (探求)', zh: '🌀 好奇 (探寻)', de: '🌀 Neugier (Wirbel)', hi: '🌀 उत्सुक (जिज्ञासा)')),
    ('sad', EmotionType.sad, _t(lang, ko: '💧 슬픔 (빗방울)', en: '💧 Sadness (Rain)', ja: '💧 悲しみ (雨滴)', zh: '💧 悲伤 (雨滴)', de: '💧 Trauer (Regen)', hi: '💧 उदासी (बारिश)')),
    ('shy', EmotionType.shy, _t(lang, ko: '💖 설렘 (하트)', en: '💖 Flutter (Heart)', ja: '💖 ときめき (ハート)', zh: '💖 心动 (爱心)', de: '💖 Herzklopfen (Herz)', hi: '💖 उत्साह (हार्ट)')),
    ('fire', EmotionType.fire, _t(lang, ko: '🔥 각성 (도깨비불)', en: '🔥 Awakening (Wisp)', ja: '🔥 覚醒 (鬼火)', zh: '🔥 觉醒 (鬼火)', de: '🔥 Erwachen (Feuer)', hi: '🔥 जागृति (अग्नि)')),
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
    final lang = context.read<DokkeyProvider>().lang;
    final showcase = _getShowcase(lang);

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
                  const SizedBox(width: 8),
                  Text(
                    _t(lang,
                      ko: '깨비 감정 쇼케이스 (8대 감정 FX)',
                      en: 'Kkaebi Emotion Showcase (8 VFX)',
                      ja: 'クケビ感情ショーケース (8大感情FX)',
                      zh: '吉鬼情感剧场 (8大情绪特效)',
                      de: 'Kkaebi-Emotions-Showcase (8 VFX)',
                      hi: 'कैबी भावना शोकेस (8 भाव FX)',
                    ),
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
                children: showcase.map((e) {
                  return OutlinedButton(
                    onPressed: () {
                      Navigator.of(sheetCtx).pop();
                      _playFx(context, e.$2);
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: DokkeyTheme.goldLight,
                      side: BorderSide(color: DokkeyTheme.gold.withValues(alpha: 0.6)),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text(e.$3, style: const TextStyle(fontSize: 12.5)),
                  );
                }).toList(),
              ),
              const SizedBox(height: 8),
              Center(
                child: Text(
                  _t(lang,
                    ko: '선택한 감정에 따라 화면 전체 풀스크린 Canvas 이펙트가 재생됩니다',
                    en: 'Plays a full-screen canvas effect matching the selected emotion',
                    ja: '選択した感情に応じて全画面Canvasエフェクトが再生されます',
                    zh: '根据所选情绪播放全屏Canvas特效',
                    de: 'Spielt Vollbild-Canvas-Effekte passend zur gewählten Emotion',
                    hi: 'चुने गए भाव के अनुसार पूर्ण-स्क्रीन कैनवास प्रभाव चलेगा',
                  ),
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
    final isJa = provider.lang == 'ja';
    final isZh = provider.lang == 'zh';
    final isHi = provider.lang == 'hi';
    final isDe = provider.lang == 'de';

    final headerTitle = isKo
        ? '오늘의 명언'
        : (isJa
            ? '今日の名言'
            : (isZh
                ? '今日名言'
                : (isHi ? 'आज का सुवचन' : (isDe ? 'Tageszitat' : "Today's Quote"))));

    return GestureDetector(
      onTap: () => QuotePosterDialog.show(context, quote),
      child: Container(
        height: 124,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFF2A2214),
              DokkeyTheme.cardDark,
              DokkeyTheme.cardDark,
            ],
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: DokkeyTheme.gold.withValues(alpha: 0.8), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: DokkeyTheme.gold.withValues(alpha: 0.16),
              blurRadius: 18,
              spreadRadius: 1,
            ),
          ],
        ),
        child: Row(
          children: [
            // 좌측: 미니 3D 깨비 (터치 12타 이스터에그 & 감정 동기화 & 360도 턴테이블)
            SizedBox(
              width: 64,
              height: 72,
              child: Kkaebi3DMascotWidget(
                size: 62,
                initialEmotion: fxEmotion,
                enableInteraction: true,
                enableAutoFloat: true,
              ),
            ),
            const SizedBox(width: 10),

            // 중앙: 선명한 [오늘의 명언] 뱃지 + 명언 2줄 + 저자
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // 상단: 선명한 골드 뱃지
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: DokkeyTheme.gold.withValues(alpha: 0.25),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: DokkeyTheme.gold.withValues(alpha: 0.7), width: 1.0),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.auto_stories_rounded, color: DokkeyTheme.gold, size: 13),
                        const SizedBox(width: 4),
                        Text(
                          headerTitle,
                          style: TextStyle(
                            color: DokkeyTheme.goldLight,
                            fontWeight: FontWeight.w900,
                            fontSize: 11.5,
                            letterSpacing: 0.6,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 5),
                  // 명언 본문
                  Text(
                    '“${quote.text}”',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: DokkeyTheme.textMain,
                      fontSize: 14.5,
                      height: 1.35,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.2,
                    ),
                  ),
                  const SizedBox(height: 3),
                  // 저자 / 출처
                  Text(
                    '- ${quote.authorLabel}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: DokkeyTheme.gold,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),

            // 우측: 3개 미니 액션 아이콘 (부적공유 / 북마크저장 / 감정FX)
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _MiniIcon(
                  icon: Icons.ios_share_rounded,
                  tooltip: isKo ? '부적카드 공유' : 'Share Amulet',
                  onTap: () {
                    SoundService().playSuccessChime();
                    QuotePosterDialog.show(context, quote);
                  },
                ),
                const SizedBox(height: 6),
                _MiniIcon(
                  icon: isBookmarked ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                  color: isBookmarked ? DokkeyTheme.dokFire : DokkeyTheme.goldLight,
                  tooltip: isBookmarked ? (isKo ? '저장됨' : 'Saved') : (isKo ? '마음에 저장' : 'Bookmark'),
                  onTap: () async {
                    await provider.bookmarkQuote(quote.id);
                    if (!isBookmarked) SoundService().playSuccessChime();
                  },
                ),
                const SizedBox(height: 6),
                _MiniIcon(
                  icon: Icons.theater_comedy_rounded,
                  tooltip: _t(provider.lang,
                    ko: '감정 리액션',
                    en: 'Emotion FX',
                    ja: '感情リアクション',
                    zh: '情绪特效',
                    de: 'Emotions-FX',
                    hi: 'भाव प्रभाव',
                  ),
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
  final String tooltip;

  const _MiniIcon({
    required this.icon,
    required this.onTap,
    this.color = const Color(0xFFD4AF37),
    this.tooltip = '',
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: DokkeyTheme.surfaceDark,
            border: Border.all(color: color.withValues(alpha: 0.6), width: 1.1),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.3),
                blurRadius: 4,
              ),
            ],
          ),
          child: Icon(icon, size: 15, color: color),
        ),
      ),
    );
  }
}
