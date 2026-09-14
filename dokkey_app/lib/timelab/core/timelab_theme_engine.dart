import 'dart:math';
import 'package:flutter/material.dart';
import '../models/timelab_models.dart';
import 'timelab_i18n.dart';

/// 🎨 시네마틱 타임 랩 테마 프리셋 엔진
class TimelabThemeConfig {
  final TimelabTheme theme;
  final String displayName;
  final String subtitle;
  final Color primaryColor;
  final Color secondaryColor;
  final Color warningColor;
  final Color backgroundColor;
  final Color cardColor;
  final Color borderColor;
  final String fontTag;

  const TimelabThemeConfig({
    required this.theme,
    required this.displayName,
    required this.subtitle,
    required this.primaryColor,
    required this.secondaryColor,
    required this.warningColor,
    required this.backgroundColor,
    required this.cardColor,
    required this.borderColor,
    required this.fontTag,
  });

  static TimelabThemeConfig of(TimelabTheme theme) {
    switch (theme) {
      case TimelabTheme.classicDigital:
        return const TimelabThemeConfig(
          theme: TimelabTheme.classicDigital,
          displayName: '클래식 디지털',
          subtitle: 'Classic 7-Segment LCD',
          primaryColor: Color(0xFF00FF66),     // 네온 그린 LCD
          secondaryColor: Color(0xFF00B347),   // 딥 그린
          warningColor: Color(0xFFFFB300),     // 앰버 오렌지
          backgroundColor: Color(0xFF0A0C0E),  // 매트 블랙 카본
          cardColor: Color(0xFF13171D),        // 다크 카본 카드
          borderColor: Color(0xFF1F2937),
          fontTag: 'Segment',
        );
      case TimelabTheme.cyberDefuser:
        return const TimelabThemeConfig(
          theme: TimelabTheme.cyberDefuser,
          displayName: '사이버 디퓨저',
          subtitle: 'Cyber Defuser HUD',
          primaryColor: Color(0xFFFF0055),     // 볼드 네온 레드
          secondaryColor: Color(0xFFFF5500),   // 네온 오렌지
          warningColor: Color(0xFFFF0033),     // 크리티컬 펄스 레드
          backgroundColor: Color(0xFF0C0710),  // 다크 HUD 글래스
          cardColor: Color(0xFF190F24),
          borderColor: Color(0xFFFF0055),
          fontTag: 'Cyber',
        );
      case TimelabTheme.orbitalLaunch:
        return const TimelabThemeConfig(
          theme: TimelabTheme.orbitalLaunch,
          displayName: '우주 발사',
          subtitle: 'Orbital Aerospace',
          primaryColor: Color(0xFF00E5FF),     // 에어로스페이스 사이언
          secondaryColor: Color(0xFF0091EA),   // 딥 궤도 블루
          warningColor: Color(0xFFFFEA00),     // 점화 옐로 플래시
          backgroundColor: Color(0xFF040B17),  // 딥 스페이스 네이비
          cardColor: Color(0xFF0C192E),
          borderColor: Color(0xFF00E5FF),
          fontTag: 'Aerospace',
        );
    }
  }

  /// 🌐 6개국어 테마 표시 이름 (displayName은 레거시/폴백용)
  String localizedName(String lang) {
    switch (theme) {
      case TimelabTheme.classicDigital:
        return TimelabI18n.themeClassic(lang);
      case TimelabTheme.cyberDefuser:
        return TimelabI18n.themeCyber(lang);
      case TimelabTheme.orbitalLaunch:
        return TimelabI18n.themeOrbital(lang);
    }
  }

  /// 잔여 시간에 따른 실시간 디스플레이 컬러 계산 (20% 이하/10초 전 특수 변화)
  Color getDynamicDisplayColor({required double progress, required Duration remaining}) {
    if (theme == TimelabTheme.classicDigital) {
      // 20% 이하 구간에서 은은한 앰버 톤으로 변화
      if (progress <= 0.20) {
        return warningColor;
      }
      return primaryColor;
    } else if (theme == TimelabTheme.cyberDefuser) {
      // 20% 이하 구간에서 강렬한 크리티컬 레드
      if (progress <= 0.20) {
        return warningColor;
      }
      return primaryColor;
    } else {
      // 우주 발사: 10초 이하 진입 시 강렬한 옐로 플래시
      if (remaining.inSeconds <= 10 && remaining > Duration.zero) {
        return warningColor;
      }
      return primaryColor;
    }
  }
}

