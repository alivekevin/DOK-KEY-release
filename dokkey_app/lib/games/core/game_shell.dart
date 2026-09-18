import 'dart:math';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart' show Ticker;
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/sound_service.dart';
import '../../core/theme.dart';
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
                      ? switch (lang) {
                          'ja' => '🏆 クリア!',
                          'zh' => '🏆 顺利通关!',
                          'hi' => '🏆 पूर्ण!',
                          'de' => '🏆 GESCHAFFT!',
                          'en' => '🏆 CLEAR!',
                          _ => '🏆 게임 클리어!',
                        }
                      : switch (lang) {
                          'ja' => '💥 ゲームオーバー',
                          'zh' => '💥 游戏结束',
                          'hi' => '💥 खेल समाप्त',
                          'de' => '💥 SPIEL ENDE',
                          'en' => '💥 GAME OVER',
                          _ => '💥 게임 종료',
                        },
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
                  switch (lang) {
                    'ja' => 'ハイスコア: $best pt',
                    'zh' => '最高纪录: $best pt',
                    'hi' => 'सर्वश्रेष्ठ: $best pt',
                    'de' => 'Beste: $best pt',
                    'en' => 'Best: $best pt',
                    _ => '최고 기록: $best pt',
                  },
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
                        label: switch (lang) {
                          'ja' => '+${reward.coins} コイン',
                          'zh' => '+${reward.coins} 金币',
                          'hi' => '+${reward.coins} सिक्के',
                          'de' => '+${reward.coins} Münzen',
                          'en' => '+${reward.coins} Coins',
                          _ => '+${reward.coins} 코인',
                        },
                      ),
                      _RewardChip(
                        icon: Icons.favorite_rounded,
                        label: switch (lang) {
                          'ja' => '+${reward.affection} 親愛度',
                          'zh' => '+${reward.affection} 亲密度',
                          'hi' => '+${reward.affection} आत्मीयता',
                          'de' => '+${reward.affection} Zuneigung',
                          'en' => '+${reward.affection} Affection',
                          _ => '+${reward.affection} 친밀도',
                        },
                      ),
                      if (reward.keys > 0)
                        _RewardChip(
                          icon: Icons.key_rounded,
                          label: switch (lang) {
                            'ja' => '+${reward.keys} 鍵',
                            'zh' => '+${reward.keys} 钥匙',
                            'hi' => '+${reward.keys} चाबियां',
                            'de' => '+${reward.keys} Schlüssel',
                            'en' => '+${reward.keys} Keys',
                            _ => '+${reward.keys} 열쇠',
                          },
                        ),
                      if (reward.newRecord)
                        _RewardChip(
                          icon: Icons.emoji_events_rounded,
                          label: switch (lang) {
                            'ja' => 'NEW 新記録!',
                            'zh' => 'NEW 创下新纪录!',
                            'hi' => 'NEW नया रिकॉर्ड!',
                            'de' => 'NEW REKORD!',
                            'en' => 'NEW RECORD!',
                            _ => 'NEW 최고기록!',
                          },
                        ),
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
                          switch (lang) {
                            'ja' => 'リトライ',
                            'zh' => '重试',
                            'hi' => 'पुनः प्रयास',
                            'de' => 'Wiederholen',
                            'en' => 'Retry',
                            _ => '다시하기',
                          },
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
                          switch (lang) {
                            'ja' => '終了',
                            'zh' => '退出',
                            'hi' => 'बाहर निकलें',
                            'de' => 'Beenden',
                            'en' => 'Exit',
                            _ => '나가기',
                          },
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

// ---------------------------------------------------------------------------
// 게임 결과 인라인 바 (화면 가림 없는 하단 도킹 UI - 6개국어 완벽 지원)
// ---------------------------------------------------------------------------
class GameResultBar extends StatelessWidget {
  final String gameId;
  final String title;
  final int score;
  final int best;
  final bool cleared;
  final VoidCallback onRetry;
  final VoidCallback onExit;
  final VoidCallback? onChangeOption;
  final String? changeOptionLabel;
  final IconData changeOptionIcon;

