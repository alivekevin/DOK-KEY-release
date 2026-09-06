import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../core/theme.dart';
import '../core/sound_service.dart';

/// 깨비 8대 감정 타입
enum EmotionType {
  normal,  // 보통 / 온화
  joy,     // 환희 / 대박 / 골드
  shy,     // 수줍음 / 애정 / 하트
  sad,     // 슬픔 / 눈물 / 빗방울
  fire,    // 각성 / 도깨비불 / 번개
  rage,    // 분노 / 지진 / 화면 금가기 (Earthquake Crack)
  curious, // 궁금 / 갸우뚱 / 반짝
  shock,   // 경악 / 깜짝 / 번개충격
}

/// 화면 전체에 극적인 8대 감정 연출을 렌더링하는 오버레이 컴포넌트
class ScreenEmotionFxOverlay extends StatefulWidget {
  final EmotionType emotion;
  final VoidCallback? onComplete;
  final Duration duration;

  const ScreenEmotionFxOverlay({
    super.key,
    required this.emotion,
    this.onComplete,
    this.duration = const Duration(milliseconds: 2200),
  });

  /// 어느 화면에서나 한 줄 코드로 8대 감정 이펙트를 화면에 띄우는 정적 헬퍼
  static OverlayEntry? show(BuildContext context, EmotionType emotion, {Duration? duration}) {
    final overlay = Overlay.of(context, rootOverlay: true);

    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (_) => ScreenEmotionFxOverlay(
        emotion: emotion,
        duration: duration ?? const Duration(milliseconds: 2400),
        onComplete: () {
          try {
            entry.remove();
          } catch (_) {}
        },
      ),
    );

    overlay.insert(entry);
    return entry;
  }

  @override
  State<ScreenEmotionFxOverlay> createState() => _ScreenEmotionFxOverlayState();
}

class _ScreenEmotionFxOverlayState extends State<ScreenEmotionFxOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late List<_Particle> _particles;
  final math.Random _random = math.Random();

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: widget.duration,
    );

    _initParticles();
    _triggerSoundAndHaptics();

    _ctrl.forward().then((_) {
      if (mounted) {
        widget.onComplete?.call();
      }
    });
  }

  void _triggerSoundAndHaptics() {
    switch (widget.emotion) {
      case EmotionType.rage:
        HapticFeedback.heavyImpact();
        SoundService().playGong();
        Future.delayed(const Duration(milliseconds: 150), () => HapticFeedback.vibrate());
        break;
      case EmotionType.joy:
        HapticFeedback.mediumImpact();
        SoundService().playSuccessChime();
        break;
      case EmotionType.shy:
        HapticFeedback.selectionClick();
        SoundService().playSuccessChime();
        break;
      case EmotionType.fire:
        HapticFeedback.heavyImpact();
        SoundService().playKkaebiCastShort();
        break;
      case EmotionType.sad:
        HapticFeedback.lightImpact();
        SoundService().playRiddleWrong();
        break;
      case EmotionType.shock:
        HapticFeedback.heavyImpact();
        SoundService().playKeyTurn();
        break;
      case EmotionType.curious:
        HapticFeedback.lightImpact();
        SoundService().playCardFlip();
        break;
      case EmotionType.normal:
        HapticFeedback.lightImpact();
        break;
    }
  }

  void _initParticles() {
    _particles = [];
    final count = widget.emotion == EmotionType.joy ? 40 : 25;
    for (int i = 0; i < count; i++) {
      _particles.add(_Particle.generate(widget.emotion, _random));
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _ctrl,
        builder: (context, child) {
          final progress = _ctrl.value;

          // 진동 쉐이크 오프셋 (분노 / 각성 / 충격 모드)
          Offset shakeOffset = Offset.zero;
          if (widget.emotion == EmotionType.rage && progress < 0.6) {
            final intensity = (1.0 - (progress / 0.6)) * 14.0;
            shakeOffset = Offset(
              (_random.nextDouble() * 2 - 1) * intensity,
              (_random.nextDouble() * 2 - 1) * intensity,
            );
          } else if (widget.emotion == EmotionType.shock && progress < 0.3) {
            final intensity = (1.0 - (progress / 0.3)) * 8.0;
            shakeOffset = Offset(
              (_random.nextDouble() * 2 - 1) * intensity,
              (_random.nextDouble() * 2 - 1) * intensity,
            );
          }

          return Transform.translate(
            offset: shakeOffset,
            child: CustomPaint(
              size: MediaQuery.of(context).size,
              painter: _EmotionFxPainter(
                emotion: widget.emotion,
                progress: progress,
                particles: _particles,
                random: _random,
              ),
            ),
          );
        },
      ),
    );
  }
}

