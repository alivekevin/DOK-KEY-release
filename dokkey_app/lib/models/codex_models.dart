import 'codex_canonical_data.dart';

/// Models for Codex 3-Tab Architecture in DOK-KEY
class CodexCardItem {
  final String id;
  final String category; // 'zodiac' | 'myth' | 'custom'
  final String tab;
  final int slot;
  final bool isRegular;
  final String fileName;
  final String imagePath;
  final String name;
  final String title;
  final String desc;
  final String nameEn;
  final String nameJa;
  final String nameZh;
  final String nameDe;
  final String nameHi;
  final String titleEn;
  final String titleJa;
  final String titleZh;
  final String titleDe;
  final String titleHi;
  final String descEn;
  final String descJa;
  final String descZh;
  final String descDe;
  final String descHi;

  const CodexCardItem({
    required this.id,
    required this.category,
    required this.tab,
    required this.slot,
    this.isRegular = true,
    required this.fileName,
    required this.imagePath,
    required this.name,
    required this.title,
    required this.desc,
    this.nameEn = '',
    this.nameJa = '',
    this.nameZh = '',
    this.nameDe = '',
    this.nameHi = '',
    this.titleEn = '',
    this.titleJa = '',
    this.titleZh = '',
    this.titleDe = '',
    this.titleHi = '',
    this.descEn = '',
    this.descJa = '',
    this.descZh = '',
    this.descDe = '',
    this.descHi = '',
  });

  factory CodexCardItem.fromJson(Map<String, dynamic> json) {
    return CodexCardItem(
      id: json['id'] as String? ?? '',
      category: json['category'] as String? ?? '',
      tab: json['tab'] as String? ?? '',
      slot: json['slot'] as int? ?? 1,
      isRegular: json['isRegular'] as bool? ?? true,
      fileName: json['fileName'] as String? ?? '',
      imagePath: json['imagePath'] as String? ?? '',
      name: json['name'] as String? ?? '',
      title: json['title'] as String? ?? '',
      desc: json['desc'] as String? ?? '',
      nameEn: json['name_en'] as String? ?? '',
      nameJa: json['name_ja'] as String? ?? '',
      nameZh: json['name_zh'] as String? ?? '',
      nameDe: json['name_de'] as String? ?? '',
      nameHi: json['name_hi'] as String? ?? '',
      titleEn: json['title_en'] as String? ?? '',
      titleJa: json['title_ja'] as String? ?? '',
      titleZh: json['title_zh'] as String? ?? '',
      titleDe: json['title_de'] as String? ?? '',
      titleHi: json['title_hi'] as String? ?? '',
      descEn: json['desc_en'] as String? ?? '',
      descJa: json['desc_ja'] as String? ?? '',
      descZh: json['desc_zh'] as String? ?? '',
      descDe: json['desc_de'] as String? ?? '',
      descHi: json['desc_hi'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'category': category,
    'tab': tab,
    'slot': slot,
    'isRegular': isRegular,
    'fileName': fileName,
    'imagePath': imagePath,
    'name': name,
    'title': title,
    'desc': desc,
    'name_en': nameEn,
    'name_ja': nameJa,
    'name_zh': nameZh,
    'name_de': nameDe,
    'name_hi': nameHi,
    'title_en': titleEn,
    'title_ja': titleJa,
    'title_zh': titleZh,
    'title_de': titleDe,
    'title_hi': titleHi,
    'desc_en': descEn,
    'desc_ja': descJa,
    'desc_zh': descZh,
    'desc_de': descDe,
    'desc_hi': descHi,
  };

  String localizedName(String lang) {
    if (lang == 'ko') return name;
    if (lang == 'ja' && nameJa.isNotEmpty && nameJa != name) return nameJa;
    if (lang == 'zh' && nameZh.isNotEmpty && nameZh != name) return nameZh;
    if (lang == 'hi' && nameHi.isNotEmpty && nameHi != name) return nameHi;
    if (lang == 'de' && nameDe.isNotEmpty && nameDe != name) return nameDe;
    if (lang == 'en' && nameEn.isNotEmpty && nameEn != name) return nameEn;

    final canonical = CodexCanonicalData.names[id]?[lang];
    if (canonical != null && canonical.isNotEmpty) return canonical;

    final enFallback = CodexCanonicalData.names[id]?['en'];
    if (enFallback != null && enFallback.isNotEmpty) return enFallback;

    return name;
  }

  String localizedTitle(String lang) {
    if (lang == 'ko') return title;
    if (lang == 'ja' && titleJa.isNotEmpty && titleJa != title) return titleJa;
    if (lang == 'zh' && titleZh.isNotEmpty && titleZh != title) return titleZh;
    if (lang == 'hi' && titleHi.isNotEmpty && titleHi != title) return titleHi;
    if (lang == 'de' && titleDe.isNotEmpty && titleDe != title) return titleDe;
    if (lang == 'en' && titleEn.isNotEmpty && titleEn != title) return titleEn;

    final canonical = CodexCanonicalData.titles[id]?[lang];
    if (canonical != null && canonical.isNotEmpty) return canonical;

    final enFallback = CodexCanonicalData.titles[id]?['en'];
    if (enFallback != null && enFallback.isNotEmpty) return enFallback;

    return title;
  }

  String localizedDesc(String lang) {
    if (lang == 'ko') return desc;
    if (lang == 'ja' && descJa.isNotEmpty && descJa != desc) return descJa;
    if (lang == 'zh' && descZh.isNotEmpty && descZh != desc) return descZh;
    if (lang == 'hi' && descHi.isNotEmpty && descHi != desc) return descHi;
    if (lang == 'de' && descDe.isNotEmpty && descDe != desc) return descDe;
    if (lang == 'en' && descEn.isNotEmpty && descEn != desc) return descEn;

    final canonical = CodexCanonicalData.descs[id]?[lang];
    if (canonical != null && canonical.isNotEmpty) return canonical;

    final enFallback = CodexCanonicalData.descs[id]?['en'];
    if (enFallback != null && enFallback.isNotEmpty) return enFallback;

    return desc;
  }
}

/// Custom User Card Model for 3rd Tab
class CustomCodexCard {
  final int slotIndex; // 0 ~ 32 (33 Slots)
  final bool isEmpty;
  final String? localImageUri;
  final String? imageBase64;
  final String? title;
  final String? memo;
  final String? updatedAt;

  const CustomCodexCard({
    required this.slotIndex,
    this.isEmpty = true,
    this.localImageUri,
    this.imageBase64,
    this.title,
    this.memo,
    this.updatedAt,
  });

  factory CustomCodexCard.fromJson(Map<String, dynamic> json) {
    return CustomCodexCard(
      slotIndex: json['slotIndex'] as int? ?? 0,
      isEmpty: json['isEmpty'] as bool? ?? true,
      localImageUri: json['localImageUri'] as String?,
      imageBase64: json['imageBase64'] as String?,
      title: json['title'] as String?,
      memo: json['memo'] as String?,
      updatedAt: json['updatedAt'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    'slotIndex': slotIndex,
    'isEmpty': isEmpty,
    'localImageUri': localImageUri,
    'imageBase64': imageBase64,
    'title': title,
    'memo': memo,
    'updatedAt': updatedAt,
  };
}