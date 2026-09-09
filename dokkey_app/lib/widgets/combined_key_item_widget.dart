import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../core/theme.dart';
import '../core/sound_service.dart';
import '../models/vault_models.dart';
import '../providers/dokkey_provider.dart';

class CombinedKeyItemWidget extends StatelessWidget {
  final CombinedKeyItem item;
  final VoidCallback? onDelete;

  const CombinedKeyItemWidget({
    super.key,
    required this.item,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<DokkeyProvider>();
    final isKo = provider.lang == 'ko';

    final createdDateStr =
        '${item.createdAt.year}.${item.createdAt.month.toString().padLeft(2, '0')}.${item.createdAt.day.toString().padLeft(2, '0')}';
    final formattedNumbers = item.formattedNumbers;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: DokkeyTheme.surfaceDark,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: item.isPermanent ? DokkeyTheme.gold : DokkeyTheme.borderDark,
          width: item.isPermanent ? 1.5 : 1.0,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Top Row: Date, N-Key Badge, TTL/Permanent Status, Actions
          Row(
            children: [
              // N Keys Badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: DokkeyTheme.gold.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: DokkeyTheme.gold.withOpacity(0.5)),
                ),
                child: Text(
                  '${item.numbers.length} Keys',
                  style: TextStyle(
                    color: DokkeyTheme.goldLight,
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const SizedBox(width: 8),

              // Date
              Text(
                createdDateStr,
                style: TextStyle(
                  color: DokkeyTheme.textMuted,
                  fontSize: 12,
                ),
              ),
              const SizedBox(width: 8),

              // 10-Year Lock or D-Day
              if (item.isPermanent)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.amber.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: Colors.amber.withOpacity(0.4), width: 0.8),
                  ),
                  child: Text(
                    provider.lang == 'ko'
                        ? '장기 보관'
                        : (provider.lang == 'ja'
                            ? '10年保管'
                            : (provider.lang == 'zh'
                                ? '10年保管'
                                : (provider.lang == 'hi' ? '10 वर्ष लॉक' : '10-Yr Lock'))),
                    style: const TextStyle(color: Colors.amber, fontSize: 10, fontWeight: FontWeight.bold),
                  ),
                )
              else
                Text(
                  item.dDayString,
                  style: TextStyle(color: DokkeyTheme.textMuted.withOpacity(0.8), fontSize: 11),
                ),

              const Spacer(),

              // Copy Button
              IconButton(
                icon: const Icon(Icons.copy_rounded, size: 18),
                color: DokkeyTheme.goldLight,
                tooltip: isKo ? '번호 복사' : 'Copy Numbers',
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                padding: EdgeInsets.zero,
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: formattedNumbers));
                  SoundService().playKeyTurn();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(isKo ? '조합 키 [$formattedNumbers]가 복사되었습니다! 📋' : 'Copied [$formattedNumbers]!'),
                      backgroundColor: DokkeyTheme.cardDark,
                      duration: const Duration(seconds: 2),
                    ),
                  );
                },
              ),

              // Pin (Permanent) Toggle Button
              IconButton(
                icon: Icon(
                  item.isPermanent ? Icons.push_pin_rounded : Icons.push_pin_outlined,
                  size: 18,
                ),
                color: item.isPermanent ? DokkeyTheme.gold : DokkeyTheme.textMuted,
                tooltip: provider.lang == 'ko'
                    ? (item.isPermanent ? '장기 보관 해제' : '장기 보관 고정')
                    : (provider.lang == 'ja'
                        ? (item.isPermanent ? '10年保管解除' : '10年安心保管固定')
                        : (provider.lang == 'zh'
                            ? (item.isPermanent ? '取消10年保管' : '10年安心保管')
                            : (provider.lang == 'hi'
                                ? (item.isPermanent ? '10 वर्ष लॉक हटाएं' : '10 वर्ष सुरक्षित लॉक')
                                : '10-Yr Lock'))),
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                padding: EdgeInsets.zero,
                onPressed: () {
                  provider.togglePermanentLock(item.id);
                  HapticFeedback.selectionClick();
                },
              ),

              // Delete Button
              if (onDelete != null)
                IconButton(
                  icon: const Icon(Icons.delete_outline_rounded, size: 18),
                  color: DokkeyTheme.textMuted,
                  tooltip: isKo ? '삭제' : 'Delete',
                  constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                  padding: EdgeInsets.zero,
                  onPressed: onDelete,
                ),
            ],
          ),
          const SizedBox(height: 10),

          // Bottom Row: Numbers Chip Row (Horizontal Scroll)
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: item.numbers.map((numStr) {
                return Container(
                  margin: const EdgeInsets.only(right: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: DokkeyTheme.cardDark,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: DokkeyTheme.gold.withOpacity(0.3)),
                  ),
                  child: Text(
                    numStr,
                    style: TextStyle(
                      color: DokkeyTheme.goldLight,
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.5,
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}