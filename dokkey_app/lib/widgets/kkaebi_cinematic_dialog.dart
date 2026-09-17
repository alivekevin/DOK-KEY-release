import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../core/sound_service.dart';
import '../core/theme.dart';
import '../core/brand_config.dart';
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

            // 1.5 [V2 NEW] 광역 충격파 & 황금 스파크 파티클 오버레이 (화면 전체 폭으로 비산)
            if (BrandConfig.cinematicFxV2Enabled)
              Positioned.fill(
                child: AnimatedBuilder(
                  animation: _ctrl,
                  builder: (context, _) {
                    final val = _ctrl.value;
                    double impactProgress = 0.0;
                    if (val >= 0.38 && val <= 0.68) {
                      impactProgress = (val - 0.38) / (0.68 - 0.38);
                    }
                    return CustomPaint(
                      size: Size.infinite,
                      painter: KkaebiImpactParticlePainter(
                        progress: impactProgress,
                        isImpact: _currentFrame == 4,
                        isBurst: _currentFrame == 5,
                      ),
                    );
                  },
                ),
              ),

            // 1.6 [V2 NEW] 찰나의 황금 스크린 플래시 (0.08초 동안 잔상 완화)
            if (BrandConfig.cinematicFxV2Enabled)
              AnimatedBuilder(
                animation: _ctrl,
                builder: (context, _) {
                  final val = _ctrl.value;
                  double flashOpacity = 0.0;
                  if (val >= 0.38 && val <= 0.46) {
                    final p = (val - 0.38) / 0.08;
                    flashOpacity = math.sin(p * math.pi) * 0.20;
                  }
                  if (flashOpacity <= 0.005) return const SizedBox.shrink();
                  return Positioned.fill(
                    child: IgnorePointer(
                      child: Container(
                        color: const Color(0xFFFFE082).withOpacity(flashOpacity),
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
                        width: (BrandConfig.cinematicFxV2Enabled && isImpactOrBurst) ? 310 : 270,
                        height: (BrandConfig.cinematicFxV2Enabled && isImpactOrBurst) ? 310 : 270,
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

                    // 자막 & 대사 말풍선 (고대비 크림 골드 & 발광 테두리)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0F121A).withOpacity(0.96),
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(
                          color: isImpactOrBurst ? const Color(0xFFFFD700) : DokkeyTheme.gold.withOpacity(0.85),
                          width: isImpactOrBurst ? 2.2 : 1.6,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: (isImpactOrBurst ? const Color(0xFFFFD700) : DokkeyTheme.gold).withOpacity(0.4),
                            blurRadius: isImpactOrBurst ? 20 : 12,
                            spreadRadius: isImpactOrBurst ? 2 : 1,
                          ),
                        ],
                      ),
                      child: Text(
                        subtitle,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: isImpactOrBurst ? const Color(0xFFFFE066) : const Color(0xFFFFF4D0),
                          fontSize: isImpactOrBurst ? 18.0 : 16.5,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.8,
                          shadows: const [
                            Shadow(color: Colors.black, blurRadius: 6, offset: Offset(0, 1.5)),
                          ],
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

/// 💥 V2: 방망이 타격 시 화면 전체(100% Width)로 뻗어나가는 광역 충격파 & 황금 스파크 파티클 페인터
class KkaebiImpactParticlePainter extends CustomPainter {
  final double progress; // 0.0 ~ 1.0 (Frame 4 타격 ~ Frame 5 폭발 구간)
  final bool isImpact;
  final bool isBurst;

  KkaebiImpactParticlePainter({
    required this.progress,
    required this.isImpact,
    required this.isBurst,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0.0 || progress >= 1.0) return;

    // 방망이가 바닥에 닿는 타격 중심점 (캐릭터 중심 아래쪽 바닥 지점)
    final impactCenter = Offset(size.width / 2, size.height / 2 + 55);
    final fade = (1.0 - progress).clamp(0.0, 1.0);

    // ──────────────────────────────────────────────────────────
    // 1. 수평 광역 충격파 타원 (Horizontal Shockwave Oval)
    // ──────────────────────────────────────────────────────────
    // 화면 전체 폭을 가뿐히 넘어 좌우 끝까지 시원하게 퍼지도록 가로 반경을 화면 폭 * 1.3배로 확장
    final maxRadiusX = size.width * 0.75;
    final maxRadiusY = size.width * 0.28;

    final shockwaveEase = math.pow(progress, 0.55).toDouble();
    final currentRadiusX = shockwaveEase * maxRadiusX;
    final currentRadiusY = shockwaveEase * maxRadiusY;

    // 메인 골드 충격파 링
    final shockwavePaint = Paint()
      ..color = const Color(0xFFFFD54F).withOpacity(fade * 0.85)
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(1.5, (1.0 - progress) * 7.5)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);

    canvas.drawOval(
      Rect.fromCenter(
        center: impactCenter,
        width: currentRadiusX * 2,
        height: currentRadiusY * 2,
      ),
      shockwavePaint,
    );

    // 세컨더리 아우라 링 (내부에서 빠르게 따라붙는 맑은 청록/사파이어 에너지)
    if (progress > 0.08) {
      final innerProgress = ((progress - 0.08) / 0.92).clamp(0.0, 1.0);
      final innerEase = math.pow(innerProgress, 0.65).toDouble();
      final innerRadiusX = innerEase * maxRadiusX * 0.78;
      final innerRadiusY = innerEase * maxRadiusY * 0.78;
      final innerFade = (1.0 - innerProgress).clamp(0.0, 1.0);

      final innerPaint = Paint()
        ..color = const Color(0xFF38BDF8).withOpacity(innerFade * 0.6)
        ..style = PaintingStyle.stroke
        ..strokeWidth = math.max(1.0, (1.0 - innerProgress) * 4.0)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5);

      canvas.drawOval(
        Rect.fromCenter(
          center: impactCenter,
          width: innerRadiusX * 2,
          height: innerRadiusY * 2,
        ),
        innerPaint,
      );
    }

    // ──────────────────────────────────────────────────────────
    // 2. 사방으로 비산하는 42개의 황금빛 별가루 파티클 (Stardust Particles)
    // ──────────────────────────────────────────────────────────
    final particlePaint = Paint()..style = PaintingStyle.fill;

    for (int i = 0; i < 42; i++) {
      final seed = i * 47.123;
      final baseAngle = (i / 42.0) * 2 * math.pi;
      final angle = baseAngle + math.sin(seed) * 0.25;

      final speed = 110.0 + (i % 7) * 32.0;
      final particleDist = speed *
          math.pow(progress, 0.68).toDouble() *
          (size.width / 360).clamp(0.85, 1.6);

      final px = impactCenter.dx + math.cos(angle) * particleDist * 1.35;
      final gravity = math.pow(progress, 2.2).toDouble() * (55.0 + (i % 5) * 15.0);
      final py = impactCenter.dy + math.sin(angle) * particleDist * 0.75 + gravity;

      final baseSize = 2.2 + (i % 5) * 1.2;
      final currentSize = math.max(0.5, baseSize * (1.0 - progress));
      final particleAlpha = (fade * (0.55 + (i % 4) * 0.15)).clamp(0.0, 1.0);

      Color pColor;
      if (i % 5 == 0) {
        pColor = const Color(0xFFFFFFFF);
      } else if (i % 3 == 0) {
        pColor = const Color(0xFF38BDF8);
      } else if (i % 2 == 0) {
        pColor = const Color(0xFFFFD54F);
      } else {
        pColor = const Color(0xFFFF9100);
      }

      particlePaint.color = pColor.withOpacity(particleAlpha);

      if (i % 2 == 0) {
        final path = Path()
          ..moveTo(px, py - currentSize * 1.5)
          ..lineTo(px + currentSize * 1.1, py)
          ..lineTo(px, py + currentSize * 1.5)
          ..lineTo(px - currentSize * 1.1, py)
          ..close();
        canvas.drawPath(path, particlePaint);
      } else {
        canvas.drawCircle(Offset(px, py), currentSize, particlePaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant KkaebiImpactParticlePainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.isImpact != isImpact ||
        oldDelegate.isBurst != isBurst;
  }
}