import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:flutter/services.dart';
import '../models/dokkey_models.dart';
import 'context_key_engine.dart';
import 'korean_josa.dart';

class DokkeyEngine {
  static final DokkeyEngine _instance = DokkeyEngine._internal();
  factory DokkeyEngine() => _instance;
  DokkeyEngine._internal();

  bool _initialized = false;
  List<Map<String, dynamic>> _commonCards = [];
  List<Map<String, dynamic>> _commonTimeslots = [];
  List<Map<String, dynamic>> _shichenTable = [];
  final Map<String, Map<String, dynamic>> _locales = {};

  Future<void> initialize() async {
    if (_initialized) return;

    // Load common
    final cardsJsonStr = await rootBundle.loadString('assets/data/common/cards.json');
    _commonCards = List<Map<String, dynamic>>.from(json.decode(cardsJsonStr));

    final slotJsonStr = await rootBundle.loadString('assets/data/common/timeslots.json');
    _commonTimeslots = List<Map<String, dynamic>>.from(json.decode(slotJsonStr));

    final shichenStr = await rootBundle.loadString('assets/data/common/shichen.json');
    _shichenTable = List<Map<String, dynamic>>.from(json.decode(shichenStr));

    // Load locales (ko, en, ja, zh, hi, de)
    for (final lang in ['ko', 'en', 'ja', 'zh', 'hi', 'de']) {
      final tonesStr = await rootBundle.loadString('assets/data/locales/$lang/tones.json');
      final cardsLocStr = await rootBundle.loadString('assets/data/locales/$lang/cards.json');
      final slotLocStr = await rootBundle.loadString('assets/data/locales/$lang/timeslots.json');
      final riddlesStr = await rootBundle.loadString('assets/data/locales/$lang/riddles.json');
      final quotesStr = await rootBundle.loadString('assets/data/locales/$lang/quotes.json');
      final chatStr = await rootBundle.loadString('assets/data/locales/$lang/kkaebi_chat.json');
      final greetStr = await rootBundle.loadString('assets/data/locales/$lang/context_greetings.json');
      final dreamStr = await rootBundle.loadString('assets/data/locales/$lang/dream_symbols.json');
      final affectionStr = await rootBundle.loadString('assets/data/locales/$lang/kkaebi_affection.json');

      _locales[lang] = {
        'tones': json.decode(tonesStr),
        'cards': json.decode(cardsLocStr),
        'timeslots': json.decode(slotLocStr),
        'riddles': json.decode(riddlesStr),
        'quotes': json.decode(quotesStr),
        'chat': json.decode(chatStr),
        'greetings': json.decode(greetStr),
        'dreams': json.decode(dreamStr),
        'affection': json.decode(affectionStr),
      };
    }

    _initialized = true;
  }

  int generateDrawSeed({
    required String userUuid,
    required String localDate,
    String birthHash = 'anon',
    String regionCode = 'GLOBAL',
    int drawIndex = 0,
  }) {
    final seedString = '$userUuid:$localDate:$birthHash:$regionCode:$drawIndex:DOK_KEY_V1';
    final digest = sha256.convert(utf8.encode(seedString));
    final hexPart = digest.toString().substring(0, 15);
    return int.parse(hexPart, radix: 16);
  }

  /// 4시간대 감지 → 현재 슬롯 (무작위 추출이 아닌 맥락 감지)
  TimeSlotId detectCurrentSlot() => ContextKeyEngine.detectTimeSlot();

