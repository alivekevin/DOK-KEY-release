/// Data Models for DOK-KEY

class CardModel {
  final String id;
  final String deck;
  final String type;
  final String artAsset;
  final String name;
  final String symbol;
  final String description;

  CardModel({
    required this.id,
    required this.deck,
    required this.type,
    required this.artAsset,
    required this.name,
    required this.symbol,
    required this.description,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'deck': deck,
    'type': type,
    'artAsset': artAsset,
    'name': name,
    'symbol': symbol,
    'description': description,
  };

  factory CardModel.fromJson(Map<String, dynamic> json) => CardModel(
    id: json['id'] ?? '',
    deck: json['deck'] ?? '',
    type: json['type'] ?? '',
    artAsset: json['artAsset'] ?? '',
    name: json['name'] ?? '',
    symbol: json['symbol'] ?? '',
    description: json['description'] ?? '',
  );
}

class TimeslotModel {
  final String id;
  final String code;
  final String name;
  final String emoji;
  final String meaningAxis;
  final String description;

  TimeslotModel({
    required this.id,
    required this.code,
    required this.name,
    this.emoji = '',
    required this.meaningAxis,
    required this.description,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'code': code,
    'name': name,
    'emoji': emoji,
    'meaningAxis': meaningAxis,
    'description': description,
  };

  factory TimeslotModel.fromJson(Map<String, dynamic> json) => TimeslotModel(
    id: json['id'] ?? 'morning',
    code: json['code'] ?? 'M',
    name: json['name'] ?? 'Morning',
    emoji: json['emoji'] ?? '',
    meaningAxis: json['meaningAxis'] ?? '',
    description: json['description'] ?? '',
  );
}

class ToneModel {
  final String id;
  final String name;
  final String color;
  final String voiceGuide;

  ToneModel({
    required this.id,
    required this.name,
    required this.color,
    required this.voiceGuide,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'color': color,
    'voiceGuide': voiceGuide,
  };

  factory ToneModel.fromJson(Map<String, dynamic> json) => ToneModel(
    id: json['id'] ?? '',
    name: json['name'] ?? '',
    color: json['color'] ?? '#F0A500',
    voiceGuide: json['voiceGuide'] ?? '',
  );
}

/// Zero-Delay context snapshot recorded with each draw (v3.0.0)
class DrawContext {
  final String timeslotId;
  final String themeMode; // dark | light
  final String visitState; // first_visit | revisit | long_absence
  final bool online;
  final String profileRef; // nickname or 'anon'

  DrawContext({
    required this.timeslotId,
    this.themeMode = 'dark',
    this.visitState = 'revisit',
    this.online = true,
    this.profileRef = 'anon',
  });

  Map<String, dynamic> toJson() => {
    'timeslotId': timeslotId,
    'themeMode': themeMode,
    'visitState': visitState,
    'online': online,
    'profileRef': profileRef,
  };

  factory DrawContext.fromJson(Map<String, dynamic> json) => DrawContext(
    timeslotId: json['timeslotId'] ?? 'morning',
    themeMode: json['themeMode'] ?? 'dark',
    visitState: json['visitState'] ?? 'revisit',
    online: json['online'] ?? true,
    profileRef: json['profileRef'] ?? 'anon',
  );
}

class DrawResult {
  final String date;
  final String lang;
  final int number;
  final CardModel card;
  final TimeslotModel timeslot;
  final ToneModel tone;
  final String headline;
  final String body;
  final String tip;
  final String shareCaption;
  final String seedHash;
  final DrawContext context;

  DrawResult({
    required this.date,
    required this.lang,
    required this.number,
    required this.card,
    required this.timeslot,
    required this.tone,
    required this.headline,
    required this.body,
    required this.tip,
    required this.shareCaption,
    required this.seedHash,
    DrawContext? context,
  }) : context = context ?? DrawContext(timeslotId: timeslot.id);

  String get dateStr => date;

  Map<String, dynamic> toJson() => {
    'date': date,
    'lang': lang,
    'number': number,
    'card': card.toJson(),
    'timeslot': timeslot.toJson(),
    'tone': tone.toJson(),
    'headline': headline,
    'body': body,
    'tip': tip,
    'shareCaption': shareCaption,
    'seedHash': seedHash,
    'context': context.toJson(),
  };

