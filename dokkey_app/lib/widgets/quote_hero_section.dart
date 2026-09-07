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

/// 📜 1순위: 오늘의 명언 히어로 카드 (v4.7.2)
/// - 1줄 (헤더): 오늘의 명언 뱃지
/// - 2줄 (본문): 좌측 3D 턴테이블 깨비 + 우측 3줄 텍스트 (1. 명언 / 2. 저자<출처> / 3. 깨비의 한마디)
/// - 3줄 (하단): [마음에 저장] [부적카드 공유] 액션 버튼
class QuoteHeroSection extends StatelessWidget {
  const QuoteHeroSection({super.key});

  static const List<(String, EmotionType, String)> _showcase = [
    ('rage', EmotionType.rage, '💢 분노 (지진)'),
    ('joy', EmotionType.joy, '✨ 환희 (폭죽)'),
    ('normal', EmotionType.normal, '❄️ 온화 (평온)'),
    ('shock', EmotionType.shock, '⚡ 경악 (충격)'),
    ('curious', EmotionType.curious, '🌀 궁금 (호기심)'),
    ('sad', EmotionType.sad, '💧 슬픔 (빗방울)'),
    ('shy', EmotionType.shy, '💖 설렘 (하트)'),
    ('fire', EmotionType.fire, '🔥 각성 (도깨비불)'),
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
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Icon(Icons.theater_comedy_rounded, color: DokkeyTheme.gold, size: 22),
                  const SizedBox(width: 8),
                  Text(
                    '깨비 감정 쇼케이스 (8대 감정 FX)',
                    style: TextStyle(
                      color: DokkeyTheme.goldLight,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: _showcase.map((e) {
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
                    child: Text(e.$3, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                  );
                }).toList(),
              ),
              const SizedBox(height: 10),
              Center(
                child: Text(
                  '선택한 감정에 따라 화면 전체 풀스크린 Canvas 이펙트가 재생됩니다',
                  style: TextStyle(color: DokkeyTheme.textMuted, fontSize: 11),
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

    final saveText = isBookmarked
        ? (isKo ? '저장됨' : (isJa ? '保存済' : 'Saved'))
        : (isKo ? '마음에 저장' : (isJa ? '心に保存' : (isZh ? '珍藏' : (isHi ? 'सहेजें' : (isDe ? 'Merken' : 'Bookmark')))));

    final shareText = isKo
        ? '부적카드'
        : (isJa
            ? '御守カード'
            : (isZh ? '神符卡片' : (isHi ? 'ताबीज कार्ड' : (isDe ? 'Talisman' : 'Amulet Card'))));

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF281F10),
            DokkeyTheme.cardDark,
            DokkeyTheme.surfaceDark,
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: DokkeyTheme.gold.withValues(alpha: 0.75), width: 1.6),
        boxShadow: [
          BoxShadow(
            color: DokkeyTheme.gold.withValues(alpha: 0.16),
            blurRadius: 22,
            spreadRadius: 1,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1줄 (헤더): [오늘의 명언] 아이콘 및 타이틀 바
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      DokkeyTheme.gold.withValues(alpha: 0.3),
                      DokkeyTheme.dokFire.withValues(alpha: 0.2),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: DokkeyTheme.gold.withValues(alpha: 0.6)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.auto_stories_rounded, color: DokkeyTheme.gold, size: 14),
                    const SizedBox(width: 6),
                    Text(
                      headerTitle,
                      style: TextStyle(
                        color: DokkeyTheme.goldLight,
                        fontWeight: FontWeight.w900,
                        fontSize: 12,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              // 8대 감정 쇼케이스 미니 버튼
              GestureDetector(
                onTap: () => _showEmotionShowcase(context),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: DokkeyTheme.cardDark,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: DokkeyTheme.borderDark),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('🎭', style: TextStyle(fontSize: 12)),
                      const SizedBox(width: 4),
                      Text(
                        isKo ? '감정 리액션' : 'FX',
                        style: TextStyle(color: DokkeyTheme.textMuted, fontSize: 10.5, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // 2줄 (본문): 좌측 3D 캐릭터 + 우측 3줄 텍스트 스택
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // 좌측: 3D 인터랙티브 깨비 마스코트 (360도 턴테이블)
              SizedBox(
                width: 90,
                height: 98,
                child: Kkaebi3DMascotWidget(
                  size: 88,
                  initialEmotion: fxEmotion,
                  enableInteraction: true,
                  enableAutoFloat: true,
                ),
              ),
              const SizedBox(width: 14),

              // 우측: 3줄 형식 (1. 명언 / 2. 저자<출처> / 3. 깨비의 한마디)
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 1) 명언 본문
                    Text(
                      '“${quote.text}”',
                      style: TextStyle(
                        color: DokkeyTheme.textMain,
                        fontSize: 14.5,
                        fontWeight: FontWeight.bold,
                        height: 1.38,
                        letterSpacing: -0.2,
                      ),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 5),

                    // 2) 저자 <출처>
                    Text(
                      '- ${quote.authorLabel}',
                      style: TextStyle(
                        color: DokkeyTheme.gold,
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),

                    // 3) 깨비의 한마디
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: DokkeyTheme.bgDark.withValues(alpha: 0.6),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: DokkeyTheme.borderDark.withValues(alpha: 0.8)),
                      ),
                      child: Text(
                        '💬 ${quote.kkaebiComment}',
                        style: TextStyle(
                          color: DokkeyTheme.goldLight,
                          fontSize: 11,
                          height: 1.35,
                          fontStyle: FontStyle.italic,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // 3줄 (하단 액션 버튼): [마음에 저장] [부적카드 공유]
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () async {
                    await provider.bookmarkQuote(quote.id);
                    if (!isBookmarked) SoundService().playSuccessChime();
                  },
                  icon: Icon(
                    isBookmarked ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                    color: isBookmarked ? DokkeyTheme.dokFire : DokkeyTheme.goldLight,
                    size: 16,
                  ),
                  label: Text(
                    saveText,
                    style: TextStyle(
                      color: isBookmarked ? DokkeyTheme.dokFire : DokkeyTheme.goldLight,
                      fontWeight: FontWeight.bold,
                      fontSize: 12.5,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(
                      color: isBookmarked ? DokkeyTheme.dokFire : DokkeyTheme.gold.withValues(alpha: 0.6),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    SoundService().playSuccessChime();
                    QuotePosterDialog.show(context, quote);
                  },
                  icon: const Icon(Icons.ios_share_rounded, size: 16),
                  label: Text(
                    shareText,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: DokkeyTheme.gold,
                    foregroundColor: DokkeyTheme.bgDark,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
