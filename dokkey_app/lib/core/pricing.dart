/// 💰 BM v5.1 최종 가격 라인업 — 단일 진실 공급원 (Single Source of Truth)
///
/// pro_pass_dialog / shop_dialog / 유료화 테스트가 모두 이 표만 참조한다.
/// 가격 변경 시 이 파일 한 곳만 수정하면 전 화면에 반영된다.
/// (과거 이중 하드코딩으로 상점 가격이 드리프트된 사례 방지)
class ProPricing {
  final String yearlyLabel; // 1년 이용권 전체 표기 (예: '₩12,000 / 1년')
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
      yearlyLabel: '₩12,000 / 1년',
      yearly: '₩12,000',
      lifetime: '₩59,000',
      pouch: '₩1,200',
    ),
    'en': ProPricing(
      yearlyLabel: r'$9.99 / Year',
      yearly: r'$9.99',
      lifetime: r'$49.99',
      pouch: r'$0.99',
    ),
    'ja': ProPricing(
      yearlyLabel: '¥1,400 / 年',
      yearly: '¥1,400',
      lifetime: '¥7,000',
      pouch: '¥140',
    ),
    'zh': ProPricing(
      yearlyLabel: '¥68 / 年',
      yearly: '¥68',
      lifetime: '¥348',
      pouch: '¥7',
    ),
    'de': ProPricing(
      yearlyLabel: '9,99 € / Jahr',
      yearly: '9,99 €',
      lifetime: '49,99 €',
      pouch: '0,99 €',
    ),
    'hi': ProPricing(
      yearlyLabel: '₹799 / वर्ष',
      yearly: '₹799',
      lifetime: '₹3,999',
      pouch: '₹99',
    ),
  };

  /// 미지원 언어는 영문 가격 폴백
  static ProPricing of(String lang) => byLang[lang] ?? byLang['en']!;
}
