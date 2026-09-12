/// 🎴 DOK-KEY 18-Talisman Data Model & Master Registry
enum TalismanCategory {
  daily,    // 상시 데일리 부적 (10종)
  seasonal, // 특정일 / 시즌 한정 부적 (4종)
  special,  // VIP 소장 / 생활 힐링 부적 (4종)
}

class TalismanItem {
  final int index; // 1 ~ 18
  final String id;
  final TalismanCategory category;
  final String imagePath;
  final String nameKo;
  final String nameEn;
  final String nameJa;
  final String nameZh;
  final String nameHi;
  final String nameDe;
  final String titleKo;
  final String descKo;
  final String descEn;
  final List<String> matchingKeywords; // 명언 매칭 키워드
  final String? emotionTag; // 8 Emotion FX 연계 (joy, calm, insight, love, passion, resolute, etc.)
  final bool isVipCustom; // 유료 커스텀 각인 지원 여부

  const TalismanItem({
    required this.index,
    required this.id,
    required this.category,
    required this.imagePath,
    required this.nameKo,
    required this.nameEn,
    required this.nameJa,
    required this.nameZh,
    required this.nameHi,
    this.nameDe = '',
    required this.titleKo,
    required this.descKo,
    required this.descEn,
    required this.matchingKeywords,
    this.emotionTag,
    this.isVipCustom = false,
  });

  String localizedName(String lang) {
    switch (lang) {
      case 'ja': return nameJa.isNotEmpty ? nameJa : nameKo;
      case 'zh': return nameZh.isNotEmpty ? nameZh : nameKo;
      case 'hi': return nameHi.isNotEmpty ? nameHi : nameKo;
      case 'de': return nameDe.isNotEmpty ? nameDe : nameEn;
      case 'en': return nameEn.isNotEmpty ? nameEn : nameKo;
      default: return nameKo;
    }
  }

  String localizedDesc(String lang) {
    if (lang == 'en' && descEn.isNotEmpty) return descEn;
    return descKo;
  }
}

