import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// ⏱️ 버튼을 누르고 있으면 수치가 연속으로 가속 증감되는 홀드 버튼 위젯
class HoldRepeatButton extends StatefulWidget {
  final IconData icon;
  final ValueChanged<int> onStep; // 전달되는 인자는 해당 틱의 증감량 (delta)
  final Color color;
  final double size;
  final bool isEnabled;
  final String? tooltip;
  final EdgeInsets padding;

  const HoldRepeatButton({
    super.key,
    required this.icon,
    required this.onStep,
    this.color = Colors.amber,
    this.size = 22,
    this.isEnabled = true,
    this.tooltip,
    this.padding = const EdgeInsets.all(8),
  });

  @override
  State<HoldRepeatButton> createState() => _HoldRepeatButtonState();
}

class _HoldRepeatButtonState extends State<HoldRepeatButton> {
  Timer? _holdTimer;
  Timer? _periodicTimer;
  int _tickCount = 0;
  bool _isPressed = false;

  @override
  void dispose() {
    _cancelHold();
    super.dispose();
  }

  void _onTapDown(TapDownDetails details) {
    if (!widget.isEnabled) return;
    setState(() => _isPressed = true);

    // 1. 첫 탭 즉시 1단계 실행
    HapticFeedback.lightImpact();
    widget.onStep(1);

    // 2. 250ms 동안 계속 누르고 있으면 가속 반복 타이머 시작
    _cancelHold();
    _holdTimer = Timer(const Duration(milliseconds: 250), () {
      _tickCount = 0;
      _startPeriodicTimer();
    });
  }

  void _startPeriodicTimer() {
    _periodicTimer?.cancel();
    _periodicTimer = Timer.periodic(const Duration(milliseconds: 50), (timer) {
      if (!mounted || !_isPressed || !widget.isEnabled) {
        _cancelHold();
        return;
      }

      _tickCount++;

      // 가속 단계 및 증감 단위 산출
      int delta = 1;
      int intervalTicks = 1; // 50ms마다 실행되는 주기 조절

      if (_tickCount < 10) {
        // 0.25s ~ 0.75s: 100ms마다 1초씩
        delta = 1;
        intervalTicks = 2;
      } else if (_tickCount < 25) {
        // 0.75s ~ 1.5s: 50ms마다 1초씩
        delta = 1;
        intervalTicks = 1;
      } else if (_tickCount < 45) {
        // 1.5s ~ 2.5s: 50ms마다 5초씩
        delta = 5;
        intervalTicks = 1;
      } else if (_tickCount < 70) {
        // 2.5s ~ 3.75s: 50ms마다 15초씩
        delta = 15;
        intervalTicks = 1;
      } else if (_tickCount < 100) {
        // 3.75s ~ 5.25s: 50ms마다 60초(1분)씩
        delta = 60;
        intervalTicks = 1;
      } else if (_tickCount < 150) {
        // 5.25s ~ 7.75s: 50ms마다 300초(5분)씩
        delta = 300;
        intervalTicks = 1;
      } else {
        // > 7.75s: 50ms마다 600초(10분)씩
        delta = 600;
        intervalTicks = 1;
      }

      if (_tickCount % intervalTicks == 0) {
        HapticFeedback.selectionClick();
        widget.onStep(delta);
      }
    });
  }

  void _onTapUp(TapUpDetails details) {
    _cancelHold();
  }

  void _onTapCancel() {
    _cancelHold();
  }

  void _cancelHold() {
    _holdTimer?.cancel();
    _holdTimer = null;
    _periodicTimer?.cancel();
    _periodicTimer = null;
    _tickCount = 0;
    if (_isPressed && mounted) {
      setState(() => _isPressed = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final effectiveColor = widget.isEnabled
        ? (_isPressed ? widget.color.withOpacity(0.7) : widget.color)
        : Colors.white24;

    Widget child = Padding(
      padding: widget.padding,
      child: AnimatedScale(
        scale: _isPressed ? 1.15 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: Icon(
          widget.icon,
          color: effectiveColor,
          size: widget.size,
        ),
      ),
    );

    if (widget.tooltip != null) {
      child = Tooltip(message: widget.tooltip!, child: child);
    }

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: widget.isEnabled ? _onTapDown : null,
      onTapUp: widget.isEnabled ? _onTapUp : null,
      onTapCancel: widget.isEnabled ? _onTapCancel : null,
      child: child,
    );
  }
}
