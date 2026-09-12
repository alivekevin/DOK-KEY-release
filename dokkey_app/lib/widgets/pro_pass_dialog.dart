import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../core/brand_config.dart';
import '../core/pricing.dart';
import '../core/theme.dart';
import '../core/sound_service.dart';
import '../providers/dokkey_provider.dart';

/// 👑 DOK-KEY PRO (1년 이용권 & 평생 소장권) — BM v5.1 최종 라인업
class ProPassDialog extends StatefulWidget {
  const ProPassDialog({super.key});

  static void show(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => const ProPassDialog(),
    );
  }

  @override
  State<ProPassDialog> createState() => _ProPassDialogState();
}

class _ProPassDialogState extends State<ProPassDialog> {
  int _selectedPlan = 0; // 0: 1년 이용권 ($9.99), 1: 평생 소장권 ($49.99)

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<DokkeyProvider>();
    final lang = provider.lang;
    final isPro = provider.isProUser;
    // 💰 BM v5.1 가격 SSOT (lib/core/pricing.dart) — 드리프트 방지 단일 공급원
    final pricing = ProPricing.of(lang);

    String title;
    String subtitle;
    String plan1Name, plan1Price, plan1Sub;
    String plan2Name, plan2Price, plan2Sub, plan2Badge;
    String feature1Title, feature1Desc;
    String feature2Title, feature2Desc;
    String feature3Title, feature3Desc;
    String feature4Title, feature4Desc;
    String feature5Title, feature5Desc;
    String feature6Title, feature6Desc;
    String pouchTitle, pouchDesc;
    String actionButtonText;
    String alreadyProText;
    String proStatusYearly;
    String proStatusLifetime;
    String proStatusLegacy;
    String comingSoonText;
    String closeText;

