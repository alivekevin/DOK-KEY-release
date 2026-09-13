/// 💰 BM v5.2 최종 가격 라인업 — 단일 진실 공급원 (Single Source of Truth)
///
/// pro_pass_dialog / shop_dialog / kkaebi_lore_help_dialog / 유료화 테스트가 모두 이 표만 참조한다.
/// 가격 변경 시 이 파일 한 곳만 수정하면 전 화면에 반영된다.
/// (과거 이중 하드코딩으로 상점 가격이 드리프트된 사례 방지)
class ProPricing {
  final String yearlyLabel; // 1년 이용권 전체 표기 (예: '₩6,900 / 1년')
  final String yearly; // 1년 이용권 가격
  final String lifetime; // 평생 소장권 가격
  final String pouch; // 황금 열쇠 10개 주머니 가격

  const ProPricing({
    required this.yearlyLabel,
    required this.yearly,
    required this.lifetime,
    required this.pouch,
  });

  static const Map<String, ProPricing> byLang = {
    'ko': ProPricing(
      yearlyLabel: '₩6,900 / 1년',
      yearly: '₩6,900',
      lifetime: '₩19,900',
      pouch: '₩1,000',
    ),
    'en': ProPricing(
      yearlyLabel: r'$4.99 / Year',
      yearly: r'$4.99',
      lifetime: r'$14.99',
      pouch: r'$0.99',
    ),
    'ja': ProPricing(
      yearlyLabel: '¥680 / 年',
      yearly: '¥680',
      lifetime: '¥2,200',
      pouch: '¥120',
    ),
    'zh': ProPricing(
      yearlyLabel: '¥33 / 年',
      yearly: '¥33',
      lifetime: '¥98',
      pouch: '¥6',
    ),
    'de': ProPricing(
      yearlyLabel: '4,99 € / Jahr',
      yearly: '4,99 €',
      lifetime: '14,99 €',
      pouch: '0,99 €',
    ),
    'hi': ProPricing(
      yearlyLabel: '₹399 / वर्ष',
      yearly: '₹399',
      lifetime: '₹1,299',
      pouch: '₹79',
    ),
  };

  /// 미지원 언어는 영문 가격 폴백
  static ProPricing of(String lang) => byLang[lang] ?? byLang['en']!;
}
