import 'dart:math';
import 'package:flutter/material.dart';
import '../core/theme.dart';

class DokkaebiFireParticles extends StatefulWidget {
  final Widget child;
  final Color? baseColor;

  const DokkaebiFireParticles({
    super.key,
    required this.child,
    this.baseColor,
  });

  @override
  State<DokkaebiFireParticles> createState() => _DokkaebiFireParticlesState();
}

class _DokkaebiFireParticlesState extends State<DokkaebiFireParticles>
    with SingleTickerProviderStateMixin {
  static const Color _defaultBase = Color(0xFFF5BD42);

  late AnimationController _controller;
  final List<_Particle> _particles = [];
  final Random _rng = Random();

  Color get _resolvedBase => widget.baseColor ?? _defaultBase;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat();

    for (var i = 0; i < 24; i++) {
      _particles.add(_Particle.random(_rng, _resolvedBase));
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return CustomPaint(
          painter: _ParticlePainter(_particles, _controller.value, _resolvedBase),
          child: child,
        );
      },
      child: widget.child,
    );
  }
}

class _Particle {
  double x;
  double y;
  double size;
  double speedY;
  double speedX;
  double opacity;
  Color color;

  _Particle({
    required this.x,
    required this.y,
    required this.size,
    required this.speedY,
    required this.speedX,
    required this.opacity,
    required this.color,
  });

  factory _Particle.random(Random rng, Color baseColor) {
    final colors = [
      baseColor,
      DokkeyTheme.dokFire,
      DokkeyTheme.goldLight,
      const Color(0xFF64B5F6),
    ];

    return _Particle(
      x: rng.nextDouble(),
      y: rng.nextDouble(),
      size: rng.nextDouble() * 5 + 2,
      speedY: rng.nextDouble() * 0.25 + 0.1,
      speedX: (rng.nextDouble() - 0.5) * 0.1,
      opacity: rng.nextDouble() * 0.6 + 0.3,
      color: colors[rng.nextInt(colors.length)],
    );
  }

  void update() {
    y -= speedY * 0.02;
    x += speedX * 0.02;
    if (y < 0) {
      y = 1.0;
      x = Random().nextDouble();
    }
  }
}

class _ParticlePainter extends CustomPainter {
  final List<_Particle> particles;
  final double progress;
  final Color baseColor;

  _ParticlePainter(this.particles, this.progress, this.baseColor);

  @override
  void paint(Canvas canvas, Size size) {
    for (final p in particles) {
      p.update();
      final paint = Paint()
        ..color = p.color.withOpacity(p.opacity)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3.0);

      final offset = Offset(p.x * size.width, p.y * size.height);
      canvas.drawCircle(offset, p.size, paint);

      // Bright core
      final corePaint = Paint()..color = Colors.white.withOpacity(p.opacity * 0.8);
      canvas.drawCircle(offset, p.size * 0.4, corePaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}