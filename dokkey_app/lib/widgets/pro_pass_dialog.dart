import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/theme.dart';
import '../core/sound_service.dart';
import '../providers/dokkey_provider.dart';

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
    String actionButtonText;
    String alreadyProText;
    String closeText;

    switch (lang) {
      case 'ja':
        title = 'DOK-KEY 10年安心プロパス';
        subtitle = 'たった1回1,100円で10年間すべてのプレミアム機能を快適に利用';
        priceText = '¥1,100 / 10年間';
        priceSub = '年間110円 (月約9円)の圧倒的バリュー';
        feature1Title = '10年安心クラウドアカウント';
        feature1Desc = '端末変更や再インストールでも10年間収集データと組合せキーを完全保護';
        feature2Title = 'カスタム図鑑 99スロット拡張';
        feature2Desc = '33種×最大99テーマスロット(計3,267枚)の自由入替＆拡張';
        feature3Title = '組合せ保管箱 99スロット拡張';
        feature3Desc = '無料版9個の制限解除 → 最大99個の大容量保管';
        feature4Title = '快適な広告完全非表示';
        feature4Desc = 'すべての広告を除去し、最速で快適な体験を提供';
        actionButtonText = '10年安心プロパスを有効化';
        alreadyProText = 'すでに10年安心プロパスをご利用中です 👑';
        closeText = '閉じる';
        break;
      case 'zh':
        title = 'DOK-KEY 10年安心专业通行证';
        subtitle = '仅需一次付费 ¥68，畅享10年全部高级特权';
        priceText = '¥68 / 10年';
        priceSub = '年均仅 ¥6.8 (月均不到 ¥0.6) 的超值体验';
        feature1Title = '10年安心云端金库';
        feature1Desc = '更换设备或重装系统，10年内所有钥匙与组合数据安全留存';
        feature2Title = '自定义图鉴 99卡槽扩展';
        feature2Desc = '支持33张×最大99主题卡槽(共3,267张)自由替换与扩容';
        feature3Title = '组合库扩容至99格';
        feature3Desc = '突破免费版9格限制，尊享99格超大组合空间';
        feature4Title = '纯净无广告体验';
        feature4Desc = '彻底去除所有插屏与奖励广告，秒速流畅';
        actionButtonText = '立即开通 10年安心专业版';
        alreadyProText = '您已尊享10年安心专业版特权 👑';
        closeText = '关闭';
        break;
      case 'hi':
        title = 'DOK-KEY 10-वर्षीय सुरक्षित प्रो पास';
        subtitle = 'केवल ₹899 में 10 वर्षों के लिए प्रीमियम सुविधाएं';
        priceText = '₹899 / 10 वर्ष';
        priceSub = 'प्रति वर्ष मात्र ₹90 का अविश्वसनीय मूल्य';
        feature1Title = '10-वर्षीय क्लाउड सुरक्षा';
        feature1Desc = 'डिवाइस बदलने पर भी 10 वर्षों तक सारा डेटा सुरक्षित';
        feature2Title = '99 कस्टम संग्रह स्लॉट (33×99)';
        feature2Desc = '33×99 स्लॉट संरचना में कस्टम थीम जोड़ें और बदलें';
        feature3Title = '99 संयोजन स्लॉट विस्तार';
        feature3Desc = 'मुफ्त 9 स्लॉट से 99 विशाल संयोजन स्लॉट में अपग्रेड';
        feature4Title = 'विज्ञापन मुक्त अनुभव';
        feature4Desc = 'बिना किसी रुकावट के तेज़ और सहज उपयोग';
        actionButtonText = '10-वर्षीय प्रो पास सक्रिय करें';
        alreadyProText = 'आप पहले से ही 10-वर्षीय प्रो पास धारक हैं 👑';
        closeText = 'बंद करें';
        break;
      case 'de':
        title = 'DOK-KEY 10-Jahre-Sicherheitspass';
        subtitle = 'Einmalig 9,99 € für 10 volle Jahre unbegrenzten Premium-Zugang';
        priceText = '9,99 € / 10 Jahre';
        priceSub = 'Nur ~1,00 €/Jahr (~0,08 €/Monat) unglaublicher Wert';
        feature1Title = '10-Jahre-Cloud-Tresor';
        feature1Desc = 'Sichere Datensicherung und Synchronisation für 10 volle Jahre';
        feature2Title = '99-Slot-Kompendium (33×99)';
        feature2Desc = 'Bis zu 99 Themendecks (je 33 Karten, 3.267 Karten gesamt)';
        feature3Title = '99 Kombinations-Slots';
        feature3Desc = 'Upgrade von 9 freien Slots auf 99 geräumige Kombi-Plätze';
        feature4Title = '100% Werbefreies Erlebnis';
        feature4Desc = 'Vollkommen werbefrei, blitzschnell und ungestört';
        actionButtonText = '10-Jahre-Pass aktivieren';
        alreadyProText = 'Sie nutzen bereits den 10-Jahre-Sicherheitspass 👑';
        closeText = 'Schließen';
        break;
      case 'en':
        title = 'DOK-KEY 10-Year Safe Pro Pass';
        subtitle = 'One-time \$9.99 for 10 full years of premium features';
        priceText = '\$9.99 / 10 Years';
        priceSub = 'Only ~\$1.00/year (~\$0.08/month) incredible value';
        feature1Title = '10-Year Safe Cloud Locker';
        feature1Desc = 'Safe backup & sync across devices for 10 full years';
        feature2Title = 'Custom Codex 99-Slot Expansion';
        feature2Desc = 'Expand up to 99 theme slots (33 cards each, 3,267 cards total)';
        feature3Title = '99 Combined Key Vault Slots';
        feature3Desc = 'Upgrade from 9 free slots to 99 massive combination slots';
        feature4Title = '100% Ad-Free Experience';
        feature4Desc = 'Remove all interstitial and rewarded ads for instant speed';
        actionButtonText = 'Activate 10-Year Pro Pass';
        alreadyProText = 'You are already a 10-Year Pro Pass member 👑';
        closeText = 'Close';
        break;
      case 'ko':
      default:
        title = 'DOK-KEY 10년 안심 프로 패스';
        subtitle = '단 1회 10,000원으로 10년간 모든 프리미엄 기능을 안심 이용';
        priceText = '₩10,000 / 10년 이용권';
        priceSub = '연 1,000원꼴 (월 83원)의 압도적 가성비';
        feature1Title = '10년 안심 클라우드 락커';
        feature1Desc = '기기 변경·재설치 시에도 10년간 열쇠와 조합 데이터 100% 안전 보관';
        feature2Title = '커스텀 도감 99슬롯 확장 (33×99)';
        feature2Desc = '테마당 33종 × 최대 99개 슬롯(총 3,267장) 지원 및 자유 교체';
        feature3Title = '조합 보관함 99슬롯 확장';
        feature3Desc = '무료 9개 제한 해제 → 최대 99개 대용량 조합 키 보관';
        feature4Title = '완벽한 광고 제거 (Ad-Free)';
        feature4Desc = '전면 및 보상형 광고 없이 쾌적하고 빠른 이용 환경';
        actionButtonText = '10년 안심 프로 패스 활성화';
        alreadyProText = '이미 10년 안심 프로 패스를 이용 중입니다 👑';
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
              // Pro Crown Icon & Badge
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

              // Title
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

              // Price Box
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
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
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
              const SizedBox(height: 16),

              // 4 Benefits
              _buildBenefitRow(Icons.cloud_done_rounded, feature1Title, feature1Desc),
              const SizedBox(height: 10),
              _buildBenefitRow(Icons.palette_rounded, feature2Title, feature2Desc),
              const SizedBox(height: 10),
              _buildBenefitRow(Icons.grid_view_rounded, feature3Title, feature3Desc),
              const SizedBox(height: 10),
              _buildBenefitRow(Icons.block_rounded, feature4Title, feature4Desc),
              const SizedBox(height: 20),

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
                                ? '🎉 10년 안심 프로 패스가 활성화되었습니다! 99개 조합 슬롯이 개방되었습니다.'
                                : '🎉 10-Year Safe Pro Pass Activated!',
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