class _Particle {
  double x;
  double y;
  double vx;
  double vy;
  double size;
  double opacity;
  double rotation;
  double vRotation;
  Color color;
  String? emoji;

  _Particle({
    required this.x,
    required this.y,
    required this.vx,
    required this.vy,
    required this.size,
    required this.opacity,
    required this.rotation,
    required this.vRotation,
    required this.color,
    this.emoji,
  });

  factory _Particle.generate(EmotionType emotion, math.Random rnd) {
    switch (emotion) {
      case EmotionType.joy:
        final emojis = ['✨', '🌟', '💰', '🎉', '💫'];
        return _Particle(
          x: rnd.nextDouble(),
          y: 0.8 + rnd.nextDouble() * 0.2,
          vx: (rnd.nextDouble() - 0.5) * 0.3,
          vy: -(0.4 + rnd.nextDouble() * 0.6),
          size: 16 + rnd.nextDouble() * 18,
          opacity: 1.0,
          rotation: rnd.nextDouble() * math.pi * 2,
          vRotation: (rnd.nextDouble() - 0.5) * 4,
          color: const Color(0xFFFFD700),
          emoji: emojis[rnd.nextInt(emojis.length)],
        );
      case EmotionType.shy:
        final emojis = ['💖', '🌸', '💕', '✨', '🥰'];
        return _Particle(
          x: 0.2 + rnd.nextDouble() * 0.6,
          y: 0.7 + rnd.nextDouble() * 0.3,
          vx: (rnd.nextDouble() - 0.5) * 0.15,
          vy: -(0.2 + rnd.nextDouble() * 0.3),
          size: 18 + rnd.nextDouble() * 16,
          opacity: 1.0,
          rotation: rnd.nextDouble() * 0.5 - 0.25,
          vRotation: (rnd.nextDouble() - 0.5) * 1.5,
          color: const Color(0xFFFF69B4),
          emoji: emojis[rnd.nextInt(emojis.length)],
        );
      case EmotionType.sad:
        return _Particle(
          x: rnd.nextDouble(),
          y: rnd.nextDouble() * 0.2,
          vx: 0.02,
          vy: 0.6 + rnd.nextDouble() * 0.8,
          size: 8 + rnd.nextDouble() * 14,
          opacity: 0.8,
          rotation: math.pi / 2,
          vRotation: 0,
          color: const Color(0xFF64B5F6),
          emoji: '💧',
        );
      case EmotionType.fire:
        return _Particle(
          x: 0.3 + rnd.nextDouble() * 0.4,
          y: 0.6 + rnd.nextDouble() * 0.4,
          vx: (rnd.nextDouble() - 0.5) * 0.4,
          vy: -(0.5 + rnd.nextDouble() * 0.7),
          size: 14 + rnd.nextDouble() * 20,
          opacity: 1.0,
          rotation: rnd.nextDouble() * math.pi * 2,
          vRotation: (rnd.nextDouble() - 0.5) * 6,
          color: const Color(0xFF00E5FF),
          emoji: '🔥',
        );
      case EmotionType.curious:
        final emojis = ['❓', '❔', '💡', '✨'];
        return _Particle(
          x: rnd.nextDouble(),
          y: 0.4 + rnd.nextDouble() * 0.4,
          vx: (rnd.nextDouble() - 0.5) * 0.1,
          vy: -(0.1 + rnd.nextDouble() * 0.2),
          size: 20 + rnd.nextDouble() * 14,
          opacity: 1.0,
          rotation: rnd.nextDouble() * 0.4 - 0.2,
          vRotation: (rnd.nextDouble() - 0.5) * 2,
          color: const Color(0xFFFFD54F),
          emoji: emojis[rnd.nextInt(emojis.length)],
        );
      case EmotionType.shock:
        final emojis = ['⚡', '❗', '💥', '💦'];
        return _Particle(
          x: 0.2 + rnd.nextDouble() * 0.6,
          y: 0.3 + rnd.nextDouble() * 0.4,
          vx: (rnd.nextDouble() - 0.5) * 0.8,
          vy: (rnd.nextDouble() - 0.5) * 0.8,
          size: 22 + rnd.nextDouble() * 18,
          opacity: 1.0,
          rotation: rnd.nextDouble() * math.pi * 2,
          vRotation: (rnd.nextDouble() - 0.5) * 8,
          color: const Color(0xFFFF5252),
          emoji: emojis[rnd.nextInt(emojis.length)],
        );
      default:
        return _Particle(
          x: rnd.nextDouble(),
          y: rnd.nextDouble(),
          vx: 0,
          vy: -0.1,
          size: 10,
          opacity: 0.5,
          rotation: 0,
          vRotation: 0,
          color: DokkeyTheme.gold,
        );
    }
  }
}

