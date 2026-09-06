import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../core/sound_service.dart';
import '../core/theme.dart';
import '../providers/dokkey_provider.dart';

/// 깨비 2D 8단계 풀 시네마틱 애니메이션 다이얼로그 (금 나와라 뚝딱!)
/// 8단계 자연스러운 프레임 전환 + 바닥 충격파/스파크 폭발 + 사운드 + 화면 셰이크 + 부드러운 스킵 지원
class KkaebiCinematicDialog extends StatefulWidget {
  final VoidCallback? onComplete;
  final String? customTitle;

  const KkaebiCinematicDialog({
    super.key,
    this.onComplete,
    this.customTitle,
  });

  static Future<void> show(BuildContext context, {VoidCallback? onComplete, String? customTitle}) {
    return showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Cinematic',
      barrierColor: Colors.black.withOpacity(0.85),
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (_, __, ___) => KkaebiCinematicDialog(
        onComplete: onComplete,
        customTitle: customTitle,
      ),
      transitionBuilder: (_, anim, __, child) {
        return FadeTransition(opacity: anim, child: child);
      },
    );
  }

  @override
  State<KkaebiCinematicDialog> createState() => _KkaebiCinematicDialogState();
}

class _KkaebiCinematicDialogState extends State<KkaebiCinematicDialog>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  int _currentFrame = 1; // 1 ~ 8
  bool _hitTriggered = false;

  final List<String> _frames = [
    'assets/images/animation/2d/01_bat_up.webp',
    'assets/images/animation/2d/02_bat_swing.webp',
    'assets/images/animation/2d/03_bat_rush.webp',
    'assets/images/animation/2d/04_bat_impact.webp',
    'assets/images/animation/2d/05_magic_burst.webp',
    'assets/images/animation/2d/06_key_rise.webp',
    'assets/images/animation/2d/07_celebrate_1.webp',
    'assets/images/animation/2d/08_celebrate_2.webp',
  ];

  final List<String> _subtitlesKo = [
    '방망이를 번쩍!',
    '힘차게 내리치며!',
    '땅으로 쇄도!',
    '💥 쾅! 금 나와라 뚝딱! 💥',
    '⚡ 황금 마법이 폭발한다! ⚡',
    '✨ 황금 열쇠가 솟아오른다! ✨',
    '🗝️ 기운을 품은 열쇠! 🗝️',
    '🎉 대박이다깨비! 🎉',
  ];

  final List<String> _subtitlesEn = [
    'Raising the magic club!',
    'Swinging with all might!',
    'Striking towards the earth!',
    '💥 Geum Nawara, Ttook-Ttak! 💥',
    '⚡ Golden magic erupts! ⚡',
    '✨ The Golden Key Awakens! ✨',
    '🗝️ The Key of Fortune! 🗝️',
    '🎉 Fortune is Granted, Kkaebi! 🎉',
  ];

  final List<String> _subtitlesJa = [
    'トッケビの小槌を高く振り上げ！',
    '力強く振り下ろす！',
    '大地へ振り下ろす！',
    '💥 ドカン！クムナワラ、トゥクタク！ 💥',
    '⚡ 黄金の魔法が爆発する！ ⚡',
    '✨ 黄金の鍵が湧き上がる！ ✨',
    '🗝️ 幸運を宿した鍵！ 🗝️',
    '🎉 大当たりだケビ！ 🎉',
  ];

  @override
  void initState() {
    super.initState();
    // 2.8초 동안 8단계 부드러운 시퀀스 재생
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2800),
    );

    _ctrl.addListener(() {
      final val = _ctrl.value;
      int newFrame = 1;
      if (val < 0.12) {
        newFrame = 1; // 01_bat_up
      } else if (val < 0.25) {
        newFrame = 2; // 02_bat_swing
      } else if (val < 0.38) {
        newFrame = 3; // 03_bat_rush
      } else if (val < 0.52) {
        newFrame = 4; // 04_bat_impact (충격파)
        if (!_hitTriggered) {
          _hitTriggered = true;
          _triggerHitEffect();
        }
      } else if (val < 0.68) {
        newFrame = 5; // 05_magic_burst (스파크 폭발)
      } else if (val < 0.82) {
        newFrame = 6; // 06_key_rise (열쇠 솟음)
      } else if (val < 0.92) {
        newFrame = 7; // 07_celebrate_1 (미소)
      } else {
        newFrame = 8; // 08_celebrate_2 (피날레 대박)
      }

      if (newFrame != _currentFrame) {
        setState(() => _currentFrame = newFrame);
      }
    });

    _ctrl.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _finishAndClose();
      }
    });

    // 사운드 재생 & 애니메이션 시작
    SoundService().playKkaebiCastShort();
    _ctrl.forward();
  }

  void _triggerHitEffect() {
    HapticFeedback.heavyImpact();
  }

  void _finishAndClose() {
    if (!mounted) return;
    Navigator.of(context, rootNavigator: true).pop();
    widget.onComplete?.call();
  }

  void _skip() {
    _ctrl.stop();
    _finishAndClose();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<DokkeyProvider>().lang;
    final subtitle = lang == 'ko'
        ? _subtitlesKo[_currentFrame - 1]
        : (lang == 'ja' ? _subtitlesJa[_currentFrame - 1] : _subtitlesEn[_currentFrame - 1]);

    // 바닥 충격파 순간(Frame 4) 지진 셰이크 오프셋 계산
    double shakeX = 0;
    double shakeY = 0;
    if (_currentFrame == 4) {
      final t = (_ctrl.value - 0.38) / 0.14;
      final decay = math.max(0.0, 1.0 - t * 2.0);
      shakeX = math.sin(t * math.pi * 14) * 9.0 * decay;
      shakeY = math.cos(t * math.pi * 14) * 7.0 * decay;
    }

    final isImpactOrBurst = _currentFrame == 4 || _currentFrame == 5;

    return GestureDetector(
      onTap: _skip,
      behavior: HitTestBehavior.opaque,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Stack(
          alignment: Alignment.center,
          children: [
            // 1. 도깨비불 & 황금빛 오라 배경
            AnimatedBuilder(
              animation: _ctrl,
              builder: (context, _) {
                final scale = 1.0 + math.sin(_ctrl.value * math.pi) * 0.30;
                return Center(
                  child: Container(
                    width: 330 * scale,
                    height: 330 * scale,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          DokkeyTheme.gold.withOpacity(isImpactOrBurst ? 0.50 : 0.25),
                          DokkeyTheme.mintCalm.withOpacity(0.12),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),

            // 2. 메인 2D 깨비 캐릭터 8단계 컷
            Transform.translate(
              offset: Offset(shakeX, shakeY),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // 캐릭터 일러스트 프레임 (3D 바운스 & 스케일)
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 140),
                      transitionBuilder: (child, anim) => ScaleTransition(
                        scale: Tween<double>(begin: 0.94, end: 1.0).animate(
                          CurvedAnimation(parent: anim, curve: Curves.easeOutBack),
                        ),
                        child: FadeTransition(opacity: anim, child: child),
                      ),
                      child: Container(
                        key: ValueKey<int>(_currentFrame),
                        width: 270,
                        height: 270,
                        alignment: Alignment.center,
                        child: Image.asset(
                          _frames[_currentFrame - 1],
                          fit: BoxFit.contain,
                          errorBuilder: (_, __, ___) => Image.asset(
                            'assets/images/kkaebi_mascot.png',
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // 자막 & 대사 말풍선
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      decoration: BoxDecoration(
                        color: DokkeyTheme.cardDark.withOpacity(0.92),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isImpactOrBurst ? DokkeyTheme.goldLight : DokkeyTheme.gold.withOpacity(0.6),
                          width: isImpactOrBurst ? 2.0 : 1.2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: (isImpactOrBurst ? DokkeyTheme.gold : Colors.black).withOpacity(0.4),
                            blurRadius: isImpactOrBurst ? 18 : 10,
                            spreadRadius: isImpactOrBurst ? 2 : 0,
                          ),
                        ],
                      ),
                      child: Text(
                        subtitle,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: isImpactOrBurst ? DokkeyTheme.goldLight : Colors.white,
                          fontSize: isImpactOrBurst ? 16.5 : 15,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // 3. 우상단 터치 스킵 안내
            Positioned(
              top: 50,
              right: 20,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white24, width: 0.8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      lang == 'ko' ? '탭하여 건너뛰기' : (lang == 'ja' ? 'タップでスキップ' : 'Tap to Skip'),
                      style: const TextStyle(color: Colors.white70, fontSize: 11),
                    ),
                    const SizedBox(width: 4),
                    const Icon(Icons.fast_forward_rounded, size: 14, color: Colors.white70),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}