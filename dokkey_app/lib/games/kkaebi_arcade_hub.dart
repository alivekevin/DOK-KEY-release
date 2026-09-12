import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/sound_service.dart';
import '../widgets/pro_pass_dialog.dart';
import '../core/theme.dart';
import '../providers/dokkey_provider.dart';
import 'kkaebi_breakout_game.dart';
import 'kkaebi_bubble_game.dart';
import 'kkaebi_cave_game.dart';
import 'kkaebi_jungle_game.dart';
import 'kkaebi_magic_square_game.dart';
import 'kkaebi_minesweeper_game.dart';
import 'kkaebi_shooter_game.dart';
import 'kkaebi_sudoku_game.dart';
import 'kkaebi_tetris_game.dart';
import 'kkaebi_xsudoku_game.dart';
import 'kkaebi_cross_magicsquare_game.dart';
import 'kkaebi_hex_minesweeper_game.dart';
import 'core/game_shell.dart';

/// 🕹️ 깨비 오락실 허브 (v4.9.1)
/// 3x3 9개 클래식 아케이드 그리드 & 상단 3개(스도쿠·마방진·지뢰찾기) 전용 '+ 변형 모드' 탑재.
class KkaebiArcadeHubDialog extends StatelessWidget {
  const KkaebiArcadeHubDialog({super.key});

