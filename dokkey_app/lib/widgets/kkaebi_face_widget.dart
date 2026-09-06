import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import '../core/theme.dart';

enum KkaebiFaceMode {
  idle,      // [1 평온] ↔ [2 반가움] (대기 / 눈 깜빡임)
  greeting,  // [2 반가움] ↔ [5 미소] (인사 / 호감)
  talking,   // [5 미소] ↔ [2 반가움] (대화 / 립싱크)
  joy,       // [5 미소] → [3 기쁨] (활짝 웃음 이벤트)
  wink,      // [5 미소] → [4 윙크] (친근한 윙크 이벤트)
  jackpot,   // [8 놀라움] → [3 기쁨] (대박/서프라이즈 환호 이벤트)
  angry,     // [5 미소] → [6 분노] (카리스마 호통 이벤트)
  sadness,   // [5 미소] → [7 슬픔] (위로/서운 이벤트)
  surprise,  // [1 평온] → [8 놀라움] (깜짝 발견 이벤트)
  neutral,   // [1 평온] 단독
}

/// 😈 깨비 8개 감정 & A → B 시퀀스 반응형 페이스 위젯 (v4.1.0)
class KkaebiFaceWidget extends StatefulWidget {
  final double size;
  final KkaebiFaceMode mode;
  final bool enableFloat;
  final bool enableGlow;
  final Color? glowColor;
  final VoidCallback? onTap;

  const KkaebiFaceWidget({
    super.key,
    this.size = 120,
    this.mode = KkaebiFaceMode.idle,
    this.enableFloat = false,
    this.enableGlow = false,
    this.glowColor,
    this.onTap,
  });

  @override
  State<KkaebiFaceWidget> createState() => _KkaebiFaceWidgetState();
}