class _EmotionFxPainter extends CustomPainter {
  final EmotionType emotion;
  final double progress;
  final List<_Particle> particles;
  final math.Random random;

  _EmotionFxPainter({
    required this.emotion,
    required this.progress,
    required this.particles,
    required this.random,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    switch (emotion) {
      case EmotionType.rage:
        _paintRageEarthquake(canvas, size, w, h);
        break;
      case EmotionType.joy:
        _paintJoyCelebration(canvas, size, w, h);
        break;
      case EmotionType.shy:
        _paintShyLove(canvas, size, w, h);
        break;
      case EmotionType.sad:
        _paintSadRain(canvas, size, w, h);
        break;
      case EmotionType.fire:
        _paintDokkaebiFire(canvas, size, w, h);
        break;
      case EmotionType.shock:
        _paintShockImpact(canvas, size, w, h);
        break;
      case EmotionType.curious:
        _paintCuriousGlow(canvas, size, w, h);
        break;
      case EmotionType.normal:
        _paintNormalAura(canvas, size, w, h);
        break;
    }
  }

  /// 1. 분노: 화면 금가는 지진 효과 (Screen Crack & Red Flame Pulse)
  void _paintRageEarthquake(Canvas canvas, Size size, double w, double h) {
    // 붉은 비네트 플래시
    final flashAlpha = (1.0 - progress) * (progress < 0.2 ? progress / 0.2 : 1.0);
    final flashPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          Colors.transparent,
          const Color(0xFFFF1744).withValues(alpha: 0.25 * flashAlpha),
          const Color(0xFFB71C1C).withValues(alpha: 0.55 * flashAlpha),
        ],
        stops: const [0.3, 0.7, 1.0],
      ).createShader(Rect.fromLTWH(0, 0, w, h));
    canvas.drawRect(Rect.fromLTWH(0, 0, w, h), flashPaint);

    // 화면 금(Crack) 그리기 (중앙에서 사방으로 뻗어나가는 날카로운 번개 형태 균열선)
    final crackAlpha = (1.0 - (progress > 0.7 ? (progress - 0.7) / 0.3 : 0.0)).clamp(0.0, 1.0);
    final crackPaint = Paint()
      ..color = const Color(0xFFFF5252).withValues(alpha: 0.9 * crackAlpha)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.8
      ..strokeCap = StrokeCap.round;

