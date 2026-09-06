import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../core/theme.dart';
import '../core/sound_service.dart';
import '../models/dokkey_models.dart';
import '../providers/dokkey_provider.dart';
import 'card_flip_widget.dart';
import 'dokkaebi_fire_particles.dart';
import 'ink_splash_burst.dart';
import '../screens/result_screen.dart';

class DrawCinematicDialog extends StatefulWidget {
  final DrawResult result;

  const DrawCinematicDialog({super.key, required this.result});

  static Future<void> show(BuildContext context, DrawResult result) {
    return showGeneralDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withOpacity(0.85),
      transitionDuration: const Duration(milliseconds: 400),
      pageBuilder: (_, __, ___) => DrawCinematicDialog(result: result),
    );
  }

  @override
  State<DrawCinematicDialog> createState() => _DrawCinematicDialogState();
}

class _DrawCinematicDialogState extends State<DrawCinematicDialog>
    with SingleTickerProviderStateMixin {
  late AnimationController _floatCtrl;
  bool _revealed = false;
  Timer? _autoTransitionTimer;

  @override
  void initState() {
    super.initState();
    _floatCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);

    SoundService().playUnlock();
  }

  @override
  void dispose() {
    _autoTransitionTimer?.cancel();
    _floatCtrl.dispose();
    super.dispose();
  }

  void _goToResult() {
    _autoTransitionTimer?.cancel();
    if (!mounted) return;
    Navigator.of(context).pop();
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ResultScreen(result: widget.result),
      ),
    );
  }

  /// 시간대별 배경 그라데이션 (아침=주황·점심=청백·저녁=주홍·심야=심청)
  List<Color> _slotGradient() {
    switch (widget.result.timeslot.id) {
      case 'morning':
        return [const Color(0xFF3A2A18), const Color(0xFF181216)];
      case 'noon':
        return [const Color(0xFF14202E), const Color(0xFF101418)];
      case 'evening':
        return [const Color(0xFF2E1A22), const Color(0xFF140F14)];
      case 'night':
      default:
        return [const Color(0xFF1A1A2E), const Color(0xFF0F1116)];
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<DokkeyProvider>();
    final isKo = provider.lang == 'ko';
    final isJa = provider.lang == 'ja';
    final toneColor = DokkeyTheme.parseHex(widget.result.tone.color);
    final slotName = widget.result.timeslot.name;
    final slotEmoji = widget.result.timeslot.emoji;

    // v4.7.0 Wisdom-First (A5): 명언-운세 연결 서사
    final headerRevealed = isKo
        ? '오늘의 명언이 고른 카드입니다'
        : (isJa ? '今日の名言が選んだカードです' : "Today's wisdom chose this card");
    final headerWaiting = isKo
        ? '도깨비의 열쇠가 돌아가는 중...'
        : (isJa ? 'ドッケビの鍵が回っている...' : 'The goblin key is turning...');
    final hintRevealed = isKo
        ? '잠시 후 자동으로 운세 화면으로 이동합니다'
        : (isJa ? 'まもなく自動で運勢画面へ移動します' : 'Auto-opening full reading shortly...');
    final hintWaiting = isKo
        ? '카드를 터치하여 앞면을 확인하세요'
        : (isJa ? 'カードをタップして表を確認しよう' : 'Tap the card to reveal the front');
    final ctaLabel = isKo
        ? '오늘의 운세 상세 보기'
        : (isJa ? '今日の運勢を詳しく見る' : 'View today’s full reading');
    final slotTag = isKo
        ? '$slotEmoji ${slotName}의 기운'
        : (isJa ? '$slotEmoji ${slotName}の気力' : '$slotEmoji $slotName energy');

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: _slotGradient(),
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Top Header Info
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 400),
                      child: Column(
                        key: ValueKey(_revealed),
                        children: [
                          Text(
                            _revealed ? headerRevealed : headerWaiting,
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: _revealed ? toneColor : DokkeyTheme.textMain,
                              letterSpacing: 1.0,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            _revealed ? hintRevealed : hintWaiting,
                            style: TextStyle(
                              fontSize: 12,
                              color: DokkeyTheme.textMuted,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: toneColor.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: toneColor.withOpacity(0.4)),
                            ),
                            child: Text(
                              slotTag,
                              style: TextStyle(
                                color: toneColor,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 28),

                    // 3D Card Flip in Center with Dokkaebi Fire Particles
                    Center(
                      child: InkSplashBurst(
                        color: toneColor,
                        trigger: _revealed,
                        child: DokkaebiFireParticles(
                          baseColor: toneColor,
                          child: AnimatedBuilder(
                            animation: _floatCtrl,
                            builder: (context, child) {
                              final dy = sin(_floatCtrl.value * 2 * 3.14159) * 8;
                              return Transform.translate(
                                offset: Offset(0, dy),
                                child: child,
                              );
                            },
                            child: CardFlipWidget(
                              card: widget.result.card,
                              number: widget.result.number,
                              tone: widget.result.tone,
                              autoFlip: true,
                              width: 250,
                              height: 380,
                              onFlipped: () {
                                setState(() => _revealed = true);
                                HapticFeedback.lightImpact();
                                SoundService().playInkSplash();

                                // Zero-Friction 2.2초 후 자동 전환
                                _autoTransitionTimer?.cancel();
                                _autoTransitionTimer = Timer(const Duration(milliseconds: 2200), () {
                                  _goToResult();
                                });
                              },
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 36),

                    AnimatedOpacity(
                      opacity: _revealed ? 1.0 : 0.0,
                      duration: const Duration(milliseconds: 400),
                      child: ElevatedButton.icon(
                        onPressed: _revealed ? _goToResult : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: toneColor,
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                          elevation: 12,
                          shadowColor: toneColor.withOpacity(0.6),
                        ),
                        icon: const Icon(Icons.menu_book_rounded, size: 20),
                        label: Text(
                          ctaLabel,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}