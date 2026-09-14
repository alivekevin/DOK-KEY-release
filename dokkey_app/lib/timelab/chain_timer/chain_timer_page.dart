import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../core/timelab_theme_engine.dart';
import '../models/timelab_models.dart';
import 'chain_timer_engine.dart';

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
                    // Top App Bar & Theme Switcher
                    _buildTopBar(cfg),

                    const SizedBox(height: 10),

                    // Set Loop & Current Phase Indicator
                    _buildPhaseHeader(cfg),

                    // Main Fullscreen Digital Countdown View
                    Expanded(
                      flex: 4,
                      child: Center(
                        child: _buildDigitalDisplay(cfg, displayColor),
                      ),
                    ),

                    // 3-Phase Sequence Slot Pipeline Card
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: _buildSequencePipelineCard(cfg),
                    ),

                    const SizedBox(height: 14),

                    // Bottom Control Buttons (START / PAUSE / RESET)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      child: _buildControls(cfg),
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

  Widget _buildTopBar(TimelabThemeConfig cfg) {
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
                '3단 시퀀스 체인 타이머',
                style: TextStyle(
                  color: cfg.primaryColor,
                  fontWeight: FontWeight.w900,
                  fontSize: 16,
                  letterSpacing: 0.5,
                ),
              ),
              Text(
                'THE DEFUSER · ${cfg.displayName}',
                style: const TextStyle(color: Colors.white54, fontSize: 10.5, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const Spacer(),
          // 테마 전환 버튼 (팝업 메뉴)
          PopupMenuButton<TimelabTheme>(
            icon: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: cfg.cardColor,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: cfg.primaryColor.withOpacity(0.5), width: 1.2),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.palette_outlined, size: 14, color: Colors.white),
                  const SizedBox(width: 4),
                  Text(
                    cfg.displayName,
                    style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
            color: const Color(0xFF161B22),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            onSelected: _engine.setTheme,
            itemBuilder: (_) => [
              _buildThemeMenuItem(TimelabTheme.classicDigital, '클래식 디지털', '7-Segment LCD'),
              _buildThemeMenuItem(TimelabTheme.cyberDefuser, '사이버 디퓨저', 'Neon Cyber HUD'),
              _buildThemeMenuItem(TimelabTheme.orbitalLaunch, '우주 발사', 'Orbital Aerospace'),
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

  Widget _buildPhaseHeader(TimelabThemeConfig cfg) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: cfg.cardColor.withOpacity(0.85),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: cfg.borderColor.withOpacity(0.4), width: 1),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Current Stage Badge
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: _engine.status == ChainTimerStatus.delaying
                      ? const Color(0xFFFF9100).withOpacity(0.25)
                      : cfg.primaryColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: _engine.status == ChainTimerStatus.delaying
                        ? const Color(0xFFFF9100)
                        : cfg.primaryColor,
                    width: 1.2,
                  ),
                ),
                child: Text(
                  _engine.status == ChainTimerStatus.delaying
                      ? '⏸ DELAY 대기'
                      : 'PHASE ${_engine.currentStepIndex + 1} / ${_engine.activeSlotCount}',
                  style: TextStyle(
                    color: _engine.status == ChainTimerStatus.delaying
                        ? const Color(0xFFFFAB40)
                        : cfg.primaryColor,
                    fontWeight: FontWeight.w900,
                    fontSize: 12,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              if (_engine.status == ChainTimerStatus.delaying)
                Text(
                  '다음 단계까지 ${(_engine.remainingDelay.inMilliseconds / 1000).toStringAsFixed(1)}s',
                  style: const TextStyle(color: Color(0xFFFFAB40), fontSize: 12, fontWeight: FontWeight.bold),
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
                    child: const Text('+세트', style: TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDigitalDisplay(TimelabThemeConfig cfg, Color displayColor) {
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
                    color: displayColor.withOpacity(0.85),
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

  Widget _buildSequencePipelineCard(TimelabThemeConfig cfg) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cfg.cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: cfg.borderColor.withOpacity(0.5), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Text('🔗', style: TextStyle(fontSize: 16)),
                  SizedBox(width: 6),
                  Text(
                    '3-Phase 시퀀스 체인 파이프라인',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 13),
                  ),
                ],
              ),
              if (_engine.status == ChainTimerStatus.idle)
                Row(
                  children: [
                    _buildSlotCountChip(1),
                    const SizedBox(width: 4),
                    _buildSlotCountChip(2),
                    const SizedBox(width: 4),
                    _buildSlotCountChip(3),
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
                  child: _buildSlotItem(i, cfg),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSlotCountChip(int count) {
    final active = _engine.activeSlotCount == count;
    return InkWell(
      onTap: () => _engine.setActiveSlotCount(count),
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
        decoration: BoxDecoration(
          color: active ? const Color(0xFFFFD700) : Colors.white10,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          '$count단',
          style: TextStyle(
            color: active ? Colors.black : Colors.white70,
            fontSize: 10.5,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildSlotItem(int idx, TimelabThemeConfig cfg) {
    final isEnabled = idx < _engine.activeSlotCount;
    final isCurrent = _engine.status != ChainTimerStatus.idle && _engine.currentStepIndex == idx;
    final step = _engine.steps[idx];

    return InkWell(
      onTap: _engine.status == ChainTimerStatus.idle && isEnabled
          ? () => _showDurationEditSheet(idx)
          : null,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        decoration: BoxDecoration(
          color: isCurrent
              ? cfg.primaryColor.withOpacity(0.18)
              : (isEnabled ? const Color(0xFF1E2532) : Colors.black26),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isCurrent
                ? cfg.primaryColor
                : (isEnabled ? cfg.borderColor.withOpacity(0.6) : Colors.white12),
            width: isCurrent ? 1.8 : 1.0,
          ),
        ),
        child: Column(
          children: [
            Text(
              '단계 ${idx + 1}',
              style: TextStyle(
                color: isEnabled ? Colors.white70 : Colors.white24,
                fontSize: 10.5,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              isEnabled ? '${step.duration.inSeconds}초' : 'OFF',
              style: TextStyle(
                color: isEnabled ? (isCurrent ? cfg.primaryColor : Colors.white) : Colors.white24,
                fontSize: 15,
                fontWeight: FontWeight.w900,
              ),
            ),
            if (isEnabled && step.delayAfter > Duration.zero) ...[
              const SizedBox(height: 3),
              Text(
                '+${step.delayAfter.inSeconds}s 대기',
                style: const TextStyle(color: Color(0xFFFFAB40), fontSize: 9.5, fontWeight: FontWeight.bold),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showDurationEditSheet(int idx) {
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
                    Text('⏱️ 단계 ${idx + 1} 시간 & 지연(Delay) 설정', style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('타이머 시간', style: TextStyle(color: Colors.white70, fontSize: 14)),
                        Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.remove_circle_outline, color: Colors.amber),
                              onPressed: sec > 1 ? () => setModalState(() => sec--) : null,
                            ),
                            Text('$sec 초', style: const TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w900)),
                            IconButton(
                              icon: const Icon(Icons.add_circle_outline, color: Colors.amber),
                              onPressed: () => setModalState(() => sec++),
                            ),
                          ],
                        ),
                      ],
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('완료 후 지연(Delay)', style: TextStyle(color: Colors.white70, fontSize: 14)),
                        Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.remove_circle_outline, color: Colors.amber),
                              onPressed: delaySec > 0 ? () => setModalState(() => delaySec--) : null,
                            ),
                            Text('$delaySec 초', style: const TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w900)),
                            IconButton(
                              icon: const Icon(Icons.add_circle_outline, color: Colors.amber),
                              onPressed: () => setModalState(() => delaySec++),
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
                      child: const Text('저장 완료', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
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

  Widget _buildControls(TimelabThemeConfig cfg) {
    final isRunning = _engine.status == ChainTimerStatus.running || _engine.status == ChainTimerStatus.delaying;

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
            label: const Text('리셋', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
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
              isRunning ? '일시 정지' : (_engine.status == ChainTimerStatus.paused ? '이어하기' : '시퀀스 시작'),
              style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
            ),
          ),
        ),
      ],
    );
  }
}