  DrawResult draw({
    required String userId,
    required String dateStr,
    String lang = 'ko',
    TimeSlotId? timeslotOverride,
    TimeSlotId? contextSlot,
    DrawContextSeed? contextSeed,
    int drawIndex = 0,
    int? overrideSeed,
    String? overrideCardId,
  }) {
    final locale = _locales[lang] ?? _locales['ko']!;
    final seed = overrideSeed ?? generateDrawSeed(userUuid: userId, localDate: dateStr, drawIndex: drawIndex);
    final rng = Random(seed);

    // 1. Number (1 ~ 45)
    final number = rng.nextInt(45) + 1;

    // 2. Card (1 of 36) — 인스펙터 강제 선택(overrideCardId) 지원
    var cardCommon = _commonCards[rng.nextInt(_commonCards.length)];
    if (overrideCardId != null) {
      final forced = _commonCards.where((c) => c['id'] == overrideCardId).toList();
      if (forced.isNotEmpty) {
        cardCommon = forced.first;
      }
    }
    final cardId = cardCommon['id'] as String;
    final cardLoc = (locale['cards'] as Map<String, dynamic>)[cardId] ?? {};
    final card = CardModel(
      id: cardId,
      deck: cardCommon['deck'] ?? '',
      type: cardCommon['type'] ?? '',
      artAsset: cardCommon['art_asset'] ?? '',
      name: cardLoc['name'] ?? cardId,
      symbol: cardLoc['symbol'] ?? '',
      description: cardLoc['description'] ?? '',
    );

    // 3. Timeslot — 시드에서 뽑지 않고 감지된 맥락으로 확정 (동일 날짜+동일 슬롯 = 동일 골격)
    final slotId = (timeslotOverride ?? contextSlot ?? detectCurrentSlot());
    final slotIdStr = ContextKeyEngine.slotIdToString(slotId);
    final slotCommon = _commonTimeslots.firstWhere(
      (s) => s['id'] == slotIdStr,
      orElse: () => _commonTimeslots.first,
    );
    final slotLoc = ((locale['timeslots'] as Map<String, dynamic>?) ?? {})[slotIdStr] as Map<String, dynamic>? ?? {};
    final timeslot = TimeslotModel(
      id: slotIdStr,
      code: slotCommon['code'] ?? 'M',
      name: slotLoc['name'] ?? slotIdStr,
      emoji: slotLoc['emoji'] ?? '',
      meaningAxis: slotLoc['meaning_axis'] ?? '',
      description: slotLoc['description'] ?? '',
    );

    // 4. Tone (1 of 12)
    final tonesMap = locale['tones'] as Map<String, dynamic>;
    final toneKeys = tonesMap.keys.toList();
    final toneId = toneKeys[rng.nextInt(toneKeys.length)];
    final toneInfo = tonesMap[toneId] as Map<String, dynamic>;
    final tone = ToneModel(
      id: toneId,
      name: toneInfo['name'] ?? toneId,
      color: toneInfo['color'] ?? '#F0A500',
      voiceGuide: toneInfo['voice_guide'] ?? '',
    );

    // 5. Template Resolution
    final templates = List<Map<String, dynamic>>.from(toneInfo['templates'] ?? []);
    final template = templates[rng.nextInt(templates.length)];

    final vars = {
      'card_name': card.name,
      'timeslot_name': timeslot.name,
      'number': number,
    };

    String headline, body, tip, shareCaption;
    if (lang == 'ko') {
      headline = KoreanJosa.format(template['headline'] ?? '', vars);
      body = KoreanJosa.format(template['body'] ?? '', vars);
      tip = KoreanJosa.format(template['tip'] ?? '', vars);
      shareCaption = KoreanJosa.format(template['share_caption'] ?? '', vars);
    } else {
      headline = _formatTemplate(template['headline'] ?? '', vars);
      body = _formatTemplate(template['body'] ?? '', vars);
      tip = _formatTemplate(template['tip'] ?? '', vars);
      shareCaption = _formatTemplate(template['share_caption'] ?? '', vars);
    }

    return DrawResult(
      date: dateStr,
      lang: lang,
      number: number,
      card: card,
      timeslot: timeslot,
      tone: tone,
      headline: headline,
      body: body,
      tip: tip,
      shareCaption: shareCaption,
      seedHash: seed.toRadixString(16),
      context: contextSeed != null
          ? DrawContext(
              timeslotId: slotIdStr,
              themeMode: contextSeed.themeMode,
              visitState: contextSeed.visitStateString,
              online: contextSeed.online,
              profileRef: contextSeed.profileRef,
            )
          : null,
    );
  }

