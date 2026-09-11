import 'dart:math';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter/services.dart';

import '../core/theme.dart';
import '../providers/dokkey_provider.dart';
import 'core/game_shell.dart';

/// ⛵ 게임 9 (Adventure Stage 3): 바다 항해 — 황금 항구 도달
/// 보트 기울기 물리 + 물 유입 게이지 + 포물선 날치 + 항구 클리어.
class SeaModel {
  final double width, height;
  final Random rng;

  // 보트 상태
  double kkaebiOffset = 0; // -1 ~ 1 (보트 중앙 기준 위치 비율)
  double tilt = 0; // 도 (°)
  double water = 0; // 유입 게이지 (100 도달 시 침몰)
  double distanceLeft = 1000;
  bool gameOver = false;
  bool cleared = false;
  int score = 0;
  int lives = 3;

  // 날치 (포물선)
  final List<FlyingFish> fishes = [];
  double _fishSpawn = 2.0;

  // 파도
  double wavePhase = 0;

  static const double maxTilt = 60;
  static const double tiltSpeed = 42; // °/s (위치 비율당)

  SeaModel({required this.width, required this.height, Random? random})
      : rng = random ?? Random(),
        wavePhase = 0;

  /// [Duck] — 날치 회피 & 물 배출 (게이지 -6)
  void duck() {
    if (gameOver || cleared) return;
    water = max(0, water - 6);
    score += 10;
  }

  /// [Jump] — 날치 회피 & 보트 수평 복원 (기울기 -8°)
  void hop() {
    if (gameOver || cleared) return;
    tilt = tilt > 0 ? max(0, tilt - 8) : min(0, tilt + 8);
    score += 10;
  }

  void moveKkaebi(double deltaRatio) {
    kkaebiOffset = (kkaebiOffset + deltaRatio).clamp(-1.0, 1.0);
  }

  void splash(double amount) {
    water += amount;
  }


  void update(double dt) {
    if (gameOver || cleared) return;

    // 항해 진행
    distanceLeft = max(0, distanceLeft - 62 * dt);
    if (distanceLeft <= 0) {
      cleared = true;
      score += 1000;
      return;
    }

    // 기울기 물리: 깨비 위치가 기울기에 힘을 가함
    final target = kkaebiOffset * maxTilt;
    tilt += (target - tilt) * dt * 1.1;
    // 파도 기울기 교란
    wavePhase += dt;
    tilt += sin(wavePhase * 2.4) * 16 * dt;

    // 전복 판정
    if (tilt.abs() > 45) {
      gameOver = true;
      return;
    }

    // 물 유입: 기울어질수록 물이 차오른다
    water += (tilt.abs() / 45) * 3.2 * dt;
    if (water >= 100) {
      gameOver = true;
      return;
    }

    // 날치 생성 (포물선 도약)
    _fishSpawn -= dt;
    if (_fishSpawn <= 0) {
      _fishSpawn = max(1.1, 2.6 - (1000 - distanceLeft) / 800);
      final fromLeft = rng.nextBool();
      fishes.add(FlyingFish(
        x: fromLeft ? -20 : width + 20,
        dir: fromLeft ? 1 : -1,
        baseY: height * 0.55,
        arc: 40 + rng.nextDouble() * 55,
        speed: 130 + rng.nextDouble() * 90,
      ));
    }
    for (final f in fishes) {
      f.x += f.dir * f.speed * dt;
      f.t += dt;
      f.y = f.baseY - f.arc * sin(f.t * 2.6).clamp(0.0, pi) ;
    }
    fishes.removeWhere((f) => f.x < -40 || f.x > width + 40);

    // 날치 충돌 (회피 실패 → 물 +12)
    final kkaebiScreenX = width / 2 + kkaebiOffset * width * 0.3;
    final kkaebiY = height * 0.62;
    for (final f in fishes) {
      if ((f.x - kkaebiScreenX).abs() < 24 &&
          (f.y - kkaebiY).abs() < 30 &&
          !f.hit) {
        f.hit = true;
        splash(12);
        lives--;
      }
    }
    if (lives <= 0) {
      gameOver = true;
    }
  }
}