/// 🌌 테마별 시네마틱 백그라운드 캔버스 페인터
class TimelabBackgroundPainter extends CustomPainter {
  final TimelabTheme theme;
  final double animationValue; // 0.0 ~ 1.0 (회전 / 펄스 루프)
  final bool isCritical; // 20% 이하 등 위기/점화 상태

  TimelabBackgroundPainter({
    required this.theme,
    required this.animationValue,
    this.isCritical = false,
  });

  @override
  void paint(Canvas canvas, Size size) {
    switch (theme) {
      case TimelabTheme.classicDigital:
        _paintClassicCarbon(canvas, size);
        break;
      case TimelabTheme.cyberDefuser:
        _paintCyberHUD(canvas, size);
        break;
      case TimelabTheme.orbitalLaunch:
        _paintOrbitalGrid(canvas, size);
        break;
    }
  }

  /// 1. 클래식 매트 블랙 카본 격자
  void _paintClassicCarbon(Canvas canvas, Size size) {
    final bgPaint = Paint()..color = const Color(0xFF080A0C);
    canvas.drawRect(Offset.zero & size, bgPaint);

    final linePaint = Paint()
      ..color = const Color(0xFF151C24).withOpacity(0.4)
      ..strokeWidth = 1.0;

    const step = 20.0;
    for (double x = 0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), linePaint);
    }
    for (double y = 0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), linePaint);
    }
  }

  /// 2. 사이버 디퓨저 HUD 그리드 + CRT 스캔라인
  void _paintCyberHUD(Canvas canvas, Size size) {
    final bgPaint = Paint()..color = const Color(0xFF0A0512);
    canvas.drawRect(Offset.zero & size, bgPaint);

    // 네온 그리드 원형 펄스
    final center = Offset(size.width / 2, size.height * 0.4);
    final maxRadius = min(size.width, size.height) * 0.7;

    for (var i = 1; i <= 3; i++) {
      final r = (maxRadius * (i / 3) + animationValue * 30) % maxRadius;
      final circlePaint = Paint()
        ..color = (isCritical ? const Color(0xFFFF0055) : const Color(0xFF8A00FF))
            .withOpacity((1.0 - (r / maxRadius)).clamp(0.05, 0.25))
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2;
      canvas.drawCircle(center, r, circlePaint);
    }

    // CRT 수평 스캔라인 FX
    final scanPaint = Paint()
      ..color = Colors.black.withOpacity(0.25)
      ..strokeWidth = 1.0;
    for (double y = 0; y < size.height; y += 4.0) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), scanPaint);
    }

    // 위기 시 붉은 비네팅 글로우
    if (isCritical) {
      final vignette = Paint()
        ..shader = RadialGradient(
          center: Alignment.center,
          radius: 0.9,
          colors: [Colors.transparent, const Color(0xFFFF0033).withOpacity(0.22)],
        ).createShader(Offset.zero & size);
      canvas.drawRect(Offset.zero & size, vignette);
    }
  }

  /// 3. 우주 발사 궤도 격자 & 레이더 스캔라인
  void _paintOrbitalGrid(Canvas canvas, Size size) {
    final bgPaint = Paint()..color = const Color(0xFF030712);
    canvas.drawRect(Offset.zero & size, bgPaint);

    final center = Offset(size.width / 2, size.height * 0.42);
    final maxR = min(size.width, size.height) * 0.65;

    // 회전하는 궤도 타원
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(animationValue * 2 * pi);

    final orbitPaint = Paint()
      ..color = const Color(0xFF00E5FF).withOpacity(0.12)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    for (var i = 1; i <= 4; i++) {
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset.zero,
          width: maxR * (i / 4) * 2,
          height: maxR * (i / 4) * 1.3,
        ),
        orbitPaint,
      );
    }
    canvas.restore();

    // 십자 에어로스페이스 조준선
    final crossPaint = Paint()
      ..color = const Color(0xFF00E5FF).withOpacity(0.18)
      ..strokeWidth = 0.8;
    canvas.drawLine(Offset(0, center.dy), Offset(size.width, center.dy), crossPaint);
    canvas.drawLine(Offset(center.dx, 0), Offset(center.dx, size.height), crossPaint);
  }

  @override
  bool shouldRepaint(covariant TimelabBackgroundPainter oldDelegate) {
    return oldDelegate.animationValue != animationValue ||
        oldDelegate.theme != theme ||
        oldDelegate.isCritical != isCritical;
  }
}