  String _formatTemplate(String template, Map<String, dynamic> vars) {
    var res = template;
    for (final entry in vars.entries) {
      res = res.replaceAll('{${entry.key}}', entry.value.toString());
    }
    return res;
  }

  QuoteModel getQuote(String lang, [int? index]) {
    final quotesJson = (_locales[lang] ?? _locales['ko']!)['quotes'] as List;
    final list = quotesJson.map((q) => QuoteModel.fromJson(q)).toList();
    if (index != null && index >= 0 && index < list.length) {
      return list[index];
    }
    return list[Random().nextInt(list.length)];
  }

  /// v4.7.0: v2 스키마가 적용된 전체 명언 풀 (150종)
  List<QuoteModel> getAllQuotes(String lang) {
    final quotesJson = (_locales[lang] ?? _locales['ko']!)['quotes'] as List;
    return quotesJson.map((q) => QuoteModel.fromJson(q)).toList();
  }

  List<CardModel> getAllCards(String lang) {
    final locale = _locales[lang] ?? _locales['ko']!;
    final cardsLoc = locale['cards'] as Map<String, dynamic>;

    return _commonCards.map((c) {
      final id = c['id'] as String;
      final loc = cardsLoc[id] ?? {};
      return CardModel(
        id: id,
        deck: c['deck'] ?? '',
        type: c['type'] ?? '',
        artAsset: c['artAsset'] ?? '',
        name: loc['name'] ?? id,
        symbol: loc['symbol'] ?? '',
        description: loc['description'] ?? '',
      );
    }).toList();
  }

  List<Map<String, dynamic>> getKkaebiTopics(String lang) {
    final locale = _locales[lang] ?? _locales['ko']!;
    final chatData = locale['chat'] as Map<String, dynamic>? ?? {};
    final topics = List<Map<String, dynamic>>.from(chatData['topics'] ?? []);
    return topics;
  }

  /// 주간 셔플 엔진: ISO 주 기반 시드로 매주 다른 오프너를 1단계 답변 앞에 부착
  String getWeeklyOpener(String lang, String topicId, {DateTime? now}) {
    final locale = _locales[lang] ?? _locales['ko']!;
    final chatData = locale['chat'] as Map<String, dynamic>? ?? {};
    final openers = chatData['weekly_openers'] as Map<String, dynamic>?;
    if (openers == null) return '';
    final list = List<String>.from(openers[topicId] ?? const []);
    if (list.isEmpty) return '';
    final date = now ?? DateTime.now();
    // ISO week number approximation (deterministic per week)
    final dayOfYear = date.difference(DateTime(date.year, 1, 1)).inDays;
    final weekIndex = ((dayOfYear + DateTime(date.year, 1, 1).weekday - 1) ~/ 7);
    return list[weekIndex % list.length];
  }

