import 'dart:math';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart' show Ticker;
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/sound_service.dart';
import '../../providers/dokkey_provider.dart';

/// 🕹️ DOK-KEY 아케이드 공용 셸 (v4.8.0)
/// 9게임이 공유하는 파티클·화면 쉐이크·HUD·리워드·고득점 인프라.
/// 게임별 코드 <150KB / 60fps(delta-time) 보장.

// ---------------------------------------------------------------------------
// 고득점 저장소
// ---------------------------------------------------------------------------
class ArcadeScores {
  ArcadeScores._();

  static const String _prefix = 'pref_hs_';

  static Future<int> get(String gameId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getInt('$_prefix$gameId') ?? 0;
    } catch (_) {
      return 0;
    }
  }

  /// 신기록이면 true
  static Future<bool> submit(String gameId, int score) async {
    final best = await get(gameId);
    if (score > best) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('$_prefix$gameId', score);
      return true;
    }
    return false;
  }
}

// ---------------------------------------------------------------------------
// 게임 리워드 (코인 10~100 + 친밀도 +5~30 + 보너스 열쇠)
// ---------------------------------------------------------------------------
class GameReward {
  final int coins;
  final int affection;
  final int keys;
  final bool newRecord;

  const GameReward({
    required this.coins,
    required this.affection,
    required this.keys,
    required this.newRecord,
  });
}

Future<GameReward> dispatchGameReward(
  BuildContext context, {
  required String gameId,
  required int score,
  required bool cleared,
}) async {
  final provider = context.read<DokkeyProvider>();
  final newRecord = await ArcadeScores.submit(gameId, score);
  final coins = (score ~/ 10).clamp(10, 100);
  final affection = (5 + (score / 50).floor()).clamp(5, 30);
  final keys = cleared ? 1 : 0;

  await provider.addCoins(coins);
  await provider.addKkaebiAffection(affection, reason: 'game_$gameId');
  if (keys > 0) await provider.addBonusKeys(keys);

  return GameReward(
    coins: coins,
    affection: affection,
    keys: keys,
    newRecord: newRecord,
  );
}

// ---------------------------------------------------------------------------
// 게임 결과 다이얼로그 (모든 게임 공용 - 고시인성 UI)
// ---------------------------------------------------------------------------
class GameResultDialog extends StatelessWidget {
  final String gameId;
  final String title;
  final int score;
  final int best;
  final bool cleared;
  final VoidCallback onRetry;
  final VoidCallback onExit;

  const GameResultDialog({
    super.key,
    required this.gameId,
    required this.title,
    required this.score,
    required this.best,
    required this.cleared,
    required this.onRetry,
    required this.onExit,
  });

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<DokkeyProvider>();
    final lang = provider.lang;
    final isKo = lang == 'ko';

