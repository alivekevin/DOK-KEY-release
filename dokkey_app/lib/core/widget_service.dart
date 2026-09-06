import 'dart:io';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:home_widget/home_widget.dart';

/// 📱 안드로이드 홈 화면 위젯 서비스 (v4.7.0 5순위 — 명언 중심)
///
/// 앱을 켜지 않고도 홈 화면에서 오늘의 명언을 확인할 수 있게
/// 위젯 데이터를 갱신한다. 갱신 시점: 앱 실행 시 + 운세 드로우 후.
/// 오프라인 100% 동작 (로컬 150종 명언 DB 기반).
class WidgetService {
  WidgetService._();

  static const String _androidProviderName = 'KkaebiQuoteWidgetProvider';
  static const String _appGroupId = 'group.com.dokkey.dokkey_app';

  /// 위젯 데이터 갱신 (오늘의 명언 + 저자 + 깨비 한마디 + 럭키 넘버)
  static Future<void> updateToday({
    required String quoteText,
    required String quoteAuthor,
    required String kkaebiComment,
    required String luckyNumber,
  }) async {
    // Web/테스트 환경에서는 플랫폼 채널이 없으므로 스킵
    if (kIsWeb || Platform.environment.containsKey('FLUTTER_TEST')) return;
    try {
      await HomeWidget.setAppGroupId(_appGroupId);
      await HomeWidget.saveWidgetData<String>('quote_text', quoteText);
      await HomeWidget.saveWidgetData<String>('quote_author', quoteAuthor);
      await HomeWidget.saveWidgetData<String>('kkaebi_comment', kkaebiComment);
      await HomeWidget.saveWidgetData<String>('lucky_number', luckyNumber);
      await HomeWidget.updateWidget(
        name: _androidProviderName,
        androidName: _androidProviderName,
        qualifiedAndroidName: 'com.dokkey.dokkey_app.$_androidProviderName',
      );
    } catch (_) {
      // 위젯 미지원 플랫폼(Web/데스크톱)에서는 무시
    }
  }
}
