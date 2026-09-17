import 'package:flutter/foundation.dart';

/// 📱 DOK-KEY 앱 버전 정보 단일 소스 (Single Source of Truth)
///
/// Flutter 빌드 도구(flutter build / flutter run)가 pubspec.yaml의 version(5.2.0+523)을
/// FLUTTER_BUILD_NAME과 FLUTTER_BUILD_NUMBER로 자동 주입하며,
/// 웹/앱 모든 플랫폼에서 외부 플러그인 의존성 충돌 없이 즉시 일관되게 동작합니다.
class AppVersion {
  AppVersion._();

  static const String _defaultVersion = '5.2.0';
  static const String _defaultBuild = '523';

  static const String version = String.fromEnvironment(
    'FLUTTER_BUILD_NAME',
    defaultValue: _defaultVersion,
  );

  static const String buildNumber = String.fromEnvironment(
    'FLUTTER_BUILD_NUMBER',
    defaultValue: _defaultBuild,
  );

  /// 앱 시작 시 초기화 훅 (하위 호환성 유지)
  static Future<void> ensureInitialized() async {
    // String.fromEnvironment로 컴파일 타임에 즉시 상수로 결정됨
  }

  /// 디스플레이용 버전 문자열 (예: 'v5.2.0')
  static String get displayVersion => 'v' + version;

  /// 상세 버전 문자열 (예: 'v5.2.0 (Build 523)')
  static String get fullVersion => 'v' + version + ' (Build ' + buildNumber + ')';

  /// 스튜디오 태그 (예: 'v5.2.0 · Dokkey Studio')
  static String get studioTag => 'v' + version + ' · Dokkey Studio';

  /// 제로 로그인 아키텍처 태그 (예: 'DOK-KEY v5.2.0 • Zero-Login Architecture')
  static String get zeroLoginTag => 'DOK-KEY v' + version + ' • Zero-Login Architecture';
}