  factory DrawResult.fromJson(Map<String, dynamic> json) => DrawResult(
    date: json['date'] ?? '',
    lang: json['lang'] ?? 'ko',
    number: json['number'] ?? 7,
    card: CardModel.fromJson(json['card'] ?? {}),
    timeslot: TimeslotModel.fromJson(json['timeslot'] ?? {}),
    tone: ToneModel.fromJson(json['tone'] ?? {}),
    headline: json['headline'] ?? '',
    body: json['body'] ?? '',
    tip: json['tip'] ?? '',
    shareCaption: json['shareCaption'] ?? '',
    seedHash: json['seedHash'] ?? '',
    context: json['context'] != null ? DrawContext.fromJson(json['context']) : null,
  );
}

class RiddleModel {
  final String id;
  final int difficulty;
  final String category;
  final String question;
  final List<String> options;
  final int answerIndex;
  final int rewardKeys;
  final String correctReaction;
  final String wrongReaction;

  RiddleModel({
    required this.id,
    required this.difficulty,
    required this.category,
    required this.question,
    required this.options,
    required this.answerIndex,
    required this.rewardKeys,
    required this.correctReaction,
    required this.wrongReaction,
  });

  factory RiddleModel.fromJson(Map<String, dynamic> json) => RiddleModel(
    id: json['id'] ?? '',
    difficulty: json['difficulty'] ?? 1,
    category: json['category'] ?? '',
    question: json['question'] ?? '',
    options: List<String>.from(json['options'] ?? []),
    answerIndex: json['answer_index'] ?? 0,
    rewardKeys: json['reward_keys'] ?? 1,
    correctReaction: json['kkaebi_reaction']?['correct'] ?? '',
    wrongReaction: json['kkaebi_reaction']?['wrong'] ?? '',
  );
}

class QuoteModel {
  final String id;
  final String text;
  final String category;
  final List<String> toneTags;

  // --- v4.7.0 Wisdom-First 확장 필드 ---
  final String author;      // 저자/출처 표기 (없으면 격언 라벨)
  final String source;      // 출처 (책/전집명)
  final String theme;       // growth | zen | comfort | challenge | gratitude | fortune
  final String emotion;     // 8대 감정 바인딩 (ScreenEmotionFxOverlay)
  final List<String> timeSlots; // 적합 시간대 (morning/noon/evening/night)
  final String kkaebiComment; // 깨비의 한마디 (명언에 대한 도깨비 해설)

  QuoteModel({
    required this.id,
    required this.text,
    required this.category,
    required this.toneTags,
    this.author = '',
    this.source = '',
    this.theme = 'zen',
    this.emotion = 'normal',
    this.timeSlots = const [],
    this.kkaebiComment = '',
  });

  bool get hasKkaebiComment => kkaebiComment.trim().isNotEmpty;

  String get authorLabel {
    if (author.trim().isNotEmpty) return author;
    if (source.trim().isNotEmpty) return source;
    return category == 'proverb' ? '옛말' : '격언';
  }

  factory QuoteModel.fromJson(Map<String, dynamic> json) => QuoteModel(
    id: json['id'] ?? '',
    text: json['text'] ?? '',
    category: json['category'] ?? '',
    toneTags: List<String>.from(json['tone_tags'] ?? []),
    author: json['author'] ?? '',
    source: json['source'] ?? '',
    theme: json['theme'] ?? 'zen',
    emotion: json['emotion'] ?? 'normal',
    timeSlots: List<String>.from(json['time_slot'] ?? []),
    kkaebiComment: json['kkaebi_comment'] ?? '',
  );
}

class DreamSymbol {
  final String id;
  final String label;
  final String cardId;
  final String meaning;
  final String advice;
  final String fortune; // auspicious(길몽) | ominous(흉몽) | normal(평몽)
  final int luckyNumber;
  final List<String> keywords;

  DreamSymbol({
    required this.id,
    required this.label,
    required this.cardId,
    required this.meaning,
    required this.advice,
    this.fortune = 'normal',
    this.luckyNumber = 7,
    this.keywords = const [],
  });

  bool get isAuspicious => fortune == 'auspicious';
  bool get isOminous => fortune == 'ominous';
  bool get isNormal => !isAuspicious && !isOminous;

  String get luckyNumberStr => luckyNumber.toString().padLeft(2, '0');

  static const Set<String> _stopWords = {
    '꿈', '꿈을', '꿈에', '꿈속', '꿈풀이', '꾸는', '꾸었어', '꿨어', '꾼', '보는', '나오는', '하는', '있는', '없는', '나는', '타는', '가는', '오는', '되다', '된다', '하다', '했다', '해서',
    'dream', 'dreams', 'dreaming', 'dreamt', 'in', 'of', 'appearing', 'seeing', 'having', 'about', 'the', 'a', 'an', 'to', 'and',
    '夢', 'の夢', '夢を見る', '夢に', '見る', '出た', '出る', '飛ぶ', '乗る',
    '梦', '做梦', '梦见', '梦到', '的梦', '飞天', '乘',
    'सपना', 'सपने', 'में', 'का', 'की', 'को',
    'traum', 'träume', 'im', 'von', 'haben', 'sehen', 'der', 'die', 'das', 'ein', 'eine', 'und', 'zu'
  };

