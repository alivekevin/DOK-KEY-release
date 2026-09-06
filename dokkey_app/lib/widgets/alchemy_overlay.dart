import 'dart:math';
import 'package:flutter/material.dart';

/// 🔥 연성 시네마틱 VFX 오버레이 (v4.1.0 PHASE 5)
/// 조합 버튼 클릭 시: 황금 가마솥 마법 링 회전 + 바닥 충격파 + 8방향 스파크 파티클
class AlchemyOverlay extends StatefulWidget {
  final VoidCallback? onComplete;
  final Duration duration;

  const AlchemyOverlay({
    super.key,
    this.onComplete,
    this.duration = const Duration(milliseconds: 1500),
  });

  static Future<void> run(BuildContext context, {VoidCallback? onComplete}) {
    return showGeneralDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.72),
      barrierDismissible: false,
      transitionDuration: Duration.zero,
      pageBuilder: (_, __, ___) => AlchemyOverlay(onComplete: onComplete),
    );
  }

  @override
  State<AlchemyOverlay> createState() => _AlchemyOverlayState();
}

class _AlchemyOverlayState extends State<AlchemyOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: widget.duration);
    _ctrl.forward();
    _ctrl.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        widget.onComplete?.call();
        if (Navigator.of(context).canPop()) Navigator.of(context).pop();
      }
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Center(
        child: AnimatedBuilder(
          animation: _ctrl,
          builder: (context, _) {
            return SizedBox(
              width: 320,
              height: 320,
              child: CustomPaint(
                painter: _AlchemyPainter(progress: _ctrl.value),
                child: Center(
                  child: Transform.scale(
                    scale: 0.7 + _ctrl.value * 0.5,
                    child: Container(
                      width: 92,
                      height: 92,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(colors: [
                          const Color(0xFFFFE29A),
                          const Color(0xFFF5BD42).withOpacity(0.85),
                          const Color(0xFFB8860B).withOpacity(0.2),
                        ]),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFF5BD42).withOpacity(0.7),
                            blurRadius: 40 * _ctrl.value + 10,
                            spreadRadius: 6 * _ctrl.value,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.auto_fix_high_rounded,
                        color: Colors.black87,
                        size: 42,
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _AlchemyPainter extends CustomPainter {
  final double progress;

  _AlchemyPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final maxR = min(size.width, size.height) * 0.48;
    final fade = (1.0 - progress).clamp(0.0, 1.0);

    // 1. 회전 황금 마법 링 (SweepGradient arc x2, 반대 방향)
    for (final (dir, width, radiusFactor) in [(1.0, 10.0, 0.92), (-1.6, 6.0, 0.78)]) {
      final sweep = SweepGradient(
        startAngle: progress * 2 * pi * dir,
        colors: [
          const Color(0xFFF5BD42).withOpacity(0.0),
          const Color(0xFFF5BD42).withOpacity(0.9 * fade),
          const Color(0xFFFFE29A).withOpacity(0.95 * fade),
          const Color(0xFFF5BD42).withOpacity(0.0),
        ],
      );
      final ringPaint = Paint()
        ..shader = sweep.createShader(Rect.fromCircle(center: center, radius: maxR))
        ..style = PaintingStyle.stroke
        ..strokeWidth = width
        ..strokeCap = StrokeCap.round;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: maxR * radiusFactor),
        0,
        2 * pi * 0.8,
        false,
        ringPaint,
      );
    }

    // 2. 바닥 충격파 링 (0.8 -> 2.4배 방사 확장)
    if (progress > 0.25) {
      final waveT = ((progress - 0.25) / 0.75).clamp(0.0, 1.0);
      final waveR = maxR * (0.8 + waveT * 1.6);
      final wavePaint = Paint()
        ..color = const Color(0xFFFFE29A).withOpacity((1.0 - waveT) * 0.55)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 6 * (1 - waveT) + 1.5;
      canvas.drawCircle(center, waveR, wavePaint);
    }

    // 3. 8방향 십자·대각선 스파크 파티클
    if (progress > 0.15) {
      final sparkT = ((progress - 0.15) / 0.85).clamp(0.0, 1.0);
      final rng = Random(88);
      final sparkPaint = Paint()..strokeCap = StrokeCap.round;
      for (var i = 0; i < 16; i++) {
        final angle = (i / 16) * 2 * pi + rng.nextDouble() * 0.2;
        final dist = maxR * (0.3 + sparkT * (0.9 + rng.nextDouble() * 0.4));
        final px = center.dx + cos(angle) * dist;
        final py = center.dy + sin(angle) * dist;
        final len = 5 * (1 - sparkT) + 2;
        sparkPaint.color = const Color(0xFFF5BD42)
            .withOpacity((1.0 - sparkT) * 0.9)
            .withOpacity((1.0 - sparkT).clamp(0.0, 1.0) * 0.9);
        sparkPaint.strokeWidth = 3 * (1 - sparkT) + 1;
        canvas.drawLine(
          Offset(px, py),
          Offset(px + cos(angle) * len, py + sin(angle) * len),
          sparkPaint,
        );
      }
    }

    // 4. 중앙 빛 번짐
    final glow = Paint()
      ..shader = RadialGradient(
        colors: [
          const Color(0xFFFFE29A).withOpacity(0.4 * fade),
          const Color(0xFFF5BD42).withOpacity(0.0),
        ],
      ).createShader(Rect.fromCircle(center: center, radius: maxR));
    canvas.drawCircle(center, maxR, glow);
  }

  @override
  bool shouldRepaint(covariant _AlchemyPainter oldDelegate) =>
      oldDelegate.progress != progress;
}