  static void show(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => const KkaebiArcadeHubDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<DokkeyProvider>();
    final isKo = provider.lang == 'ko';
    final quotaLeft = provider.isProUser ? -1 : (3 - provider.arcadePlaysToday).clamp(0, 3);

    final games = <_ArcadeEntry>[
      _ArcadeEntry(
        '🔢',
        isKo ? '깨비 스도쿠' : 'Kkaebi Sudoku',
        KkaebiSudokuGame.gameId,
        () => const KkaebiSudokuGame(),
        bonusTag: isKo ? '+ X모드' : '+ X-Mode',
        bonusBuilder: () => const KkaebiXSudokuGame(),
        gradient: const [Color(0xFF1A237E), Color(0xFF0D1B2A)],
        accent: const Color(0xFF448AFF),
      ),
      _ArcadeEntry(
        '🧮',
        isKo ? '깨비 마방진' : 'Magic Square',
        KkaebiMagicSquareGame.gameId,
        () => const KkaebiMagicSquareGame(),
        bonusTag: isKo ? '+ 크로스' : '+ Cross',
        bonusBuilder: () => const KkaebiCrossMagicSquareGame(),
        gradient: const [Color(0xFF4A148C), Color(0xFF1F0933)],
        accent: const Color(0xFFE040FB),
      ),
      _ArcadeEntry(
        '💣',
        isKo ? '깨비 지뢰찾기' : 'Minesweeper',
        KkaebiMinesweeperGame.gameId,
        () => const KkaebiMinesweeperGame(),
        bonusTag: isKo ? '+ 육각' : '+ Hex',
        bonusBuilder: () => const KkaebiHexMinesweeperGame(),
        gradient: const [Color(0xFF37474F), Color(0xFF1E272C)],
        accent: const Color(0xFFFF5252),
      ),
      _ArcadeEntry(
        '🧱',
        isKo ? '깨비 테트리스' : 'Tetris',
        KkaebiTetrisGame.gameId,
        () => const KkaebiTetrisGame(),
        gradient: const [Color(0xFF006064), Color(0xFF00252A)],
        accent: const Color(0xFF00E5FF),
      ),
      _ArcadeEntry(
        '💥',
        isKo ? '깨비 벽돌깨기' : 'Breakout',
        KkaebiBreakoutGame.gameId,
        () => const KkaebiBreakoutGame(),
        gradient: const [Color(0xFFBF360C), Color(0xFF330E03)],
        accent: const Color(0xFFFF9100),
      ),
      _ArcadeEntry(
        '🫧',
        isKo ? '깨비 뽀글뽀글' : 'Bubble Bobble',
        KkaebiBubbleGame.gameId,
        () => const KkaebiBubbleGame(),
        gradient: const [Color(0xFF880E4F), Color(0xFF2E051B)],
        accent: const Color(0xFFFF4081),
      ),
      _ArcadeEntry(
        '🚀',
        isKo ? '깨비 X-RION' : 'Kkaebi X-RION',
        KkaebiShooterGame.gameId,
        () => const KkaebiShooterGame(),
        gradient: const [Color(0xFF0D47A1), Color(0xFF021024)],
        accent: const Color(0xFF00E5FF),
      ),
      _ArcadeEntry(
        '🏛️',
        isKo ? '깨비 고대유적' : 'Ancient Ruins',
        KkaebiJungleGame.gameId,
        () => const KkaebiJungleGame(),
        gradient: const [Color(0xFF4E342E), Color(0xFF1D130F)],
        accent: const Color(0xFFFFD54F),
      ),
      _ArcadeEntry(
        '🏄',
        isKo ? '깨비 윈드서퍼' : 'Windsurfer',
        KkaebiCaveGame.gameId,
        () => const KkaebiCaveGame(),
        gradient: const [Color(0xFF00695C), Color(0xFF00251F)],
        accent: const Color(0xFF69F0AE),
      ),
    ];

    void onLaunchGame(Widget Function() builder) async {
      final ok = await provider.consumeArcadePlay();
      if (!ok) {
        SoundService().playRiddleWrong();
        if (context.mounted) ProPassDialog.show(context);
        return;
      }
      if (!context.mounted) return;
      SoundService().playSuccessChime();
      Navigator.of(context).pop();
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => builder()),
      );
    }

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 24),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 480, maxHeight: 670),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF261909), Color(0xFF120E08)],
          ),
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: DokkeyTheme.gold, width: 2.2),
          boxShadow: [
            BoxShadow(
              color: DokkeyTheme.gold.withOpacity(0.25),
              blurRadius: 28,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 16, 14, 4),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: DokkeyTheme.gold.withOpacity(0.18),
                      shape: BoxShape.circle,
                    ),
                    child: const Text('🕹️', style: TextStyle(fontSize: 20)),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    isKo ? '깨비 오락실' : 'Kkaebi Arcade',
                    style: TextStyle(
                      color: DokkeyTheme.goldLight,
                      fontWeight: FontWeight.w900,
                      fontSize: 18.5,
                      letterSpacing: 0.5,
                      shadows: [
                        Shadow(
                          color: DokkeyTheme.gold.withOpacity(0.6),
                          blurRadius: 10,
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  // 일일 무료 플레이
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: provider.isProUser
                          ? Colors.green.withOpacity(0.18)
                          : DokkeyTheme.surfaceDark,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: provider.isProUser ? Colors.greenAccent : DokkeyTheme.borderDark,
                      ),
                    ),
                    child: Text(
                      provider.isProUser
                          ? (isKo ? 'PRO ∞' : 'PRO ∞')
                          : '${provider.arcadeQuotaRemaining ? quotaLeft : 0}/3',
                      style: TextStyle(
                        color: provider.isProUser
                            ? Colors.greenAccent
                            : (provider.arcadeQuotaRemaining ? DokkeyTheme.goldLight : Colors.redAccent),
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // 닫기 (✕) 버튼
                  InkWell(
                    onTap: () {
                      SoundService().playCardFlip();
                      Navigator.of(context).pop();
                    },
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      padding: const EdgeInsets.all(5),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.5),
                        shape: BoxShape.circle,
                        border: Border.all(color: DokkeyTheme.gold.withOpacity(0.6), width: 1.2),
                      ),
                      child: Icon(
                        Icons.close_rounded,
                        size: 17,
                        color: DokkeyTheme.goldLight,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18),
              child: Divider(color: DokkeyTheme.gold.withOpacity(0.25), thickness: 1),
            ),

            // 3x3 Classic Game Grid
            Expanded(
              child: GridView.builder(
                padding: const EdgeInsets.fromLTRB(14, 8, 14, 10),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  childAspectRatio: 0.76,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                ),
                itemCount: games.length,
                itemBuilder: (ctx, idx) {
                  final g = games[idx];
                  return _GameCard(
                    entry: g,
                    enabled: provider.arcadeQuotaRemaining,
                    onTap: () => onLaunchGame(g.builder),
                    onTapBonus: g.bonusBuilder != null ? () => onLaunchGame(g.bonusBuilder!) : null,
                  );
                },
              ),
            ),

            // Footer
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      isKo
                          ? '상단 3개 게임의 [+ 변형] 터치 시 보너스 모드 실행'
                          : 'Tap [+ Mode] on top games for bonus variants',
                      style: TextStyle(color: DokkeyTheme.textMuted, fontSize: 10.5),
                    ),
                  ),
                  if (!provider.isProUser && provider.arcadePlaysToday >= 3)
                    TextButton.icon(
                      onPressed: () {
                        SoundService().playCardFlip();
                        ProPassDialog.show(context);
                      },
                      icon: const Icon(Icons.workspace_premium_rounded, size: 14, color: Colors.amber),
                      label: Text(
                        isKo ? 'PRO 무제한 해금 👑' : 'Go PRO for Unlimited 👑',
                        style: const TextStyle(color: Colors.amber, fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        backgroundColor: Colors.amber.withOpacity(0.12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ArcadeEntry {
  final String emoji;
  final String label;
  final String gameId;
  final Widget Function() builder;
  final String? bonusTag;
  final Widget Function()? bonusBuilder;
  final List<Color> gradient;
  final Color accent;

  const _ArcadeEntry(
    this.emoji,
    this.label,
    this.gameId,
    this.builder, {
    this.bonusTag,
    this.bonusBuilder,
    required this.gradient,
    required this.accent,
  });
}

class _GameCard extends StatelessWidget {
  final _ArcadeEntry entry;
  final bool enabled;
  final VoidCallback onTap;
  final VoidCallback? onTapBonus;

  const _GameCard({
    required this.entry,
    required this.enabled,
    required this.onTap,
    this.onTapBonus,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<int>(
      future: ArcadeScores.get(entry.gameId),
      builder: (ctx, snap) {
        final best = snap.data ?? 0;
        return Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: enabled ? onTap : null,
            borderRadius: BorderRadius.circular(18),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: entry.gradient,
                ),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: best > 0 ? entry.accent : entry.accent.withOpacity(0.4),
                  width: 1.4,
                ),
                boxShadow: [
                  BoxShadow(
                    color: (best > 0 ? entry.accent : entry.gradient.first).withOpacity(0.25),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(5),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: entry.accent.withOpacity(0.18),
                      border: Border.all(
                        color: entry.accent.withOpacity(0.4),
                        width: 1.0,
                      ),
                    ),
                    child: Text(entry.emoji, style: const TextStyle(fontSize: 26)),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    entry.label,
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 11.5,
                      letterSpacing: -0.2,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    best > 0 ? '$best pt' : '-',
                    style: TextStyle(
                      color: best > 0 ? entry.accent : Colors.white38,
                      fontSize: 9.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (entry.bonusTag != null && onTapBonus != null) ...[
                    const SizedBox(height: 4),
                    InkWell(
                      onTap: enabled ? onTapBonus : null,
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFF7C4DFF).withOpacity(0.35),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFFB388FF), width: 1.2),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF7C4DFF).withOpacity(0.4),
                              blurRadius: 4,
                            ),
                          ],
                        ),
                        child: Text(
                          entry.bonusTag!,
                          style: const TextStyle(
                            color: Color(0xFFEA80FC),
                            fontSize: 9.0,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
