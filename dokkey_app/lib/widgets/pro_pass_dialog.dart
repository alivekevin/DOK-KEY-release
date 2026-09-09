import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/theme.dart';
import '../core/sound_service.dart';
import '../providers/dokkey_provider.dart';

/// 👑 DOK-KEY PRO (1년 이용권) — BM v5.0 최종 라인업
/// '모든 기능 잠금해제 (All-Features Unlocked)' 중심. v5 용어 정비 규칙 준수 (레거시 표현 미사용).
class ProPassDialog extends StatelessWidget {
  const ProPassDialog({super.key});

  static void show(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => const ProPassDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<DokkeyProvider>();
    final lang = provider.lang;
    final isPro = provider.isProUser;

    String title;
    String subtitle;
    String priceText;
    String priceSub;
    String feature1Title, feature1Desc;
    String feature2Title, feature2Desc;
    String feature3Title, feature3Desc;
    String feature4Title, feature4Desc;
    String feature5Title, feature5Desc;
    String pouchTitle, pouchDesc;
    String actionButtonText;
    String alreadyProText;
    String closeText;

    switch (lang) {
      case 'ja':
        title = '👑 DOK-KEY PRO (1年プラン)';
        subtitle = 'すべての機能をアンロック — 月のブレンドコーヒーより安い';
        priceText = '¥250 / 1年間';
        priceSub = 'すべての機能のロック解除 (追加料金なし)';
        feature1Title = '組合せ保管箱 99スロット拡張';
        feature1Desc = '無料9スロットの制限を解除し、99スロットの大容量保管';
        feature2Title = 'カスタム図鑑 99テーマ拡張';
        feature2Desc = '33種×最大99テーマスロット(計3,267枚)の自由入替';
        feature3Title = ' 부적図鑑 33スロット全開放';
        feature3Desc = '公式18種の即時コレクション＋MY custom 15スロット開放';
        feature4Title = '広告完全非表示';
        feature4Desc = '全ての広告をスキップした快適な体験';
        feature5Title = '毎日追加ドロー +3回';
        feature5Desc = '1日1回 → 合計4回のキー回転が毎日可能';
        pouchTitle = '🗝️ 黄金の鍵10個ポーチ (消耗品)';
        pouchDesc = '¥120 — 今すぐ回して錬成したい方向けの追加キーパック';
        actionButtonText = 'PRO を有効化';
        alreadyProText = 'PRO 利用中 — 全機能アンロック済 👑';
        closeText = '閉じる';
        break;
      case 'zh':
        title = '👑 DOK-KEY 专业版 (1年)';
        subtitle = '解锁全部功能 — 比一杯咖啡更实惠';
        priceText = '¥68 / 1年';
        priceSub = '全部功能一键解锁 (无额外费用)';
        feature1Title = '组合库 99格大容量扩展';
        feature1Desc = '解除免费9格限制，尊享99格本地组合空间';
        feature2Title = '自定义图鉴 99主题扩展';
        feature2Desc = '33张×最多99主题卡槽(共3,267张)自由替换';
        feature3Title = ' 符咒图鉴 33格全开放';
        feature3Desc = '官方18种立即收集＋MY custom 15格全开放';
        feature4Title = '广告完全移除';
        feature4Desc = '跳过所有广告，极速清爽体验';
        feature5Title = '每日追加抽取 +3次';
        feature5Desc = '每日1次 → 每天共4次转钥匙机会';
        pouchTitle = '🗝️ 黄金钥匙10个锦囊 (消耗品)';
        pouchDesc = '¥120 — 想立即抽取与炼成用户的追加钥匙包';
        actionButtonText = '立即解锁专业版';
        alreadyProText = '专业版使用中 — 全功能已解锁 👑';
        closeText = '关闭';
        break;
      case 'hi':
        title = '👑 DOK-KEY प्रो (1 वर्ष प्लान)';
        subtitle = 'सभी फ़ीचर्स अनलॉक — एक कॉफ़ी से भी सस्ता';
        priceText = '₹149 / 1 वर्ष';
        priceSub = 'सभी फ़ीचर्स का वन-टैप अनलॉक (कोई अतिरिक्त शुल्क नहीं)';
        feature1Title = '99 कंबिनेशन स्लॉट विस्तार';
        feature1Desc = 'मुफ़्त 9 स्लॉट सीमा हटें — 99 विशाल स्लॉट';
        feature2Title = 'कस्टम संग्रह 99 थीम विस्तार';
        feature2Desc = '33×अधिकतम 99 थीम स्लॉट (कुल 3,267 कार्ड) स्वतंत्र उपयोग';
        feature3Title = ' ताबीज संग्रह 33 स्लॉट पूर्ण खुले';
        feature3Desc = 'आधिकारिक 18 का तुरंत संग्रह + MY custom 15 स्लॉट खुले';
        feature4Title = 'विज्ञापन पूर्ण हटाए गए';
        feature4Desc = 'सभी विज्ञापन छोड़कर तेज़ अनुभव';
        feature5Title = 'रोज़ाना अतिरिक्त ड्रॉ +3';
        feature5Desc = 'दिन में 1 → कुल 4 बार की चाबी घुमाव';
        pouchTitle = '🗝️ गोल्डन की 10 पाउच (उपभोग्य)';
        pouchDesc = '₹99 — तुरंत घुमाकर संग्रह बढ़ाने वालों के लिए';
        actionButtonText = 'प्रो अनलॉक करें';
        alreadyProText = 'PRO सक्रिय — सभी फ़ीचर्स अनलॉक्ड 👑';
        closeText = 'बंद करें';
        break;
      case 'de':
        title = '👑 DOK-KEY PRO (1-Jahres-Plan)';
        subtitle = 'Alle Funktionen freischaltet — günstiger als ein Kaffee';
        priceText = '1,99 € / 1 Jahr';
        priceSub = 'Alle Funktionen mit einem Tap freischalten (ohne Zusatzkosten)';
        feature1Title = '99 Kombinations-Slots';
        feature1Desc = 'Gratis-Limit von 9 Slots fallen lassen — 99 geräumige Slots';
        feature2Title = 'Custom-Kodex 99 Themes';
        feature2Desc = '33 Karten × bis zu 99 Theme-Slots (3.267 Karten) frei tauschbar';
        feature3Title = ' Talisman-Kodex: alle 33 Slots offen';
        feature3Desc = '18 offizielle sofort gesammelt + 15 MY-Custom-Slots offen';
        feature4Title = 'Werbung vollständig entfernt';
        feature4Desc = 'Alle Werbung überspringen — blitzschnell';
        feature5Title = 'Täglich +3 Extra-Ziehungen';
        feature5Desc = '1× pro Tag → insgesamt 4× Schlüsseldrehen';
        pouchTitle = '🗝️ Goldener Schlüssel-Bundle (10 Stk., Verbrauchsgut)';
        pouchDesc = '0,99 € — für alle, die sofort drehen und sammeln wollen';
        actionButtonText = 'PRO freischalten';
        alreadyProText = 'PRO aktiv — alle Funktionen freigeschaltet 👑';
        closeText = 'Schließen';
        break;
      case 'en':
        title = '👑 DOK-KEY PRO (1-Year Plan)';
        subtitle = 'All-Features Unlocked — cheaper than a cup of coffee';
        priceText = '\$1.99 / 1 Year';
        priceSub = 'All-Features Unlocked with one tap (no extra fees)';
        feature1Title = '99 Combined Vault Slots';
        feature1Desc = 'Drop the free 9-slot limit — 99 massive local slots';
        feature2Title = 'Custom Codex 99 Themes';
        feature2Desc = '33 cards × up to 99 theme slots (3,267 cards total), freely swappable';
        feature3Title = ' Talisman Codex: all 33 slots open';
        feature3Desc = 'Official 18 instantly collected + 15 MY custom slots open';
        feature4Title = '100% Ads Removed';
        feature4Desc = 'Skip all ads for a fast, clean experience';
        feature5Title = 'Daily Extra Draws +3';
        feature5Desc = '1 per day → 4 total key spins every day';
        pouchTitle = '🗝️ Golden Key Pouch ×10 (Consumable)';
        pouchDesc = '\$0.99 — for those who want to spin and collect right now';
        actionButtonText = 'Unlock PRO';
        alreadyProText = 'PRO Active — All-Features Unlocked 👑';
        closeText = 'Close';
        break;
      case 'ko':
      default:
        title = '👑 DOK-KEY PRO (1년 이용권)';
        subtitle = '모든 기능 잠금해제 — 커피 한 잔보다 저렴하게';
        priceText = '₩2,500 / 1년';
        priceSub = '모든 기능 잠금해제 (추가 결제 없음)';
        feature1Title = '조합 보관함 99슬롯 대용량 확장';
        feature1Desc = '무료 9슬롯 한도 해제 → 99슬롯 대용량 로컬 보관';
        feature2Title = '커스텀 도감 99테마 확장';
        feature2Desc = '테마당 33종 × 최대 99슬롯(총 3,267장) 자유 교체';
        feature3Title = ' 부적 도감 33슬롯 전체 개방';
        feature3Desc = '공식 18종 즉시 수집 + MY 커스텀 15슬롯 완전 개방';
        feature4Title = '광고 100% 제거';
        feature4Desc = '전면·배너 광고 없이 빠르고 쾌적한 실행';
        feature5Title = '매일 데일리 추가 뽑기 +3회';
        feature5Desc = '하루 1회 → 하루 총 4회 열쇠 돌리기';
        pouchTitle = '🗝️ 황금 열쇠 10개 주머니 (소모품)';
        pouchDesc = '₩1,200 — 지금 바로 돌리고 모으고 싶은 분께';
        actionButtonText = 'PRO 잠금해제';
        alreadyProText = 'PRO 이용 중 — 모든 기능 잠금해제 👑';
        closeText = '닫기';
        break;
    }

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 20),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 440),
        decoration: BoxDecoration(
          color: DokkeyTheme.cardDark,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: DokkeyTheme.gold, width: 2),
          boxShadow: [
            BoxShadow(
              color: DokkeyTheme.gold.withOpacity(0.25),
              blurRadius: 30,
              spreadRadius: 2,
            ),
          ],
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Crown Icon
              Center(
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [DokkeyTheme.goldLight, DokkeyTheme.gold],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: DokkeyTheme.gold.withOpacity(0.4),
                        blurRadius: 16,
                      ),
                    ],
                  ),
                  child: const Icon(Icons.workspace_premium_rounded, color: Colors.black, size: 36),
                ),
              ),
              const SizedBox(height: 12),

              Text(
                title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.w900,
                  color: DokkeyTheme.goldLight,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                textAlign: TextAlign.center,
                style: TextStyle(color: DokkeyTheme.textMuted, fontSize: 12, height: 1.4),
              ),
              const SizedBox(height: 16),

              // Price Box — 1년 이용권
              Container(
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                decoration: BoxDecoration(
                  color: DokkeyTheme.surfaceDark,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: DokkeyTheme.gold.withOpacity(0.5)),
                ),
                child: Column(
                  children: [
                    Text(
                      priceText,
                      style: const TextStyle(
                        color: Colors.amber,
                        fontSize: 19,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      priceSub,
                      style: TextStyle(color: DokkeyTheme.textMuted, fontSize: 11),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // 5 Benefits (All-Features Unlocked)
              _buildBenefitRow(Icons.inventory_2_rounded, feature1Title, feature1Desc),
              const SizedBox(height: 9),
              _buildBenefitRow(Icons.palette_rounded, feature2Title, feature2Desc),
              const SizedBox(height: 9),
              _buildBenefitRow(Icons.grid_view_rounded, feature3Title, feature3Desc),
              const SizedBox(height: 9),
              _buildBenefitRow(Icons.block_rounded, feature4Title, feature4Desc),
              const SizedBox(height: 9),
              _buildBenefitRow(Icons.add_circle_outline_rounded, feature5Title, feature5Desc),
              const SizedBox(height: 14),

              // 🗝️ 황금 열쇠 10개 주머니 (소모품 안내)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: DokkeyTheme.surfaceDark,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: DokkeyTheme.borderDark),
                ),
                child: Row(
                  children: [
                    const Text('🗝️', style: TextStyle(fontSize: 20)),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            pouchTitle,
                            style: TextStyle(
                              color: DokkeyTheme.textMain,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            pouchDesc,
                            style: TextStyle(color: DokkeyTheme.textMuted, fontSize: 10.5),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Activation / Status Button
              if (isPro)
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.greenAccent),
                  ),
                  child: Text(
                    alreadyProText,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.greenAccent,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                )
              else
                ElevatedButton(
                  onPressed: () async {
                    await provider.upgradeToProPass();
                    SoundService().playGong();
                    if (context.mounted) {
                      Navigator.of(context).pop();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            lang == 'ko'
                                ? '🎉 PRO가 잠금해제되었습니다! 99개 조합 슬롯과 부적 33슬롯이 열렸습니다.'
                                : '🎉 PRO Unlocked! 99 vault slots & talisman codex are open.',
                          ),
                          backgroundColor: DokkeyTheme.surfaceDark,
                        ),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: DokkeyTheme.gold,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 6,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.flash_on_rounded, size: 20, color: Colors.black),
                      const SizedBox(width: 6),
                      Text(
                        actionButtonText,
                        style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14),
                      ),
                    ],
                  ),
                ),

              const SizedBox(height: 8),
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(closeText, style: TextStyle(color: DokkeyTheme.textMuted, fontSize: 13)),
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
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: DokkeyTheme.gold.withOpacity(0.15),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: DokkeyTheme.goldLight, size: 18),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  color: DokkeyTheme.textMain,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                desc,
                style: TextStyle(
                  color: DokkeyTheme.textMuted,
                  fontSize: 11,
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