  /// Zero-Delay 맥락 인사: 방문 상태 × 시간대 × 닉네임 분기 (결정론적 일일 선택)
  String getContextGreeting({
    required String lang,
    required VisitState visitState,
    required TimeSlotId slotId,
    String nickname = '',
    DateTime? now,
  }) {
    final locale = _locales[lang] ?? _locales['ko']!;
    final greetings = locale['greetings'] as Map<String, dynamic>? ?? {};
    String stateKey;
    switch (visitState) {
      case VisitState.firstVisit:
        stateKey = 'first_visit';
        break;
      case VisitState.longAbsence:
        stateKey = 'long_absence';
        break;
      case VisitState.revisit:
        stateKey = 'revisit';
        break;
    }
    final stateMap = greetings[stateKey] as Map<String, dynamic>? ?? {};
    final slotKey = ContextKeyEngine.slotIdToString(slotId);
    final list = List<String>.from(stateMap[slotKey] ?? const []);
    if (list.isEmpty) return '';

    // 같은 상태 내 반복 방지: 날짜 시드로 결정론적 선택
    final date = now ?? DateTime.now();
    final digest = sha256.convert(utf8.encode('greet:$stateKey:$slotKey:${date.year}-${date.month}-${date.day}'));
    final idx = int.parse(digest.toString().substring(0, 8), radix: 16) % list.length;
    var text = list[idx];
    if (nickname.trim().isNotEmpty) {
      final nick = nickname.trim();
      text = text.replaceAll('{닉네임}', nick).replaceAll('{nick}', nick);
      text = text.replaceAll('  ', ' ');
    } else {
      text = text
          .replaceAll('{닉네임}아, ', '')
          .replaceAll('{닉네임}아,', '')
          .replaceAll('{닉네임}아', '')
          .replaceAll('{닉네임}이 ', '')
          .replaceAll('{닉네임}이', '')
          .replaceAll('{닉네임}!', '')
          .replaceAll(', {닉네임}', '')
          .replaceAll(', {nick}', '')
          .replaceAll('{닉네임}, ', '')
          .replaceAll('{nick}, ', '')
          .replaceAll('{닉네임}', '')
          .replaceAll('{nick}', '')
          .replaceAll(' ,', ',')
          .replaceAll('  ', ' ')
          .trim();
    }
    return text;
  }

  String getKkaebiProgressiveAnswer(
    String lang,
    String topicId,
    int stepCount,
    DrawResult? todayResult, {
    String nickname = '',
  }) {
    final locale = _locales[lang] ?? _locales['ko']!;
    final chatData = locale['chat'] as Map<String, dynamic>? ?? {};
    final topics = List<Map<String, dynamic>>.from(chatData['topics'] ?? []);
    final topic = topics.firstWhere((t) => t['id'] == topicId, orElse: () => topics.first);

    final steps = List<String>.from(topic['steps'] ?? []);
    final endings = List<String>.from(chatData['exhausted_endings'] ?? []);

    String rawText;
    if (stepCount >= 6 || stepCount > steps.length) {
      rawText = endings.isNotEmpty
          ? endings[Random().nextInt(endings.length)]
          : '오늘 천기누설을 너무 많이 했다! 이제 다른 거나 물어보거라! 💨';
    } else {
      final idx = max(0, stepCount - 1);
      rawText = steps[idx];
      // 주간 셔플: 1단계 답변에 이번 주 전용 오프너를 부착
      if (stepCount == 1) {
        final opener = getWeeklyOpener(lang, topicId);
        if (opener.isNotEmpty) rawText = '$opener $rawText';
      }
    }

    final vars = {
      'card_name': todayResult?.card.name ?? (lang == 'ko' ? '도깨비 열쇠' : (lang == 'ja' ? 'トッケビの鍵' : (lang == 'zh' ? '鬼怪之匙' : (lang == 'hi' ? 'यक्ष कुंजी' : 'Dokkaebi Key')))),
      'tone_name': todayResult?.tone.name ?? (lang == 'ko' ? '희망' : (lang == 'ja' ? '希望' : (lang == 'zh' ? '曙光希望' : (lang == 'hi' ? 'आशा की किरण' : 'Hope')))),
      'number': todayResult?.number ?? 7,
      'nickname': nickname,
    };

    return _formatTemplate(rawText, vars);
  }

  String getKkaebiAnswer(String lang, String topicId, DrawResult? todayResult, {String nickname = ''}) {
    return getKkaebiProgressiveAnswer(lang, topicId, 1, todayResult, nickname: nickname);
  }

