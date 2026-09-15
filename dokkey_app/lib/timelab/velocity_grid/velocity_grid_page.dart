import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../core/sound_service.dart';
import '../../core/theme.dart';
import '../../providers/dokkey_provider.dart';
import '../../widgets/pro_pass_dialog.dart';
import '../core/timelab_i18n.dart';
import '../core/timelab_theme_engine.dart';
import '../models/timelab_models.dart';
import '../core/timelab_screen_keeper.dart';
import 'velocity_grid_engine.dart';
import 'velocity_records_dialog.dart';

/// ⚡ 모듈 2: 9-레인 그리드 스톱워치 (The Velocity Grid) 가변형 벤토 그리드
class VelocityGridPage extends StatefulWidget {
  const VelocityGridPage({super.key});

  @override
  State<VelocityGridPage> createState() => _VelocityGridPageState();
}

class _VelocityGridPageState extends State<VelocityGridPage>
    with SingleTickerProviderStateMixin {
  late final VelocityGridEngine _engine;
  late final AnimationController _animCtrl;
  bool _summaryShown = false;

  @override
  void initState() {
    super.initState();
    _engine = VelocityGridEngine(lang: context.read<DokkeyProvider>().lang);
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();

    _engine.addListener(_onEngineUpdate);
  }

  void _onEngineUpdate() {
    if (_engine.allFinished && !_summaryShown) {
      _summaryShown = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _showFinishSummaryModal(context.read<DokkeyProvider>().lang);
        }
      });
    }
  }

  @override
  void dispose() {
    _engine.removeListener(_onEngineUpdate);
    _animCtrl.dispose();
    _engine.dispose();
    TimeLabScreenKeeper.release();
    super.dispose();
  }

  String _formatLapTime(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    final ms = (d.inMilliseconds.remainder(1000) ~/ 10).toString().padLeft(2, '0');
    return '$m:$s.$ms';
  }

  void _showSaveRecordDialog(BuildContext dialogCtx, String lang) {
    final isPro = context.read<DokkeyProvider>().isProUser;
    if (!isPro) {
      SoundService().playCardFlip();
      ProPassDialog.show(context);
      return;
    }

    final titleCtrl = TextEditingController(
      text: TimelabI18n.defaultRecordTitle(lang, _engine.laneCount),
    );

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF161E2E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Text('💾', style: TextStyle(fontSize: 20)),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                TimelabI18n.saveToVault(lang),
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(TimelabI18n.recordTitlePrompt(lang), style: const TextStyle(color: Colors.white70, fontSize: 13)),
            const SizedBox(height: 10),
            TextField(
              controller: titleCtrl,
              autofocus: true,
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              decoration: InputDecoration(
                filled: true,
                fillColor: const Color(0xFF0D131F),
                hintText: TimelabI18n.recordTitleHint(lang),
                hintStyle: const TextStyle(color: Colors.white38),
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.white24)),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFFFD700), width: 1.5)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(TimelabI18n.cancelLabel(lang), style: const TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFFD700),
              foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () async {
              final title = titleCtrl.text.trim();
              await _engine.saveCurrentRecord(title);
              if (ctx.mounted) Navigator.of(ctx).pop();
              if (mounted) {
                HapticFeedback.heavyImpact();
                SoundService().playCoinJangle();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(TimelabI18n.recordSavedToast(lang, title)),
                    backgroundColor: DokkeyTheme.cardDark,
                  ),
                );
              }
            },
            child: Text(TimelabI18n.saveRecordLabel(lang), style: const TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showFinishSummaryModal(String lang) {
    final sorted = [..._engine.lanes]..sort((a, b) {
        if (a.rank == null) return 1;
        if (b.rank == null) return -1;
        return a.rank!.compareTo(b.rank!);
      });

    final isPro = context.read<DokkeyProvider>().isProUser;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: Container(
            padding: const EdgeInsets.all(22),
            constraints: const BoxConstraints(maxWidth: 420),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF1E2638), Color(0xFF0F1420)],
              ),
              borderRadius: BorderRadius.circular(26),
              border: Border.all(color: const Color(0xFFFFD700), width: 2),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFFFD700).withValues(alpha: 0.35),
                  blurRadius: 28,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('🏆', style: TextStyle(fontSize: 42)),
                const SizedBox(height: 6),
                Text(
                  TimelabI18n.allFinishedTitle(lang),
                  style: const TextStyle(
                    color: Color(0xFFFFE66D),
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'VELOCITY GRID FINAL RANKINGS',
                  style: TextStyle(color: Colors.white54, fontSize: 10.5, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                Flexible(
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: sorted.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 6),
                    itemBuilder: (_, idx) {
                      final l = sorted[idx];
                      final isFirst = l.rank == 1;
                      final isSecond = l.rank == 2;
                      final isThird = l.rank == 3;

                      final medal = TimelabI18n.rankLabel(lang, l.rank ?? 0);

                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: isFirst
                              ? const Color(0xFFFFD700).withValues(alpha: 0.18)
                              : Colors.black26,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isFirst ? const Color(0xFFFFD700) : Colors.white12,
                            width: isFirst ? 1.5 : 1.0,
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Text(
                                  medal,
                                  style: TextStyle(
                                    color: isFirst
                                        ? const Color(0xFFFFE66D)
                                        : (isSecond ? const Color(0xFFE2E8F0) : (isThird ? const Color(0xFFFFAB40) : Colors.white70)),
                                    fontWeight: FontWeight.w900,
                                    fontSize: 14,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  l.name,
                                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                                ),
                              ],
                            ),
                            Text(
                              l.lapTime != null ? _formatLapTime(l.lapTime!) : '--:--.--',
                              style: TextStyle(
                                fontFamily: 'monospace',
                                color: isFirst ? const Color(0xFFFFE66D) : Colors.white,
                                fontWeight: FontWeight.w900,
                                fontSize: 15,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 16),

                // 💾 기록 영구 저장 버튼 (PRO)
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => _showSaveRecordDialog(ctx, lang),
                    icon: const Icon(Icons.bookmark_add_rounded, size: 18, color: Colors.black),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFFE66D),
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    label: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Flexible(
                          child: Text(
                            TimelabI18n.saveToVault(lang),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13.5),
                          ),
                        ),
                        if (!isPro) ...[
                          const SizedBox(width: 6),
                          const Text('👑 PRO', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                        ],
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.of(ctx).pop();
                          _summaryShown = false;
                          _engine.reset();
                        },
                        icon: const Icon(Icons.replay_rounded, size: 18, color: Colors.white70),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2D3748),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        label: Text(TimelabI18n.remeasureLabel(lang), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => Navigator.of(ctx).pop(),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1E2532),
                          foregroundColor: Colors.white70,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        child: Text(TimelabI18n.closeLabel(lang), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
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

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([_engine, _animCtrl]),
      builder: (context, _) {
        final lang = context.watch<DokkeyProvider>().lang;
        final cfg = TimelabThemeConfig.of(_engine.theme);

        return Scaffold(
          backgroundColor: cfg.backgroundColor,
          body: Stack(
            children: [
              // Background Canvas
              Positioned.fill(
                child: CustomPaint(
                  painter: TimelabBackgroundPainter(
                    theme: _engine.theme,
                    animationValue: _animCtrl.value,
                  ),
                ),
              ),

              // Main Content Layer
              SafeArea(
                child: Column(
                  children: [
                    // Top Bar (Back, Title, Runner Count Selector, Theme)
                    _buildTopBar(cfg, lang),

                    // Stopwatch Global Master Timer Display
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: _buildMasterTimer(cfg),
                    ),

                    // Dynamic Bento Grid (1~3: Wide, 4~6: 2-Col, 7~9: 3x3)
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        child: _buildBentoGrid(cfg, lang),
                      ),
                    ),

                    const SizedBox(height: 10),

                    // Bottom Big START/GO / RESET Bar
                    Padding(
                      padding: const EdgeInsets.fromLTRB(14, 0, 14, 16),
                      child: _buildBottomControls(cfg, lang),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTopBar(TimelabThemeConfig cfg, String lang) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
            onPressed: () => Navigator.of(context).pop(),
          ),
          const SizedBox(width: 4),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                TimelabI18n.module2Title(lang),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: cfg.primaryColor,
                  fontWeight: FontWeight.w900,
                  fontSize: 16,
                  letterSpacing: 0.5,
                ),
              ),
              Text(
                'THE VELOCITY GRID · ${TimelabI18n.runnersCount(lang, _engine.laneCount)}',
                style: const TextStyle(color: Colors.white54, fontSize: 10.5, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const Spacer(),
          // 기록 보관함 버튼 (PRO 기능)
          IconButton(
            icon: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: cfg.cardColor,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: cfg.borderColor.withValues(alpha: 0.6), width: 1.2),
              ),
              child: const Icon(Icons.history_edu_rounded, color: Colors.white, size: 17),
            ),
            tooltip: TimelabI18n.viewRecords(lang),
            onPressed: () {
              final isPro = context.read<DokkeyProvider>().isProUser;
              if (!isPro) {
                SoundService().playCardFlip();
                ProPassDialog.show(context);
                return;
              }
              VelocityRecordsDialog.show(context, _engine);
            },
          ),
          const SizedBox(width: 4),
          // Lane Count Picker (1~9, >1인은 PRO)
          if (!_engine.isRunning)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: cfg.cardColor,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: cfg.primaryColor.withValues(alpha: 0.4)),
              ),
              child: DropdownButton<int>(
                value: _engine.laneCount,
                dropdownColor: const Color(0xFF161B22),
                underline: const SizedBox(),
                icon: const Icon(Icons.arrow_drop_down, color: Colors.white70),
                items: List.generate(
                  9,
                  (i) {
                    final num = i + 1;
                    final isPro = context.read<DokkeyProvider>().isProUser;
                    return DropdownMenuItem(
                      value: num,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(TimelabI18n.personShort(lang, num), style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                          if (num > 1 && !isPro) ...[
                            const SizedBox(width: 4),
                            const Text('👑', style: TextStyle(fontSize: 10)),
                          ],
                        ],
                      ),
                    );
                  },
                ),
                onChanged: (val) {
                  if (val != null) {
                    final isPro = context.read<DokkeyProvider>().isProUser;
                    if (val > 1 && !isPro) {
                      SoundService().playCardFlip();
                      ProPassDialog.show(context);
                      return;
                    }
                    _summaryShown = false;
                    _engine.setLaneCount(val);
                  }
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMasterTimer(TimelabThemeConfig cfg) {
    final timeStr = _formatLapTime(_engine.elapsedTime);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 14),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: cfg.cardColor.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: cfg.borderColor.withValues(alpha: 0.5), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: cfg.primaryColor.withValues(alpha: 0.2),
            blurRadius: 16,
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(Icons.timer_rounded, color: cfg.primaryColor, size: 20),
              const SizedBox(width: 8),
              const Text('MASTER TIMER', style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold, fontSize: 12)),
            ],
          ),
          Text(
            timeStr,
            style: TextStyle(
              fontFamily: 'monospace',
              fontSize: 26,
              fontWeight: FontWeight.w900,
              color: cfg.primaryColor,
              letterSpacing: 1.0,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBentoGrid(TimelabThemeConfig cfg, String lang) {
    final count = _engine.laneCount;

    if (count <= 3) {
      // 1~3인: 가로형 와이드 3단 슬롯
      return Column(
        children: [
          for (var i = 0; i < count; i++)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: _buildRunnerCard(i, cfg, lang, isWide: true),
              ),
            ),
        ],
      );
    } else if (count <= 6) {
      // 4~6인: 2열 대형 터치 그리드
      return GridView.builder(
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 1.45,
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
        ),
        itemCount: count,
        itemBuilder: (_, idx) => _buildRunnerCard(idx, cfg, lang),
      );
    } else {
      // 7~9인: 3×3 터치 패드
      return GridView.builder(
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          childAspectRatio: 1.05,
          crossAxisSpacing: 6,
          mainAxisSpacing: 6,
        ),
        itemCount: count,
        itemBuilder: (_, idx) => _buildRunnerCard(idx, cfg, lang, isCompact: true),
      );
    }
  }

  Widget _buildRunnerCard(int idx, TimelabThemeConfig cfg, String lang, {bool isWide = false, bool isCompact = false}) {
    final runner = _engine.lanes[idx];
    final isFinished = runner.isFinished;
    final rank = runner.rank;

    Color cardBg = cfg.cardColor;
    Color borderC = cfg.borderColor.withValues(alpha: 0.3);

    if (isFinished) {
      if (rank == 1) {
        cardBg = const Color(0xFFFFD700).withValues(alpha: 0.22);
        borderC = const Color(0xFFFFD700);
      } else if (rank == 2) {
        cardBg = const Color(0xFFE2E8F0).withValues(alpha: 0.18);
        borderC = const Color(0xFFE2E8F0);
      } else if (rank == 3) {
        cardBg = const Color(0xFFFF9800).withValues(alpha: 0.18);
        borderC = const Color(0xFFFF9800);
      } else {
        cardBg = const Color(0xFF102A43).withValues(alpha: 0.5);
        borderC = cfg.primaryColor.withValues(alpha: 0.6);
      }
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: _engine.isRunning && !isFinished
            ? () => _engine.recordRunnerFinish(idx)
            : null,
        borderRadius: BorderRadius.circular(16),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          padding: EdgeInsets.all(isCompact ? 8 : (isWide ? 14 : 10)),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: borderC, width: isFinished ? 2.0 : 1.2),
            boxShadow: isFinished && rank == 1
                ? [
                    BoxShadow(
                      color: const Color(0xFFFFD700).withValues(alpha: 0.4),
                      blurRadius: 14,
                    ),
                  ]
                : null,
          ),
          child: isWide
              ? Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      child: Row(
                        children: [
                          _buildRankBadge(runner, lang, isCompact),
                          const SizedBox(width: 14),
                          Flexible(
                            child: Text(
                              runner.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                          ),
                        ],
                      ),
                    ),
                    _buildLapDisplay(runner, cfg, lang, isWide: true),
                  ],
                )
              : Column(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildRankBadge(runner, lang, isCompact),
                        Flexible(
                          child: Text(
                            runner.name,
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: isCompact ? 11 : 13,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    _buildLapDisplay(runner, cfg, lang, isCompact: isCompact),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _buildRankBadge(RunnerLane runner, String lang, bool isCompact) {
    if (runner.isFinished && runner.rank != null) {
      final text = TimelabI18n.rankLabel(lang, runner.rank!);

      return Container(
        padding: EdgeInsets.symmetric(horizontal: isCompact ? 5 : 8, vertical: 3),
        decoration: BoxDecoration(
          color: runner.rank == 1 ? const Color(0xFFFFD700) : Colors.black45,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          text,
          style: TextStyle(
            color: runner.rank == 1 ? Colors.black : Colors.white,
            fontWeight: FontWeight.w900,
            fontSize: isCompact ? 10 : 12,
          ),
        ),
      );
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: isCompact ? 5 : 8, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.white10,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        '#${runner.laneNumber}',
        style: TextStyle(color: Colors.white70, fontSize: isCompact ? 10 : 12, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildLapDisplay(RunnerLane runner, TimelabThemeConfig cfg, String lang, {bool isWide = false, bool isCompact = false}) {
    if (runner.isFinished && runner.lapTime != null) {
      return Text(
        _formatLapTime(runner.lapTime!),
        style: TextStyle(
          fontFamily: 'monospace',
          fontSize: isWide ? 22 : (isCompact ? 13 : 17),
          fontWeight: FontWeight.w900,
          color: runner.rank == 1 ? const Color(0xFFFFE66D) : Colors.white,
        ),
      );
    }

    return Text(
      _engine.isRunning ? TimelabI18n.touchToFinish(lang) : TimelabI18n.waitingLabel(lang),
      style: TextStyle(
        color: _engine.isRunning ? cfg.primaryColor : Colors.white30,
        fontSize: isCompact ? 10 : 12,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _buildBottomControls(TimelabThemeConfig cfg, String lang) {
    return Row(
      children: [
        // Reset Button
        Expanded(
          flex: 2,
          child: ElevatedButton.icon(
            onPressed: () {
              HapticFeedback.lightImpact();
              _summaryShown = false;
              _engine.reset();
            },
            icon: const Icon(Icons.replay_rounded, size: 18, color: Colors.white70),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF21262D),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: const BorderSide(color: Color(0xFF30363D), width: 1.2),
              ),
            ),
            label: Text(TimelabI18n.resetLabel(lang), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          ),
        ),
        const SizedBox(width: 10),

        // Start / Pause Big Button
        Expanded(
          flex: 4,
          child: ElevatedButton.icon(
            onPressed: () {
              HapticFeedback.heavyImpact();
              if (_engine.isRunning) {
                _engine.pause();
              } else {
                _summaryShown = false;
                _engine.start();
              }
            },
            icon: Icon(
              _engine.isRunning ? Icons.pause_rounded : Icons.play_arrow_rounded,
              size: 24,
              color: Colors.black,
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: _engine.isRunning ? const Color(0xFFFF5252) : const Color(0xFFFFD700),
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(vertical: 16),
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            label: Text(
              _engine.isRunning ? TimelabI18n.pauseAllLabel(lang) : TimelabI18n.startGoLabel(lang),
              style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
            ),
          ),
        ),
      ],
    );
  }
}
