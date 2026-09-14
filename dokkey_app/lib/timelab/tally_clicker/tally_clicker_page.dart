import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../core/sound_service.dart';
import '../../providers/dokkey_provider.dart';
import '../models/timelab_models.dart';
import '../core/timelab_theme_engine.dart';
import '../core/timelab_i18n.dart';
import 'tally_clicker_engine.dart';

/// 🔢 택티컬 탭 카운터 (The Tactical Clicker)
/// 풀스크린 네온 터치패드 & 7-세그먼트 스타일 계수기 UI (6개국어 완벽 지원)
class TallyClickerPage extends StatefulWidget {
  const TallyClickerPage({super.key});

  static void show(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const TallyClickerPage()),
    );
  }

  @override
  State<TallyClickerPage> createState() => _TallyClickerPageState();
}

class _TallyClickerPageState extends State<TallyClickerPage> with SingleTickerProviderStateMixin {
  late final TallyClickerEngine _engine;
  late final AnimationController _bgAnimCtrl;

  // 리셋 버튼 롱프레스 홀드 게이지 타이머 및 진행도
  Timer? _resetHoldTimer;
  double _resetHoldProgress = 0.0;
  bool _isResetHolding = false;

  // 탭 물결 이펙트 좌표 목록
  final List<Offset> _tapRipples = [];

  // 10단위 / 100단위 / 목표 도달 스케일 & 플래시 상태
  double _displayScale = 1.0;
  bool _showFlashGlow = false;

