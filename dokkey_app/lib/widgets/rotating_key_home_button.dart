import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../core/theme.dart';
import '../core/sound_service.dart';
import '../providers/dokkey_provider.dart';

/// 🗝️ 홈 "열쇠돌리기" 오브 스타일 홈 바로가기 버튼 (v4.2.4)
/// - 컴팩트한 규격 (28dp 고정) + 슬림하고 세련된 회전 골드 테두리 (2.2dp 림)
/// - 코어 공간 확장으로 더 크고 선명해진 골드 자물쇠 엠블럼 (18.0dp)
/// - 은은한 생동감 슬로우 회전 애니메이션 (9.6초 턴)
class RotatingKeyHomeButton extends StatefulWidget {
  final double size;

  const RotatingKeyHomeButton({super.key, this.size = 28.0});

  @override
  State<RotatingKeyHomeButton> createState() => _RotatingKeyHomeButtonState();
}

class _RotatingKeyHomeButtonState extends State<RotatingKeyHomeButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 9600),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTapHome(BuildContext context) {
    HapticFeedback.lightImpact();
    SoundService().playKeyTurn();
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<DokkeyProvider>();
    final lang = provider.lang;

    final tooltip = lang == 'ko'
        ? '홈 (열쇠돌리기)'
        : (lang == 'ja'
            ? 'ホーム (鍵を回す)'
            : (lang == 'zh'
                ? '主页 (转动钥匙)'
                : (lang == 'hi'
                    ? 'होम (चाबी घुमाएं)'
                    : (lang == 'de' ? 'Startseite (Drehen)' : 'Home (Turn Key)'))));

    final double borderWidth = 2.2;
    final double coreSize = widget.size - (borderWidth * 2);

    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: () => _onTapHome(context),
        borderRadius: BorderRadius.circular(widget.size / 2),
        child: Container(
          width: widget.size,
          height: widget.size,
          margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return Stack(
                alignment: Alignment.center,
                children: [
                  // 1. 바깥쪽 슬로우 회전하는 슬림한 골드 테두리 (2.2dp Slim SweepGradient Rim)
                  Transform.rotate(
                    angle: _controller.value * 2 * math.pi,
                    child: Container(
                      width: widget.size,
                      height: widget.size,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: SweepGradient(
                          colors: [
                            DokkeyTheme.gold.withValues(alpha: 0.15),
                            DokkeyTheme.dokFire.withValues(alpha: 0.85),
                            DokkeyTheme.goldLight,
                            const Color(0xFFFFF7D6),
                            DokkeyTheme.gold,
                            DokkeyTheme.gold.withValues(alpha: 0.15),
                          ],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: DokkeyTheme.gold.withValues(alpha: 0.25),
                            blurRadius: 4,
                            spreadRadius: 0.5,
                          ),
                        ],
                      ),
                    ),
                  ),
                  // 2. 내부 확장된 어두운 원형 코어 (23.6dp)
                  Container(
                    width: coreSize,
                    height: coreSize,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          DokkeyTheme.surfaceDark,
                          DokkeyTheme.cardDark,
                          DokkeyTheme.bgDark,
                        ],
                      ),
                    ),
                    child: Center(
                      // 3. 중앙에 더 크고 또렷하게 자리잡은 골드 자물쇠(Lock) 아이콘 (18.0dp)
                      child: ShaderMask(
                        shaderCallback: (bounds) => LinearGradient(
                          colors: [
                            const Color(0xFFFFFFFF),
                            const Color(0xFFFFF2B2),
                            DokkeyTheme.gold,
                          ],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ).createShader(bounds),
                        child: const Icon(
                          Icons.lock_open_rounded,
                          color: Colors.white,
                          size: 18.0,
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