    final glowPaint = Paint()
      ..color = const Color(0xFFFFD54F).withValues(alpha: 0.6 * crackAlpha)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5.5
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4.0);

    final centerX = w * 0.5;
    final centerY = h * 0.45;
    final crackProgress = (progress / 0.4).clamp(0.0, 1.0);

    // 7개의 주요 균열 가지
    final angles = [0.2, 0.8, 1.6, 2.3, 3.5, 4.8, 5.6];
    for (int i = 0; i < angles.length; i++) {
      final baseAngle = angles[i];
      final path = Path();
      path.moveTo(centerX, centerY);

      double cx = centerX;
      double cy = centerY;
      final maxLen = (w * 0.45) * crackProgress;
      double curLen = 0;

      while (curLen < maxLen) {
        final step = 25.0 + ((i * 7 + curLen.toInt()) % 20);
        curLen += step;
        final angleOffset = (((i + curLen.toInt()) % 5) - 2) * 0.18;
        final targetX = centerX + math.cos(baseAngle + angleOffset) * curLen;
        final targetY = centerY + math.sin(baseAngle + angleOffset) * curLen;
        path.lineTo(targetX, targetY);
        cx = targetX;
        cy = targetY;

        // 보조 서브 균열 가지
        if (curLen > 60 && (i % 2 == 0)) {
          final subPath = Path();
          subPath.moveTo(cx, cy);
          subPath.lineTo(
            cx + math.cos(baseAngle + 0.6) * 35 * crackProgress,
            cy + math.sin(baseAngle + 0.6) * 35 * crackProgress,
          );
          canvas.drawPath(subPath, glowPaint);
          canvas.drawPath(subPath, crackPaint);
        }
      }
      canvas.drawPath(path, glowPaint);
      canvas.drawPath(path, crackPaint);
    }
  }

  /// 2. 환희: 황금 폭죽 및 상승하는 별/코인 파티클
  void _paintJoyCelebration(Canvas canvas, Size size, double w, double h) {
    final glowAlpha = (1.0 - progress) * 0.35;
    final glowPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          const Color(0xFFFFD700).withValues(alpha: glowAlpha),
          Colors.transparent,
        ],
      ).createShader(Rect.fromCircle(center: Offset(w * 0.5, h * 0.5), radius: w * 0.7));
    canvas.drawCircle(Offset(w * 0.5, h * 0.5), w * 0.7, glowPaint);

    _drawEmojiParticles(canvas, size, w, h);
  }

  /// 3. 수줍음: 핑크 하트 블룸 & 따스한 펄스
  void _paintShyLove(Canvas canvas, Size size, double w, double h) {
    final auraAlpha = (math.sin(progress * math.pi)) * 0.28;
    final auraPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          const Color(0xFFFF80AB).withValues(alpha: auraAlpha),
          Colors.transparent,
        ],
      ).createShader(Rect.fromCircle(center: Offset(w * 0.5, h * 0.45), radius: w * 0.6));
    canvas.drawCircle(Offset(w * 0.5, h * 0.45), w * 0.6, auraPaint);

    _drawEmojiParticles(canvas, size, w, h);
  }

  /// 4. 슬픔: 창문에 흐르는 빗방울 및 눈물 연출
  void _paintSadRain(Canvas canvas, Size size, double w, double h) {
    final blueTint = Paint()
      ..color = const Color(0xFF0D47A1).withValues(alpha: 0.18 * (1.0 - progress * 0.5));
    canvas.drawRect(Rect.fromLTWH(0, 0, w, h), blueTint);

    _drawEmojiParticles(canvas, size, w, h);
  }

  /// 5. 도깨비불 각성: 푸른 화염과 시안빛 번개 아크
  void _paintDokkaebiFire(Canvas canvas, Size size, double w, double h) {
    final fireAlpha = (math.sin(progress * math.pi)) * 0.4;
    final firePaint = Paint()
      ..shader = RadialGradient(
        colors: [
          Colors.transparent,
          const Color(0xFF00E5FF).withValues(alpha: 0.25 * fireAlpha),
          const Color(0xFF2979FF).withValues(alpha: 0.55 * fireAlpha),
        ],
        stops: const [0.4, 0.75, 1.0],
      ).createShader(Rect.fromLTWH(0, 0, w, h));
    canvas.drawRect(Rect.fromLTWH(0, 0, w, h), firePaint);

    _drawEmojiParticles(canvas, size, w, h);
  }

  /// 6. 경악 / 충격: 코믹 임팩트 라인
  void _paintShockImpact(Canvas canvas, Size size, double w, double h) {
    final impactAlpha = (1.0 - progress).clamp(0.0, 1.0);
    final linePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.6 * impactAlpha)
      ..strokeWidth = 2.0;

    final cx = w * 0.5;
    final cy = h * 0.45;
    for (int i = 0; i < 16; i++) {
      final angle = (i / 16) * math.pi * 2;
      final startR = (w * 0.35) * (0.8 + 0.2 * progress);
      final endR = (w * 0.6) * (0.9 + 0.3 * progress);
      canvas.drawLine(
        Offset(cx + math.cos(angle) * startR, cy + math.sin(angle) * startR),
        Offset(cx + math.cos(angle) * endR, cy + math.sin(angle) * endR),
        linePaint,
      );
    }
    _drawEmojiParticles(canvas, size, w, h);
  }

  /// 7. 궁금 / 탐구
  void _paintCuriousGlow(Canvas canvas, Size size, double w, double h) {
    _drawEmojiParticles(canvas, size, w, h);
  }

  /// 8. 기본
  void _paintNormalAura(Canvas canvas, Size size, double w, double h) {
    final auraAlpha = (1.0 - progress) * 0.2;
    final p = Paint()
      ..color = DokkeyTheme.gold.withValues(alpha: auraAlpha)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 20.0);
    canvas.drawCircle(Offset(w * 0.5, h * 0.5), w * 0.35, p);
  }

  void _drawEmojiParticles(Canvas canvas, Size size, double w, double h) {
    for (final p in particles) {
      final curX = (p.x + p.vx * progress) * w;
      final curY = (p.y + p.vy * progress) * h;
      final alpha = (1.0 - (progress > 0.7 ? (progress - 0.7) / 0.3 : 0.0)).clamp(0.0, 1.0);

      if (p.emoji != null) {
        final textSpan = TextSpan(
          text: p.emoji,
          style: TextStyle(
            fontSize: p.size,
            color: Colors.white.withValues(alpha: alpha),
          ),
        );
        final tp = TextPainter(
          text: textSpan,
          textDirection: TextDirection.ltr,
        );
        tp.layout();

        canvas.save();
        canvas.translate(curX, curY);
        canvas.rotate(p.rotation + p.vRotation * progress);
        tp.paint(canvas, Offset(-tp.width / 2, -tp.height / 2));
        canvas.restore();
      }
    }
  }

  @override
  bool shouldRepaint(covariant _EmotionFxPainter oldDelegate) => true;
}