  @override
  void initState() {
    super.initState();
    _engine = TallyClickerEngine();
    _engine.addListener(_onEngineUpdated);

    _bgAnimCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 12),
    )..repeat();
  }

  @override
  void dispose() {
    _resetHoldTimer?.cancel();
    _engine.removeListener(_onEngineUpdated);
    _bgAnimCtrl.dispose();
    super.dispose();
  }

  void _onEngineUpdated() {
    if (!mounted) return;

    // 마일스톤 또는 목표 도달 시 시각 연출 트리거
    if (_engine.isTargetReached || _engine.isMilestone100) {
      setState(() {
        _displayScale = 1.25;
        _showFlashGlow = true;
      });
      Future.delayed(const Duration(milliseconds: 350), () {
        if (mounted) {
          setState(() {
            _displayScale = 1.0;
            _showFlashGlow = false;
          });
        }
      });
    } else if (_engine.isMilestone10) {
      setState(() {
        _displayScale = 1.15;
      });
      Future.delayed(const Duration(milliseconds: 200), () {
        if (mounted) {
          setState(() {
            _displayScale = 1.0;
          });
        }
      });
    } else {
      setState(() {});
    }
  }

  void _handleTapDown(TapDownDetails details) {
    _engine.increment();
    setState(() {
      _tapRipples.add(details.localPosition);
    });
    Future.delayed(const Duration(milliseconds: 400), () {
      if (mounted && _tapRipples.isNotEmpty) {
        setState(() {
          _tapRipples.removeAt(0);
        });
      }
    });
  }

  void _startResetHold(String lang) {
    setState(() {
      _isResetHolding = true;
      _resetHoldProgress = 0.0;
    });

    const totalSteps = 20;
    const stepDuration = Duration(milliseconds: 40); // 총 800ms
    int currentStep = 0;

    _resetHoldTimer?.cancel();
    _resetHoldTimer = Timer.periodic(stepDuration, (timer) {
      currentStep++;
      if (mounted) {
        setState(() {
          _resetHoldProgress = (currentStep / totalSteps).clamp(0.0, 1.0);
        });
      }

      if (currentStep >= totalSteps) {
        timer.cancel();
        _engine.reset();
        SoundService().playKeyTurn();
        if (mounted) {
          setState(() {
            _isResetHolding = false;
            _resetHoldProgress = 0.0;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(TimelabI18n.resetDone(lang)),
              duration: const Duration(milliseconds: 1000),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    });
  }

  void _cancelResetHold() {
    _resetHoldTimer?.cancel();
    if (_isResetHolding && mounted) {
      setState(() {
        _isResetHolding = false;
        _resetHoldProgress = 0.0;
      });
    }
  }

  void _showTargetDialog(TimelabThemeConfig themeCfg, String lang) {
    final controller = TextEditingController(
      text: _engine.targetCount != null ? _engine.targetCount.toString() : '',
    );

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF141923),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: themeCfg.primaryColor, width: 1.5),
        ),
        title: Row(
          children: [
            const Text('🎯', style: TextStyle(fontSize: 22)),
            const SizedBox(width: 8),
            Text(
              TimelabI18n.targetSettingTitle(lang),
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              TimelabI18n.targetSettingDesc(lang),
              style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13, height: 1.4),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              autofocus: true,
              style: TextStyle(
                color: themeCfg.primaryColor,
                fontSize: 22,
                fontWeight: FontWeight.bold,
                fontFamily: 'monospace',
              ),
              decoration: InputDecoration(
                hintText: TimelabI18n.targetHint(lang),
                hintStyle: const TextStyle(color: Colors.white24, fontSize: 14),
                filled: true,
                fillColor: const Color(0xFF0A0C10),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFF2A364F)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: themeCfg.primaryColor, width: 1.8),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              children: [50, 100, 300, 500, 1000].map((preset) {
                return ActionChip(
                  backgroundColor: const Color(0xFF1E2638),
                  side: BorderSide(color: themeCfg.primaryColor.withOpacity(0.4)),
                  label: Text(
                    '+$preset',
                    style: TextStyle(color: themeCfg.primaryColor, fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                  onPressed: () {
                    controller.text = preset.toString();
                  },
                );
              }).toList(),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              _engine.setTargetCount(null);
              Navigator.of(ctx).pop();
            },
            child: Text(TimelabI18n.clearTarget(lang), style: const TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: themeCfg.primaryColor,
              foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () {
              final parsed = int.tryParse(controller.text.trim());
              _engine.setTargetCount(parsed);
              Navigator.of(ctx).pop();
            },
            child: Text(TimelabI18n.saveSetting(lang), style: const TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showThemeSelector(String lang) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF121620),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  TimelabI18n.selectThemeTitle(lang),
                  style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                ...TimelabTheme.values.map((t) {
                  final cfg = TimelabThemeConfig.of(t);
                  final isSel = _engine.theme == t;

                  String displayName;
                  String subtitle;
                  switch (t) {
                    case TimelabTheme.classicDigital:
                      displayName = TimelabI18n.themeClassic(lang);
                      subtitle = TimelabI18n.themeClassicDesc(lang);
                      break;
                    case TimelabTheme.cyberDefuser:
                      displayName = TimelabI18n.themeCyber(lang);
                      subtitle = TimelabI18n.themeCyberDesc(lang);
                      break;
                    case TimelabTheme.orbitalLaunch:
                      displayName = TimelabI18n.themeOrbital(lang);
                      subtitle = TimelabI18n.themeOrbitalDesc(lang);
                      break;
                  }

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: InkWell(
                      onTap: () {
                        _engine.setTheme(t);
                        Navigator.of(context).pop();
                      },
                      borderRadius: BorderRadius.circular(14),
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: isSel ? cfg.primaryColor.withOpacity(0.15) : const Color(0xFF1B2232),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: isSel ? cfg.primaryColor : const Color(0xFF2A364F),
                            width: isSel ? 1.8 : 1.0,
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 16,
                              height: 16,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: cfg.primaryColor,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    displayName,
                                    style: TextStyle(
                                      color: isSel ? cfg.primaryColor : Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                  Text(
                                    subtitle,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 11),
                                  ),
                                ],
                              ),
                            ),
                            if (isSel)
                              Icon(Icons.check_circle_rounded, color: cfg.primaryColor, size: 20),
                          ],
                        ),
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<DokkeyProvider>().lang;
    final themeCfg = TimelabThemeConfig.of(_engine.theme);

    return Scaffold(
      backgroundColor: themeCfg.backgroundColor,
      body: Stack(
        children: [
          // 1. 시네마틱 애니메이션 백그라운드
          AnimatedBuilder(
            animation: _bgAnimCtrl,
            builder: (ctx, child) {
              return CustomPaint(
                size: Size.infinite,
                painter: TimelabBackgroundPainter(
                  theme: _engine.theme,
                  animationValue: _bgAnimCtrl.value,
                  isCritical: _showFlashGlow,
                ),
              );
            },
          ),

          // 2. 풀스크린 메인 터치 영역 (>80% 면적)
          SafeArea(
            child: Column(
              children: [
                // Top Custom Header Bar
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white70, size: 20),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'THE TACTICAL CLICKER',
                        style: TextStyle(
                          fontFamily: 'monospace',
                          color: themeCfg.primaryColor,
                          fontWeight: FontWeight.w900,
                          fontSize: 14,
                          letterSpacing: 1.5,
                        ),
                      ),
                      const Spacer(),
                      // 사운드 토글
                      IconButton(
                        icon: Icon(
                          _engine.soundEnabled ? Icons.volume_up_rounded : Icons.volume_off_rounded,
                          color: _engine.soundEnabled ? themeCfg.primaryColor : Colors.white38,
                          size: 20,
                        ),
                        onPressed: () => _engine.toggleSound(),
                        tooltip: 'Sound ON/OFF',
                      ),
                      // 진동 토글
                      IconButton(
                        icon: Icon(
                          _engine.vibrationEnabled ? Icons.vibration_rounded : Icons.phonelink_erase_rounded,
                          color: _engine.vibrationEnabled ? themeCfg.primaryColor : Colors.white38,
                          size: 20,
                        ),
                        onPressed: () => _engine.toggleVibration(),
                        tooltip: 'Vibrate ON/OFF',
                      ),
                      // 테마 변경
                      IconButton(
                        icon: const Icon(Icons.palette_outlined, color: Colors.white70, size: 20),
                        onPressed: () => _showThemeSelector(lang),
                        tooltip: 'Theme',
                      ),
                    ],
                  ),
                ),

                // Target Banner (설정 시 상단에 표시)
                if (_engine.targetCount != null)
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF141923).withOpacity(0.9),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: themeCfg.primaryColor.withOpacity(0.5)),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.flag_rounded, color: themeCfg.primaryColor, size: 16),
                        const SizedBox(width: 8),
                        Text(
                          'TARGET: ${_engine.targetCount}',
                          style: TextStyle(
                            color: themeCfg.primaryColor,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'monospace',
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: _engine.progressToTarget,
                              backgroundColor: const Color(0xFF1F293D),
                              valueColor: AlwaysStoppedAnimation<Color>(themeCfg.primaryColor),
                              minHeight: 6,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          '${(_engine.progressToTarget * 100).toInt()}%',
                          style: const TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),

                // 거대 풀스크린 터치 패드
                Expanded(
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTapDown: _handleTapDown,
                    child: Container(
                      width: double.infinity,
                      alignment: Alignment.center,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          // 탭 파동 링 리플
                          ..._tapRipples.map((pos) => Positioned(
                                left: pos.dx - 40,
                                top: pos.dy - 40,
                                child: Container(
                                  width: 80,
                                  height: 80,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: themeCfg.primaryColor.withOpacity(0.6),
                                      width: 2.0,
                                    ),
                                  ),
                                ),
                              )),

                          // 네온 카운트 디스플레이 (0 ~ 99,999)
                          AnimatedScale(
                            scale: _displayScale,
                            duration: const Duration(milliseconds: 150),
                            curve: Curves.easeOutBack,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  _engine.count.toString().padLeft(1, '0'),
                                  style: TextStyle(
                                    fontFamily: 'monospace',
                                    fontSize: 84,
                                    fontWeight: FontWeight.w900,
                                    color: themeCfg.primaryColor,
                                    letterSpacing: 4.0,
                                    shadows: [
                                      Shadow(
                                        color: themeCfg.primaryColor.withOpacity(0.8),
                                        blurRadius: 28,
                                      ),
                                      Shadow(
                                        color: themeCfg.primaryColor.withOpacity(0.4),
                                        blurRadius: 56,
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: themeCfg.primaryColor.withOpacity(0.12),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(color: themeCfg.primaryColor.withOpacity(0.4)),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.touch_app_rounded, color: themeCfg.primaryColor, size: 14),
                                      const SizedBox(width: 6),
                                      Text(
                                        TimelabI18n.tapAnywhere(lang),
                                        style: TextStyle(
                                          color: themeCfg.primaryColor,
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // 3. 하단 컨트롤 패널 바 (-1, RESET 롱프레스, TARGET)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF10141D),
                    border: Border(top: BorderSide(color: themeCfg.borderColor.withOpacity(0.4))),
                  ),
                  child: Row(
                    children: [
                      // [-1] 감소 버튼
                      Expanded(
                        flex: 2,
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFFFF5252),
                            side: const BorderSide(color: Color(0xFFFF5252), width: 1.5),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                          onPressed: _engine.count > 0 ? () => _engine.decrement() : null,
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.remove_rounded, size: 18),
                              SizedBox(width: 4),
                              Text('-1', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),

                      // [RESET] 길게 눌러 초기화 버튼 (원형/직사각형 게이지)
                      Expanded(
                        flex: 3,
                        child: GestureDetector(
                          onLongPressStart: (_) => _startResetHold(lang),
                          onLongPressEnd: (_) => _cancelResetHold(),
                          onLongPressCancel: () => _cancelResetHold(),
                          child: Container(
                            height: 50,
                            decoration: BoxDecoration(
                              color: const Color(0xFF1E2638),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: _isResetHolding ? const Color(0xFFFF9100) : const Color(0xFF334155),
                                width: 1.5,
                              ),
                            ),
                            child: Stack(
                              children: [
                                // 홀드 차오르는 게이지
                                if (_isResetHolding)
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(12),
                                    child: FractionallySizedBox(
                                      alignment: Alignment.centerLeft,
                                      widthFactor: _resetHoldProgress,
                                      child: Container(
                                        color: const Color(0xFFFF9100).withOpacity(0.35),
                                      ),
                                    ),
                                  ),
                                Center(
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.restart_alt_rounded,
                                        size: 18,
                                        color: _isResetHolding ? const Color(0xFFFF9100) : Colors.white70,
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        _isResetHolding ? TimelabI18n.resetting(lang) : TimelabI18n.resetHold(lang),
                                        style: TextStyle(
                                          color: _isResetHolding ? const Color(0xFFFF9100) : Colors.white,
                                          fontSize: 13,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),

                      // [TARGET] 목표 수치 설정 버튼
                      Expanded(
                        flex: 2,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: themeCfg.primaryColor.withOpacity(0.18),
                            foregroundColor: themeCfg.primaryColor,
                            elevation: 0,
                            side: BorderSide(color: themeCfg.primaryColor, width: 1.5),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                          onPressed: () => _showTargetDialog(themeCfg, lang),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.track_changes_rounded, size: 18),
                              SizedBox(width: 4),
                              Text('TARGET', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w900)),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