    return FutureBuilder<GameReward>(
      future: dispatchGameReward(context, gameId: gameId, score: score, cleared: cleared),
      builder: (context, snap) {
        final reward = snap.data;
        return Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.all(24),
            constraints: const BoxConstraints(maxWidth: 390),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topCenter,
                colors: [Color(0xFF222B38), Color(0xFF141923)],
              ),
              borderRadius: BorderRadius.circular(26),
              border: Border.all(
                color: cleared ? const Color(0xFFFFD700) : const Color(0xFFFF5252),
                width: 2.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: (cleared ? const Color(0xFFFFD700) : const Color(0xFFFF5252)).withOpacity(0.3),
                  blurRadius: 25,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  cleared
                      ? (isKo ? '🏆 게임 클리어!' : '🏆 CLEAR!')
                      : (isKo ? '💥 게임 종료' : '💥 GAME OVER'),
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    color: cleared ? const Color(0xFFFFE66D) : const Color(0xFFFF5252),
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.black38,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '$title · $score pt',
                    style: const TextStyle(
                      color: Color(0xFFE2E8F0),
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  isKo
                      ? '최고 기록: $best pt'
                      : (lang == 'ja' ? 'ハ이스コア: $best pt' : 'Best: $best pt'),
                  style: const TextStyle(
                    color: Color(0xFFFFD700),
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                if (snap.connectionState == ConnectionState.done && reward != null) ...[
                  const SizedBox(height: 16),
                  Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 8,
                    runSpacing: 6,
                    children: [
                      _RewardChip(
                          icon: Icons.monetization_on_rounded,
                          label: '+${reward.coins} 코인'),
                      _RewardChip(
                          icon: Icons.favorite_rounded,
                          label: '+${reward.affection} 친밀도'),
                      if (reward.keys > 0)
                        _RewardChip(icon: Icons.key_rounded, label: '+${reward.keys} 열쇠'),
                      if (reward.newRecord)
                        const _RewardChip(icon: Icons.emoji_events_rounded, label: 'NEW 최고기록!'),
                    ],
                  ),
                ],
                const SizedBox(height: 24),
                Row(
                  children: [
                    // 다시하기 버튼 (황금 고시인성)
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: onRetry,
                        icon: const Icon(Icons.replay_rounded, size: 19, color: Colors.black),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFFD700),
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          elevation: 4,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        label: Text(
                          isKo ? '다시하기' : 'Retry',
                          style: const TextStyle(
                            color: Colors.black,
                            fontWeight: FontWeight.w900,
                            fontSize: 15,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    // 나가기 버튼 (선명한 다크솔리드 고시인성)
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: onExit,
                        icon: const Icon(Icons.logout_rounded, size: 18, color: Colors.white),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF333D4F),
                          foregroundColor: Colors.white,
                          side: const BorderSide(color: Color(0xFF64748B), width: 1.5),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          elevation: 2,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        label: Text(
                          isKo ? '나가기' : 'Exit',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                            fontSize: 15,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _RewardChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _RewardChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFFFD700).withOpacity(0.18),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFFFD700).withOpacity(0.6), width: 1.2),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: const Color(0xFFFFD700)),
          const SizedBox(width: 5),
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFFFFE66D),
              fontWeight: FontWeight.w800,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// 게임 HUD (상단 점수바 + 고시인성 나가기 버튼)
// ---------------------------------------------------------------------------
class GameHud extends StatelessWidget {
  final String title;
  final int score;
  final String rightLabel; // lives / timer / etc.
  final VoidCallback onQuit;
  final Color accent;

  const GameHud({
    super.key,
    required this.title,
    required this.score,
    required this.rightLabel,
    required this.onQuit,
    Color? accent,
  }) : accent = accent ?? const Color(0xFFD4AF37);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: const BoxDecoration(
        color: Color(0xFF1E2532),
        border: Border(bottom: BorderSide(color: Color(0xFF333D4F), width: 1.5)),
      ),
      child: SafeArea(
        bottom: false,
        child: Row(
          children: [
            // 선명한 나가기 뱃지 버튼
            InkWell(
              onTap: onQuit,
              borderRadius: BorderRadius.circular(10),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: const Color(0xFF333D4F),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFF64748B), width: 1.2),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.arrow_back_ios_new_rounded, size: 12, color: Colors.white),
                    SizedBox(width: 4),
                    Text(
                      '종료',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 12),
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 15,
              ),
            ),
            const Spacer(),
            Text(
              '$score pt',
              style: TextStyle(
                color: accent,
                fontWeight: FontWeight.w900,
                fontSize: 16,
              ),
            ),
            const SizedBox(width: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: Colors.black45,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                rightLabel,
                style: const TextStyle(
                  color: Color(0xFFCBD5E1),
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// 파티클 시스템 (스파크·폭발·오라 공용)
// ---------------------------------------------------------------------------
class GParticle {
  double x, y, vx, vy, life, maxLife, size;
  final Color color;
  final double spin;
  double angle;

  GParticle({
    required this.x,
    required this.y,
    required this.vx,
    required this.vy,
    required this.maxLife,
    required this.size,
    required this.color,
    this.spin = 0,
    this.angle = 0,
  }) : life = maxLife;
}

class GameParticles {
  final List<GParticle> _particles = [];
  final Random rng;

  GameParticles({int? seed}) : rng = Random(seed);

  bool get isEmpty => _particles.isEmpty;

  void burst({
    required double x,
    required double y,
    required Color color,
    int count = 18,
    double speed = 160,
    double size = 4,
    double life = 0.7,
  }) {
    for (var i = 0; i < count; i++) {
      final angle = rng.nextDouble() * 2 * pi;
      final sp = speed * (0.4 + rng.nextDouble() * 0.9);
      _particles.add(GParticle(
        x: x,
        y: y,
        vx: cos(angle) * sp,
        vy: sin(angle) * sp,
        maxLife: life * (0.6 + rng.nextDouble() * 0.7),
        size: size * (0.5 + rng.nextDouble()),
        color: color,
        spin: rng.nextDouble() * 8 - 4,
      ));
    }
  }

  void update(double dt) {
    for (final p in _particles) {
      p.x += p.vx * dt;
      p.y += p.vy * dt;
      p.vy += 260 * dt; // 중력
      p.angle += p.spin * dt;
      p.life -= dt;
    }
    _particles.removeWhere((p) => p.life <= 0);
  }

  void paint(Canvas canvas) {
    for (final p in _particles) {
      final opacity = (p.life / p.maxLife).clamp(0.0, 1.0);
      canvas.save();
      canvas.translate(p.x, p.y);
      canvas.rotate(p.angle);
      canvas.drawRect(
        Rect.fromCenter(
          center: Offset.zero,
          width: p.size,
          height: p.size * 0.7,
        ),
        Paint()..color = p.color.withOpacity(opacity),
      );
      canvas.restore();
    }
  }
}

// ---------------------------------------------------------------------------
// 화면 쉐이크 (사인 기반 trauma 감쇠)
// ---------------------------------------------------------------------------
class ScreenShake {
  double _trauma = 0;

  void add(double amount) => _trauma = min(1.0, _trauma + amount);

  Offset offset(double t, double intensity) {
    if (_trauma <= 0) return Offset.zero;
    final decay = _trauma * _trauma * intensity;
    return Offset(
      sin(t * 44) * decay,
      cos(t * 39) * decay,
    );
  }

  void update(double dt) {
    _trauma = max(0.0, _trauma - dt * 1.4);
  }
}

// ---------------------------------------------------------------------------
// 게임 페이지 공통 스캐폴드 (Ticker 루프 + 쉐이크 적용)
// ---------------------------------------------------------------------------
mixin GameLoopMixin<T extends StatefulWidget> on State<T> {
  Ticker? _ticker;
  Duration _lastElapsed = Duration.zero;
  double gameTime = 0;
  final GameParticles particles = GameParticles();
  final ValueNotifier<double> _tickNotifier = ValueNotifier<double>(0);

  void onUpdate(double dt);
  void onPaint(Canvas canvas, Size size);

  ScreenShake shake = ScreenShake();
  double shakeIntensity = 6;

  @override
  void initState() {
    super.initState();
    _ticker = Ticker(_onTick);
    _ticker!.start();
  }

  void _onTick(Duration elapsed) {
    final dt = ((elapsed - _lastElapsed).inMicroseconds / 1e6).clamp(0.0, 0.05);
    _lastElapsed = elapsed;
    if (dt <= 0) return;
    gameTime += dt;
    shake.update(dt);
    particles.update(dt);
    onUpdate(dt);
    _tickNotifier.value = gameTime;
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _ticker?.dispose();
    _tickNotifier.dispose();
    super.dispose();
  }

  Widget gameCanvas({required Widget Function() overlayBuilder}) {
    return LayoutBuilder(builder: (context, constraints) {
      return Stack(
        children: [
          Positioned.fill(
            child: CustomPaint(
              size: Size.infinite,
              painter: _GameCanvasPainter(
                repaint: _tickNotifier,
                render: (canvas, s) => onPaint(canvas, s),
              ),
            ),
          ),
          Positioned.fill(
            child: Transform.translate(
              offset: shake.offset(gameTime, shakeIntensity),
              child: overlayBuilder(),
            ),
          ),
        ],
      );
    });
  }
}

class _GameCanvasPainter extends CustomPainter {
  final void Function(Canvas canvas, Size size) render;

  _GameCanvasPainter({
    required Listenable repaint,
    required this.render,
  }) : super(repaint: repaint);

  @override
  void paint(Canvas canvas, Size size) => render(canvas, size);

  @override
  bool shouldRepaint(covariant _GameCanvasPainter oldDelegate) => true;
}

// ---------------------------------------------------------------------------
// 게임 종료 헬퍼
// ---------------------------------------------------------------------------
Future<void> finishGame(
  BuildContext context, {
  required String gameId,
  required String title,
  required int score,
  required bool cleared,
  required VoidCallback onRetry,
}) async {
  SoundService().playGong();
  HapticFeedback.mediumImpact();
  final best = await ArcadeScores.get(gameId);
  if (!context.mounted) return;
  await showDialog(
    context: context,
    barrierDismissible: false,
    builder: (ctx) => GameResultDialog(
      gameId: gameId,
      title: title,
      score: score,
      best: max(best, score),
      cleared: cleared,
      onRetry: () {
        Navigator.of(ctx).pop(); // 결과 닫기
        Navigator.of(ctx).pop(); // 게임 화면 닫기
        onRetry(); // 재시작 (호출 측에서 다시 push)
      },
      onExit: () {
        Navigator.of(ctx).pop();
        Navigator.of(ctx).pop();
      },
    ),
  );
}