class TalismanRegistry {
  static final List<TalismanItem> items = [
    // ----------------------------------------------------
    // Sheet 1: 기본 운세 & 대운 (1 ~ 6)
    // ----------------------------------------------------
    TalismanItem(
      index: 1,
      id: 'talisman_wealth',
      category: TalismanCategory.daily,
      imagePath: 'assets/images/talismans/talisman_01.webp',
      nameKo: '재물·성취 부적 (萬事亨通)',
      nameEn: 'Wealth & Prosperity Talisman',
      nameJa: '財運・成就の御札 (萬事亨通)',
      nameZh: '财运・万事亨通符',
      nameHi: 'धन और समृद्धि ताबीज',
      nameDe: 'Reichtum & Erfolg Talisman',
      titleKo: '황금빛 깨비와 엽전·금괴의 만사형통 대운',
      descKo: '막힌 재물길을 활짝 열고 사업과 금전의 큰 복을 부르는 황금 부적입니다.',
      descEn: 'Attracts overwhelming wealth, financial growth, and infinite abundance.',
      matchingKeywords: ['돈', '재물', '부자', '성공', '기회', '풍요', 'wealth', 'money', 'rich', 'abundance'],
      emotionTag: 'joy',
    ),
    TalismanItem(
      index: 2,
      id: 'talisman_wisdom',
      category: TalismanCategory.daily,
      imagePath: 'assets/images/talismans/talisman_02.webp',
      nameKo: '지혜·통찰 부적 (魁 智)',
      nameEn: 'Wisdom & Insight Talisman',
      nameJa: '知恵・洞察の御札 (魁 智)',
      nameZh: '智慧・洞察魁星符',
      nameHi: 'ज्ञान और अंतर्दृष्टि ताबीज',
      nameDe: 'Weisheit & Einsicht Talisman',
      titleKo: '족자와 서예 붓, 밤하늘의 혜안을 여는 지혜',
      descKo: '배움의 길을 밝히고 명석한 결단력과 통찰을 선사하는 지혜 부적입니다.',
      descEn: 'Sharpens your mind, brings profound insight, and grants crystal-clear decisions.',
      matchingKeywords: ['지혜', '배움', '공부', '생각', '통찰', '결정', 'wisdom', 'learn', 'insight', 'mind'],
      emotionTag: 'insight',
    ),
    TalismanItem(
      index: 3,
      id: 'talisman_peace',
      category: TalismanCategory.daily,
      imagePath: 'assets/images/talismans/talisman_03.webp',
      nameKo: '평온·치유 부적 (壽福康寧)',
      nameEn: 'Peace & Healing Talisman',
      nameJa: '平穏・癒しの御札 (壽福康寧)',
      nameZh: '平稳・治愈康宁符',
      nameHi: 'शांति और आरोग्य ताबीज',
      nameDe: 'Frieden & Heilung Talisman',
      titleKo: '청아한 연꽃 대좌와 액운을 막는 치유의 매듭',
      descKo: '불안한 마음을 가라앉히고 심신의 안정을 선물하는 평온 부적입니다.',
      descEn: 'Soothes restless anxiety, restores emotional calm, and brings tranquil harmony.',
      matchingKeywords: ['평온', '마음', '치유', '휴식', '안정', '힐링', 'peace', 'calm', 'rest', 'healing'],
      emotionTag: 'calm',
    ),
    TalismanItem(
      index: 4,
      id: 'talisman_ward',
      category: TalismanCategory.daily,
      imagePath: 'assets/images/talismans/talisman_04.webp',
      nameKo: '벽사·용기 부적 (辟邪 鬼타파)',
      nameEn: 'Ward Evil & Courage Talisman',
      nameJa: '辟邪・勇気の御札 (鬼타파)',
      nameZh: '辟邪・退散恶运符',
      nameHi: 'बुराई निवारण और साहस ताबीज',
      nameDe: 'Dämonenabwehr & Mut Talisman',
      titleKo: '흑적 벼락 일광륜과 결의에 찬 벽사 인장',
      descKo: '잡귀와 불운을 물리치고 흔들리지 않는 용기를 북돋는 수호 부적입니다.',
      descEn: 'Dispels negative energies and bad luck, igniting unyielding courage.',
      matchingKeywords: ['용기', '두려움', '극복', '액운', '벽사', '수호', 'courage', 'overcome', 'shield', 'ward'],
      emotionTag: 'resolute',
    ),
    TalismanItem(
      index: 5,
      id: 'talisman_newyear',
      category: TalismanCategory.seasonal,
      imagePath: 'assets/images/talismans/talisman_05.webp',
      nameKo: '신년 만사형통 대박 부적',
      nameEn: 'New Year Grand Fortune Talisman',
      nameJa: '新年 万事亨通 大福の御札',
      nameZh: '新年・万事亨通大吉符',
      nameHi: 'नव वर्ष महाभाग्य ताबीज',
      nameDe: 'Neujahrs-Großglück Talisman',
      titleKo: '새해 일출과 십이지신의 축복을 담은 황금 열쇠',
      descKo: '새로운 한 해를 찬란하게 열어주는 신년 소원 성취 부적입니다.',
      descEn: 'Opens glorious new horizons and fulfills all your deepest new year wishes.',
      matchingKeywords: ['새해', '신년', '시작', '출발', '소원', 'new year', 'start', 'wish', 'hope'],
      emotionTag: 'joy',
    ),
    TalismanItem(
      index: 6,
      id: 'talisman_exam',
      category: TalismanCategory.seasonal,
      imagePath: 'assets/images/talismans/talisman_06.webp',
      nameKo: '장원급제 합격 부적 (魁)',
      nameEn: 'Supreme Exam Success Talisman',
      nameJa: '状元及第・合格の御札 (魁)',
      nameZh: '金榜题名・及第必胜符',
      nameHi: 'परीक्षा में पूर्ण सफलता ताबीज',
      nameDe: 'Prüfungserfolg Talisman',
      titleKo: '학사모 깨비와 월계관의 빛나는 합격 기운',
      descKo: '시험, 면접, 승진, 자격증의 최고 성취를 이끄는 합격 부적입니다.',
      descEn: 'Guarantees supreme success and triumph in exams, tests, and job interviews.',
      matchingKeywords: ['합격', '시험', '수능', '면접', '승진', '성취', 'exam', 'pass', 'test', 'success'],
      emotionTag: 'insight',
    ),

    // ----------------------------------------------------
    // Sheet 2: 특수 비전 & 시즌 수호 (7 ~ 12)
    // ----------------------------------------------------
    TalismanItem(
      index: 7,
      id: 'talisman_vault',
      category: TalismanCategory.special,
      imagePath: 'assets/images/talismans/talisman_07.webp',
      nameKo: '황금창고 금고 수호 부적 (金庫)',
      nameEn: 'Vault Guardian Wealth Talisman',
      nameJa: '黄金金庫・守護の御札',
      nameZh: '黄金金库・财富镇守符',
      nameHi: 'स्वर्ण तिजोरी रक्षा ताबीज',
      nameDe: 'Tresor-Wächter Talisman',
      titleKo: '황금 열쇠와 닫힌 금고의 강력한 자산 수호',
      descKo: '모은 재산이 새어나가지 않게 단단히 지켜주는 황금창고 부적입니다.',
      descEn: 'Safeguards your wealth and secures tremendous assets against all financial leaks.',
      matchingKeywords: ['금고', '저축', '보호', '자산', '수호', 'vault', 'save', 'protect', 'secure'],
      emotionTag: 'joy',
      isVipCustom: true,
    ),
    TalismanItem(
      index: 8,
      id: 'talisman_supermoon',
      category: TalismanCategory.seasonal,
      imagePath: 'assets/images/talismans/talisman_08.webp',
      nameKo: '슈퍼문 만월 소원 성취 부적 (滿月)',
      nameEn: 'Supermoon Wish Fulfiller Talisman',
      nameJa: '満月・大願成就の御札',
      nameZh: '超级满月・心愿圆满符',
      nameHi: 'पूर्णिमा इच्छा सिद्धि ताबीज',
      nameDe: 'Vollmond-Wunsch Talisman',
      titleKo: '은은한 보름달과 단풍의 가을 낭만 기원',
      descKo: '보름달처럼 꽉 찬 풍요와 소망을 이루어주는 만월 소원 부적입니다.',
      descEn: 'Harnesses full-moon celestial energy to make your greatest dreams manifest.',
      matchingKeywords: ['달', '보름달', '추석', '소원', '풍요', 'moon', 'dream', 'wish', 'harvest'],
      emotionTag: 'calm',
    ),
    TalismanItem(
      index: 9,
      id: 'talisman_thunder',
      category: TalismanCategory.special,
      imagePath: 'assets/images/talismans/talisman_09.webp',
      nameKo: '뇌공벽사 도깨비 방망이 부적 (雷霆)',
      nameEn: 'Thunder Goblin Bat Exorcism Talisman',
      nameJa: '雷霆辟邪・トッケビ棍棒の御札',
      nameZh: '雷霆辟邪・神棒镇煞符',
      nameHi: 'वज्र गदा संकट मोचन ताबीज',
      nameDe: 'Donner-Keule Talisman',
      titleKo: '황금 방망이와 청룡 벼락의 삼재/악귀 타파',
      descKo: '삼재와 불길한 징조를 번개로 일격에 부숴버리는 강력한 뇌공 부적입니다.',
      descEn: 'Strikes down terrible omens, curses, and bad karma with divine lightning.',
      matchingKeywords: ['벼락', '방망이', '타파', '삼재', '격퇴', 'thunder', 'strike', 'power', 'break'],
      emotionTag: 'resolute',
      isVipCustom: true,
    ),
    TalismanItem(
      index: 10,
      id: 'talisman_love',
      category: TalismanCategory.daily,
      imagePath: 'assets/images/talismans/talisman_10.webp',
      nameKo: '인연화합 연인/부부 부적 (緣 結)',
      nameEn: 'Love & Relationship Harmony Talisman',
      nameJa: '良縁・夫婦和合の御札 (緣 結)',
      nameZh: '天赐良缘・琴瑟和鸣符',
      nameHi: 'प्रेम और संबंध सद्भाव ताबीज',
      nameDe: 'Liebe & Harmonie Talisman',
      titleKo: '원앙 한 쌍과 분홍빛 구름의 아름다운 인연',
      descKo: '운명 같은 사랑을 맺어주고 소중한 관계를 화목하게 지켜주는 인연 부적입니다.',
      descEn: 'Brings destiny-bound lovers together and deepens everlasting relational warmth.',
      matchingKeywords: ['사랑', '인연', '연인', '부부', '우정', '만남', 'love', 'relationship', 'couple', 'friend'],
      emotionTag: 'love',
    ),
    TalismanItem(
      index: 11,
      id: 'talisman_victory',
      category: TalismanCategory.daily,
      imagePath: 'assets/images/talismans/talisman_11.webp',
      nameKo: '급속돌파 승리·불꽃 부적 (勝 疾走)',
      nameEn: 'Rapid Breakthrough Victory Talisman',
      nameJa: '突破・必勝の炎の御札 (勝 疾走)',
      nameZh: '突飞猛进・百战百胜符',
      nameHi: 'तेज सफलता और विजय ताबीज',
      nameDe: 'Durchbruch & Sieg Talisman',
      titleKo: '쌍깃발과 타오르는 불꽃의 폭발적인 승부 기운',
      descKo: '정체된 국면을 시원하게 뚫고 파죽지세로 승리하는 돌파 부적입니다.',
      descEn: 'Blazes through stagnant obstacles and drives rapid, unstoppable victory.',
      matchingKeywords: ['승리', '도전', '돌파', '열정', '전진', 'victory', 'breakthrough', 'fire', 'win'],
      emotionTag: 'passion',
    ),
    TalismanItem(
      index: 12,
      id: 'talisman_purify',
      category: TalismanCategory.seasonal,
      imagePath: 'assets/images/talismans/talisman_12.webp',
      nameKo: '초하루 월간 액운 정화 부적 (朔日)',
      nameEn: 'Monthly Renewal & Purifying Talisman',
      nameJa: '朔日・月間厄除け浄化の御札',
      nameZh: '初一・月度净煞开运符',
      nameHi: 'मासिक शुद्धि और नवीनीकरण ताबीज',
      nameDe: 'Monatserneuerung Talisman',
      titleKo: '푸른 태극과 십이지신 결계의 청정한 기운',
      descKo: '새로운 달이 시작될 때 지난달의 묵은 때와 액운을 맑게 씻어내는 정화 부적입니다.',
      descEn: 'Purifies past negativity and resets your spiritual energy for the month ahead.',
      matchingKeywords: ['정화', '초하루', '새달', '청정', '새로움', 'purify', 'cleanse', 'renewal', 'fresh'],
      emotionTag: 'calm',
    ),

    // ----------------------------------------------------
    // Sheet 3: 생활 소원 & 현대 힐링 (13 ~ 18)
    // ----------------------------------------------------
    TalismanItem(
      index: 13,
      id: 'talisman_health',
      category: TalismanCategory.daily,
      imagePath: 'assets/images/talismans/talisman_13.webp',
      nameKo: '만병통치 무병장수 부적 (康 壽)',
      nameEn: 'Radiant Longevity & Health Talisman',
      nameJa: '無病息災・長寿の御札 (康 壽)',
      nameZh: '祛病延年・万寿康宁符',
      nameHi: 'आरोग्य और दीर्घायु ताबीज',
      nameDe: 'Gesundheit & Langlebigkeit Talisman',
      titleKo: '소나무와 불로초, 비취옥빛 청정 치유의 생기',
      descKo: '아픈 곳을 쾌유시키고 맑은 활력과 장수의 복을 내리는 건강 부적입니다.',
      descEn: 'Bestows vibrant physical health, vitality, and lifelong wellness.',
      matchingKeywords: ['건강', '치료', '무병', '장수', '활력', 'health', 'vitality', 'longevity', 'energy'],
      emotionTag: 'calm',
    ),
    TalismanItem(
      index: 14,
      id: 'talisman_estate',
      category: TalismanCategory.daily,
      imagePath: 'assets/images/talismans/talisman_14.webp',
      nameKo: '대명당 가택안녕·문서운 부적 (家 門)',
      nameEn: 'Home Protection & Real Estate Talisman',
      nameJa: '家内安全・不動産文書の御札 (家 門)',
      nameZh: '家宅平安・置业文书符',
      nameHi: 'गृह रक्षा और संपत्ति ताबीज',
      nameDe: 'Haus- & Dokumentenschutz Talisman',
      titleKo: '전통 기와 대문과 황금 인장의 든든한 명당 수호',
      descKo: '가족의 안녕을 지키고 이사, 청약, 계약 등의 문서운을 대통하게 합니다.',
      descEn: 'Protects the sanctity of home and ensures prosperous real estate contracts.',
      matchingKeywords: ['집', '이사', '가족', '계약', '부동산', '문서', 'home', 'house', 'family', 'contract'],
      emotionTag: 'joy',
    ),
    TalismanItem(
      index: 15,
      id: 'talisman_travel',
      category: TalismanCategory.daily,
      imagePath: 'assets/images/talismans/talisman_15.webp',
      nameKo: '무사고 안전운행·여정평안 부적 (安 途)',
      nameEn: 'Safe Journey & Travel Guardian Talisman',
      nameJa: '交通安全・道中無事の御札 (安 途)',
      nameZh: '出行平安・顺风顺水符',
      nameHi: 'सुरक्षित यात्रा और मार्गदर्शक ताबीज',
      nameDe: 'Sichere Reise Talisman',
      titleKo: '길을 밝히는 청사초롱과 나침반의 든든한 길잡이',
      descKo: '출퇴근길, 장거리 여행, 해외 출장의 모든 발걸음을 무탈하게 지켜줍니다.',
      descEn: 'Guides your journeys safely through all roads, skies, and destinations.',
      matchingKeywords: ['안전', '운전', '여행', '길', '출장', 'safe', 'travel', 'trip', 'journey'],
      emotionTag: 'calm',
    ),
    TalismanItem(
      index: 16,
      id: 'talisman_fame',
      category: TalismanCategory.daily,
      imagePath: 'assets/images/talismans/talisman_16.webp',
      nameKo: '만인환호 귀인조력 부적 (貴 德)',
      nameEn: 'Charisma & Noble Helper Attraction Talisman',
      nameJa: '人気・貴人助力の御札 (貴 德)',
      nameZh: '贵人相助・万人瞩目符',
      nameHi: 'आकर्षण और उच्च मित्र ताबीज',
      nameDe: 'Charisma & Gönner Talisman',
      titleKo: '화려한 전통선추 부채와 황금 나비의 매력적인 기운',
      descKo: '나를 돕는 귀인을 만나게 하고 사람들의 호감과 신뢰를 이끌어냅니다.',
      descEn: 'Attracts generous mentors and builds magnetic charisma with deep trust.',
      matchingKeywords: ['인기', '귀인', '사람', '도움', '매력', '신뢰', 'charm', 'people', 'friendship', 'trust'],
      emotionTag: 'love',
    ),
    TalismanItem(
      index: 17,
      id: 'talisman_sleep',
      category: TalismanCategory.special,
      imagePath: 'assets/images/talismans/talisman_17.webp',
      nameKo: '악몽퇴치 숙면안심 부적 (夢 寧)',
      nameEn: 'Sweet Dreams & Nightmare Ward Talisman',
      nameJa: '悪夢退散・安眠熟睡の御札 (夢 寧)',
      nameZh: '除梦宁神・安枕无忧符',
      nameHi: 'मधुर स्वप्न और गहरी नींद ताबीज',
      nameDe: 'Süßer Schlaf Talisman',
      titleKo: '별밤 구름 베개에서 편안히 잠든 아기 깨비',
      descKo: '밤의 불안과 악몽을 물리치고 포근하고 달콤한 꿀잠으로 이끌어 줍니다.',
      descEn: 'Wards off night terrors and brings deep, serene sleep with peaceful dreams.',
      matchingKeywords: ['잠', '수면', '꿈', '밤', '휴식', '불면', 'sleep', 'dream', 'night', 'relax'],
      emotionTag: 'calm',
    ),
    TalismanItem(
      index: 18,
      id: 'talisman_surge',
      category: TalismanCategory.special,
      imagePath: 'assets/images/talismans/talisman_18.webp',
      nameKo: '신의 한수 대세상승 부적 (騰 買)',
      nameEn: 'Surge & Great Investment Fortune Talisman',
      nameJa: '大勢上昇・勝負運の御札 (騰 買)',
      nameZh: '行大运・势如破竹上升符',
      nameHi: 'महान निवेश और लाभ ताबीज',
      nameDe: 'Aufstiegs-Glück Talisman',
      titleKo: '하늘로 승천하는 황금용과 붉은 상승 랠리의 기운',
      descKo: '투자와 도전에서 결정적인 타이밍을 잡아 거대한 성장을 이루어냅니다.',
      descEn: 'Aligns you with the explosive upward momentum of great wealth and investment.',
      matchingKeywords: ['투자', '주식', '코인', '상승', '도약', '대박', 'invest', 'stock', 'surge', 'rally'],
      emotionTag: 'passion',
      isVipCustom: true,
    ),
  ];

  /// 특정 명언 텍스트나 감정에 가장 잘 맞는 부적 자동 추천 매칭
  static TalismanItem matchTalisman(String quoteText, {String? emotion}) {
    final lower = quoteText.toLowerCase();
    
    // 1. 시간대 체크: 밤 10시 ~ 새벽 5시 사이면 숙면 부적 우선 후보
    final now = DateTime.now();
    if (now.hour >= 22 || now.hour <= 5) {
      if (lower.contains('잠') || lower.contains('밤') || lower.contains('휴식') || lower.contains('sleep')) {
        return items[16]; // 17번 숙면 부적
      }
    }

    // 2. 키워드 매칭
    for (final item in items) {
      for (final kw in item.matchingKeywords) {
        if (lower.contains(kw)) {
          return item;
        }
      }
    }

    // 3. 감정 태그 매칭
    if (emotion != null) {
      final matched = items.firstWhere(
        (i) => i.emotionTag == emotion,
        orElse: () => items[0],
      );
      return matched;
    }

    // 4. 기본: 1번 재물/성취 부적
    return items[0];
  }
}
