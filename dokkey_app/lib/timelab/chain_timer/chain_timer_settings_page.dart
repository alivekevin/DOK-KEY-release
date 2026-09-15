import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../core/sound_service.dart';
import '../../core/theme.dart';
import '../../providers/dokkey_provider.dart';
import '../../widgets/pro_pass_dialog.dart';
import '../core/hold_repeat_button.dart';
import '../core/timelab_i18n.dart';
import '../core/timelab_sound_engine.dart';
import 'chain_timer_engine.dart';

/// ⚙️ 3단 시퀀스 체인 타이머 전용 설정 페이지
class ChainTimerSettingsPage extends StatefulWidget {
  final ChainTimerEngine engine;

  const ChainTimerSettingsPage({super.key, required this.engine});

  static Future<void> show(BuildContext context, ChainTimerEngine engine) async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => ChainTimerSettingsPage(engine: engine)),
    );
  }

  @override
  State<ChainTimerSettingsPage> createState() => _ChainTimerSettingsPageState();
}

class _ChainTimerSettingsPageState extends State<ChainTimerSettingsPage> {
  final TimelabSoundEngine _soundEngine = TimelabSoundEngine();

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<DokkeyProvider>();
    final lang = provider.lang;
    final isPro = provider.isProUser;

    return Scaffold(
      backgroundColor: const Color(0xFF0C0F17),
      appBar: AppBar(
        backgroundColor: const Color(0xFF141923),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          TimelabI18n.settingsHeader(lang),
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 16),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Hero Guide
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF24180A), Color(0xFF161F33)],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: DokkeyTheme.gold.withOpacity(0.6), width: 1.2),
                ),
                child: Row(
                  children: [
                    const Text('💣', style: TextStyle(fontSize: 26)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            TimelabI18n.settingsFlowTitle(lang),
                            style: const TextStyle(color: Color(0xFFFFE66D), fontWeight: FontWeight.bold, fontSize: 13.5),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            isPro
                                ? TimelabI18n.settingsDescPro(lang)
                                : TimelabI18n.settingsDescFree(lang),
                            style: const TextStyle(color: Color(0xFFCBD5E1), fontSize: 11.5, height: 1.35),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Active Slots Count Selector
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(TimelabI18n.chainStepCountLabel(lang), style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
                  Row(
                    children: [
                      _buildSlotTab(1, lang: lang, isPro: true),
                      const SizedBox(width: 6),
                      _buildSlotTab(2, lang: lang, isPro: isPro),
                      const SizedBox(width: 6),
                      _buildSlotTab(3, lang: lang, isPro: isPro),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 18),

              // 1단계 슬롯 카드 (기본)
              _buildStepCard(0, lang: lang, isLocked: false),

              const SizedBox(height: 14),

              // 2단계 슬롯 카드 (PRO)
              _buildStepCard(1, lang: lang, isLocked: !isPro),

              const SizedBox(height: 14),

              // 3단계 슬롯 카드 (PRO)
              _buildStepCard(2, lang: lang, isLocked: !isPro),

              const SizedBox(height: 24),

              // Set Loop Repetition
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF141923),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: const Color(0xFF26334A)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(TimelabI18n.setRepeatTitle(lang), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13.5)),
                        Text(TimelabI18n.setRepeatDesc(lang), style: const TextStyle(color: Colors.white54, fontSize: 11)),
                      ],
                    ),
                    Row(
                      children: [
                        HoldRepeatButton(
                          icon: Icons.remove_circle_outline,
                          color: Colors.amber,
                          isEnabled: widget.engine.totalSets > 1,
                          onStep: (_) => setState(() => widget.engine.setTotalSets(widget.engine.totalSets - 1)),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 6),
                          child: Text(
                            TimelabI18n.setsCount(lang, widget.engine.totalSets),
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 16),
                          ),
                        ),
                        HoldRepeatButton(
                          icon: Icons.add_circle_outline,
                          color: Colors.amber,
                          isEnabled: widget.engine.totalSets < 9,
                          onStep: (_) => setState(() => widget.engine.setTotalSets(widget.engine.totalSets + 1)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFFD700),
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                onPressed: () {
                  HapticFeedback.lightImpact();
                  Navigator.of(context).pop();
                },
                child: Text(TimelabI18n.saveAndReturnLabel(lang), style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15)),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSlotTab(int count, {required String lang, required bool isPro}) {
    final active = widget.engine.activeSlotCount == count;

    return InkWell(
      onTap: () {
        if (!isPro && count > 1) {
          SoundService().playCardFlip();
          ProPassDialog.show(context);
          return;
        }
        HapticFeedback.selectionClick();
        setState(() => widget.engine.setActiveSlotCount(count));
      },
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: active ? const Color(0xFFFFD700) : const Color(0xFF1E2638),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: active ? const Color(0xFFFFD700) : Colors.white12,
            width: 1.2,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              TimelabI18n.phaseUnit(lang, count),
              style: TextStyle(
                color: active ? Colors.black : Colors.white70,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
            if (!isPro && count > 1) ...[
              const SizedBox(width: 4),
              const Text('👑', style: TextStyle(fontSize: 10)),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStepCard(int idx, {required String lang, required bool isLocked}) {
    final step = widget.engine.steps[idx];
    final isEnabled = idx < widget.engine.activeSlotCount;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isLocked ? Colors.black38 : const Color(0xFF141A26),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isLocked
              ? Colors.white10
              : (isEnabled ? const Color(0xFFFFD700).withOpacity(0.5) : const Color(0xFF2E384D)),
          width: isEnabled && !isLocked ? 1.5 : 1.0,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: isEnabled ? const Color(0xFFFFD700) : Colors.white12,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'PHASE ${idx + 1}',
                      style: TextStyle(
                        color: isEnabled ? Colors.black : Colors.white54,
                        fontWeight: FontWeight.w900,
                        fontSize: 11,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    isEnabled ? TimelabI18n.statusActive(lang) : TimelabI18n.statusInactive(lang),
                    style: TextStyle(
                      color: isEnabled ? Colors.greenAccent : Colors.white38,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              if (isLocked)
                InkWell(
                  onTap: () => ProPassDialog.show(context),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.amber.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.amber),
                    ),
                    child: Text(
                      TimelabI18n.proOnlyBadge(lang),
                      style: const TextStyle(color: Colors.amber, fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
            ],
          ),

          const SizedBox(height: 14),

          // 1) 타이머 시간 설정 (홀드 연속 가속 증감 + 터치 시 직접 입력)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text(
                  TimelabI18n.timerDurationLabel(lang),
                  style: const TextStyle(color: Colors.white70, fontSize: 13),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Row(
                children: [
                  HoldRepeatButton(
                    icon: Icons.remove_circle_outline,
                    color: Colors.amber,
                    isEnabled: !isLocked && isEnabled && step.duration.inSeconds > 1,
                    onStep: (delta) {
                      final currentSec = step.duration.inSeconds;
                      final nextSec = (currentSec - delta).clamp(1, 86400);
                      setState(() {
                        widget.engine.updateStepDuration(idx, Duration(seconds: nextSec));
                      });
                    },
                  ),
                  InkWell(
                    onTap: !isLocked && isEnabled
                        ? () => _showDirectTimeInputDialog(idx, isDelay: false, lang: lang)
                        : null,
                    borderRadius: BorderRadius.circular(8),
                    child: Tooltip(
                      message: TimelabI18n.tapToEditTooltip(lang),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.06),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.white12),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              TimelabI18n.formatDurationHuman(lang, step.duration.inSeconds),
                              style: TextStyle(
                                color: isLocked ? Colors.white38 : Colors.white,
                                fontWeight: FontWeight.w900,
                                fontSize: 15,
                              ),
                            ),
                            if (step.duration.inSeconds >= 60)
                              Text(
                                '(${step.duration.inSeconds}s)',
                                style: const TextStyle(color: Colors.white38, fontSize: 9.5),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  HoldRepeatButton(
                    icon: Icons.add_circle_outline,
                    color: Colors.amber,
                    isEnabled: !isLocked && isEnabled && step.duration.inSeconds < 86400,
                    onStep: (delta) {
                      final currentSec = step.duration.inSeconds;
                      final nextSec = (currentSec + delta).clamp(1, 86400);
                      setState(() {
                        widget.engine.updateStepDuration(idx, Duration(seconds: nextSec));
                      });
                    },
                  ),
                ],
              ),
            ],
          ),

          // ⚡ 퀵 프리셋 칩 (+10s, +1m, +5m, +10m, +30m, +1h)
          if (!isLocked && isEnabled) ...[
            const SizedBox(height: 8),
            _buildQuickPresetChips(
              onAdd: (addedSec) {
                final nextSec = (step.duration.inSeconds + addedSec).clamp(1, 86400);
                setState(() {
                  widget.engine.updateStepDuration(idx, Duration(seconds: nextSec));
                });
              },
              onReset: () {
                setState(() {
                  widget.engine.updateStepDuration(idx, const Duration(seconds: 10));
                });
              },
              lang: lang,
            ),
          ],

          const Divider(color: Colors.white10, height: 20),

          // 2) 종료음 선택 (내 폰 사운드 or 내장 프리셋)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text(
                  TimelabI18n.endSoundLabel(lang),
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.white70, fontSize: 13),
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (!isLocked && isEnabled)
                    IconButton(
                      icon: const Icon(Icons.volume_up_rounded, color: Colors.amberAccent, size: 20),
                      tooltip: TimelabI18n.previewSfxTooltip(lang),
                      onPressed: () {
                        _soundEngine.playCustomOrPreset(
                          soundId: step.soundId,
                          customFilePath: step.customSoundPath,
                          customSoundBytes: step.customSoundBytes,
                          fallbackTheme: widget.engine.theme,
                        );
                      },
                    ),
                  InkWell(
                    onTap: !isLocked && isEnabled ? () => _showSoundPickerSheet(idx, lang) : null,
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white10,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.white24),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Flexible(
                            child: Text(
                              step.soundDisplayName(lang),
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: isLocked ? Colors.white38 : const Color(0xFFFFE66D),
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Icon(Icons.arrow_drop_down, color: Colors.white70, size: 18),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),

          const Divider(color: Colors.white10, height: 20),

          // 3) 완료 후 지연 대기 시간 (Delay)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text(
                  TimelabI18n.delayAfterStep(lang),
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.white70, fontSize: 13),
                ),
              ),
              Row(
                children: [
                  HoldRepeatButton(
                    icon: Icons.remove_circle_outline,
                    color: Colors.amber,
                    isEnabled: !isLocked && isEnabled && step.delayAfter.inSeconds > 0,
                    onStep: (delta) {
                      final currentSec = step.delayAfter.inSeconds;
                      final nextSec = (currentSec - delta).clamp(0, 3600);
                      setState(() {
                        widget.engine.updateStepDelay(idx, Duration(seconds: nextSec));
                      });
                    },
                  ),
                  InkWell(
                    onTap: !isLocked && isEnabled
                        ? () => _showDirectTimeInputDialog(idx, isDelay: true, lang: lang)
                        : null,
                    borderRadius: BorderRadius.circular(8),
                    child: Tooltip(
                      message: TimelabI18n.tapToEditTooltip(lang),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.06),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.white12),
                        ),
                        child: Text(
                          TimelabI18n.formatDurationHuman(lang, step.delayAfter.inSeconds),
                          style: TextStyle(
                            color: isLocked ? Colors.white38 : const Color(0xFFFFAB40),
                            fontWeight: FontWeight.w900,
                            fontSize: 15,
                          ),
                        ),
                      ),
                    ),
                  ),
                  HoldRepeatButton(
                    icon: Icons.add_circle_outline,
                    color: Colors.amber,
                    isEnabled: !isLocked && isEnabled && step.delayAfter.inSeconds < 3600,
                    onStep: (delta) {
                      final currentSec = step.delayAfter.inSeconds;
                      final nextSec = (currentSec + delta).clamp(0, 3600);
                      setState(() {
                        widget.engine.updateStepDelay(idx, Duration(seconds: nextSec));
                      });
                    },
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickPresetChips({
    required ValueChanged<int> onAdd,
    required VoidCallback onReset,
    required String lang,
  }) {
    final chips = [
      {'label': '+10s', 'sec': 10},
      {'label': '+1m', 'sec': 60},
      {'label': '+5m', 'sec': 300},
      {'label': '+10m', 'sec': 600},
      {'label': '+30m', 'sec': 1800},
      {'label': '+1h', 'sec': 3600},
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (final c in chips)
            Padding(
              padding: const EdgeInsets.only(right: 6),
              child: InkWell(
                onTap: () {
                  HapticFeedback.lightImpact();
                  onAdd(c['sec'] as int);
                },
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E2838),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFFFD700).withOpacity(0.35)),
                  ),
                  child: Text(
                    c['label'] as String,
                    style: const TextStyle(
                      color: Color(0xFFFFE66D),
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          InkWell(
            onTap: () {
              HapticFeedback.lightImpact();
              onReset();
            },
            borderRadius: BorderRadius.circular(8),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white10,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.white24),
              ),
              child: Text(
                TimelabI18n.resetDefaultTime(lang),
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 10.5,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showDirectTimeInputDialog(int idx, {required bool isDelay, required String lang}) {
    final currentSeconds = isDelay
        ? widget.engine.steps[idx].delayAfter.inSeconds
        : widget.engine.steps[idx].duration.inSeconds;

    int curHours = currentSeconds ~/ 3600;
    int curMins = (currentSeconds % 3600) ~/ 60;
    int curSecs = currentSeconds % 60;

    final hrCtrl = TextEditingController(text: curHours.toString());
    final minCtrl = TextEditingController(text: curMins.toString());
    final secCtrl = TextEditingController(text: curSecs.toString());

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF161B24),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetCtx) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(sheetCtx).viewInsets.bottom,
            left: 20,
            right: 20,
            top: 20,
          ),
          child: StatefulBuilder(
            builder: (ctx, setDialogState) {
              return SafeArea(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            TimelabI18n.directInputTitle(lang, idx + 1, isDelay),
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, color: Colors.white70),
                          onPressed: () => Navigator.of(sheetCtx).pop(),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Inputs: Hours, Minutes, Seconds
                    Row(
                      children: [
                        Expanded(
                          child: _buildTimeInputField(
                            controller: hrCtrl,
                            unit: TimelabI18n.hoursUnit(lang),
                            maxVal: 24,
                            onChanged: (_) => setDialogState(() {}),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _buildTimeInputField(
                            controller: minCtrl,
                            unit: TimelabI18n.minutesUnit(lang),
                            maxVal: 59,
                            onChanged: (_) => setDialogState(() {}),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _buildTimeInputField(
                            controller: secCtrl,
                            unit: TimelabI18n.secondsUnit(lang),
                            maxVal: 59,
                            onChanged: (_) => setDialogState(() {}),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // Quick Jump Presets
                    Text(
                      TimelabI18n.quickAddTitle(lang),
                      style: const TextStyle(color: Colors.white54, fontSize: 11.5, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _buildPresetButton('10s', 10, hrCtrl, minCtrl, secCtrl, setDialogState),
                        _buildPresetButton('30s', 30, hrCtrl, minCtrl, secCtrl, setDialogState),
                        _buildPresetButton('1m', 60, hrCtrl, minCtrl, secCtrl, setDialogState),
                        _buildPresetButton('5m', 300, hrCtrl, minCtrl, secCtrl, setDialogState),
                        _buildPresetButton('10m', 600, hrCtrl, minCtrl, secCtrl, setDialogState),
                        _buildPresetButton('30m', 1800, hrCtrl, minCtrl, secCtrl, setDialogState),
                        _buildPresetButton('1h', 3600, hrCtrl, minCtrl, secCtrl, setDialogState),
                      ],
                    ),

                    const SizedBox(height: 20),

                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFFD700),
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      onPressed: () {
                        final h = int.tryParse(hrCtrl.text) ?? 0;
                        final m = int.tryParse(minCtrl.text) ?? 0;
                        final s = int.tryParse(secCtrl.text) ?? 0;
                        final total = (h * 3600 + m * 60 + s).clamp(isDelay ? 0 : 1, 86400);

                        setState(() {
                          if (isDelay) {
                            widget.engine.updateStepDelay(idx, Duration(seconds: total));
                          } else {
                            widget.engine.updateStepDuration(idx, Duration(seconds: total));
                          }
                        });
                        HapticFeedback.lightImpact();
                        Navigator.of(sheetCtx).pop();
                      },
                      child: Text(TimelabI18n.saveSetting(lang), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                    ),
                    const SizedBox(height: 12),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildTimeInputField({
    required TextEditingController controller,
    required String unit,
    required int maxVal,
    required ValueChanged<String> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF0F141C),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white24),
      ),
      child: Column(
        children: [
          TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900),
            decoration: const InputDecoration(
              isDense: true,
              border: InputBorder.none,
              contentPadding: EdgeInsets.zero,
            ),
            onChanged: onChanged,
          ),
          const SizedBox(height: 2),
          Text(unit, style: const TextStyle(color: Colors.white54, fontSize: 11, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildPresetButton(
    String label,
    int totalSec,
    TextEditingController hrCtrl,
    TextEditingController minCtrl,
    TextEditingController secCtrl,
    StateSetter setDialogState,
  ) {
    return InkWell(
      onTap: () {
        HapticFeedback.selectionClick();
        final h = totalSec ~/ 3600;
        final m = (totalSec % 3600) ~/ 60;
        final s = totalSec % 60;
        hrCtrl.text = h.toString();
        minCtrl.text = m.toString();
        secCtrl.text = s.toString();
        setDialogState(() {});
      },
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: const Color(0xFF1F2937),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFFFFD700).withOpacity(0.4)),
        ),
        child: Text(
          label,
          style: const TextStyle(color: Color(0xFFFFE66D), fontSize: 12, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  void _showSoundPickerSheet(int stepIndex, String lang) {
    final step = widget.engine.steps[stepIndex];

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF161B24),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetCtx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        TimelabI18n.soundPickerTitle(lang, stepIndex + 1),
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white70),
                      onPressed: () => Navigator.of(sheetCtx).pop(),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // 1. 내 휴대폰에서 직접 오디오 파일 선택
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF26334A),
                    foregroundColor: const Color(0xFFFFE66D),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                      side: const BorderSide(color: Color(0xFFFFD700), width: 1.2),
                    ),
                  ),
                  icon: const Icon(Icons.folder_open_rounded, size: 20),
                  label: Text(
                    TimelabI18n.pickCustomSound(lang),
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5),
                  ),
                  onPressed: () async {
                    Navigator.of(sheetCtx).pop();
                    await _pickCustomAudioFile(stepIndex, lang);
                  },
                ),

                if (step.customSoundName != null) ...[
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFD700).withOpacity(0.12),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFFFD700).withOpacity(0.4)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            TimelabI18n.currentlyRegistered(lang, step.customSoundName ?? ''),
                            style: const TextStyle(color: Color(0xFFFFE66D), fontWeight: FontWeight.bold, fontSize: 12),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.volume_up_rounded, color: Colors.amberAccent, size: 18),
                          onPressed: () {
                            _soundEngine.playCustomOrPreset(
                              soundId: 'custom',
                              customFilePath: step.customSoundPath,
                              customSoundBytes: step.customSoundBytes,
                              fallbackTheme: widget.engine.theme,
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 14),
                Text(TimelabI18n.builtinPackTitle(lang), style: const TextStyle(color: Colors.white54, fontSize: 11.5, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),

                // 2. 내장 프리셋 사운드 목록
                _buildPresetTile(sheetCtx, stepIndex, null, TimelabI18n.soundDefault(lang)),
                _buildPresetTile(sheetCtx, stepIndex, 'gate', TimelabI18n.soundGate(lang)),
                _buildPresetTile(sheetCtx, stepIndex, 'blast', TimelabI18n.soundBlast(lang)),
                _buildPresetTile(sheetCtx, stepIndex, 'buzzer', TimelabI18n.soundBuzzer(lang)),
                _buildPresetTile(sheetCtx, stepIndex, 'beep', TimelabI18n.soundBeep(lang)),
                _buildPresetTile(sheetCtx, stepIndex, 'gong', TimelabI18n.soundGong(lang)),
                _buildPresetTile(sheetCtx, stepIndex, 'magic', TimelabI18n.soundMagic(lang)),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildPresetTile(BuildContext sheetCtx, int stepIndex, String? soundId, String title) {
    final isSelected = widget.engine.steps[stepIndex].soundId == soundId &&
        widget.engine.steps[stepIndex].customSoundName == null;

    return ListTile(
      dense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
      title: Text(
        title,
        style: TextStyle(
          color: isSelected ? const Color(0xFFFFE66D) : Colors.white,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          fontSize: 13,
        ),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.volume_up_rounded, color: Colors.amberAccent, size: 18),
            onPressed: () {
              _soundEngine.playCustomOrPreset(soundId: soundId, fallbackTheme: widget.engine.theme);
            },
          ),
          if (isSelected)
            const Icon(Icons.check_circle_rounded, color: Color(0xFFFFD700), size: 18),
        ],
      ),
      onTap: () {
        setState(() {
          widget.engine.steps[stepIndex].soundId = soundId;
          widget.engine.steps[stepIndex].customSoundPath = null;
          widget.engine.steps[stepIndex].customSoundName = null;
          widget.engine.steps[stepIndex].customSoundBytes = null;
        });
        Navigator.of(sheetCtx).pop();
      },
    );
  }

  Future<void> _pickCustomAudioFile(int stepIndex, String lang) async {
    try {
      final file = await FilePicker.pickFile(
        type: FileType.custom,
        allowedExtensions: ['mp3', 'wav', 'm4a', 'ogg', 'aac', 'flac'],
      );

      if (file != null) {
        final fileName = file.name;
        final filePath = file.path;
        final bytes = await file.readAsBytes();

        setState(() {
          widget.engine.steps[stepIndex].soundId = 'custom';
          widget.engine.steps[stepIndex].customSoundPath = filePath;
          widget.engine.steps[stepIndex].customSoundName = fileName;
          widget.engine.steps[stepIndex].customSoundBytes = bytes;
        });

        // 미리듣기 재생
        await _soundEngine.playCustomOrPreset(
          soundId: 'custom',
          customFilePath: filePath,
          customSoundBytes: bytes,
          fallbackTheme: widget.engine.theme,
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(TimelabI18n.audioLoadedToast(lang, fileName)),
              backgroundColor: DokkeyTheme.cardDark,
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('File pick error: $e');
    }
  }
}
