import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/theme.dart';
import '../providers/dokkey_provider.dart';

/// 계절 열거형
enum AppSeason {
  spring, // 🌸 봄: 벚꽃 & 매화 꽃잎
  summer, // 🌿 여름: 반딧불이 & 청량 숲 기운
  autumn, // 🍁 가을: 단풍잎 & 황금 은행잎
  winter, // ❄️ 겨울: 눈송이 & 서리 결정
}

/// 시간대 열거형
enum AppTimeOfDay {
  dawn,  // 🌅 새벽/아침 (05:00 ~ 11:00)
  day,   // ☀️ 낮/오후 (11:00 ~ 17:00)
  dusk,  // 🌆 노을/황혼 (17:00 ~ 20:00)
  night, // 🌙 밤/심야 (20:00 ~ 05:00)
}

/// 사계절 및 시간대 연동 앰비언트 배경 파티클 위젯
class SeasonalAmbientBackground extends StatefulWidget {
  final Widget child;

  const SeasonalAmbientBackground({super.key, required this.child});

  @override
  State<SeasonalAmbientBackground> createState() => _SeasonalAmbientBackgroundState();
}

class _SeasonalAmbientBackgroundState extends State<SeasonalAmbientBackground>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final List<_SeasonalParticle> _particles = [];
  final List<_TouchSparkle> _touchSparkles = [];
  final math.Random _rng = math.Random();
  AppSeason _lastSeason = AppSeason.autumn;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat();

    _initParticles(AppSeason.autumn);
  }

  void _initParticles(AppSeason season) {
    _particles.clear();
    _lastSeason = season;
    final count = season == AppSeason.summer ? 22 : 26;
    for (var i = 0; i < count; i++) {
      _particles.add(_SeasonalParticle.random(_rng, season));
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handlePointerDown(PointerDownEvent event) {
    _addSparklesAt(event.localPosition);
  }

  void _handlePointerMove(PointerMoveEvent event) {
    if (_rng.nextDouble() < 0.35) {
      _addSparklesAt(event.localPosition);
    }
  }

  void _addSparklesAt(Offset pos) {
    if (_touchSparkles.length > 30) {
      _touchSparkles.removeRange(0, 10);
    }
    for (var i = 0; i < 3; i++) {
      _touchSparkles.add(_TouchSparkle.create(_rng, pos));
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<DokkeyProvider>();
    final enabled = provider.particlesEnabled;
    final currentSeason = provider.effectiveSeason;
    final currentTimeOfDay = provider.effectiveTimeOfDay;

    if (_lastSeason != currentSeason) {
      _initParticles(currentSeason);
    }

    if (!enabled) {
      return widget.child;
    }

    return Listener(
      onPointerDown: _handlePointerDown,
      onPointerMove: _handlePointerMove,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // 1. 시간대별 앰비언트 백그라운드 틴트
          _buildTimeOfDayAmbient(currentTimeOfDay),

          // 2. 사계절 파티클 & 터치 스파클 캔버스
          AnimatedBuilder(
            animation: _controller,
            builder: (context, _) {
              return CustomPaint(
                painter: _SeasonalParticlePainter(
                  particles: _particles,
                  touchSparkles: _touchSparkles,
                  season: currentSeason,
                  timeOfDay: currentTimeOfDay,
                ),
              );
            },
          ),

          // 3. 자식 콘텐츠 (화면 요소)
          widget.child,
        ],
      ),
    );
  }

  Widget _buildTimeOfDayAmbient(AppTimeOfDay time) {
    List<Color> gradientColors;
    switch (time) {
      case AppTimeOfDay.dawn:
        gradientColors = [
          const Color(0xFF0F1B29).withValues(alpha: 0.5),
          const Color(0xFF1E293B).withValues(alpha: 0.2),
          Colors.transparent,
        ];
        break;
      case AppTimeOfDay.day:
        gradientColors = [
          DokkeyTheme.gold.withValues(alpha: 0.04),
          const Color(0xFF1B231D).withValues(alpha: 0.15),
          Colors.transparent,
        ];
        break;
      case AppTimeOfDay.dusk:
        gradientColors = [
          const Color(0xFF2E1225).withValues(alpha: 0.4),
          const Color(0xFF1F1020).withValues(alpha: 0.2),
          Colors.transparent,
        ];
        break;
      case AppTimeOfDay.night:
        gradientColors = [
          const Color(0xFF080C14).withValues(alpha: 0.6),
          const Color(0xFF0D1524).withValues(alpha: 0.3),
          Colors.transparent,
        ];
        break;
    }

    return IgnorePointer(
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: gradientColors,
          ),
        ),
      ),
    );
  }
}

