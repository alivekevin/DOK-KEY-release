import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';

/// 🏷️ DOK-KEY 브랜드 정체성 중앙 설정 (v4.7.0 Wisdom-First Rebrand)
///
/// 슬로건/OG/목적 문구의 단일 소스(Single Source of Truth).
/// 앱·웹·위젯·포스터 전부 이 설정을 참조하므로 슬로건 변경 시 JSON 한 곳만 수정하면 된다.
class BrandConfig {
  BrandConfig._();

  /// Wisdom-First IA 활성화 플래그 — 롤백 시 false 한 줄로 기존 운세 중심 홈 복귀.
  static bool wisdomFirstEnabled = true;

  static Map<String, dynamic>? _data;
  static bool _loaded = false;

  static const String fallbackLang = 'ko';

  /// 앱 시작 시 1회 로드 (DokkeyProvider.initialize → engine.initialize 이후)
  static Future<void> ensureLoaded() async {
    if (_loaded) return;
    try {
      final raw = await rootBundle.loadString('assets/data/common/brand_slogans.json');
      _data = json.decode(raw) as Map<String, dynamic>;
    } catch (e) {
      debugPrint('BrandConfig load failed: $e');
      _data = null;
    }
    _loaded = true;
  }

  static String _section(String section, String lang) {
    final node = _data?[section] as Map<String, dynamic>?;
    if (node == null) return '';
    return (node[lang] ?? node[fallbackLang] ?? '') as String;
  }

  /// 메인 슬로건 ("어둠을 밝히는 도깨비불처럼, ...")
  static String mainSlogan(String lang) => _section('main_slogan', lang);

  /// 서브 슬로건 ("3D 깨비가 건네는 오늘의 명언 · ...")
  static String subSlogan(String lang) => _section('sub_slogan', lang);

  /// 앱 목적 문구
  static String appPurpose(String lang) => _section('app_purpose', lang);

  /// 웹 OG 타이틀
  static String ogTitle(String lang) => _section('og_title', lang);

  /// 웹 OG 설명
  static String ogDescription(String lang) => _section('og_description', lang);

  /// 웹 히어로 문구 ("하루 한 줄, 나를 바꾸는 도깨비 명언")
  static String webHero(String lang) => _section('web_hero', lang);

  /// 부적 카드 도장 텍스트 (언어별 로컬라이징 — 타언어 한자 혼입 방지)
  static String posterStamp(String lang) => _section('poster_stamp', lang);

  /// 부적 카드 푸터 태그라인
  static String posterFooter(String lang) => _section('poster_footer', lang);
}