  static bool _isCjkOrHangul(String text) {
    return RegExp(r'[\uac00-\ud7a3\u4e00-\u9fff\u3040-\u30ff]').hasMatch(text);
  }

  /// 자연어 검색: 입력 문장을 토큰화하여 라벨/키워드/ID와 정밀 유사어 매칭 (6개국어 완벽 지원)
  bool matchesQuery(String rawQuery) {
    final q = rawQuery.trim().toLowerCase();
    if (q.isEmpty) return false;
    final haystack = <String>[
      label.toLowerCase(),
      ...keywords.map((k) => k.toLowerCase()),
      id.toLowerCase(),
    ];

    // 1. 직접 전체 일치 또는 단순 포함 검사 (3자 이상)
    for (final h in haystack) {
      if (h == q) return true;
      if (q.length >= 3 && h.contains(q)) return true;
      if (h.length >= 3 && q.contains(h)) return true;
    }

    // 2. 토큰 분리 정밀 매칭 ("조상님이 나오는 꿈" -> 조상, 등)
    final tokens = _tokenize(q);
    for (final token in tokens) {
      if (token.isEmpty || _stopWords.contains(token)) continue;
      for (final h in haystack) {
        if (h == token) return true;
        if (_isCjkOrHangul(token)) {
          if (token.length == 1) {
            if (h == token) return true;
          } else {
            if (h.contains(token) || token.contains(h)) return true;
          }
        } else {
          // 알파벳 / 힌디어 등 단어 기반 언어: 단어 단위 접두사 및 완전 일치 (최소 3글자)
          final words = h.split(RegExp(r'[\s,\./\-_]+'));
          for (final w in words) {
            if (w == token) return true;
            if (token.length >= 3 && w.length >= 3 && (w.startsWith(token) || token.startsWith(w))) {
              return true;
            }
          }
        }
      }
    }
    return false;
  }

  static List<String> _tokenize(String query) {
    final tokens = <String>{};
    // 1. 공백 및 특수문자 분리
    for (final raw in query.split(RegExp(r'[\s,\.\?!~]+'))) {
      if (raw.isEmpty) continue;
      var t = raw.toLowerCase();
      if (!_stopWords.contains(t)) tokens.add(t);

      // 다단계 조사/어미 제거
      const josaList = [
        '한테서', '에게서', '한테', '에게', '에서', '으로', '부터', '까지', '이나', '하고',
        '이며', '처럼', '마저', '조차', '하는꿈', '꾼꿈', '보는꿈', '타는꿈', '먹는꿈',
        '하는', '꾸는', '싸는', '빠진', '빠지는', '흘리는', '자르는', '나오는', '입는',
        '타는', '걸리는', '있는', '없는', '되는', '잡는', '보는', '나는', '가는', '오는',
        '나서', '타서', '샀어', '샀어요', '봤어', '봤어요', '났어', '났어요', '했어', '했어요',
        '꾼', '님', '님이', '님을', '이', '가', '을', '를', '은', '는',
        '과', '와', '의', '도', '만', '에', '로', '꿈'
      ];

      for (var pass = 0; pass < 3; pass++) {
        for (final josa in josaList) {
          if (t.endsWith(josa) && t.length > josa.length) {
            t = t.substring(0, t.length - josa.length);
            if (t.isNotEmpty && !_stopWords.contains(t)) tokens.add(t);
          }
        }
      }

      if (t.isNotEmpty && !_stopWords.contains(t)) tokens.add(t);

      // 2. 2글자 슬라이딩 윈도우 매칭 (CJK / 한글 전용)
      if (_isCjkOrHangul(t) && t.length >= 3) {
        for (var i = 0; i + 2 <= t.length; i++) {
          final sub = t.substring(i, i + 2);
          if (!_stopWords.contains(sub)) tokens.add(sub);
        }
      }
    }
    return tokens.where((tok) => !_stopWords.contains(tok)).toList();
  }

  factory DreamSymbol.fromJson(Map<String, dynamic> json) => DreamSymbol(
    id: json['id'] ?? '',
    label: json['label'] ?? '',
    cardId: json['card_id'] ?? '',
    meaning: json['meaning'] ?? '',
    advice: json['advice'] ?? '',
    fortune: json['fortune'] ?? 'normal',
    luckyNumber: json['lucky_number'] ?? 7,
    keywords: List<String>.from(json['keywords'] ?? []),
  );
}