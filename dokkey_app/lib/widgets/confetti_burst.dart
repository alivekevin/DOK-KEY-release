import 'dart:math';
import 'package:flutter/material.dart';

/// 컨페티 버스트 오버레이 (v3.0.0 P2) — 수수께끼 정답·신규 카드 해금 시
class ConfettiBurst extends StatefulWidget {
  final Widget child;
  final Color color;
  final bool trigger;

  const ConfettiBurst({
    super.key,
    required this.child,
    required this.color,
    this.trigger = false,
  });

  static Future<void> show(BuildContext context, {Color color = const Color(0xFFF5BD42)}) {
    return showGeneralDialog(
      context: context,
      barrierColor: Colors.transparent,
      barrierDismissible: false,
      transitionDuration: Duration.zero,
      pageBuilder: (_, __, ___) => const _FloatingConfetti(),
    );
  }

  @override
  State<ConfettiBurst> createState() => _ConfettiBurstState();
}

class _ConfettiBurstState extends State<ConfettiBurst> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1700));
    if (widget.trigger) _ctrl.forward();
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
          painter: _ConfettiPainter(progress: _ctrl.value, color: widget.color),
          child: child,
        );
      },
      child: widget.child,
    );
  }
}

class _FloatingConfetti extends StatefulWidget {
  const _FloatingConfetti();

  @override
  State<_FloatingConfetti> createState() => _FloatingConfettiState();
}

class _FloatingConfettiState extends State<_FloatingConfetti> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1600));
    _ctrl.forward();
    Future.delayed(const Duration(milliseconds: 2000), () {
      if (mounted && Navigator.of(context).canPop()) Navigator.of(context).pop();
    });
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
        builder: (context, _) {
          return CustomPaint(
            size: MediaQuery.of(context).size,
            painter: _ConfettiPainter(
              progress: _ctrl.value,
              color: const Color(0xFFF5BD42),
              fullScreen: true,
            ),
          );
        },
      ),
    );
  }
}

class _ConfettiPainter extends CustomPainter {
  final double progress;
  final Color color;
  final bool fullScreen;

  _ConfettiPainter({
    required this.progress,
    required this.color,
    this.fullScreen = false,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (progress >= 1.0) return;
    final rng = Random(42);
    final cx = size.width / 2;
    final cy = fullScreen ? size.height * 0.38 : size.height * 0.4;
    final colors = [
      color,
      const Color(0xFFFF6647),
      const Color(0xFF4E9F8E),
      const Color(0xFF64B5F6),
      const Color(0xFFFFE29A),
    ];

    for (var i = 0; i < 42; i++) {
      final angle = rng.nextDouble() * 2 * pi;
      final speed = 0.5 + rng.nextDouble() * 1.0;
      final dist = speed * (0.25 + progress * 1.4) * min(size.width, size.height) * 0.4;
      final x = cx + cos(angle) * dist;
      final fall = progress * progress * min(size.width, size.height) * 0.5;
      final y = cy + sin(angle) * dist * 0.6 + fall;
      final pieceSize = rng.nextDouble() * 5 + 3;
      final opacity = (1.0 - progress).clamp(0.0, 1.0);
      final paint = Paint()..color = colors[rng.nextInt(colors.length)].withOpacity(opacity);
      final spin = rng.nextDouble() * pi * 2 + progress * pi * 4;

      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(spin);
      canvas.drawRect(Rect.fromCenter(center: Offset.zero, width: pieceSize, height: pieceSize * 0.55), paint);
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _ConfettiPainter oldDelegate) => oldDelegate.progress != progress;
}
