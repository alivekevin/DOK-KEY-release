import 'dart:math';
import 'package:flutter/material.dart';

/// 잉크 스플래시 버스트 — 카드 공개 순간의 동양 판타지 잉크 번짐 이펙트
class InkSplashBurst extends StatefulWidget {
  final Widget child;
  final Color color;
  final bool trigger;

  const InkSplashBurst({
    super.key,
    required this.child,
    required this.color,
    this.trigger = false,
  });

  @override
  State<InkSplashBurst> createState() => _InkSplashBurstState();
}

class _InkSplashBurstState extends State<InkSplashBurst>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 900));
    if (widget.trigger) _ctrl.forward();
  }

  @override
  void didUpdateWidget(InkSplashBurst oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.trigger && !oldWidget.trigger) {
      _ctrl.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, child) {
        return CustomPaint(
          painter: _InkSplashPainter(progress: _ctrl.value, color: widget.color),
          child: child,
        );
      },
      child: widget.child,
    );
  }
}

class _InkSplashPainter extends CustomPainter {
  final double progress;
  final Color color;

  _InkSplashPainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0 || progress >= 1) return;
    final rng = Random(7);
    final cx = size.width / 2;
    final cy = size.height * 0.45;
    final maxR = min(size.width, size.height) * 0.7;

    // Main ink bloom
    final bloomR = Curves.easeOutCubic.transform(progress) * maxR;
    final opacity = (1.0 - progress).clamp(0.0, 1.0) * 0.5;

    final bloomPaint = Paint()
      ..color = color.withOpacity(opacity * 0.35)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, 20 * (1 - progress) + 4);
    canvas.drawCircle(Offset(cx, cy), bloomR, bloomPaint);

    // Irregular droplets
    final dropletPaint = Paint()..color = color.withOpacity(opacity);
    for (var i = 0; i < 18; i++) {
      final angle = rng.nextDouble() * 2 * pi;
      final dist = bloomR * (0.55 + rng.nextDouble() * 0.5);
      final dr = (rng.nextDouble() * 4 + 1.5) * (1 - progress * 0.6);
      canvas.drawCircle(
        Offset(cx + cos(angle) * dist, cy + sin(angle) * dist * 0.85),
        dr,
        dropletPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _InkSplashPainter oldDelegate) =>
      oldDelegate.progress != progress;
}
