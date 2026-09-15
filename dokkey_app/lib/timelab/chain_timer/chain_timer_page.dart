import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../core/sound_service.dart';
import '../../providers/dokkey_provider.dart';
import '../../widgets/pro_pass_dialog.dart';
import '../core/timelab_i18n.dart';
import '../core/timelab_theme_engine.dart';
import '../models/timelab_models.dart';
import '../core/timelab_screen_keeper.dart';
import 'chain_timer_engine.dart';
import '../core/hold_repeat_button.dart';
import 'chain_timer_settings_page.dart';

/// 💣 모듈 1: 3단 시퀀스 체인 타이머 (The Defuser) 풀스크린 뷰
class ChainTimerPage extends StatefulWidget {
  const ChainTimerPage({super.key});

  @override
  State<ChainTimerPage> createState() => _ChainTimerPageState();
}

class _ChainTimerPageState extends State<ChainTimerPage>
    with SingleTickerProviderStateMixin {
  late final ChainTimerEngine _engine;
  late final AnimationController _animCtrl;

  @override
  void initState() {
    super.initState();
    _engine = ChainTimerEngine();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    _engine.dispose();
    TimeLabScreenKeeper.release();
    super.dispose();
  }

  String _formatTime(Duration d) {
    final minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    final millis = (d.inMilliseconds.remainder(1000) ~/ 10).toString().padLeft(2, '0');
    return '$minutes:$seconds.$millis';
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([_engine, _animCtrl]),
      builder: (context, _) {
        final lang = context.watch<DokkeyProvider>().lang;
        final cfg = TimelabThemeConfig.of(_engine.theme);
        final displayColor = cfg.getDynamicDisplayColor(
          progress: _engine.currentStepProgress,
          remaining: _engine.remainingTime,
        );

        return Scaffold(
          backgroundColor: cfg.backgroundColor,
          body: Stack(
            children: [
              // 1. 시네마틱 캔버스 백그라운드 FX
              Positioned.fill(
                child: CustomPaint(
                  painter: TimelabBackgroundPainter(
                    theme: _engine.theme,
                    animationValue: _animCtrl.value,
                    isCritical: _engine.isCritical,
                  ),
                ),
              ),

              // 2. 메인 UI 레이어
              SafeArea(
                child: Column(
                  children: [
                    // Top App Bar & Theme Switcher & Settings Button
                    _buildTopBar(cfg, lang),

                    const SizedBox(height: 10),

                    // Set Loop & Current Phase Indicator
                    _buildPhaseHeader(cfg, lang),

                    // Main Fullscreen Digital Countdown View
                    Expanded(
                      flex: 4,
                      child: Center(
                        child: _buildDigitalDisplay(cfg, displayColor, lang),
                      ),
                    ),

                    // 3-Phase Sequence Slot Pipeline Card
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: _buildSequencePipelineCard(cfg, lang),
                    ),

                    const SizedBox(height: 14),

                    // Bottom Control Buttons (START / PAUSE / RESET)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      child: _buildControls(cfg, lang),
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
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  TimelabI18n.module1Title(lang),
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
                  'THE DEFUSER · ${cfg.localizedName(lang)}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.white54, fontSize: 10.5, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          // ⚡ 루틴 프리셋 라이브러리 버튼
          IconButton(
            icon: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              decoration: BoxDecoration(
                color: cfg.cardColor,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFFFD700).withValues(alpha: 0.6), width: 1.2),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('⚡', style: TextStyle(fontSize: 13)),
                ],
              ),
            ),
            tooltip: TimelabI18n.routinePresetsTitle(lang),
            onPressed: () => _showRoutinePresetsModal(context, lang, cfg),
          ),
          const SizedBox(width: 4),
          // 설정 페이지 이동 버튼 (종료음 & 딜레이 & PRO 관리)
          IconButton(
            icon: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: cfg.cardColor,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: cfg.borderColor.withValues(alpha: 0.6), width: 1.2),
              ),
              child: const Icon(Icons.settings_outlined, color: Colors.white, size: 17),
            ),
            tooltip: TimelabI18n.settingsHeader(lang),
            onPressed: () => ChainTimerSettingsPage.show(context, _engine),
          ),
          const SizedBox(width: 4),
          // 테마 전환 버튼 (팝업 메뉴)
          PopupMenuButton<TimelabTheme>(
            icon: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: cfg.cardColor,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: cfg.primaryColor.withValues(alpha: 0.5), width: 1.2),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.palette_outlined, size: 14, color: Colors.white),
                  const SizedBox(width: 4),
                  Text(
                    cfg.localizedName(lang),
                    style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
            color: const Color(0xFF161B22),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            onSelected: _engine.setTheme,
            itemBuilder: (_) => [
              _buildThemeMenuItem(TimelabTheme.classicDigital, TimelabI18n.themeClassic(lang), '7-Segment LCD'),
              _buildThemeMenuItem(TimelabTheme.cyberDefuser, TimelabI18n.themeCyber(lang), 'Neon Cyber HUD'),
              _buildThemeMenuItem(TimelabTheme.orbitalLaunch, TimelabI18n.themeOrbital(lang), 'Orbital Aerospace'),
            ],
          ),
        ],
      ),
    );
  }

  PopupMenuItem<TimelabTheme> _buildThemeMenuItem(TimelabTheme t, String name, String sub) {
    final active = _engine.theme == t;
    return PopupMenuItem(
      value: t,
      child: Row(
        children: [
          Icon(
            active ? Icons.radio_button_checked : Icons.radio_button_off,
            color: active ? const Color(0xFFFFD700) : Colors.white38,
            size: 16,
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(name, style: TextStyle(color: active ? Colors.white : Colors.white70, fontWeight: FontWeight.bold, fontSize: 13)),
              Text(sub, style: const TextStyle(color: Colors.white38, fontSize: 10)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPhaseHeader(TimelabThemeConfig cfg, String lang) {
    final isAudioPlaying = _engine.status == ChainTimerStatus.audioPlaying;
    final isDelaying = _engine.status == ChainTimerStatus.delaying;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: cfg.cardColor.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: cfg.borderColor.withValues(alpha: 0.4), width: 1),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Current Stage Badge & Status Indicator
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: isAudioPlaying
                      ? const Color(0xFF00E5FF).withValues(alpha: 0.2)
                      : (isDelaying
                          ? const Color(0xFFFF9100).withValues(alpha: 0.25)
                          : cfg.primaryColor.withValues(alpha: 0.2)),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isAudioPlaying
                        ? const Color(0xFF00E5FF)
                        : (isDelaying
                            ? const Color(0xFFFF9100)
                            : cfg.primaryColor),
                    width: 1.2,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      isAudioPlaying
                          ? TimelabI18n.musicPlayingBadge(lang)
                          : (isDelaying
                              ? TimelabI18n.delayWaitingBadge(lang)
                              : 'PHASE ${_engine.currentStepIndex + 1} / ${_engine.activeSlotCount}'),
                      style: TextStyle(
                        color: isAudioPlaying
                            ? const Color(0xFF00E5FF)
                            : (isDelaying
                                ? const Color(0xFFFFAB40)
                                : cfg.primaryColor),
                        fontWeight: FontWeight.w900,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              if (isAudioPlaying || isDelaying)
                InkWell(
                  onTap: () {
                    HapticFeedback.lightImpact();
                    _engine.skipAudioOrDelay();
                  },
                  borderRadius: BorderRadius.circular(6),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFD700).withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: const Color(0xFFFFD700)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.fast_forward_rounded, size: 12, color: Color(0xFFFFD700)),
                        const SizedBox(width: 3),
                        Text(TimelabI18n.skipLabel(lang), style: const TextStyle(color: Color(0xFFFFD700), fontSize: 10.5, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                ),
            ],
          ),

          // Set Repetition Counter (1~9 Loops)
          Row(
            children: [
              const Text('SET ', style: TextStyle(color: Colors.white54, fontSize: 11, fontWeight: FontWeight.bold)),
              Text(
                '${_engine.currentSet} / ${_engine.totalSets}',
                style: TextStyle(color: cfg.primaryColor, fontSize: 14, fontWeight: FontWeight.w900),
              ),
              if (_engine.status == ChainTimerStatus.idle) ...[
                const SizedBox(width: 6),
                InkWell(
                  onTap: () => _engine.setTotalSets((_engine.totalSets % 9) + 1),
                  borderRadius: BorderRadius.circular(6),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.white12,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(TimelabI18n.addSetLabel(lang), style: const TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDigitalDisplay(TimelabThemeConfig cfg, Color displayColor, String lang) {
    if (_engine.status == ChainTimerStatus.audioPlaying) {
      final currentStep = _engine.steps[_engine.currentStepIndex];
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            decoration: BoxDecoration(
              color: const Color(0xFF0F172A).withValues(alpha: 0.85),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: const Color(0xFF00E5FF).withValues(alpha: 0.6), width: 1.8),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF00E5FF).withValues(alpha: 0.3),
                  blurRadius: 24,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Column(
              children: [
                const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.graphic_eq_rounded, color: Color(0xFF00E5FF), size: 30),
                    SizedBox(width: 8),
                    Text(
                      'MUSIC PLAYING',
                      style: TextStyle(color: Color(0xFF00E5FF), fontSize: 13, fontWeight: FontWeight.w900, letterSpacing: 2),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  currentStep.soundDisplayName(lang),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 20,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                Text(
                  TimelabI18n.musicAutoNext(lang),
                  style: const TextStyle(color: Colors.white60, fontSize: 11),
                ),
                const SizedBox(height: 14),
                ElevatedButton.icon(
                  onPressed: () {
                    HapticFeedback.heavyImpact();
                    _engine.skipAudioOrDelay();
                  },
                  icon: const Icon(Icons.skip_next_rounded, size: 18, color: Colors.black),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFFD700),
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  label: Text(TimelabI18n.skipToNextLabel(lang), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5)),
                ),
              ],
            ),
          ),
        ],
      );
    }

    final timeStr = _formatTime(
      _engine.status == ChainTimerStatus.delaying
          ? _engine.remainingDelay
          : _engine.remainingTime,
    );

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Pulsing / Glowing Giant Digits
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              timeStr,
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: 78,
                fontWeight: FontWeight.w900,
                color: displayColor,
                letterSpacing: 2.0,
                shadows: [
                  Shadow(
                    color: displayColor.withValues(alpha: 0.85),
                    blurRadius: _engine.isCritical ? 28 : 16,
                  ),
                  if (_engine.isCritical)
                    const Shadow(
                      color: Color(0xFFFF0033),
                      blurRadius: 40,
                    ),
                ],
              ),
            ),
          ),
        ),

        // Progress Linear Bar
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: _engine.currentStepProgress,
              minHeight: 6,
              backgroundColor: Colors.white12,
              valueColor: AlwaysStoppedAnimation<Color>(displayColor),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSequencePipelineCard(TimelabThemeConfig cfg, String lang) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cfg.cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: cfg.borderColor.withValues(alpha: 0.5), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('🔗', style: TextStyle(fontSize: 16)),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        TimelabI18n.pipelineTitle(lang),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),
              if (_engine.status == ChainTimerStatus.idle)
                Row(
                  children: [
                    _buildSlotCountChip(1, lang),
                    const SizedBox(width: 4),
                    _buildSlotCountChip(2, lang),
                    const SizedBox(width: 4),
                    _buildSlotCountChip(3, lang),
                  ],
                ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              for (var i = 0; i < 3; i++) ...[
                if (i > 0)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 12,
                      color: i < _engine.activeSlotCount ? cfg.primaryColor : Colors.white24,
                    ),
                  ),
                Expanded(
                  child: _buildSlotItem(i, cfg, lang),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSlotCountChip(int count, String lang) {
    final active = _engine.activeSlotCount == count;
    final isPro = context.read<DokkeyProvider>().isProUser;

    return InkWell(
      onTap: () {
        if (!isPro && count > 1) {
          SoundService().playCardFlip();
          ProPassDialog.show(context);
          return;
        }
        HapticFeedback.selectionClick();
        _engine.setActiveSlotCount(count);
      },
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
        decoration: BoxDecoration(
          color: active ? const Color(0xFFFFD700) : Colors.white10,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              TimelabI18n.phaseUnit(lang, count),
              style: TextStyle(
                color: active ? Colors.black : Colors.white70,
                fontSize: 10.5,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (!isPro && count > 1) ...[
              const SizedBox(width: 3),
              const Text('👑', style: TextStyle(fontSize: 8.5)),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSlotItem(int idx, TimelabThemeConfig cfg, String lang) {
    final isEnabled = idx < _engine.activeSlotCount;
    final isCurrent = _engine.status != ChainTimerStatus.idle && _engine.currentStepIndex == idx;
    final step = _engine.steps[idx];

    return InkWell(
      onTap: _engine.status == ChainTimerStatus.idle && isEnabled
          ? () => _showDurationEditSheet(idx, lang)
          : null,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        decoration: BoxDecoration(
          color: isCurrent
              ? cfg.primaryColor.withValues(alpha: 0.18)
              : (isEnabled ? const Color(0xFF1E2532) : Colors.black26),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isCurrent
                ? cfg.primaryColor
                : (isEnabled ? cfg.borderColor.withValues(alpha: 0.6) : Colors.white12),
            width: isCurrent ? 1.8 : 1.0,
          ),
        ),
        child: Column(
          children: [
            Text(
              TimelabI18n.stepItemLabel(lang, idx + 1),
              style: TextStyle(
                color: isEnabled ? Colors.white70 : Colors.white24,
                fontSize: 10.5,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              isEnabled ? TimelabI18n.formatDurationHuman(lang, step.duration.inSeconds) : 'OFF',
              style: TextStyle(
                color: isEnabled ? (isCurrent ? cfg.primaryColor : Colors.white) : Colors.white24,
                fontSize: 15,
                fontWeight: FontWeight.w900,
              ),
            ),
            if (isEnabled && step.delayAfter > Duration.zero) ...[
              const SizedBox(height: 3),
              Text(
                TimelabI18n.waitShort(lang, step.delayAfter.inSeconds),
                style: const TextStyle(color: Color(0xFFFFAB40), fontSize: 9.5, fontWeight: FontWeight.bold),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showDurationEditSheet(int idx, String lang) {
    var sec = _engine.steps[idx].duration.inSeconds;
    var delaySec = _engine.steps[idx].delayAfter.inSeconds;

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF161B22),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      TimelabI18n.durationEditTitle(lang, idx + 1),
                      style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    // 1) 타이머 시간 (홀드 연속 증감)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(TimelabI18n.timerDurationLabel(lang), style: const TextStyle(color: Colors.white70, fontSize: 14)),
                        Row(
                          children: [
                            HoldRepeatButton(
                              icon: Icons.remove_circle_outline,
                              color: Colors.amber,
                              isEnabled: sec > 1,
                              onStep: (delta) => setModalState(() {
                                sec = (sec - delta).clamp(1, 86400);
                              }),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 8),
                              child: Text(
                                TimelabI18n.formatDurationHuman(lang, sec),
                                style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w900),
                              ),
                            ),
                            HoldRepeatButton(
                              icon: Icons.add_circle_outline,
                              color: Colors.amber,
                              isEnabled: sec < 86400,
                              onStep: (delta) => setModalState(() {
                                sec = (sec + delta).clamp(1, 86400);
                              }),
                            ),
                          ],
                        ),
                      ],
                    ),

                    // Quick presets in runtime sheet
                    const SizedBox(height: 6),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          for (final p in [10, 60, 300, 600, 1800, 3600])
                            Padding(
                              padding: const EdgeInsets.only(right: 6),
                              child: InkWell(
                                onTap: () {
                                  HapticFeedback.lightImpact();
                                  setModalState(() {
                                    sec = (sec + p).clamp(1, 86400);
                                  });
                                },
                                borderRadius: BorderRadius.circular(8),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF1E2838),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: const Color(0xFFFFD700).withValues(alpha: 0.35)),
                                  ),
                                  child: Text(
                                    p >= 3600 ? '+1h' : (p >= 60 ? '+${p ~/ 60}m' : '+${p}s'),
                                    style: const TextStyle(color: Color(0xFFFFE66D), fontSize: 11, fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 12),

                    // 2) 지연 대기 시간 (홀드 연속 증감)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(TimelabI18n.delayAfterStep(lang), style: const TextStyle(color: Colors.white70, fontSize: 14)),
                        Row(
                          children: [
                            HoldRepeatButton(
                              icon: Icons.remove_circle_outline,
                              color: Colors.amber,
                              isEnabled: delaySec > 0,
                              onStep: (delta) => setModalState(() {
                                delaySec = (delaySec - delta).clamp(0, 3600);
                              }),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 8),
                              child: Text(
                                TimelabI18n.formatDurationHuman(lang, delaySec),
                                style: const TextStyle(color: Color(0xFFFFAB40), fontSize: 16, fontWeight: FontWeight.w900),
                              ),
                            ),
                            HoldRepeatButton(
                              icon: Icons.add_circle_outline,
                              color: Colors.amber,
                              isEnabled: delaySec < 3600,
                              onStep: (delta) => setModalState(() {
                                delaySec = (delaySec + delta).clamp(0, 3600);
                              }),
                            ),
                          ],
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFFD700),
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      onPressed: () {
                        _engine.updateStepDuration(idx, Duration(seconds: sec));
                        _engine.updateStepDelay(idx, Duration(seconds: delaySec));
                        Navigator.of(ctx).pop();
                      },
                      child: Text(TimelabI18n.saveDoneLabel(lang), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildControls(TimelabThemeConfig cfg, String lang) {
    final isRunning = _engine.status == ChainTimerStatus.running ||
        _engine.status == ChainTimerStatus.delaying ||
        _engine.status == ChainTimerStatus.audioPlaying;

    return Row(
      children: [
        // Reset Button
        Expanded(
          flex: 2,
          child: ElevatedButton.icon(
            onPressed: () {
              HapticFeedback.lightImpact();
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
              if (isRunning) {
                _engine.pause();
              } else {
                _engine.startOrResume();
              }
            },
            icon: Icon(
              isRunning ? Icons.pause_rounded : Icons.play_arrow_rounded,
              size: 22,
              color: Colors.black,
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: isRunning ? const Color(0xFFFF5252) : const Color(0xFFFFD700),
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(vertical: 16),
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            label: Text(
              isRunning
                  ? TimelabI18n.pauseLabel(lang)
                  : (_engine.status == ChainTimerStatus.paused
                      ? TimelabI18n.resumeLabel(lang)
                      : TimelabI18n.startSequenceLabel(lang)),
              style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
            ),
          ),
        ),
      ],
    );
  }

  void _showRoutinePresetsModal(BuildContext context, String lang, TimelabThemeConfig cfg) {
    HapticFeedback.mediumImpact();
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF161B22),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            return DraggableScrollableSheet(
              initialChildSize: 0.75,
              minChildSize: 0.4,
              maxChildSize: 0.92,
              expand: false,
              builder: (ctx, scrollCtrl) {
                return Column(
                  children: [
                    // Handle bar
                    const SizedBox(height: 12),
                    Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.white24,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Title Header
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFD700).withValues(alpha: 0.15),
                              shape: BoxShape.circle,
                            ),
                            child: const Text('⚡', style: TextStyle(fontSize: 18)),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  TimelabI18n.routinePresetsTitle(lang),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 17,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  TimelabI18n.routinePresetsDesc(lang),
                                  style: const TextStyle(color: Colors.white54, fontSize: 11.5),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close_rounded, color: Colors.white70, size: 20),
                            onPressed: () => Navigator.pop(ctx),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Divider(color: Colors.white10, height: 1),

                    // Content List
                    Expanded(
                      child: ListView(
                        controller: scrollCtrl,
                        padding: const EdgeInsets.all(16),
                        children: [
                          // 1. Built-in Recommended Presets
                          for (final preset in builtinRoutinePresets)
                            _buildRoutinePresetCard(preset, lang, cfg, ctx),

                          const SizedBox(height: 16),

                          // 2. Save Current Routine Button
                          Container(
                            decoration: BoxDecoration(
                              color: const Color(0xFF1E2532),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: const Color(0xFFFFD700).withValues(alpha: 0.4), width: 1.2),
                            ),
                            child: ListTile(
                              leading: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFFD700).withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(Icons.bookmark_add_rounded, color: Color(0xFFFFD700), size: 22),
                              ),
                              title: Text(
                                TimelabI18n.saveCurrentAsRoutine(lang),
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                              ),
                              subtitle: Text(
                                TimelabI18n.customRoutineSummary(lang, _engine.activeSlotCount, _engine.totalSets),
                                style: const TextStyle(color: Colors.white54, fontSize: 11),
                              ),
                              trailing: const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white38, size: 14),
                              onTap: () async {
                                final saved = await _showSaveRoutineDialog(context, lang);
                                if (saved != null) {
                                  setSheetState(() {});
                                }
                              },
                            ),
                          ),

                          const SizedBox(height: 22),

                          // 3. Saved Custom Routines Section
                          Row(
                            children: [
                              const Text('⭐', style: TextStyle(fontSize: 14)),
                              const SizedBox(width: 6),
                              Text(
                                TimelabI18n.customRoutinesTitle(lang),
                                style: const TextStyle(
                                  color: Color(0xFFFFD700),
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.white10,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  '${_engine.customRoutines.length}',
                                  style: const TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),

                          if (_engine.customRoutines.isEmpty)
                            Container(
                              padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
                              decoration: BoxDecoration(
                                color: const Color(0xFF12161E),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: Colors.white10),
                              ),
                              child: Center(
                                child: Text(
                                  TimelabI18n.noSavedRoutines(lang),
                                  style: const TextStyle(color: Colors.white38, fontSize: 12.5),
                                ),
                              ),
                            )
                          else
                            for (final customPreset in _engine.customRoutines)
                              _buildCustomRoutineCard(customPreset, lang, cfg, ctx, setSheetState),

                          const SizedBox(height: 30),
                        ],
                      ),
                    ),
                  ],
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildRoutinePresetCard(
    ChainRoutinePreset preset,
    String lang,
    TimelabThemeConfig cfg,
    BuildContext sheetCtx,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF1A202C),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10, width: 1.0),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            HapticFeedback.mediumImpact();
            _engine.applyRoutinePreset(preset);
            Navigator.pop(sheetCtx);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(TimelabI18n.routineAppliedToast(lang, preset.localizedTitle(lang))),
                backgroundColor: const Color(0xFF1E2532),
                behavior: SnackBarBehavior.floating,
                duration: const Duration(seconds: 2),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(preset.icon, style: const TextStyle(fontSize: 22)),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        preset.localizedTitle(lang),
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14.5),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFD700).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFFFFD700).withValues(alpha: 0.4)),
                      ),
                      child: Text(
                        TimelabI18n.setsCountLabel(lang, preset.totalSets),
                        style: const TextStyle(color: Color(0xFFFFD700), fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  preset.localizedDesc(lang),
                  style: const TextStyle(color: Colors.white60, fontSize: 11.5, height: 1.35),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: [
                    for (var i = 0; i < preset.activeSlots; i++)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.07),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: Colors.white12),
                        ),
                        child: Text(
                          'P${i + 1}: ${TimelabI18n.formatDurationHuman(lang, preset.steps[i].duration.inSeconds)}${preset.steps[i].delayAfter > Duration.zero ? " (+${preset.steps[i].delayAfter.inSeconds}s)" : ""}',
                          style: const TextStyle(color: Colors.white70, fontSize: 10.5, fontWeight: FontWeight.w600),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCustomRoutineCard(
    ChainRoutinePreset customPreset,
    String lang,
    TimelabThemeConfig cfg,
    BuildContext sheetCtx,
    void Function(void Function()) setSheetState,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF1E2532),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFFD700).withValues(alpha: 0.3), width: 1.0),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            HapticFeedback.mediumImpact();
            _engine.applyRoutinePreset(customPreset);
            Navigator.pop(sheetCtx);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(TimelabI18n.routineAppliedToast(lang, customPreset.localizedTitle(lang))),
                backgroundColor: const Color(0xFF1E2532),
                behavior: SnackBarBehavior.floating,
                duration: const Duration(seconds: 2),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Text(customPreset.icon, style: const TextStyle(fontSize: 20)),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        customPreset.localizedTitle(lang),
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        customPreset.localizedDesc(lang),
                        style: const TextStyle(color: Colors.white54, fontSize: 11),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline_rounded, color: Colors.white38, size: 18),
                  tooltip: TimelabI18n.delete(lang),
                  onPressed: () async {
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (dCtx) => AlertDialog(
                        backgroundColor: const Color(0xFF1F2633),
                        title: Text(
                          TimelabI18n.deleteRoutineConfirm(lang),
                          style: const TextStyle(color: Colors.white, fontSize: 15),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(dCtx, false),
                            child: Text(TimelabI18n.cancel(lang), style: const TextStyle(color: Colors.white54)),
                          ),
                          TextButton(
                            onPressed: () => Navigator.pop(dCtx, true),
                            child: Text(
                              TimelabI18n.delete(lang),
                              style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                    );
                    if (confirm == true) {
                      await _engine.deleteCustomRoutine(customPreset.id);
                      setSheetState(() {});
                    }
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<ChainRoutinePreset?> _showSaveRoutineDialog(BuildContext context, String lang) async {
    final textController = TextEditingController(text: '루틴 ${_engine.customRoutines.length + 1}');
    var selectedIcon = '⭐';

    return showDialog<ChainRoutinePreset>(
      context: context,
      builder: (dCtx) => StatefulBuilder(
        builder: (dCtx, setDialogState) => AlertDialog(
          backgroundColor: const Color(0xFF1A2230),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(
            TimelabI18n.saveCurrentAsRoutine(lang),
            style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: textController,
                autofocus: true,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: TimelabI18n.routineNameInputHint(lang),
                  hintStyle: const TextStyle(color: Colors.white38, fontSize: 13),
                  filled: true,
                  fillColor: const Color(0xFF10141D),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                children: ['⭐', '🏃', '🧘', '🍳', '📖', '🎯', '🥊', '🔥'].map((ico) {
                  final isSelected = selectedIcon == ico;
                  return InkWell(
                    onTap: () => setDialogState(() => selectedIcon = ico),
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: isSelected ? const Color(0xFFFFD700).withValues(alpha: 0.25) : Colors.white10,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: isSelected ? const Color(0xFFFFD700) : Colors.transparent),
                      ),
                      child: Text(ico, style: const TextStyle(fontSize: 18)),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dCtx, null),
              child: Text(TimelabI18n.cancel(lang), style: const TextStyle(color: Colors.white54)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFFD700),
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () async {
                final name = textController.text.trim();
                final preset = await _engine.saveCustomRoutine(name, icon: selectedIcon);
                if (dCtx.mounted) Navigator.pop(dCtx, preset);
              },
              child: Text(TimelabI18n.save(lang), style: const TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }
}

