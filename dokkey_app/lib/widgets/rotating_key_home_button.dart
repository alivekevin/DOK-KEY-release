import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../core/sound_service.dart';
import '../core/theme.dart';
import '../providers/dokkey_provider.dart';

/// 🏠 100% 캔버스 벡터 그래픽 홈 바로가기 버튼 (v4.7.6)
/// - 폰트/아이콘 애셋 로딩이나 트리쉐이킹 누락 위험이 전혀 없는 순수 Canvas DrawPath 벡터 렌더링
/// - 34dp 원형 골드 글래스 배지 + 중앙 골드 도깨비 사당/홈 엠블럼 + 아치 도어
/// - 어떤 웹 브라우저나 모바일 기기에서도 100% 선명하고 즉각적으로 렌더링
class RotatingKeyHomeButton extends StatelessWidget {
  final double size;

  const RotatingKeyHomeButton({super.key, this.size = 34.0});

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

    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _onTapHome(context),
          borderRadius: BorderRadius.circular(size / 2),
          child: Container(
            width: size,
            height: size,
            margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  const Color(0xFF382B14),
                  DokkeyTheme.surfaceDark,
                  DokkeyTheme.cardDark,
                ],
              ),
              border: Border.all(
                color: DokkeyTheme.gold.withValues(alpha: 0.9),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: DokkeyTheme.gold.withValues(alpha: 0.3),
                  blurRadius: 8,
                  spreadRadius: 1.0,
                ),
              ],
            ),
            child: Center(
              child: CustomPaint(
                size: Size(size * 0.65, size * 0.65),
                painter: _GoldenHomeVectorPainter(
                  goldColor: DokkeyTheme.gold,
                  lightGold: DokkeyTheme.goldLight,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// 캔버스에 직접 그리는 황금 홈 벡터 심볼
class _GoldenHomeVectorPainter extends CustomPainter {
  final Color goldColor;
  final Color lightGold;

  _GoldenHomeVectorPainter({
    required this.goldColor,
    required this.lightGold,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // 1. House Roof & Body Path (지붕 + 외벽)
    final housePath = Path()
      ..moveTo(w * 0.50, h * 0.15) // Top roof apex
      ..lineTo(w * 0.90, h * 0.46) // Right eaves
      ..lineTo(w * 0.78, h * 0.46)
      ..lineTo(w * 0.78, h * 0.88) // Right wall
      ..lineTo(w * 0.22, h * 0.88) // Left wall
      ..lineTo(w * 0.22, h * 0.46)
      ..lineTo(w * 0.10, h * 0.46) // Left eaves
      ..close();

    // Metallic gold linear gradient
    final bodyPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          const Color(0xFFFFF9E6),
          lightGold,
          goldColor,
          const Color(0xFFB8860B),
        ],
      ).createShader(Rect.fromLTWH(0, 0, w, h))
      ..style = PaintingStyle.fill;

    canvas.drawPath(housePath, bodyPaint);

    // 2. Door / Keyhole opening (열쇠 구멍 아치형 출입문)
    final doorPath = Path()
      ..moveTo(w * 0.38, h * 0.88)
      ..lineTo(w * 0.38, h * 0.64)
      ..arcToPoint(
        Offset(w * 0.62, h * 0.64),
        radius: Radius.circular(w * 0.12),
        clockwise: true,
      )
      ..lineTo(w * 0.62, h * 0.88)
      ..close();

    final doorPaint = Paint()
      ..color = const Color(0xFF141822)
      ..style = PaintingStyle.fill;

    canvas.drawPath(doorPath, doorPaint);

    // 3. Crisp roof edge highlight
    final strokePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.9)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(
      Offset(w * 0.50, h * 0.15),
      Offset(w * 0.90, h * 0.46),
      strokePaint,
    );
    canvas.drawLine(
      Offset(w * 0.50, h * 0.15),
      Offset(w * 0.10, h * 0.46),
      strokePaint,
    );
  }

  @override
  bool shouldRepaint(covariant _GoldenHomeVectorPainter oldDelegate) {
    return oldDelegate.goldColor != goldColor || oldDelegate.lightGold != lightGold;
  }
}