  const GameResultBar({
    super.key,
    required this.gameId,
    required this.title,
    required this.score,
    required this.best,
    required this.cleared,
    required this.onRetry,
    required this.onExit,
    this.onChangeOption,
    this.changeOptionLabel,
    this.changeOptionIcon = Icons.photo_library_rounded,
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

        String clearText;
        if (cleared) {
          switch (lang) {
            case 'ko':
              clearText = '🏆 완성/클리어!';
              break;
            case 'ja':
              clearText = '🏆 クリア！';
              break;
            case 'zh':
              clearText = '🏆 通关成功！';
              break;
            case 'hi':
              clearText = '🏆 पूर्ण!';
              break;
            case 'de':
              clearText = '🏆 GESCHAFFT!';
              break;
            default:
              clearText = '🏆 CLEAR!';
          }
        } else {
          switch (lang) {
            case 'ko':
              clearText = '💥 게임 종료';
              break;
            case 'ja':
              clearText = '💥 ゲームオーバー';
              break;
            case 'zh':
              clearText = '💥 游戏结束';
              break;
            case 'hi':
              clearText = '💥 खेल समाप्त';
              break;
            case 'de':
              clearText = '💥 SPIEL ENDE';
              break;
            default:
              clearText = '💥 GAME OVER';
          }
        }

        String retryLabel;
        switch (lang) {
          case 'ko':
            retryLabel = '다시하기';
            break;
          case 'ja':
            retryLabel = '再挑戦';
            break;
          case 'zh':
            retryLabel = '再试一次';
            break;
          case 'hi':
            retryLabel = 'पुनः प्रयास';
            break;
          case 'de':
            retryLabel = 'Nochmal';
            break;
          default:
            retryLabel = 'Retry';
        }

        String exitLabel;
        switch (lang) {
          case 'ko':
            exitLabel = '나가기';
            break;
          case 'ja':
            exitLabel = '終了';
            break;
          case 'zh':
            exitLabel = '退出';
            break;
          case 'hi':
            exitLabel = 'बाहर';
            break;
          case 'de':
            exitLabel = 'Beenden';
            break;
          default:
            exitLabel = 'Exit';
        }

        return Container(
          width: double.infinity,
          margin: const EdgeInsets.symmetric(vertical: 6),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: const Color(0xFF141923),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: cleared ? const Color(0xFFFFD700) : const Color(0xFFFF5252),
              width: 1.8,
            ),
            boxShadow: [
              BoxShadow(
                color: (cleared ? const Color(0xFFFFD700) : const Color(0xFFFF5252)).withValues(alpha: 0.3),
                blurRadius: 14,
                spreadRadius: 1,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Tier 1: Header & Score Summary Row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        clearText,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w900,
                          color: cleared ? const Color(0xFFFFE66D) : const Color(0xFFFF5252),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.black54,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.white24, width: 0.8),
                        ),
                        child: Text(
                          '$score pt',
                          style: const TextStyle(
                            color: Color(0xFFE2E8F0),
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  Text(
                    isKo ? '최고: $best pt' : 'Best: $best pt',
                    style: const TextStyle(
                      color: Color(0xFFFFD700),
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),

              // Tier 2: Rewards Chips Row (if rewarded)
              if (reward != null) ...[
                const SizedBox(height: 10),
                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    _RewardChip(
                      icon: Icons.monetization_on_rounded,
                      label: isKo ? '+${reward.coins} 코인' : '+${reward.coins}',
                    ),
                    _RewardChip(
                      icon: Icons.favorite_rounded,
                      label: isKo ? '+${reward.affection} 친밀도' : '+${reward.affection}',
                    ),
                    if (reward.keys > 0)
                      _RewardChip(
                        icon: Icons.key_rounded,
                        label: isKo ? '+${reward.keys} 열쇠' : '+${reward.keys} Key',
                      ),
                    if (reward.newRecord)
                      _RewardChip(
                        icon: Icons.emoji_events_rounded,
                        label: isKo ? 'NEW 신기록!' : 'NEW Best!',
                      ),
                  ],
                ),
              ],
              const SizedBox(height: 12),

              // Tier 3: Action Buttons Row
              Row(
                children: [
                  if (onChangeOption != null && changeOptionLabel != null) ...[
                    Expanded(
                      flex: 3,
                      child: ElevatedButton.icon(
                        onPressed: onChangeOption,
                        icon: Icon(changeOptionIcon, size: 14, color: const Color(0xFFFFD54F)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2D2214),
                          foregroundColor: const Color(0xFFFFD54F),
                          side: const BorderSide(color: Color(0xFFFFD54F), width: 1.2),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        label: Text(
                          changeOptionLabel!,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11.5),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                  ],
                  Expanded(
                    flex: 3,
                    child: ElevatedButton.icon(
                      onPressed: onRetry,
                      icon: const Icon(Icons.replay_rounded, size: 14, color: Colors.black),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFFD700),
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        elevation: 2,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      label: Text(
                        retryLabel,
                        style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton.icon(
                      onPressed: onExit,
                      icon: const Icon(Icons.logout_rounded, size: 13, color: Colors.white70),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2D3748),
                        foregroundColor: Colors.white,
                        side: const BorderSide(color: Color(0xFF4A5568), width: 1),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      label: Text(
                        exitLabel,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11.5),
                      ),
                    ),
                  ),
                ],
              ),
            ],
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
// 🕹️ 깨비 오락실 공통 원형 골드 닫기(X) 버튼 (v5.2.3)
// ---------------------------------------------------------------------------
class KkaebiGameCloseButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final double size;

  const KkaebiGameCloseButton({
    super.key,
    this.onPressed,
    this.size = 17,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onPressed ?? () {
        SoundService().playCardFlip();
        Navigator.of(context).pop();
      },
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(5),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.5),
          shape: BoxShape.circle,
          border: Border.all(
            color: DokkeyTheme.gold.withOpacity(0.6),
            width: 1.2,
          ),
        ),
        child: Icon(
          Icons.close_rounded,
          size: size,
          color: DokkeyTheme.goldLight,
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// 게임 HUD (상단 점수바 + 고시인성 원형 골드 나가기 버튼)
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
            // 🕹️ 원형 골드 닫기(X) 버튼 (아케이드 허브와 100% 디자인 통일)
            KkaebiGameCloseButton(onPressed: onQuit),
            const SizedBox(width: 12),
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
                fontSize: 16.5,
                letterSpacing: 0.3,
                shadows: [
                  Shadow(
                    color: Colors.black,
                    offset: Offset(0, 1.2),
                    blurRadius: 3,
                  ),
                ],
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