class _KkaebiFaceWidgetState extends State<KkaebiFaceWidget>
    with TickerProviderStateMixin {
  late AnimationController _frameCtrl;
  late AnimationController _breathCtrl;
  int _currentFrame = 1;
  Timer? _oneShotTimer;

  @override
  void initState() {
    super.initState();

    // 1. 호흡 / 부유 컨트롤러 (2.8초 주기 부드러운 스케일)
    _breathCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2800),
    )..repeat(reverse: true);

    // 2. 프레임 전환 컨트롤러
    _frameCtrl = AnimationController(vsync: this);
    _applyMode(widget.mode);
  }

  void _applyMode(KkaebiFaceMode mode) {
    _oneShotTimer?.cancel();
    _frameCtrl.stop();
    _frameCtrl.reset();

    switch (mode) {
      // 🔁 1. 반복 재생 (Loop)
      case KkaebiFaceMode.idle:
        // [5 미소] ↔ [4 윙크] (3.0초 주기: 평소에는 [5 미소], 주기적으로 [4 윙크])
        _frameCtrl.duration = const Duration(milliseconds: 3000);
        _frameCtrl.repeat();
        _frameCtrl.addListener(_onIdleTick);
        break;

      case KkaebiFaceMode.greeting:
        // [2 반가움] ↔ [5 미소] (1.6초 주기)
        _frameCtrl.duration = const Duration(milliseconds: 1600);
        _frameCtrl.repeat(reverse: true);
        _frameCtrl.addListener(_onGreetingTick);
        break;

      case KkaebiFaceMode.talking:
        // [5 미소] ↔ [2 반가움] (220ms 주기 립싱크)
        _frameCtrl.duration = const Duration(milliseconds: 220);
        _frameCtrl.repeat(reverse: true);
        _frameCtrl.addListener(_onTalkingTick);
        break;

      case KkaebiFaceMode.neutral:
        _currentFrame = 1; // [1 평온]
        break;

      // ▶ 2. 1회 재생 감정 이벤트 (One-Shot -> [5 미소] 복귀)
      case KkaebiFaceMode.joy:
        // [5 미소] → [3 기쁨] (600ms 유지 후 [5 미소])
        _playOneShotSequence(startFrame: 5, targetFrame: 3, returnFrame: 5, durationMs: 700);
        break;

      case KkaebiFaceMode.wink:
        // [5 미소] → [4 윙크] (750ms 유지 후 [5 미소])
        _playOneShotSequence(startFrame: 5, targetFrame: 4, returnFrame: 5, durationMs: 750);
        break;

      case KkaebiFaceMode.jackpot:
        // [8 놀라움] → [3 기쁨] (850ms 유지 후 [5 미소])
        _playOneShotSequence(startFrame: 8, targetFrame: 3, returnFrame: 5, durationMs: 850);
        break;

      case KkaebiFaceMode.angry:
        // [5 미소] → [6 분노] (900ms 유지 후 [1 평온])
        _playOneShotSequence(startFrame: 5, targetFrame: 6, returnFrame: 1, durationMs: 900);
        break;

      case KkaebiFaceMode.sadness:
        // [5 미소] → [7 슬픔] (900ms 유지 후 [5 미소])
        _playOneShotSequence(startFrame: 5, targetFrame: 7, returnFrame: 5, durationMs: 900);
        break;

      case KkaebiFaceMode.surprise:
        // [1 평온] → [8 놀라움] (800ms 유지 후 [5 미소])
        _playOneShotSequence(startFrame: 1, targetFrame: 8, returnFrame: 5, durationMs: 800);
        break;
    }
  }

  void _onIdleTick() {
    final v = _frameCtrl.value;
    // 0.0 ~ 0.78: [5 미소] (약 2.34초 동안 부드러운 미소)
    // 0.78 ~ 0.98: [4 윙크] (약 0.60초 동안 친근하게 윙크!)
    // 0.98 ~ 1.00: [5 미소] 복귀
    final newFrame = (v >= 0.78 && v <= 0.98) ? 4 : 5;
    if (_currentFrame != newFrame && mounted) {
      setState(() => _currentFrame = newFrame);
    }
  }

  void _onGreetingTick() {
    final newFrame = _frameCtrl.value < 0.5 ? 2 : 5;
    if (_currentFrame != newFrame && mounted) {
      setState(() => _currentFrame = newFrame);
    }
  }

  void _onTalkingTick() {
    final newFrame = _frameCtrl.value < 0.5 ? 5 : 2;
    if (_currentFrame != newFrame && mounted) {
      setState(() => _currentFrame = newFrame);
    }
  }

  void _playOneShotSequence({
    required int startFrame,
    required int targetFrame,
    required int returnFrame,
    required int durationMs,
  }) {
    setState(() => _currentFrame = startFrame);
    _oneShotTimer = Timer(const Duration(milliseconds: 150), () {
      if (!mounted) return;
      setState(() => _currentFrame = targetFrame);

      _oneShotTimer = Timer(Duration(milliseconds: durationMs), () {
        if (!mounted) return;
        setState(() => _currentFrame = returnFrame);
      });
    });
  }

  @override
  void didUpdateWidget(KkaebiFaceWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.mode != oldWidget.mode) {
      _frameCtrl.removeListener(_onIdleTick);
      _frameCtrl.removeListener(_onGreetingTick);
      _frameCtrl.removeListener(_onTalkingTick);
      _applyMode(widget.mode);
    }
  }

  @override
  void dispose() {
    _oneShotTimer?.cancel();
    _frameCtrl.dispose();
    _breathCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final frameStr = _currentFrame.toString().padLeft(2, '0');
    final assetPath = 'assets/images/kkaebi_face/face_$frameStr.webp';
    final glowColor = widget.glowColor ?? DokkeyTheme.gold;

    return GestureDetector(
      onTap: widget.onTap,
      child: AnimatedBuilder(
        animation: _breathCtrl,
        builder: (context, child) {
          final breathScale = 1.0 + sin(_breathCtrl.value * pi) * 0.025;
          final floatOffset = widget.enableFloat ? sin(_breathCtrl.value * 2 * pi) * 6.0 : 0.0;

          return Transform.translate(
            offset: Offset(0, floatOffset),
            child: Transform.scale(
              scale: breathScale,
              child: Container(
                width: widget.size,
                height: widget.size,
                decoration: widget.enableGlow
                    ? BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: glowColor.withOpacity(0.35),
                            blurRadius: widget.size * 0.25,
                            spreadRadius: 2,
                          ),
                        ],
                      )
                    : null,
                child: Image.asset(
                  assetPath,
                  width: widget.size,
                  height: widget.size,
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => Image.asset(
                    'assets/images/kkaebi_mascot.png',
                    width: widget.size,
                    height: widget.size,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
