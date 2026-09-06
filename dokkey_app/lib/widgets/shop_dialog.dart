import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/theme.dart';
import '../core/sound_service.dart';
import '../providers/dokkey_provider.dart';
import 'riddle_dialog.dart';
import 'pro_pass_dialog.dart';

class ShopDialog extends StatelessWidget {
  const ShopDialog({super.key});

  static void show(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => const ShopDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<DokkeyProvider>();
    final isKo = provider.lang == 'ko';
    final isJa = provider.lang == 'ja';

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Container(
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          color: DokkeyTheme.cardDark,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: DokkeyTheme.gold, width: 2),
          boxShadow: [
            BoxShadow(
              color: DokkeyTheme.gold.withOpacity(0.2),
              blurRadius: 28,
            ),
          ],
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Row(
                children: [
                  const SizedBox(width: 24),
                  const Spacer(),
                  Icon(Icons.storefront_rounded, color: DokkeyTheme.gold, size: 24),
                  const SizedBox(width: 8),
                  Text(
                    isKo ? '깨비의 만물상' : (isJa ? 'クケビの萬物店' : "Kkaebi's Shop"),
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: DokkeyTheme.goldLight,
                      letterSpacing: 1.0,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: Icon(Icons.close_rounded, color: DokkeyTheme.textMuted, size: 22),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    tooltip: isKo ? '닫기' : (isJa ? '閉じる' : 'Close'),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                isKo
                    ? '오늘의 데일리 열쇠를 무료로 충전하세요'
                    : (isJa ? '今日のデイリー鍵をチャージしましょう' : 'Refill your daily keys for free'),
                textAlign: TextAlign.center,
                style: TextStyle(color: DokkeyTheme.textMuted, fontSize: 12),
              ),
              const SizedBox(height: 20),

              // Item 1: Daily Free Treasure Box
              _ShopItem(
                icon: Icons.card_giftcard_rounded,
                iconColor: DokkeyTheme.dokFire,
                title: isKo ? '일일 무료 도깨비 보물상자' : (isJa ? '一日一回無料の宝箱' : 'Daily Free Treasure Box'),
                subtitle: isKo
                    ? (provider.canClaimBonusBox ? '탭하여 보너스 열쇠 +1 획득' : '오늘 이미 획득했습니다 (내일 다시 오픈)')
                    : (provider.canClaimBonusBox ? 'Tap to get +1 Bonus Key' : 'Claimed for today'),
                badge: provider.canClaimBonusBox ? 'FREE' : 'DONE',
                badgeColor: provider.canClaimBonusBox ? DokkeyTheme.mintCalm : DokkeyTheme.textMuted,
                isEnabled: provider.canClaimBonusBox,
                onTap: () async {
                  final success = await provider.claimDailyBonusBox();
                  if (success) {
                    SoundService().playBoxOpen();
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(isKo ? '보너스 열쇠 1개를 획득했습니다! 🗝️' : (isJa ? 'ボーナスキー +1 を獲得! 🗝️' : 'Earned +1 Bonus Key! 🗝️')),
                          backgroundColor: DokkeyTheme.surfaceDark,
                        ),
                      );
                    }
                  }
                },
              ),
              const SizedBox(height: 12),

              // Item 2: Riddle Challenge
              _ShopItem(
                icon: Icons.psychology_outlined,
                iconColor: DokkeyTheme.gold,
                title: isKo ? '깨비의 수수께끼 맞히기' : (isJa ? 'クケビのなぞなぞ挑戦' : "Solve Kkaebi's Riddle"),
                subtitle: isKo ? '정답 시 보너스 열쇠 즉시 지급' : 'Earn bonus keys with correct answer',
                badge: '+1 KEY',
                badgeColor: DokkeyTheme.gold,
                isEnabled: true,
                onTap: () {
                  Navigator.of(context).pop();
                  final riddle = provider.getTodayRiddle();
                  showDialog(
                    context: context,
                    builder: (_) => RiddleDialog(riddle: riddle),
                  );
                },
              ),
              const SizedBox(height: 12),

              // Item 3: Ad Reward Simulation
              _ShopItem(
                icon: Icons.ondemand_video_rounded,
                iconColor: const Color(0xFF64B5F6),
                title: isKo ? '깨비의 응원 영상 시청' : (isJa ? '応援動画を見てチャージ' : 'Watch Short Clip'),
                subtitle: isKo ? '간단한 시청 후 열쇠 +1개 지급' : 'Get +1 key immediately',
                badge: '+1 KEY',
                badgeColor: const Color(0xFF64B5F6),
                isEnabled: true,
                onTap: () async {
                  await provider.addBonusKeys(1);
                  SoundService().playSuccessChime();
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(isKo ? '열쇠 1개가 충전되었습니다! 🗝️' : (isJa ? 'キー +1 をチャージしました! 🗝️' : '+1 Key refilled! 🗝️')),
                        backgroundColor: DokkeyTheme.surfaceDark,
                      ),
                    );
                  }
                },
              ),
              // Item 4: DOK-KEY 10-Year Safe Pro Pass
              _ShopItem(
                icon: Icons.workspace_premium_rounded,
                iconColor: DokkeyTheme.gold,
                title: isKo
                    ? 'DOK-KEY 10년 안심 프로 패스'
                    : (isJa
                        ? '10年安心プロパス (10,000₩)'
                        : (provider.lang == 'zh'
                            ? '10年安心专业通行证'
                            : (provider.lang == 'de' ? '10-Jahre-Sicherheitspass' : (provider.lang == 'hi' ? '10-वर्षीय सुरक्षित प्रो पास' : '10-Year Safe Pro Pass')))),
                subtitle: isKo
                    ? '₩10,000 / 10년 (연 1,000원꼴) · 99슬롯·클라우드·도감'
                    : '10-Yr Safe Locker · 99 Slots · Custom Codex · Ad-Free',
                badge: provider.isProUser ? 'PRO 👑' : '₩10,000',
                badgeColor: DokkeyTheme.gold,
                isEnabled: true,
                onTap: () {
                  Navigator.of(context).pop();
                  ProPassDialog.show(context);
                },
              ),
              const SizedBox(height: 20),

              // Close Button
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(isKo ? '닫기' : 'Close', style: TextStyle(color: DokkeyTheme.textMuted)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ShopItem extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final String badge;
  final Color badgeColor;
  final bool isEnabled;
  final VoidCallback onTap;

  const _ShopItem({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.badge,
    required this.badgeColor,
    required this.isEnabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: DokkeyTheme.surfaceDark,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: isEnabled ? DokkeyTheme.borderDark : DokkeyTheme.borderDark.withOpacity(0.3)),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isEnabled ? onTap : null,
          borderRadius: BorderRadius.circular(18),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: iconColor.withOpacity(0.15),
                  ),
                  child: Icon(icon, color: iconColor, size: 22),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          color: isEnabled ? DokkeyTheme.textMain : DokkeyTheme.textMuted,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: TextStyle(color: DokkeyTheme.textMuted, fontSize: 11),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: badgeColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: badgeColor.withOpacity(0.5)),
                  ),
                  child: Text(
                    badge,
                    style: TextStyle(
                      color: badgeColor,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}