    switch (lang) {
      case 'ja':
        title = '👑 DOK-KEY PRO プラン';
        subtitle = 'すべての制限を解除し、完全な機能をお楽しみください';
        plan1Name = '1年プラン';
        plan1Price = pricing.yearlyLabel;
        plan1Sub = '月額わずか ¥116';
        plan2Name = '永久ライセンス';
        plan2Price = pricing.lifetime;
        plan2Sub = '1回のみのお支払い・生涯有効';
        plan2Badge = '一番人気 ⭐';
        feature1Title = '組合せ保管箱 99スロット拡張';
        feature1Desc = '無料9スロットの制限を解除し、99スロットの大容量保管';
        feature2Title = 'カスタム図鑑 99テーマ拡張';
        feature2Desc = '33種×最大99テーマスロット(計3,267枚)の自由入替';
        feature3Title = 'お札図鑑 33スロット全開放';
        feature3Desc = '公式18種の即時コレクション＋MY custom 15スロット開放';
        feature4Title = 'クケビアーケード 13種 無制限プレイ';
        feature4Desc = '1日3回制限を完全解除し、好きなだけプレイ';
        feature5Title = '広告完全非表示';
        feature5Desc = '全ての広告をスキップした快適な体験';
        feature6Title = '毎日追加ドロー +3回';
        feature6Desc = '1日1回 → 合計4回のキー回転が毎日可能';
        pouchTitle = '🗝️ 黄金の鍵10個ポーチ (消耗品)';
        pouchDesc = '${pricing.pouch} — 今すぐ回して錬成したい方向けの追加キーパック';
        actionButtonText = 'PRO を有効化';
        alreadyProText = 'PRO 利用中 — 全機能アンロック済 👑';
        proStatusYearly = '1年プラン · {date}まで有効';
        proStatusLifetime = '永久ライセンス · 期限なし';
        proStatusLegacy = '既存のPRO等級を維持中';
        comingSoonText = '🔒 ストア版でご購入いただけます（決済機能準備中）';
        closeText = '閉じる';
        break;
      case 'zh':
        title = '👑 DOK-KEY 专业版方案';
        subtitle = '解锁全部限制，畅享完整高阶体验';
        plan1Name = '1年订阅';
        plan1Price = pricing.yearlyLabel;
        plan1Sub = '每月仅需 ¥5.6';
        plan2Name = '终身买断版';
        plan2Price = pricing.lifetime;
        plan2Sub = '一次性付款 · 永久有效';
        plan2Badge = '最超值 ⭐';
        feature1Title = '组合库 99格大容量扩展';
        feature1Desc = '解除免费9格限制，尊享99格本地组合空间';
        feature2Title = '自定义图鉴 99主题扩展';
        feature2Desc = '33张×最多99主题卡槽(共3,267张)自由替换';
        feature3Title = '符咒图鉴 33格全开放';
        feature3Desc = '官方18种立即收集＋MY custom 15格全开放';
        feature4Title = '小妖街机 13款游戏无限畅玩';
        feature4Desc = '解除每日3次限制，无次数上限尽情游玩';
        feature5Title = '广告完全移除';
        feature5Desc = '跳过所有广告，极速清爽体验';
        feature6Title = '每日追加抽取 +3次';
        feature6Desc = '每日1次 → 每天共4次转钥匙机会';
        pouchTitle = '🗝️ 黄金钥匙10个锦囊 (消耗品)';
        pouchDesc = '${pricing.pouch} — 想立即抽取与炼成用户的追加钥匙包';
        actionButtonText = '立即解锁专业版';
        alreadyProText = '专业版使用中 — 全功能已解锁 👑';
        proStatusYearly = '1年订阅 · 有效期至 {date}';
        proStatusLifetime = '终身买断 · 永不过期';
        proStatusLegacy = '保留原有PRO等级';
        comingSoonText = '🔒 将在商店版本中提供购买（支付功能准备中）';
        closeText = '关闭';
        break;
      case 'hi':
        title = '👑 DOK-KEY प्रो प्लान';
        subtitle = 'सभी सीमाएं हटाएं और संपूर्ण अनुभव का आनंद लें';
        plan1Name = '1 वर्ष प्लान';
        plan1Price = pricing.yearlyLabel;
        plan1Sub = 'प्रति माह केवल ₹66';
        plan2Name = 'लाइफटाइम पास';
        plan2Price = pricing.lifetime;
        plan2Sub = 'एकमुश्त भुगतान · आजीवन सक्रिय';
        plan2Badge = 'सर्वोत्तम मूल्य ⭐';
        feature1Title = '99 कंबिनेशन स्लॉट विस्तार';
        feature1Desc = 'मुफ़्त 9 स्लॉट सीमा हटें — 99 विशाल स्लॉट';
        feature2Title = 'कस्टम संग्रह 99 थीम विस्तार';
        feature2Desc = '33×अधिकतम 99 थीम स्लॉट (कुल 3,267 कार्ड) स्वतंत्र उपयोग';
        feature3Title = 'ताबीज संग्रह 33 स्लॉट पूर्ण खुले';
        feature3Desc = 'आधिकारिक 18 का तुरंत संग्रह + MY custom 15 स्लॉट खुले';
        feature4Title = '13 आर्केड गेम्स असीमित खेल';
        feature4Desc = 'दैनिक 3 बार की सीमा समाप्त — जब चाहें खेलें';
        feature5Title = 'विज्ञापन पूर्ण हटाए गए';
        feature5Desc = 'सभी विज्ञापन छोड़कर तेज़ अनुभव';
        feature6Title = 'रोज़ाना अतिरिक्त ड्रॉ +3';
        feature6Desc = 'दिन में 1 → कुल 4 बार की चाबी घुमाव';
        pouchTitle = '🗝️ गोल्डन की 10 पाउच (उपभोग्य)';
        pouchDesc = '${pricing.pouch} — तुरंत घुमाकर संग्रह बढ़ाने वालों के लिए';
        actionButtonText = 'प्रो अनलॉक करें';
        alreadyProText = 'PRO सक्रिय — सभी फ़ीचर्स अनलॉक्ड 👑';
        proStatusYearly = '1 वर्ष प्लान · {date} तक वैध';
        proStatusLifetime = 'लाइफटाइम पास · कभी समाप्त नहीं होता';
        proStatusLegacy = 'मौजूदा PRO स्तर बना रहेगा';
        comingSoonText = '🔒 स्टोर संस्करण में खरीदा जा सकेगा (भुगतान जल्द आ रहा है)';
        closeText = 'बंद करें';
        break;
      case 'de':
        title = '👑 DOK-KEY PRO-Tarife';
        subtitle = 'Alle Limits aufheben — volles Premium-Erlebnis genießen';
        plan1Name = '1-Jahres-Abo';
        plan1Price = pricing.yearlyLabel;
        plan1Sub = 'Nur 0,83 € / Monat';
        plan2Name = 'Lifetime VIP';
        plan2Price = pricing.lifetime;
        plan2Sub = 'Einmalzahlung · lebenslang gültig';
        plan2Badge = 'Bester Wert ⭐';
        feature1Title = '99 Kombinations-Slots';
        feature1Desc = 'Gratis-Limit von 9 Slots fallen lassen — 99 geräumige Slots';
        feature2Title = 'Custom-Kodex 99 Themes';
        feature2Desc = '33 Karten × bis zu 99 Theme-Slots (3.267 Karten) frei tauschbar';
        feature3Title = 'Talisman-Kodex: alle 33 Slots offen';
        feature3Desc = '18 offizielle sofort gesammelt + 15 MY-Custom-Slots offen';
        feature4Title = '13 Arcade-Spiele unbegrenzt';
        feature4Desc = 'Tägliches Limit von 3 Spielen aufgehoben — grenzenloser Spielspaß';
        feature5Title = 'Werbung vollständig entfernt';
        feature5Desc = 'Alle Werbung überspringen — blitzschnell';
        feature6Title = 'Täglich +3 Extra-Ziehungen';
        feature6Desc = '1× pro Tag → insgesamt 4× Schlüsseldrehen';
        pouchTitle = '🗝️ Goldener Schlüssel-Bundle (10 Stk., Verbrauchsgut)';
        pouchDesc = '${pricing.pouch} — für alle, die sofort drehen und sammeln wollen';
        actionButtonText = 'PRO freischalten';
        alreadyProText = 'PRO aktiv — alle Funktionen freigeschaltet 👑';
        proStatusYearly = '1-Jahres-Abo · gültig bis {date}';
        proStatusLifetime = 'Lifetime VIP · läuft nie ab';
        proStatusLegacy = 'Bisheriger PRO-Status bleibt erhalten';
        comingSoonText = '🔒 Kauf in der Store-Version möglich (Zahlung folgt bald)';
        closeText = 'Schließen';
        break;
      case 'en':
        title = '👑 DOK-KEY PRO Plans';
        subtitle = 'Unlock all limits — enjoy the ultimate full-tier experience';
        plan1Name = '1-Year Pass';
        plan1Price = pricing.yearlyLabel;
        plan1Sub = 'Only \$0.83 / month';
        plan2Name = 'Lifetime VIP';
        plan2Price = pricing.lifetime;
        plan2Sub = 'One-time payment · Forever yours';
        plan2Badge = 'Best Value ⭐';
        feature1Title = '99 Combined Vault Slots';
        feature1Desc = 'Drop the free 9-slot limit — 99 massive local slots';
        feature2Title = 'Custom Codex 99 Themes';
        feature2Desc = '33 cards × up to 99 theme slots (3,267 cards total), freely swappable';
        feature3Title = 'Talisman Codex: all 33 slots open';
        feature3Desc = 'Official 18 instantly collected + 15 MY custom slots open';
        feature4Title = '13 Arcade Games Unlimited';
        feature4Desc = 'No more 3 plays/day limit — play as much as you want';
        feature5Title = '100% Ads Removed';
        feature5Desc = 'Skip all ads for a fast, clean experience';
        feature6Title = 'Daily Extra Draws +3';
        feature6Desc = '1 per day → 4 total key spins every day';
        pouchTitle = '🗝️ Golden Key Pouch ×10 (Consumable)';
        pouchDesc = '${pricing.pouch} — for those who want to spin and collect right now';
        actionButtonText = 'Unlock PRO';
        alreadyProText = 'PRO Active — All-Features Unlocked 👑';
        proStatusYearly = '1-Year Pass · valid until {date}';
        proStatusLifetime = 'Lifetime Pass · never expires';
        proStatusLegacy = 'Existing PRO tier preserved';
        comingSoonText = '🔒 Purchases will be available in the store release (billing coming soon)';
        closeText = 'Close';
        break;
      case 'ko':
      default:
        title = '👑 DOK-KEY PRO 플랜';
        subtitle = '모든 한도를 해제하고 완전한 고품격 기능을 누리세요';
        plan1Name = '1년 정기 이용권';
        plan1Price = pricing.yearlyLabel;
        plan1Sub = '월 1,000원 꼴의 합리적 가격';
        plan2Name = '평생 소장권 (VIP)';
        plan2Price = pricing.lifetime;
        plan2Sub = '추가 결제 없이 영구 소장';
        plan2Badge = '최고 인기 ⭐';
        feature1Title = '조합 보관함 99슬롯 대용량 확장';
        feature1Desc = '무료 9슬롯 한도 해제 → 99슬롯 대용량 로컬 보관';
        feature2Title = '커스텀 도감 99테마 확장';
        feature2Desc = '테마당 33종 × 최대 99슬롯(총 3,267장) 자유 교체';
        feature3Title = '부적 도감 33슬롯 전체 개방';
        feature3Desc = '공식 18종 즉시 수집 + MY 커스텀 15슬롯 완전 개방';
        feature4Title = '깨비 오락실 13종 무제한 플레이';
        feature4Desc = '하루 3회 플레이 제한 해제 → 무제한 자유 플레이';
        feature5Title = '광고 100% 영구 제거';
        feature5Desc = '전면·배너 광고 없이 빠르고 쾌적한 실행';
        feature6Title = '매일 데일리 추가 뽑기 +3회';
        feature6Desc = '하루 1회 → 하루 총 4회 열쇠 돌리기';
        pouchTitle = '🗝️ 황금 열쇠 10개 주머니 (소모품)';
        pouchDesc = '${pricing.pouch} — 지금 바로 돌리고 모으고 싶은 분께';
        actionButtonText = 'PRO 잠금해제';
        alreadyProText = 'PRO 이용 중 — 모든 기능 잠금해제 👑';
        proStatusYearly = '1년 이용권 · {date}까지 이용';
        proStatusLifetime = '평생 소장권 · 만료 없음';
        proStatusLegacy = '기존 PRO 등급이 유지됩니다';
        comingSoonText = '🔒 스토어 출시 버전에서 구매할 수 있습니다 (결제 기능 준비 중)';
        closeText = '닫기';
        break;
    }

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 460),
        decoration: BoxDecoration(
          color: DokkeyTheme.cardDark,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: DokkeyTheme.gold, width: 2),
          boxShadow: [
            BoxShadow(
              color: DokkeyTheme.gold.withValues(alpha: 0.25),
              blurRadius: 30,
              spreadRadius: 2,
            ),
          ],
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Crown Icon
              Center(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [DokkeyTheme.goldLight, DokkeyTheme.gold],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: DokkeyTheme.gold.withValues(alpha: 0.4),
                        blurRadius: 16,
                      ),
                    ],
                  ),
                  child: const Icon(Icons.workspace_premium_rounded, color: Colors.black, size: 32),
                ),
              ),
              const SizedBox(height: 10),

              Text(
                title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 18.5,
                  fontWeight: FontWeight.w900,
                  color: DokkeyTheme.goldLight,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                subtitle,
                textAlign: TextAlign.center,
                style: TextStyle(color: DokkeyTheme.textMuted, fontSize: 11.5, height: 1.35),
              ),
              const SizedBox(height: 14),

              // Dual Plan Selectors (1-Year vs Lifetime)
              Row(
                children: [
                  // Option 1: 1-Year Pass
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        setState(() => _selectedPlan = 0);
                        SoundService().playCardFlip();
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
                        decoration: BoxDecoration(
                          color: _selectedPlan == 0
                              ? DokkeyTheme.gold.withValues(alpha: 0.18)
                              : DokkeyTheme.surfaceDark,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: _selectedPlan == 0 ? DokkeyTheme.gold : DokkeyTheme.borderDark,
                            width: _selectedPlan == 0 ? 2.0 : 1.0,
                          ),
                        ),
                        child: Column(
                          children: [
                            Text(
                              plan1Name,
                              style: TextStyle(
                                color: _selectedPlan == 0 ? DokkeyTheme.goldLight : Colors.white70,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              plan1Price,
                              style: const TextStyle(
                                color: Colors.amber,
                                fontSize: 15,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              plan1Sub,
                              style: TextStyle(color: DokkeyTheme.textMuted, fontSize: 10),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),

                  // Option 2: Lifetime Pass
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        setState(() => _selectedPlan = 1);
                        SoundService().playCardFlip();
                      },
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
                            decoration: BoxDecoration(
                              color: _selectedPlan == 1
                                  ? const Color(0xFFFFD54F).withValues(alpha: 0.22)
                                  : DokkeyTheme.surfaceDark,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: _selectedPlan == 1 ? const Color(0xFFFFD54F) : DokkeyTheme.borderDark,
                                width: _selectedPlan == 1 ? 2.0 : 1.0,
                              ),
                            ),
                            child: Column(
                              children: [
                                Text(
                                  plan2Name,
                                  style: TextStyle(
                                    color: _selectedPlan == 1 ? DokkeyTheme.goldLight : Colors.white70,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  plan2Price,
                                  style: const TextStyle(
                                    color: Color(0xFFFFD54F),
                                    fontSize: 15,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  plan2Sub,
                                  style: TextStyle(color: DokkeyTheme.textMuted, fontSize: 10),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                          Positioned(
                            top: -8,
                            right: 8,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFF5252),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                plan2Badge,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // 6 Benefits
              _buildBenefitRow(Icons.inventory_2_rounded, feature1Title, feature1Desc),
              const SizedBox(height: 8),
              _buildBenefitRow(Icons.palette_rounded, feature2Title, feature2Desc),
              const SizedBox(height: 8),
              _buildBenefitRow(Icons.grid_view_rounded, feature3Title, feature3Desc),
              const SizedBox(height: 8),
              _buildBenefitRow(Icons.sports_esports_rounded, feature4Title, feature4Desc),
              const SizedBox(height: 8),
              _buildBenefitRow(Icons.block_rounded, feature5Title, feature5Desc),
              const SizedBox(height: 8),
              _buildBenefitRow(Icons.add_circle_outline_rounded, feature6Title, feature6Desc),
              const SizedBox(height: 12),

              // 🗝️ 황금 열쇠 10개 주머니 (소모품 안내)
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: DokkeyTheme.surfaceDark,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: DokkeyTheme.borderDark),
                ),
                child: Row(
                  children: [
                    const Text('🗝️', style: TextStyle(fontSize: 18)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            pouchTitle,
                            style: TextStyle(
                              color: DokkeyTheme.textMain,
                              fontWeight: FontWeight.bold,
                              fontSize: 11.5,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            pouchDesc,
                            style: TextStyle(color: DokkeyTheme.textMuted, fontSize: 10),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // Activation / Status Button
              if (isPro)
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 11, horizontal: 10),
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.greenAccent),
                  ),
                  child: Column(
                    children: [
                      Text(
                        alreadyProText,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.greenAccent,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        provider.proPlan == 'yearly' && provider.proExpiry != null
                            ? proStatusYearly.replaceFirst(
                                '{date}', DateFormat('yyyy.MM.dd').format(provider.proExpiry!))
                            : (provider.proPlan == 'lifetime'
                                ? proStatusLifetime
                                : proStatusLegacy),
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.greenAccent.withValues(alpha: 0.85),
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                )
              else
                ElevatedButton(
                  onPressed: () async {
                    // 💳 결제 미연동 릴리즈 빌드: 유료 상품 무료 지급 차단 (스토어 정책)
                    if (!BrandConfig.billingEnabled && !kDebugMode) {
                      SoundService().playCardFlip();
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(comingSoonText),
                            backgroundColor: DokkeyTheme.surfaceDark,
                          ),
                        );
                      }
                      return;
                    }
                    // BM v5.1: 선택된 플랜(1년 구독 / 평생 소장)으로 활성화
                    await provider.upgradeToProPass(lifetime: _selectedPlan == 1);
                    SoundService().playGong();
                    if (context.mounted) {
                      Navigator.of(context).pop();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            lang == 'ko'
                                ? '🎉 PRO가 잠금해제되었습니다! 99개 조합 슬롯과 오락실 무제한 플레이가 열렸습니다.'
                                : '🎉 PRO Unlocked! 99 vault slots & unlimited arcade are active.',
                          ),
                          backgroundColor: DokkeyTheme.surfaceDark,
                        ),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: DokkeyTheme.gold,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 6,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.flash_on_rounded, size: 20, color: Colors.black),
                      const SizedBox(width: 6),
                      Text(
                        _selectedPlan == 0 ? '$actionButtonText ($plan1Price)' : '$actionButtonText ($plan2Price)',
                        style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13.5),
                      ),
                    ],
                  ),
                ),

              const SizedBox(height: 6),
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(closeText, style: TextStyle(color: DokkeyTheme.textMuted, fontSize: 12.5)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static Widget _buildBenefitRow(IconData icon, String title, String desc) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(5),
          decoration: BoxDecoration(
            color: DokkeyTheme.gold.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: DokkeyTheme.goldLight, size: 16),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  color: DokkeyTheme.textMain,
                  fontWeight: FontWeight.bold,
                  fontSize: 12.5,
                ),
              ),
              const SizedBox(height: 1.5),
              Text(
                desc,
                style: TextStyle(
                  color: DokkeyTheme.textMuted,
                  fontSize: 10.5,
                  height: 1.3,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
