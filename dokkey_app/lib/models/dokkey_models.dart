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

  /// 자연어 검색: 입력 문장을 토큰화하여 라벨/키워드와 유사어 매칭
  bool matchesQuery(String rawQuery) {
    final q = rawQuery.trim().toLowerCase();
    if (q.isEmpty) return false;
    final haystack = <String>[
      label.toLowerCase(),
      ...keywords.map((k) => k.toLowerCase()),
      id.toLowerCase(),
    ];
    // 토큰 분리 매칭: "호랑이한테 쫓기는 꿈" -> 호랑이, 쫓기
    for (final token in _tokenize(q)) {
      if (token.length < 2) continue;
      if (haystack.any((h) => h.contains(token))) return true;
    }
    return false;
  }

  static List<String> _tokenize(String query) {
    final tokens = <String>{};
    // 1. 공백/조사 분리
    for (final raw in query.split(RegExp(r'[\s,\.]+'))) {
      var t = raw;
      for (final josa in ['한테', '에게', '에서', '으로', '로', '하는', '하는', '꾸는', '꾼', '싸는', '빠지는', '나는', '보는']) {
        if (t.endsWith(josa) && t.length > josa.length + 1) {
          t = t.substring(0, t.length - josa.length);
        }
      }
      if (t.length >= 2) tokens.add(t);
      // 2. 2글자 슬라이딩 부분 매칭 (유사어: 쫓기다 -> 쫓기)
      if (t.length >= 3) {
        for (var i = 0; i + 2 <= t.length; i++) {
          tokens.add(t.substring(i, i + 2));
        }
      }
    }
    return tokens.toList();
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