class FlyingFish {
  double x, y, t;
  final double dir, baseY, arc, speed;
  bool hit = false;

  FlyingFish({
    required this.x,
    required this.dir,
    required this.baseY,
    required this.arc,
    required this.speed,
  }) : t = 0, y = baseY;
}

/// ⛵ 바다 항해 화면
class KkaebiSeaGame extends StatefulWidget {
  const KkaebiSeaGame({super.key});

  static const String gameId = 'sea';

  @override
  State<KkaebiSeaGame> createState() => _KkaebiSeaGameState();
}

class _KkaebiSeaGameState extends State<KkaebiSeaGame>
    with GameLoopMixin {
  late SeaModel model;
  bool _finished = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      model = SeaModel(
        width: MediaQuery.of(context).size.width,
        height: MediaQuery.of(context).size.height - 100,
      );
      setState(() {});
    });
  }

  @override
  void onUpdate(double dt) {
    if (_finished || model.width == 0) return;
    model.update(dt);
    if (model.gameOver || model.cleared) {
      _finished = true;
      finishGame(
        context,
        gameId: KkaebiSeaGame.gameId,
        title: 'Sea Voyage',
        score: model.score,
        cleared: model.cleared,
        onRetry: () => Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const KkaebiSeaGame()),
        ),
      );
    }
  }

  @override
  void onPaint(Canvas canvas, Size size) {
    // 하늘/바다 배경
    canvas.drawRect(
      Offset.zero & size,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.center,
          colors: [Color(0xFF0F2027), Color(0xFF153A5B)],
        ).createShader(Offset.zero & size),
    );
    final seaTop = size.height * 0.62;
    canvas.drawRect(
      Rect.fromLTWH(0, seaTop, size.width, size.height - seaTop),
      Paint()
        ..shader = const LinearGradient(
          colors: [Color(0xFF134E5E), Color(0xFF0A2A38)],
        ).createShader(Rect.fromLTWH(0, seaTop, size.width, size.height - seaTop)),
    );

    // 파도
    final wavePaint = Paint()
      ..color = Colors.white.withOpacity(0.12)
      ..strokeWidth = 2;
    for (var i = 0; i < 3; i++) {
      final path = Path();
      final wy = seaTop + 14 + i * 18;
      path.moveTo(0, wy);
      for (var x = 0.0; x <= size.width; x += 14) {
        path.lineTo(x, wy + sin(x / 34 + gameTime * 2.2 + i) * 5);
      }
      canvas.drawPath(path, wavePaint);
    }

    if (model.width == 0) return;

    // 물 게이지 (좌측 세로)
    canvas.drawRect(
      Rect.fromLTWH(14, 70, 10, 160),
      Paint()..color = DokkeyTheme.borderDark,
    );
    canvas.drawRect(
      Rect.fromLTWH(14, 230 - 160 * (model.water / 100), 10,
          160 * (model.water / 100)),
      Paint()
        ..color = model.water > 70
            ? DokkeyTheme.dokFire
            : (model.water > 40 ? DokkeyTheme.gold : DokkeyTheme.mintCalm),
    );

    // 날치 (칼치)
    for (final f in model.fishes) {
      canvas.save();
      canvas.translate(f.x, f.y);
      canvas.scale(f.dir, 1);
      canvas.drawOval(
        Rect.fromCenter(center: Offset.zero, width: 26, height: 12),
        Paint()..color = const Color(0xFF80DEEA),
      );
      canvas.drawOval(
        Rect.fromCenter(center: Offset(-10, -6), width: 12, height: 8),
        Paint()..color = const Color(0xFF4DD0E1),
      );
      canvas.restore();
    }

    // 보트 (기울기 적용) — 화면 중앙
    final boatCx = size.width / 2;
    final boatCy = seaTop + 26;
    final tiltRad = model.tilt * pi / 180;
    canvas.save();
    canvas.translate(boatCx, boatCy);
    canvas.rotate(tiltRad);
    // 선체
    final hull = Path()
      ..moveTo(-56, 0)
      ..lineTo(-42, 22)
      ..lineTo(42, 22)
      ..lineTo(56, 0)
      ..close();
    canvas.drawPath(
      hull,
      Paint()
        ..shader = const LinearGradient(colors: [
          Color(0xFF8B5A2B),
          Color(0xFF5D4037),
        ]).createShader(Rect.fromLTWH(-56, 0, 112, 22)),
    );
    // 깨비 (위치 비율 반영)
    final kx = model.kkaebiOffset * 36;
    canvas.drawCircle(Offset(kx, -12), 11, Paint()..color = DokkeyTheme.mintCalm);
    canvas.drawCircle(Offset(kx - 4, -20), 3.4, kkaebiPaint());
    canvas.drawCircle(Offset(kx + 4, -20), 3.4, kkaebiPaint());
    canvas.restore();

    // 물 튀김 (기울기에 따른 유입 시각화)
    if (model.tilt.abs() > 25) {
      final side = tiltRad > 0 ? 1 : -1;
      canvas.drawCircle(
        Offset(boatCx + side * 50, boatCy + 6),
        3 + Random().nextDouble() * 3,
        Paint()..color = Colors.white.withOpacity(0.6),
      );
    }

    // 항구(골드 항구) — 클리어 직전 표시
    if (model.distanceLeft < 150) {
      canvas.drawRect(
        Rect.fromLTWH(size.width - 46, seaTop - 6, 40, seaTop + 20),
        Paint()..color = const Color(0xFFD4AF37).withOpacity(0.8),
      );
      canvas.drawRect(
        Rect.fromLTWH(size.width - 40, seaTop - 46, 28, 40),
        Paint()..color = const Color(0xFFB8860B).withOpacity(0.8),
      );
    }

    // 남은 거리
    final tp = TextPainter(
      text: TextSpan(
        text: '⚓ ${model.distanceLeft.toInt()}m',
        style: TextStyle(
            color: DokkeyTheme.goldLight,
            fontSize: 20,
            fontWeight: FontWeight.w900),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset(size.width / 2 - tp.width / 2, 64));

    particles.paint(canvas);
  }

  Paint kkaebiPaint() => Paint()..color = Colors.black.withOpacity(0.7);

  @override
  Widget build(BuildContext context) {
    final isKo = context.watch<DokkeyProvider>().lang == 'ko';

    return Scaffold(
      backgroundColor: DokkeyTheme.bgDark,
      body: SafeArea(
        child: Column(
          children: [
            GameHud(
              title: '⛵ Sea Voyage',
              score: model.width == 0 ? 0 : model.score,
              rightLabel: '💧${model.width == 0 ? 0 : model.water.toInt()} · ❤×${model.width == 0 ? 3 : model.lives}',
              onQuit: () => Navigator.of(context).pop(),
            ),
            Expanded(
              child: gameCanvas(overlayBuilder: () => const SizedBox.expand()),
            ),
            // 컨트롤: [웅크리기] [좌/우 이동 슬라이더] [점프]
            Container(
              color: DokkeyTheme.surfaceDark,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: SafeArea(
                top: false,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _SeaButton(
                      label: isKo ? '웅크리기' : 'Duck',
                      icon: Icons.arrow_downward_rounded,
                      color: DokkeyTheme.mintCalm,
                      onTap: () => model.duck(),
                    ),
                    // 깨비 좌우 이동 슬라이더
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Slider(
                          value: model.kkaebiOffset,
                          min: -1,
                          max: 1,
                          activeColor: DokkeyTheme.gold,
                          onChanged: (v) {
                            model.moveKkaebi(v - model.kkaebiOffset);
                          },
                        ),
                      ),
                    ),
                    _SeaButton(
                      label: isKo ? '점프' : 'Jump',
                      icon: Icons.arrow_upward_rounded,
                      color: DokkeyTheme.gold,
                      onTap: () => model.hop(),
                    ),
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

class _SeaButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _SeaButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: Column(
        children: [
          Container(
            width: 52,
            height: 44,
            decoration: BoxDecoration(
              color: DokkeyTheme.cardDark,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: color.withOpacity(0.6)),
            ),
            child: Icon(icon, size: 22, color: color),
          ),
          const SizedBox(height: 3),
          Text(label,
              style: TextStyle(color: DokkeyTheme.textMuted, fontSize: 10)),
        ],
      ),
    );
  }
}
