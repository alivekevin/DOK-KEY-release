import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../core/sound_service.dart';
import '../../core/theme.dart';
import '../../providers/dokkey_provider.dart';
import '../../widgets/pro_pass_dialog.dart';
import '../core/timelab_sound_engine.dart';
import '../core/timelab_theme_engine.dart';
import '../models/timelab_models.dart';
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
    final isPro = provider.isProUser;
    final cfg = TimelabThemeConfig.of(widget.engine.theme);

    return Scaffold(
      backgroundColor: const Color(0xFF0C0F17),
      appBar: AppBar(
        backgroundColor: const Color(0xFF141923),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          '시퀀스 체인 & 종료음 설정',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 16),
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
                          const Text(
                            '3-Phase 시네마틱 체인 플로우',
                            style: TextStyle(color: Color(0xFFFFE66D), fontWeight: FontWeight.bold, fontSize: 13.5),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            isPro
                              ? '각 단계별 타이머 시간, 내 폰의 음악/효과음, 완료 후 지연시간(Delay)을 완벽하게 커스텀 설정할 수 있습니다.'
                              : '무료 티어는 1단계 타이머를 이용할 수 있습니다. 2~3단계 커스텀 체인 및 내 폰 사운드 지정은 PRO 전용입니다 👑',
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
                  const Text('체인 단계 수', style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
                  Row(
                    children: [
                      _buildSlotTab(1, isPro: true),
                      const SizedBox(width: 6),
                      _buildSlotTab(2, isPro: isPro),
                      const SizedBox(width: 6),
                      _buildSlotTab(3, isPro: isPro),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 18),

              // 1단계 슬롯 카드 (기본)
              _buildStepCard(0, isLocked: false),

              const SizedBox(height: 14),

              // 2단계 슬롯 카드 (PRO)
              _buildStepCard(1, isLocked: !isPro),

              const SizedBox(height: 14),

              // 3단계 슬롯 카드 (PRO)
              _buildStepCard(2, isLocked: !isPro),

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
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('세트 완주 반복 횟수', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13.5)),
                        Text('1~9회 세트 루프 지원', style: TextStyle(color: Colors.white54, fontSize: 11)),
                      ],
                    ),
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.remove_circle_outline, color: Colors.amber),
                          onPressed: widget.engine.totalSets > 1
                              ? () => setState(() => widget.engine.setTotalSets(widget.engine.totalSets - 1))
                              : null,
                        ),
                        Text(
                          '${widget.engine.totalSets} 세트',
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 16),
                        ),
                        IconButton(
                          icon: const Icon(Icons.add_circle_outline, color: Colors.amber),
                          onPressed: widget.engine.totalSets < 9
                              ? () => setState(() => widget.engine.setTotalSets(widget.engine.totalSets + 1))
                              : null,
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
                child: const Text('설정 완료 및 타이머로 돌아가기', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15)),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSlotTab(int count, {required bool isPro}) {
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
              '$count단',
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

  Widget _buildStepCard(int idx, {required bool isLocked}) {
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
                    isEnabled ? '가동 중' : '비활성',
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
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('👑 PRO 전용', style: TextStyle(color: Colors.amber, fontSize: 11, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                ),
            ],
          ),

          const SizedBox(height: 14),

          // 1) 타이머 시간 설정
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('타이머 시간', style: TextStyle(color: Colors.white70, fontSize: 13)),
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.remove_circle_outline, color: Colors.amber, size: 20),
                    onPressed: !isLocked && isEnabled && step.duration.inSeconds > 1
                        ? () => setState(() {
                            widget.engine.updateStepDuration(idx, Duration(seconds: step.duration.inSeconds - 1));
                          })
                        : null,
                  ),
                  Text(
                    '${step.duration.inSeconds}초',
                    style: TextStyle(
                      color: isLocked ? Colors.white38 : Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 16,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.add_circle_outline, color: Colors.amber, size: 20),
                    onPressed: !isLocked && isEnabled
                        ? () => setState(() {
                            widget.engine.updateStepDuration(idx, Duration(seconds: step.duration.inSeconds + 1));
                          })
                        : null,
                  ),
                ],
              ),
            ],
          ),

          const Divider(color: Colors.white10, height: 16),

          // 2) 종료음 선택 (내 폰 사운드 or 내장 프리셋)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('종료 시 효과음', style: TextStyle(color: Colors.white70, fontSize: 13)),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (!isLocked && isEnabled)
                    IconButton(
                      icon: const Icon(Icons.volume_up_rounded, color: Colors.amberAccent, size: 20),
                      tooltip: '효과음 미리듣기',
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
                    onTap: !isLocked && isEnabled ? () => _showSoundPickerSheet(idx) : null,
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
                          Text(
                            step.soundDisplayName,
                            style: TextStyle(
                              color: isLocked ? Colors.white38 : const Color(0xFFFFE66D),
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
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

          const Divider(color: Colors.white10, height: 16),

          // 3) 완료 후 지연 대기 시간 (Delay)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('완료 후 다음 지연(Delay)', style: TextStyle(color: Colors.white70, fontSize: 13)),
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.remove_circle_outline, color: Colors.amber, size: 20),
                    onPressed: !isLocked && isEnabled && step.delayAfter.inSeconds > 0
                        ? () => setState(() {
                            widget.engine.updateStepDelay(idx, Duration(seconds: step.delayAfter.inSeconds - 1));
                          })
                        : null,
                  ),
                  Text(
                    '${step.delayAfter.inSeconds}초',
                    style: TextStyle(
                      color: isLocked ? Colors.white38 : const Color(0xFFFFAB40),
                      fontWeight: FontWeight.w900,
                      fontSize: 16,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.add_circle_outline, color: Colors.amber, size: 20),
                    onPressed: !isLocked && isEnabled
                        ? () => setState(() {
                            widget.engine.updateStepDelay(idx, Duration(seconds: step.delayAfter.inSeconds + 1));
                          })
                        : null,
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showSoundPickerSheet(int stepIndex) {
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
                    Text(
                      '🔊 단계 ${stepIndex + 1} 종료 효과음 선택',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
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
                  label: const Text(
                    '📁 내 휴대폰에서 오디오 파일 선택 (.mp3, .wav, .m4a)',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5),
                  ),
                  onPressed: () async {
                    Navigator.of(sheetCtx).pop();
                    await _pickCustomAudioFile(stepIndex);
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
                            '현재 등록: 📁 ${step.customSoundName}',
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
                const Text('⚡ 시네마틱 내장 사운드 팩', style: TextStyle(color: Colors.white54, fontSize: 11.5, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),

                // 2. 내장 프리셋 사운드 목록
                _buildPresetTile(sheetCtx, stepIndex, null, '⚡ 테마 기본 사운드'),
                _buildPresetTile(sheetCtx, stepIndex, 'gate', '🚪 묵직한 철문 개방음'),
                _buildPresetTile(sheetCtx, stepIndex, 'blast', '💥 시한폭탄 대폭발음'),
                _buildPresetTile(sheetCtx, stepIndex, 'buzzer', '🏁 레이싱 출발 부저'),
                _buildPresetTile(sheetCtx, stepIndex, 'beep', '📡 관제탑 비프음'),
                _buildPresetTile(sheetCtx, stepIndex, 'gong', '🔔 황금 징 피날레'),
                _buildPresetTile(sheetCtx, stepIndex, 'magic', '🪄 도깨비 방망이 마법'),
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

  Future<void> _pickCustomAudioFile(int stepIndex) async {
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
              content: Text('🎵 "$fileName" 오디오 등록 및 로드 완료!'),
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
