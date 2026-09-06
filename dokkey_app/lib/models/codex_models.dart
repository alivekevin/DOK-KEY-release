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
  final String nameHi;

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
    this.nameHi = '',
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
      nameHi: json['name_hi'] as String? ?? '',
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
    'name_hi': nameHi,
  };

  String localizedName(String lang) {
    if (lang == 'ja' && nameJa.isNotEmpty) return nameJa;
    if (lang == 'zh' && nameZh.isNotEmpty) return nameZh;
    if (lang == 'hi' && nameHi.isNotEmpty) return nameHi;
    if (lang == 'en' && nameEn.isNotEmpty) return nameEn;
    return name;
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