  RiddleModel getRiddle(String lang, [int? index]) {
    final riddlesJson = (_locales[lang] ?? _locales['ko']!)['riddles'] as List;
    final list = riddlesJson.map((r) => RiddleModel.fromJson(r)).toList();
    if (index != null && index >= 0 && index < list.length) {
      return list[index];
    }
    return list[Random().nextInt(list.length)];
  }

  // --- Dream Interpretation (꿈풀이) ---

  List<DreamSymbol> getDreamSymbols(String lang) {
    final locale = _locales[lang] ?? _locales['ko']!;
    final data = locale['dreams'] as Map<String, dynamic>? ?? {};
    final list = List<Map<String, dynamic>>.from(data['symbols'] ?? []);
    return list.map(DreamSymbol.fromJson).toList();
  }

  /// 날짜 기반 결정론적 오늘의 꿈 심볼
  DreamSymbol getDailyDreamSymbol(String lang, String dateStr) {
    final list = getDreamSymbols(lang);
    if (list.isEmpty) {
      return DreamSymbol(id: '', label: '', cardId: '', meaning: '', advice: '');
    }
    final digest = sha256.convert(utf8.encode('dream:$dateStr:DOK_KEY_V1'));
    final idx = int.parse(digest.toString().substring(0, 8), radix: 16) % list.length;
    return list[idx];
  }

  // --- Shichen bridge (시辰 브릿지) ---

  /// 현재 시각의 지신 ID 및 12지 카드와의 공명 여부 반환
  Map<String, dynamic> getShichenForNow([DateTime? now]) {
    final time = now ?? DateTime.now();
    final h = time.hour;
    for (final s in _shichenTable) {
      final start = s['start'] as int;
      final end = s['end'] as int;
      final inRange = start < end ? (h >= start && h < end) : (h >= start || h < end);
      if (inRange) {
        return {'id': s['id'], 'hanja': s['hanja'], 'zodiac': s['zodiac']};
      }
    }
    return {'id': '', 'hanja': '', 'zodiac': ''};
  }

  bool isZodiacCard(String cardId) =>
      _commonCards.any((c) => c['id'] == cardId && c['deck'] == '12jishin');

  // --- Kkaebi Affection / Intimacy System (깨비 친밀도 시스템) ---

  Map<String, dynamic> getAffectionLevelData(String lang, int level) {
    final clampedLevel = level.clamp(1, 5);
    final locale = _locales[lang] ?? _locales['ko']!;
    final affectionData = locale['affection'] as Map<String, dynamic>? ?? {};
    final levelsMap = affectionData['levels'] as Map<String, dynamic>? ?? {};
    return levelsMap['$clampedLevel'] as Map<String, dynamic>? ?? {};
  }

  String getAffectionTitle(String lang, int level) {
    final data = getAffectionLevelData(lang, level);
    return data['title'] as String? ?? (level == 1 ? '낯선 손님' : '깨비 동무');
  }

  String getAffectionSubtitle(String lang, int level) {
    final data = getAffectionLevelData(lang, level);
    return data['subtitle'] as String? ?? '';
  }

  String getAffectionQuote(String lang, int level) {
    final data = getAffectionLevelData(lang, level);
    return data['quote'] as String? ?? '';
  }

  List<String> getAffectionPerks(String lang, int level) {
    final data = getAffectionLevelData(lang, level);
    final perksList = data['perks'] as List<dynamic>? ?? [];
    return perksList.map((e) => e.toString()).toList();
  }

  String getRandomTouchReaction(String lang) {
    final locale = _locales[lang] ?? _locales['ko']!;
    final affectionData = locale['affection'] as Map<String, dynamic>? ?? {};
    final reactions = affectionData['touch_reactions'] as List<dynamic>? ?? [];
    if (reactions.isEmpty) {
      return lang == 'ko' ? '헤헤, 깨비랑 놀아줘서 고마워! ✨' : 'Hehe, thanks for playing with me! ✨';
    }
    return reactions[Random().nextInt(reactions.length)].toString();
  }
}