/// 개별 사계절 파티클 모델
class _SeasonalParticle {
  double x; // 0.0 ~ 1.0
  double y; // 0.0 ~ 1.0
  double size;
  double speedY;
  double speedX;
  double rotation;
  double rotationSpeed;
  double opacity;
  double swingProgress;
  double swingSpeed;
  Color color;
  int variant; // 형태 변형 (0, 1, 2)

  _SeasonalParticle({
    required this.x,
    required this.y,
    required this.size,
    required this.speedY,
    required this.speedX,
    required this.rotation,
    required this.rotationSpeed,
    required this.opacity,
    required this.swingProgress,
    required this.swingSpeed,
    required this.color,
    required this.variant,
  });

  factory _SeasonalParticle.random(math.Random rng, AppSeason season) {
    Color color;
    double size;
    double speedY;

    switch (season) {
      case AppSeason.spring:
        // 🌸 벚꽃 / 매화: 부드러운 핑크, 연분홍, 화이트
        final colors = [
          const Color(0xFFFFB7C5),
          const Color(0xFFFFC0CB),
          const Color(0xFFFFE4E1),
          const Color(0xFFFFF0F5),
        ];
        color = colors[rng.nextInt(colors.length)];
        size = rng.nextDouble() * 6 + 6; // 6 ~ 12
        speedY = rng.nextDouble() * 0.0012 + 0.0008;
        break;

      case AppSeason.summer:
        // 🌿 반딧불이: 청록, 에메랄드, 금빛 반짝임
        final colors = [
          const Color(0xFF64FFDA),
          const Color(0xFF80E27E),
          const Color(0xFFFFD54F),
          const Color(0xFF81D4FA),
        ];
        color = colors[rng.nextInt(colors.length)];
        size = rng.nextDouble() * 4 + 3; // 3 ~ 7
        speedY = (rng.nextDouble() - 0.5) * 0.0008; // 위아래 자유 부유
        break;

      case AppSeason.autumn:
        // 🍁 단풍 / 은행: 붉은 단풍, 은행 골드, 앰버, 주황
        final colors = [
          const Color(0xFFE65100),
          const Color(0xFFFFB300),
          const Color(0xFFD84315),
          const Color(0xFFFF8F00),
          const Color(0xFFC2185B),
        ];
        color = colors[rng.nextInt(colors.length)];
        size = rng.nextDouble() * 7 + 7; // 7 ~ 14
        speedY = rng.nextDouble() * 0.0015 + 0.0010;
        break;

      case AppSeason.winter:
        // ❄️ 눈송이 / 서리: 순백, 아이스 블루, 은빛
        final colors = [
          const Color(0xFFFFFFFF),
          const Color(0xFFE1F5FE),
          const Color(0xFFB3E5FC),
          const Color(0xFFEDE7F6),
        ];
        color = colors[rng.nextInt(colors.length)];
        size = rng.nextDouble() * 5 + 3; // 3 ~ 8
        speedY = rng.nextDouble() * 0.0016 + 0.0009;
        break;
    }

    return _SeasonalParticle(
      x: rng.nextDouble(),
      y: rng.nextDouble(),
      size: size,
      speedY: speedY,
      speedX: (rng.nextDouble() - 0.5) * 0.0006,
      rotation: rng.nextDouble() * math.pi * 2,
      rotationSpeed: (rng.nextDouble() - 0.5) * 0.04,
      opacity: rng.nextDouble() * 0.45 + 0.35,
      swingProgress: rng.nextDouble() * math.pi * 2,
      swingSpeed: rng.nextDouble() * 0.03 + 0.015,
      color: color,
      variant: rng.nextInt(3),
    );
  }

  void update(AppSeason season) {
    swingProgress += swingSpeed;
    rotation += rotationSpeed;

    if (season == AppSeason.summer) {
      // 반딧불이 부유 모션
      y += speedY;
      x += speedX + math.sin(swingProgress) * 0.0008;
      if (y < 0.05) speedY = speedY.abs();
      if (y > 0.95) speedY = -speedY.abs();
      if (x < 0.05) speedX = speedX.abs();
      if (x > 0.95) speedX = -speedX.abs();
    } else {
      // 낙하 모션 (봄, 가을, 겨울)
      y += speedY;
      x += speedX + math.sin(swingProgress) * 0.0012;

      if (y > 1.05) {
        y = -0.05;
        x = math.Random().nextDouble();
      }
      if (x < -0.05) x = 1.05;
      if (x > 1.05) x = -0.05;
    }
  }
}

/// 터치/스와이프 시 생성되는 황금 스파클 잔상
class _TouchSparkle {
  Offset position;
  Offset velocity;
  double size;
  double opacity;
  Color color;

  _TouchSparkle({
    required this.position,
    required this.velocity,
    required this.size,
    required this.opacity,
    required this.color,
  });

  factory _TouchSparkle.create(math.Random rng, Offset pos) {
    final colors = [
      DokkeyTheme.goldLight,
      DokkeyTheme.dokFire,
      const Color(0xFFFFFFFF),
      const Color(0xFFFFE082),
    ];
    final angle = rng.nextDouble() * math.pi * 2;
    final speed = rng.nextDouble() * 2.5 + 0.5;

    return _TouchSparkle(
      position: pos + Offset((rng.nextDouble() - 0.5) * 12, (rng.nextDouble() - 0.5) * 12),
      velocity: Offset(math.cos(angle) * speed, math.sin(angle) * speed),
      size: rng.nextDouble() * 3.5 + 2.0,
      opacity: 0.85,
      color: colors[rng.nextInt(colors.length)],
    );
  }

  bool update() {
    position += velocity;
    opacity -= 0.035;
    size *= 0.96;
    return opacity > 0.05;
  }
}

/// 사계절 파티클 렌더러 페인터
class _SeasonalParticlePainter extends CustomPainter {
  final List<_SeasonalParticle> particles;
  final List<_TouchSparkle> touchSparkles;
  final AppSeason season;
  final AppTimeOfDay timeOfDay;

  _SeasonalParticlePainter({
    required this.particles,
    required this.touchSparkles,
    required this.season,
    required this.timeOfDay,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // 1. 계절별 파티클 그리기
    for (final p in particles) {
      p.update(season);
      final offset = Offset(p.x * size.width, p.y * size.height);

      canvas.save();
      canvas.translate(offset.dx, offset.dy);
      canvas.rotate(p.rotation);

      switch (season) {
        case AppSeason.spring:
          _drawCherryPetal(canvas, p);
          break;
        case AppSeason.summer:
          _drawFirefly(canvas, p);
          break;
        case AppSeason.autumn:
          _drawAutumnLeaf(canvas, p);
          break;
        case AppSeason.winter:
          _drawSnowflake(canvas, p);
          break;
      }

      canvas.restore();
    }

    // 2. 터치 스파클 잔상 그리기
    for (var i = touchSparkles.length - 1; i >= 0; i--) {
      final s = touchSparkles[i];
      if (!s.update()) {
        touchSparkles.removeAt(i);
        continue;
      }

      final paint = Paint()
        ..color = s.color.withValues(alpha: s.opacity.clamp(0.0, 1.0))
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.0);

      canvas.drawCircle(s.position, s.size, paint);

      // 밝은 코어
      final corePaint = Paint()
        ..color = Colors.white.withValues(alpha: (s.opacity * 0.9).clamp(0.0, 1.0));
      canvas.drawCircle(s.position, s.size * 0.5, corePaint);
    }
  }

  /// 🌸 벚꽃잎 / 매화 꽃잎 드로잉 (유기적 하트/타원 형태)
  void _drawCherryPetal(Canvas canvas, _SeasonalParticle p) {
    final paint = Paint()
      ..color = p.color.withValues(alpha: p.opacity)
      ..style = PaintingStyle.fill;

    final path = Path();
    final r = p.size;
    path.moveTo(0, -r);
    path.cubicTo(r * 0.7, -r * 0.8, r * 0.9, r * 0.3, 0, r);
    path.cubicTo(-r * 0.9, r * 0.3, -r * 0.7, -r * 0.8, 0, -r);
    canvas.drawPath(path, paint);

    // 은은한 꽃잎 결 하이라이트
    final veinPaint = Paint()
      ..color = Colors.white.withValues(alpha: p.opacity * 0.4)
      ..strokeWidth = 0.6
      ..style = PaintingStyle.stroke;
    canvas.drawLine(Offset(0, -r * 0.6), Offset(0, r * 0.6), veinPaint);
  }

  /// 🌿 반딧불이 드로잉 (부유하는 빛무리 & 펄스 오라)
  void _drawFirefly(Canvas canvas, _SeasonalParticle p) {
    final pulse = (math.sin(p.swingProgress * 2) * 0.3 + 0.7) * p.opacity;

    // 외곽 은은한 오라
    final auraPaint = Paint()
      ..color = p.color.withValues(alpha: (pulse * 0.45).clamp(0.0, 1.0))
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, p.size * 1.5);
    canvas.drawCircle(Offset.zero, p.size * 1.8, auraPaint);

    // 중간 코어
    final midPaint = Paint()
      ..color = p.color.withValues(alpha: (pulse * 0.85).clamp(0.0, 1.0));
    canvas.drawCircle(Offset.zero, p.size * 0.8, midPaint);

    // 중심 순백 빛
    final corePaint = Paint()
      ..color = Colors.white.withValues(alpha: (pulse * 0.95).clamp(0.0, 1.0));
    canvas.drawCircle(Offset.zero, p.size * 0.4, corePaint);
  }

  /// 🍁 단풍 / 은행잎 드로잉 (전통 3지 단풍 및 은행 부채꼴)
  void _drawAutumnLeaf(Canvas canvas, _SeasonalParticle p) {
    final paint = Paint()
      ..color = p.color.withValues(alpha: p.opacity)
      ..style = PaintingStyle.fill;

    final r = p.size;
    final path = Path();

    if (p.variant == 0) {
      // 은행잎 (부채꼴)
      path.moveTo(0, r * 0.8);
      path.lineTo(r * 0.8, -r * 0.4);
      path.cubicTo(r * 0.5, -r * 0.9, -r * 0.5, -r * 0.9, -r * 0.8, -r * 0.4);
      path.close();
    } else {
      // 단풍잎 (3지 다각형)
      path.moveTo(0, -r);
      path.lineTo(r * 0.4, -r * 0.3);
      path.lineTo(r, -r * 0.1);
      path.lineTo(r * 0.5, r * 0.4);
      path.lineTo(0, r * 0.9);
      path.lineTo(-r * 0.5, r * 0.4);
      path.lineTo(-r, -r * 0.1);
      path.lineTo(-r * 0.4, -r * 0.3);
      path.close();
    }

    canvas.drawPath(path, paint);

    // 잎맥 선
    final veinPaint = Paint()
      ..color = Colors.white.withValues(alpha: p.opacity * 0.3)
      ..strokeWidth = 0.7
      ..style = PaintingStyle.stroke;
    canvas.drawLine(Offset(0, r * 0.8), Offset(0, -r * 0.6), veinPaint);
  }

  /// ❄️ 겨울 눈송이 / 서리 결정 드로잉
  void _drawSnowflake(Canvas canvas, _SeasonalParticle p) {
    final r = p.size;

    if (p.variant == 0) {
      // 십자/육각 서리 결정 (Frost Crystal)
      final paint = Paint()
        ..color = p.color.withValues(alpha: p.opacity)
        ..strokeWidth = 1.0
        ..style = PaintingStyle.stroke;

      for (var i = 0; i < 3; i++) {
        canvas.save();
        canvas.rotate(i * math.pi / 3);
        canvas.drawLine(Offset(0, -r), Offset(0, r), paint);
        // 가지
        canvas.drawLine(Offset(-r * 0.3, -r * 0.5), Offset(r * 0.3, -r * 0.5), paint);
        canvas.drawLine(Offset(-r * 0.3, r * 0.5), Offset(r * 0.3, r * 0.5), paint);
        canvas.restore();
      }
    } else {
      // 둥근 솜눈송이 (Snowball)
      final glowPaint = Paint()
        ..color = p.color.withValues(alpha: p.opacity * 0.6)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, r * 0.8);
      canvas.drawCircle(Offset.zero, r, glowPaint);

      final corePaint = Paint()
        ..color = Colors.white.withValues(alpha: p.opacity * 0.9);
      canvas.drawCircle(Offset.zero, r * 0.55, corePaint);
    }
  }

  @override
  bool shouldRepaint(covariant _SeasonalParticlePainter oldDelegate) => true;
}
